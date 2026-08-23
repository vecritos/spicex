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

# =============================
# 1) Base / default allowlist
# =============================
# Allow loopback traffic for IPv4 and IPv6
sudo nft add rule inet spicex_firewall input iifname "lo" accept
sudo nft add rule inet spicex_firewall output oifname "lo" accept

# Allow return traffic for established sessions
sudo nft add rule inet spicex_firewall input ct state established,related accept
sudo nft add rule inet spicex_firewall output ct state established,related accept

# =============================
# 2) Network bootstrap / system essentials
# =============================
# Allow DHCP and NTP so the host can actually function on a network
sudo nft add rule inet spicex_firewall output udp dport { 67, 68 } accept
sudo nft add rule inet spicex_firewall output udp dport 123 accept
sudo nft add rule inet spicex_firewall output udp dport 546 accept

# Allow safe ICMP for diagnostics and IPv6 neighbor discovery
sudo nft add rule inet spicex_firewall input ip protocol icmp limit rate 10/minute accept
sudo nft add rule inet spicex_firewall output ip protocol icmp limit rate 10/minute accept
sudo nft add rule inet spicex_firewall input ip6 nexthdr icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, router-solicitation, neighbor-solicitation, neighbor-advertisement } accept
sudo nft add rule inet spicex_firewall output ip6 nexthdr icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-reply, router-solicitation, neighbor-solicitation, neighbor-advertisement } accept

# =============================
# 3) DNS resolution
# =============================
# Allow DNS lookups to trusted public resolvers (IPv4 + IPv6)
sudo nft add rule inet spicex_firewall output ip daddr 8.8.8.8 udp dport 53 accept
sudo nft add rule inet spicex_firewall output ip daddr 8.8.8.8 tcp dport 53 accept
sudo nft add rule inet spicex_firewall output ip daddr 1.1.1.1 udp dport 53 accept
sudo nft add rule inet spicex_firewall output ip daddr 1.1.1.1 tcp dport 53 accept
sudo nft add rule inet spicex_firewall output ip6 daddr 2001:4860:4860::8888 udp dport 53 accept
sudo nft add rule inet spicex_firewall output ip6 daddr 2001:4860:4860::8888 tcp dport 53 accept
sudo nft add rule inet spicex_firewall output ip6 daddr 2606:4700:4700::1111 udp dport 53 accept
sudo nft add rule inet spicex_firewall output ip6 daddr 2606:4700:4700::1111 tcp dport 53 accept

# =============================
# 4) Internet access for common workflows
# =============================
# Allow web browsing and Git over HTTPS/HTTP
sudo nft add rule inet spicex_firewall output tcp dport { 80, 443 } ct state new,established accept

# Allow outbound SSH to other computers
sudo nft add rule inet spicex_firewall output tcp dport "$SSH_PORT" ct state new,established accept

# =============================
# 5) Logging / visibility
# =============================
# Log dropped packets without flooding the logs
sudo nft add rule inet spicex_firewall input limit rate 5/minute log prefix "DROP-IN: " counter drop
sudo nft add rule inet spicex_firewall output limit rate 5/minute log prefix "DROP-OUT: " counter drop

# Save and reload the ruleset
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
sudo nft -f /etc/nftables.conf

echo "[*] Standard firewall applied."
echo "[*] Allowed: DNS, browser traffic on 80/443, Git over HTTPS, and outbound SSH on port $SSH_PORT."
echo "[*] All inbound traffic is blocked by default except established/related replies."
