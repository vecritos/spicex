#!/bin/bash
# =========================================
# Hardened Git User Setup
# =========================================

echo "[*] Creating hardened git user..."

read -p "Enter username (default: gituser): " GIT_USER
GIT_USER=${GIT_USER:-gituser}

# Create user with home directory
sudo useradd -m -s /bin/bash "$GIT_USER"

# Set password
sudo passwd "$GIT_USER"

# Ensure no sudo access
sudo gpasswd -d "$GIT_USER" sudo 2>/dev/null
sudo rm -f /etc/sudoers.d/$GIT_USER 2>/dev/null

# Tighten home permissions
sudo chmod 700 /home/$GIT_USER
sudo chown -R $GIT_USER:$GIT_USER /home/$GIT_USER

echo "[*] User created and hardened."