#!/bin/bash
# =========================================
# Home Server Hardening & Encrypted LAN Setup
# =========================================
# Author: Auto-generated
# Description: Sets up firewall, monitoring, VPN, DNS, and basic hardening
# WARNING: Run as root. Modify config values to suit your environment.
# =========================================

# -------------------------------
# Section 1: Variables / Config
# -------------------------------
SERVER_HOSTNAME="homeserver"
ADMIN_USER="youruser"
VPN_INTERFACE="wg0"
VPN_CONFIG_PATH="/etc/wireguard/wg0.conf"
PIHOLE_ENABLED=true
VPN_PORT=51820
DNS_PROVIDER="1.1.1.1"  # Cloudflare
ALERT_EMAIL="your@email.com"

# -------------------------------
# Section 2: System Update
# -------------------------------
echo "Updating system..."
apt update && apt upgrade -y
apt install -y ufw fail2ban wireguard resolvconf curl unzip git

# -------------------------------
# Section 3: Firewall Setup (UFW)
# -------------------------------
echo "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh   # Change if using non-standard port
ufw allow ${VPN_PORT}/udp
ufw enable

# -------------------------------
# Section 4: Fail2Ban Setup
# -------------------------------
echo "Setting up fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# -------------------------------
# Section 5: User / SSH Hardening
# -------------------------------
echo "Hardening SSH..."
# Disable password login (ensure key-based login is set up first!)
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# -------------------------------
# Section 6: VPN Setup (WireGuard)
# -------------------------------
echo "Setting up WireGuard VPN..."
if [ ! -f "$VPN_CONFIG_PATH" ]; then
    echo "Generating WireGuard keys..."
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
    PRIVATE_KEY=$(cat /etc/wireguard/privatekey)
    echo "[Interface]
Address = 10.10.10.1/24
ListenPort = ${VPN_PORT}
PrivateKey = ${PRIVATE_KEY}
SaveConfig = true
PostUp = iptables -A FORWARD -i ${VPN_INTERFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i ${VPN_INTERFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" > ${VPN_CONFIG_PATH}

    chmod 600 ${VPN_CONFIG_PATH}
    systemctl enable wg-quick@${VPN_INTERFACE}
    systemctl start wg-quick@${VPN_INTERFACE}
fi

# -------------------------------
# Section 7: DNS / Pi-hole (Optional)
# -------------------------------
if [ "$PIHOLE_ENABLED" = true ]; then
    echo "Installing Pi-hole..."
    curl -sSL https://install.pi-hole.net | bash
    # During install, set DNS_PROVIDER and interface appropriately
fi

# -------------------------------
# Section 8: Monitoring Setup (Netdata)
# -------------------------------
echo "Installing Netdata for monitoring..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

# -------------------------------
# Section 9: Automatic Updates
# -------------------------------
echo "Enabling unattended upgrades..."
apt install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# -------------------------------
# Section 10: Alerts / Logging
# -------------------------------
echo "Setting up email alerts (fail2ban, system logs)..."
# Basic fail2ban email alert setup
sed -i "s/^destemail = root@localhost/destemail = ${ALERT_EMAIL}/" /etc/fail2ban/jail.local
systemctl restart fail2ban

# -------------------------------
# Section 11: Summary
# -------------------------------
echo "===================================="
echo "Server hardening and VPN setup complete!"
echo "Firewall enabled, SSH hardened, VPN running on ${VPN_INTERFACE}, monitoring installed."
if [ "$PIHOLE_ENABLED" = true ]; then
    echo "Pi-hole installed for DNS filtering."
fi
echo "Remember to configure VPN clients and Pi-hole as needed."
echo "All outgoing traffic can now be routed through the VPN for encryption."
echo "===================================="
