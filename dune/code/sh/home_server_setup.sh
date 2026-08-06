#!/bin/bash
# =============================================================================
# linux-home-server-setup.sh
#
# Minimal home server setup:
# - Locks down SSH to trusted devices
# - Sets up a basic firewall
# - Safe to run before configuring static Wi-Fi
# =============================================================================

echo "[*] Starting Linux home server minimal setup..."

# ----------------------------
# Configuration
# ----------------------------
# Trusted devices (replace with your IPs)
TRUSTED_IPS=(
  "192.168.1.10"   # desktop
  "192.168.1.11"   # laptop
)

# SSH port
SSH_PORT=22

# ----------------------------
# Step 1: Ensure SSH server is installed
# ----------------------------
echo "[*] Installing OpenSSH server if missing..."
sudo apt update
sudo apt install -y openssh-server

# ----------------------------
# Step 2: Start and enable SSH
# ----------------------------
echo "[*] Starting and enabling SSH..."
sudo systemctl start ssh
sudo systemctl enable ssh

# ----------------------------
# Step 3: Apply minimal firewall
# ----------------------------
echo "[*] Applying minimal firewall..."

# Flush existing rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t mangle -F

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH and ICMP from trusted IPs
for ip in "${TRUSTED_IPS[@]}"; do
    sudo iptables -A INPUT -p tcp -s $ip --dport $SSH_PORT -m conntrack --ctstate NEW -j ACCEPT
    sudo iptables -A INPUT -p icmp -s $ip -j ACCEPT
done

# Log dropped packets (optional)
sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "FIREWALL DROP: " --log-level 7

# Final drop
sudo iptables -A INPUT -j DROP

echo "[✓] Minimal firewall applied."

# ----------------------------
# Step 4: Persist firewall after reboot
# ----------------------------
echo "[*] Saving firewall rules..."
sudo apt install -y iptables-persistent
sudo netfilter-persistent save

echo "[✓] Linux home server minimal setup complete."
echo "[*] Verify SSH access from a trusted device before logging out!"
