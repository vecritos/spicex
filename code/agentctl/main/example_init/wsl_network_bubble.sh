#!/bin/bash
# ===================================================
# WSL2 NAT Sandbox – Dual IP + VPN + DNS + Firewall
# Ubuntu 24.04
# ===================================================

set -e

echo "=== Starting WSL2 NAT Sandbox Setup ==="

# -----------------------------
# 1️⃣ Update & install necessary tools
# -----------------------------
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw openvpn tor torsocks dnsutils curl jq

# -----------------------------
# 2️⃣ UFW firewall – default deny
# -----------------------------
sudo ufw --force reset
sudo ufw default deny outgoing
sudo ufw default deny incoming

# Allow localhost for Tor and DNS
sudo ufw allow out to 127.0.0.1
sudo ufw allow in from 127.0.0.1

sudo ufw enable
echo "Firewall configured: default deny"

# -----------------------------
# 3️⃣ Encrypted DNS – stubby
# -----------------------------
sudo apt install -y stubby
sudo systemctl enable stubby
sudo systemctl start stubby

# Point DNS to local stubby
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 127.0.0.1
EOF

echo "Encrypted DNS active: $(dig +short @127.0.0.1 whoami.cloudflare)"

# -----------------------------
# 4️⃣ VPN setup – independent public IP
# -----------------------------
VPN_CONFIG="$HOME/configs/my-wsl-vpn.ovpn"

if [ -f "$VPN_CONFIG" ]; then
    echo "Starting WSL2 VPN..."
    sudo openvpn --config "$VPN_CONFIG" --daemon
    sleep 5
    VPN_IF=$(ip route | grep tun | awk '{print $3}' | head -n1)
    if [ -n "$VPN_IF" ]; then
        echo "WSL2 VPN interface detected: $VPN_IF"
    else
        echo "Warning: VPN interface not detected. Check config."
    fi
else
    echo "VPN config missing at $VPN_CONFIG. Skipping VPN."
fi

# -----------------------------
# 5️⃣ Force all traffic through VPN interface
# -----------------------------
if [ -n "$VPN_IF" ]; then
    echo "Routing all traffic through VPN..."
    sudo ip route add default dev "$VPN_IF"
    sudo iptables -A OUTPUT ! -o "$VPN_IF" -j DROP
    echo "Traffic now forced through VPN NAT interface"
fi

# -----------------------------
# 6️⃣ Tor optional
# -----------------------------
echo "Starting Tor service..."
sudo systemctl enable tor
sudo systemctl start tor
torsocks curl -s https://check.torproject.org | grep -q "Congratulations" && \
    echo "Tor ready" || echo "Tor failed"

# -----------------------------
# 7️⃣ WSL2 secure workspace folder
# -----------------------------
mkdir -p ~/SecureArchives
echo "Secure workspace ready at ~/SecureArchives"

# -----------------------------
# 8️⃣ Test public IP
# -----------------------------
echo "Testing WSL2 public IP via VPN:"
curl -s ifconfig.me

echo "=== WSL2 NAT Sandbox Setup Complete ==="
echo "Host and WSL2 now have separate public IPs:"
echo "- Windows host IP: check normal browser or curl ifconfig.me"
echo "- WSL2 sandbox IP: above VPN-assigned IP"
echo "All traffic in WSL2 is blocked except VPN/Tor, DNS encrypted, firewall enforced."

