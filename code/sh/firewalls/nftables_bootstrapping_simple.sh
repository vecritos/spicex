#!/usr/bin/env bash
set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"

if ! command -v nft >/dev/null 2>&1; then
    echo "[*] nftables is not installed. Installing it now..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y nftables
    else
        echo "Error: nft is required but no supported package manager was found."
        exit 1
    fi
fi

echo "[*] Applying standard nftables firewall for Git, browser traffic, and outbound SSH..."

sudo systemctl enable nftables 2>/dev/null || true
sudo systemctl start nftables 2>/dev/null || true
sudo nft flush ruleset

sudo nft add table inet spicex_firewall
sudo nft 'add chain inet spicex_firewall input { type filter hook input priority 0; policy drop; }'
sudo nft 'add chain inet spicex_firewall forward { type filter hook forward priority 0; policy drop; }'
sudo nft 'add chain inet spicex_firewall output { type filter hook output priority 0; policy drop; }'

# Allow loopback traffic
sudo nft add rule inet spicex_firewall input iifname "lo" accept
sudo nft add rule inet spicex_firewall output oifname "lo" accept

# Allow return traffic for established sessions
sudo nft add rule inet spicex_firewall input ct state established,related accept
sudo nft add rule inet spicex_firewall output ct state established,related accept

# Allow DNS lookups
sudo nft add rule inet spicex_firewall output udp dport 53 accept
sudo nft add rule inet spicex_firewall output tcp dport 53 accept

# Allow web browsing and Git over HTTPS/HTTP
sudo nft add rule inet spicex_firewall output tcp dport { 80, 443 } ct state new,established accept

# Allow outbound SSH to other computers
sudo nft add rule inet spicex_firewall output tcp dport "$SSH_PORT" ct state new,established accept

# Optional ICMP diagnostics
# sudo nft add rule inet spicex_firewall input ip protocol icmp accept
# sudo nft add rule inet spicex_firewall output ip protocol icmp accept

# Log dropped packets without flooding the logs
sudo nft add rule inet spicex_firewall input limit rate 5/minute log prefix "DROP-IN: " counter drop
sudo nft add rule inet spicex_firewall output limit rate 5/minute log prefix "DROP-OUT: " counter drop

# Save and reload the ruleset
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
sudo nft -f /etc/nftables.conf

echo "[*] Standard firewall applied."
echo "[*] Allowed: DNS, browser traffic on 80/443, Git over HTTPS, and outbound SSH on port $SSH_PORT."
echo "[*] All inbound traffic is blocked by default except established/related replies."
