# Minimal Private Linux SSH Server Setup Guide

This guide walks through setting up a **simple, private Linux server that only accepts SSH connections from inside your home network**. It is designed to be followed **offline** and focuses on a minimal, secure configuration.

---

# Goal

You will create a server with:

- A Linux server installation
- A static local IP
- SSH-only access
- Key-based authentication
- Password login disabled
- Firewall restricting access to your LAN

Final usage from another machine:

```
ssh username@192.168.1.50
```

---

# 1. Install the Base System

Install **Ubuntu Server** on the machine that will act as your home server.

During installation select:

```
Install OpenSSH server
```

Create a normal user:

```
username
password
```

After installation finishes, log into the server.

---

# 2. Verify SSH Is Running

Check that the SSH service is active.

```
sudo systemctl status ssh
```

Expected output should contain:

```
active (running)
```

If it is not running:

```
sudo systemctl start ssh
sudo systemctl enable ssh
```

---

# 3. Find Your Current IP Address

Run:

```
ip a
```

Look for an address like:

```
192.168.1.50
```

This is your current local network IP.

You will convert it to a static address next.

---

# 4. Configure a Static IP

Edit the network configuration:

```
sudo nano /etc/netplan/*.yaml
```

Example configuration:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.1.50/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

Important values:

| Field | Meaning |
|------|------|
| 192.168.1.50 | Server IP |
| 192.168.1.1 | Router |
| /24 | Standard home subnet |

Apply the configuration:

```
sudo netplan apply
```

Confirm:

```
ip a
```

---

# 5. Generate an SSH Key (Client Computer)

On the computer you will use to connect:

```
ssh-keygen -t ed25519
```

Press **Enter** for all prompts.

This creates:

```
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

---

# 6. Copy the Key to the Server

From your client machine:

```
ssh-copy-id username@192.168.1.50
```

Enter the server password once.

Test login:

```
ssh username@192.168.1.50
```

If you log in without typing a password, the key works.

Do not continue until this works.

---

# 7. Lock Down SSH Configuration

Edit the SSH configuration file:

```
sudo nano /etc/ssh/sshd_config
```

Add or modify:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
```

Optional but recommended:

```
AllowUsers username
```

Restart SSH:

```
sudo systemctl restart ssh
```

Test again from your client machine:

```
ssh username@192.168.1.50
```

---

# 8. Enable Firewall

Ubuntu includes a firewall called **ufw**.

Set the default policy:

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow SSH only from your local network:

```
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
```

Enable the firewall:

```
sudo ufw enable
```

Check status:

```
sudo ufw status
```

Expected result:

```
22/tcp ALLOW FROM 192.168.1.0/24
```

---

# 9. Verify the Final Setup

From another computer on your network:

```
ssh username@192.168.1.50
```

You should connect using your SSH key.

---

# 10. Optional: Automatic Security Updates

Install unattended updates:

```
sudo apt update
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

Choose:

```
Yes
```

---

# 11. Optional: Check Listening Services

View open network services:

```
sudo ss -tulpn
```

A minimal server usually shows:

```
ssh (port 22)
```

If other services appear unexpectedly, investigate before exposing the system further.

---

# 12. Daily Usage

Connect:

```
ssh username@192.168.1.50
```

Transfer files:

```
scp file.txt username@192.168.1.50:/home/username/
```

Update system periodically:

```
sudo apt update
sudo apt upgrade
```

---

# Final Result

Your server now has:

- SSH key authentication
- Password login disabled
- Root login disabled
- Firewall restricted to your LAN
- Static IP for reliable access

This configuration is a solid minimal baseline for a private home server.
