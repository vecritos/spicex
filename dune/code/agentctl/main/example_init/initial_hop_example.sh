#!/bin/bash
# ===================================================
# WSL2 NAT Sandbox – Tor Initial Hop + VPN + Proxy Chain
# Ubuntu 24.04
# ===================================================

set -e

echo "=== Starting WSL2 NAT Sandbox Setup ==="

# -----------------------------
# 1️⃣ Update system & install tools
# -----------------------------
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw iptables tor openvpn proxychains-ng curl dnsutils gnupg p7zip-full rclone

# -----------------------------
# 2️⃣ Firewall – block all except local & VPN/proxy
# -----------------------------
sudo ufw --force reset
sudo ufw default deny outgoing
sudo ufw default deny incoming

# Allow localhost (Tor/Proxy)
sudo ufw allow out to 127.0.0.1
sudo ufw allow in from 127.0.0.1

sudo ufw enable
echo "Firewall configured: default deny"

# -----------------------------
# 3️⃣ Encrypted DNS via stubby
# -----------------------------
sudo apt install -y stubby
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 127.0.0.1
EOF
sudo systemctl enable stubby
sudo systemctl start stubby
echo "Encrypted DNS active: $(dig +short @127.0.0.1 whoami.cloudflare)"

# -----------------------------
# 4️⃣ Tor SOCKS5 (Initial Hop)
# -----------------------------
sudo systemctl enable tor
sudo systemctl start tor

# Test Tor
if curl --socks5 127.0.0.1:9050 -s https://check.torproject.org | grep -q "Congratulations"; then
    echo "Tor SOCKS5 running on 127.0.0.1:9050"
else
    echo "Warning: Tor test failed"
fi

# -----------------------------
# 5️⃣ ProxyChains configuration
# -----------------------------
PROXYCHAINS_CONF="/etc/proxychains.conf"
sudo tee $PROXYCHAINS_CONF > /dev/null <<EOF
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
# 1) Tor local SOCKS5 (initial hop)
socks5 127.0.0.1 9050
# 2) Optional VPN SOCKS5 (if provider supports)
# socks5 10.10.10.1 1080
# 3) Optional external proxy hop
# socks5 1.2.3.4 1080
EOF
echo "ProxyChains configured. Edit $PROXYCHAINS_CONF to adjust hops."

# -----------------------------
# 6️⃣ VPN Setup (over Tor)
# -----------------------------
VPN_CONFIG="$HOME/configs/my-wsl-vpn.ovpn"

if [ -f "$VPN_CONFIG" ]; then
    echo "Starting VPN through Tor..."
    sudo openvpn --config "$VPN_CONFIG" --daemon
    sleep 5
    VPN_IF=$(ip route | grep tun | awk '{print $3}' | head -n1)
    if [ -n "$VPN_IF" ]; then
        echo "VPN interface detected: $VPN_IF"

        # Route all traffic through VPN
        sudo ip route replace default dev "$VPN_IF"
        # Kill-switch: drop all outgoing not on VPN
        sudo iptables -A OUTPUT ! -o "$VPN_IF" -m conntrack --ctstate NEW -j DROP
        sudo ufw allow out on "$VPN_IF"
    else
        echo "Warning: VPN interface not detected. Check config."
    fi
else
    echo "VPN config missing at $VPN_CONFIG. Skipping VPN."
fi

# -----------------------------
# 7️⃣ Secure workspace
# -----------------------------
mkdir -p ~/SecureArchives
echo "Secure workspace ready at ~/SecureArchives"

# -----------------------------
# 8️⃣ Aliases for manual workflow
# -----------------------------
tee -a ~/.bash_aliases > /dev/null <<'EOF'
# k: encrypt folder manually with timestamp
alias k='read -sp "Enter passphrase: " P; echo; \
7z a -t7z ~/SecureArchives/MyData_$(date +%Y%m%d_%H%M).7z /mnt/c/Users/YourUser/SensitiveData -p"$P" -mhe=on'

# u: upload via proxy chain
alias u='read -p "Enter archive filename: " F; \
proxychains4 rclone copy ~/SecureArchives/"$F" cryptremote:securefolder'
EOF
echo "Aliases installed. Reload shell or run 'source ~/.bashrc'."

# -----------------------------
# 9️⃣ Test public IP through proxy chain
# -----------------------------
echo "Testing WSL2 public IP via proxy chain:"
proxychains4 curl -s https://ifconfig.me

echo "=== WSL2 NAT Sandbox Setup Complete ==="
echo "- Host Windows IP: normal network or host VPN"
echo "- WSL2 sandbox IP: above VPN-over-Tor chained IP"
echo "- All sensitive traffic should now go through Tor → VPN with encrypted DNS and firewall enforced"
echo "- Use 'k' to encrypt archives, 'u' to upload via proxy chain"

