#!/bin/bash
# =========================================
# nftables Bootstrapping Firewall
# IPv4 + Dynamic GitHub Restriction
# =========================================

echo "[*] Starting nftables bootstrapping..."

read -p "Allow SSH access? (y/n) " ALLOW_SSH
read -p "Allow ping (ICMP)? (y/n) " ALLOW_PING
read -p "Allow GitHub access? (y/n) " ALLOW_GIT

# Install nftables if missing
sudo apt-get update
sudo apt-get install -y nftables curl

# Enable nftables service
sudo systemctl enable nftables
sudo systemctl start nftables

# Flush existing rules
sudo nft flush ruleset

# -----------------------------
# Base Ruleset
# -----------------------------
sudo nft add table inet firewall

sudo nft 'add chain inet firewall input { type filter hook input priority 0; policy drop; }'
sudo nft 'add chain inet firewall forward { type filter hook forward priority 0; policy drop; }'
sudo nft 'add chain inet firewall output { type filter hook output priority 0; policy drop; }'

# Allow loopback
sudo nft add rule inet firewall input iif lo accept
sudo nft add rule inet firewall output oif lo accept

# Allow established connections
sudo nft add rule inet firewall input ct state established,related accept
sudo nft add rule inet firewall output ct state established,related accept

# -----------------------------
# Optional SSH
# -----------------------------
if [[ "$ALLOW_SSH" =~ ^[Yy]$ ]]; then
    read -p "Enter SSH port (default 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
    sudo nft add rule inet firewall input tcp dport $SSH_PORT ct state new accept
    echo "[*] SSH allowed on port $SSH_PORT"
fi

# -----------------------------
# Optional Ping
# -----------------------------
if [[ "$ALLOW_PING" =~ ^[Yy]$ ]]; then
    sudo nft add rule inet firewall input ip protocol icmp icmp type echo-request accept
    echo "[*] Ping allowed"
fi

# -----------------------------
# GitHub Restriction
# -----------------------------
if [[ "$ALLOW_GIT" =~ ^[Yy]$ ]]; then
    echo "[*] Fetching official GitHub IP ranges..."

    # Temporary DNS + HTTPS for metadata fetch
    sudo nft add rule inet firewall output udp dport 53 accept
    sudo nft add rule inet firewall output tcp dport 53 accept
    sudo nft add rule inet firewall output tcp dport 443 accept

    GITHUB_META=$(curl -s https://api.github.com/meta)

    GIT_IPS=$(echo "$GITHUB_META" | \
        grep -Eo '"([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+)"' | tr -d '"')

    # Remove temporary open HTTPS
    sudo nft delete rule inet firewall output handle $(sudo nft -a list chain inet firewall output | grep 'tcp dport 443 accept' | awk '{print $NF}')

    # Create GitHub set
    sudo nft add set inet firewall github_ips '{ type ipv4_addr; flags interval; }'

    for ip in $GIT_IPS; do
        sudo nft add element inet firewall github_ips { $ip }
    done

    # Allow HTTPS only to GitHub IPs
    sudo nft add rule inet firewall output ip daddr @github_ips tcp dport 443 ct state new,established accept

    echo "[*] GitHub access restricted to official published ranges."
fi

# -----------------------------
# Logging (rate limited)
# -----------------------------
sudo nft add rule inet firewall input limit rate 5/minute log prefix \"NFT-Dropped-IN: \" drop
sudo nft add rule inet firewall output limit rate 5/minute log prefix \"NFT-Dropped-OUT: \" drop

# Save config permanently
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null

echo "[*] nftables bootstrapping complete."