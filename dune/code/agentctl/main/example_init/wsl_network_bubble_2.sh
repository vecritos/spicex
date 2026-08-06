#!/bin/bash
# ===================================================
# WSL2 NAT Sandbox with Manual Proxy Chain
# Ubuntu 24.04
# ===================================================

set -e

echo "=== Starting WSL2 NAT Sandbox with Proxy Chain ==="

# -----------------------------
# 1️⃣ Update system & install tools
# -----------------------------
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw tor proxychains-ng openvpn curl gnupg rsync

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
# 4️⃣ Tor SOCKS5
# -----------------------------
sudo systemctl enable tor
sudo systemctl start tor

# Confirm Tor is running
if curl --socks5 127.0.0.1:9050 -s https://check.torproject.org | grep -q "Congratulations"; then
    echo "Tor SOCKS5 running on 127.0.0.1:9050"
else
    echo "Warning: Tor test failed"
fi

# -----------------------------
# 5️⃣ ProxyChains configuration
# -----------------------------
echo "Configuring proxychains for manual chaining..."
PROXYCHAINS_CONF="/etc/proxychains.conf"

sudo tee $PROXYCHAINS_CONF > /dev/null <<EOF
strict_chain
proxy_dns
remote_dns_subnet 224
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
# 1) Tor local SOCKS5
socks5 127.0.0.1 9050
# 2) Optional VPN SOCKS5 (replace if your VPN provides one)
# socks5 10.10.10.1 1080
# 3) Optional external proxy hop
# socks5 1.2.3.4 1080
EOF

echo "ProxyChains configured. Edit $PROXYCHAINS_CONF to adjust hops."

# -----------------------------
# 6️⃣ VPN Setup (Optional)
# -----------------------------
VPN_CONFIG="$HOME/configs/my-wsl-vpn.ovpn"

if [ -f "$VPN_CONFIG" ]; then
    echo "Starting VPN..."
    sudo openvpn --config "$VPN_CONFIG" --daemon
    sleep 5
    VPN_IF=$(ip route | grep tun | awk '{print $3}' | head -n1)
    if [ -n "$VPN_IF" ]; then
        echo "VPN interface detected: $VPN_IF"
        # Route all traffic through VPN interface
        sudo ip route add default dev "$VPN_IF"
        sudo iptables -A OUTPUT ! -o "$VPN_IF" -j DROP
    else
        echo "Warning: VPN interface not detected"
    fi
else
    echo "VPN config not found. Skipping VPN."
fi

# -----------------------------
# 7️⃣ Secure workspace
# -----------------------------
mkdir -p ~/SecureArchives
echo "Secure workspace ready at ~/SecureArchives"

# -----------------------------
# 8️⃣ Alias for semi-automatic workflow
# -----------------------------
echo "Setting up aliases for manual control..."

# Add to ~/.bash_aliases or ~/.bashrc
tee -a ~/.bash_aliases > /dev/null <<'EOF'
# k: encrypt folder manually
alias k='read -sp "Enter passphrase: " P; echo; \
7z a -t7z ~/SecureArchives/MyData_$(date +%Y%m%d_%H%M).7z /mnt/c/Users/YourUser/SensitiveData -p"$P" -mhe=on'

# u: upload via proxy chain
alias u='read -p "Enter archive filename: " F; \
proxychains4 rclone copy ~/SecureArchives/"$F" cryptremote:securefolder'
EOF

echo "Aliases installed. Reload shell or run 'source ~/.bashrc'."
echo "Usage examples: k + Enter → encrypt, u + Enter → upload via proxy chain"

# -----------------------------
# 9️⃣ Test public IP through proxy chain
# -----------------------------
echo "Testing WSL2 public IP via proxy chain:"
proxychains4 curl -s https://ifconfig.me

echo "=== WSL2 NAT Sandbox with Proxy Chain Setup Complete ==="
echo "- Host Windows IP: normal network or host VPN"
echo "- WSL2 sandbox IP: above proxy/VPN chained IP"
echo "- All sensitive traffic should now go through configured proxy chain with encrypted DNS"

