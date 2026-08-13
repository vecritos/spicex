#!/bin/bash
# =========================================
# Basic IPv4 Hardening Firewall Script
# Author: ChatGPT
# Purpose: Paranoid but safe firewall for learning
# =========================================

echo "[*] Starting IPv4 firewall setup..."

# 1️⃣ush existing rules
sudo iptables -F
sudo iptables -X
sudo iptables -Z

# 2️⃣fault policies: DROP all by default
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT   # outgoing traffic allowed

# 3️⃣low loopback interface (internal system processes)
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# 4️⃣low established and related connections (return traffic)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 5️⃣low SSH (change port if needed)
SSH_PORT=22
sudo iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT

# 6️⃣tional: allow HTTP/HTTPS if you want a web server
#sudo iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
#sudo iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

# 7️⃣tional: ICMP (ping)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 8️⃣g dropped packets (optional, learning purpose)
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

# 9️⃣ve rules so they persist after reboot
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save

echo "[*] IPv4 firewall setup complete!"
