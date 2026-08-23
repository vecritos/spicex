#!/bin/bash
# =========================================
# Bootstrapping Firewall + Paranoid Git Script
# =========================================

echo "[*] Starting bootstrapping script..."

# -----------------------------
# 1️⃣ Firewall configuration
# -----------------------------

read -p "Do you want to allow SSH access? (y/n) " ALLOW_SSH
read -p "Do you want to allow ping (ICMP echo requests)? (y/n) " ALLOW_PING

# Flush existing rules
sudo iptables -F
sudo iptables -X
sudo iptables -Z

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP   # outgoing is locked down

# Loopback interface
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Established/related connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Conditional rules
if [[ "$ALLOW_SSH" =~ ^[Yy]$ ]]; then
    read -p "Enter SSH port to allow (default 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
    sudo iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT
    echo "[*] SSH allowed on port $SSH_PORT"
else
    echo "[*] SSH access blocked"
fi

if [[ "$ALLOW_PING" =~ ^[Yy]$ ]]; then
    sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    echo "[*] Ping allowed"
else
    echo "[*] Ping blocked"
fi

# Logging dropped packets
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
sudo iptables -A OUTPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped-OUT: " --log-level 4

# -----------------------------
# 2️⃣ Git internet restriction
# -----------------------------

read -p "Do you want to allow Git to access the internet? (y/n) " ALLOW_GIT

if [[ "$ALLOW_GIT" =~ ^[Yy]$ ]]; then
    echo "[*] Configuring restricted Git access..."

    # Example: GitHub known IPs (add more if needed)
    GIT_IPS=(
        "140.82.112.0/20"
        "185.199.108.0/22"
        "192.30.252.0/22"
    )

    for ip in "${GIT_IPS[@]}"; do
        sudo iptables -A OUTPUT -p tcp -d $ip --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
    done

    # Allow DNS (needed to resolve Git hostnames)
    sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

    echo "[*] Git internet access restricted to known IPs."
else
    echo "[*] Git access blocked"
fi

# -----------------------------
# 3️⃣ Persist rules
# -----------------------------

sudo apt-get update && sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save

# -----------------------------
# 4️⃣ Optional Git setup
# -----------------------------

read -p "Do you want to configure Git locally? (y/n) " CONFIG_GIT
if [[ "$CONFIG_GIT" =~ ^[Yy]$ ]]; then
    read -p "Enter Git username: " GIT_USER
    read -p "Enter Git email: " GIT_EMAIL
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
    echo "[*] Git configured locally for $GIT_USER <$GIT_EMAIL>"
else
    echo "[*] Git setup skipped"
fi

echo "[*] Bootstrapping complete!"