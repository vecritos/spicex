# Home Server Setup

This is the single reference for setting up a basic home server on Linux with a secure and easy-to-follow flow.

## 1. Minimal base setup

Start with a minimal secure SSH and firewall configuration.

### Install the base system

Install Ubuntu Server or another supported Linux distribution. During installation, select the OpenSSH server package if the installer offers it, and create a normal administrative user. Do not use the root account for routine administration.

After installation, update the system:

```bash
sudo apt update
sudo apt upgrade -y
```

### Verify SSH is running

```bash
sudo systemctl status ssh --no-pager
sudo systemctl enable --now ssh
```

The service should report `active (running)`.

### Configure a stable local IP

Find the current address and network interface:

```bash
ip address
ip route
```

For most home networks, a router DHCP reservation is safer and easier than manually configuring a static address on the server. Reserve an address such as `192.168.1.50` for the server's MAC address in the router.

If you configure the address with Netplan instead, first identify the interface name, then edit the appropriate YAML file:

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Example Ethernet configuration:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

Replace the interface, server address, gateway, and DNS addresses with values from your network. Test carefully because an incorrect network file can disconnect the server:

```bash
sudo netplan try
sudo netplan apply
ip address
ip route
```

### What this does
- installs OpenSSH
- enables SSH
- applies a minimal firewall
- allows SSH only from trusted LAN devices
- persists firewall rules across reboots

### Secure SSH configuration essentials
Use the following settings for a minimal secure SSH server setup.

1. Disable root login.
2. Disable password authentication.
3. Use SSH keys only.
4. Restrict allowed users.
5. Change the default port if you want a small additional layer of obscurity.
6. Keep `AllowUsers` or `Match User` rules as narrow as possible.
7. Use a firewall to limit inbound SSH to trusted IPs.
8. Consider rate limiting or Fail2Ban.

Example config:

```bash
sudo nano /etc/ssh/sshd_config
```

Add or change:

```bash
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers youruser
X11Forwarding no
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
PrintMotd no
UsePAM yes
```

Then reload SSH:

```bash
sudo sshd -t
sudo systemctl reload ssh
```

### Create an SSH keypair on the client

```bash
ssh-keygen -t ed25519 -C "yourname@home"
```

Then copy the public key to the server:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub youruser@server-ip
```

### Edit the allowed IPs first
Open the trusted IP list and replace the example addresses with your own:

```bash
TRUSTED_IPS=(
  "192.168.1.10"
  "192.168.1.11"
)
SSH_PORT=22
```

Follow the SSH, firewall, and verification steps in this guide rather than running an old helper script. Keep one SSH session open while applying firewall changes so you can recover if a rule is incorrect.

### Minimum secure SSH checklist

Before leaving the machine online, verify:

```bash
sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers|port'
```

Expected result:
- `PermitRootLogin no`
- `PasswordAuthentication no`
- `PubkeyAuthentication yes`
- only your trusted user(s) are allowed

---

## 2. Physical hardening

If your server is a laptop or physically exposed machine, disable USB storage and keep the lid from suspending the machine.

For a laptop server, you can optionally disable USB mass storage and configure lid behavior. Treat these as separate, hardware-specific changes and test that they do not interfere with maintenance or recovery.

```bash
printf '%s\n' 'blacklist usb_storage' | sudo tee /etc/modprobe.d/blacklist-usb.conf
sudo update-initramfs -u
```

This reduces removable-media attack paths, but it also prevents normal USB storage use. Do not apply it until you have another recovery method.

---

## 3. Advanced ISP-minded hardening

This is the more complete server setup for a person who wants a stronger baseline security posture.

### What this layering adds
- secure SSH access with key-based auth only
- firewall default deny with selective allow rules
- fail2ban to block repeated SSH attacks
- WireGuard VPN for remote administration
- unattended security updates
- optional Pi-hole DNS filtering
- netdata or another lightweight monitoring path

### Step 3.1: Harden SSH

Install OpenSSH if it is not already present:

```bash
sudo apt update
sudo apt install -y openssh-server
```

Edit the config file:

```bash
sudo nano /etc/ssh/sshd_config
```

Use a minimal secure configuration like this:

```bash
Port 22
Protocol 2

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers youruser

X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
GatewayPorts no

LoginGraceTime 30
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
PermitEmptyPasswords no
UsePAM yes
PrintMotd no
```

Then reload and validate:

```bash
sudo sshd -t
sudo systemctl reload ssh
sudo systemctl status ssh --no-pager
```

Critical notes:
- Do not disable password auth until key-based login has already been tested.
- If you change the SSH port, you must also update your firewall and ssh client command.
- `AllowUsers youruser` restricts access to only the account you intend to use.

### Step 3.2: Firewall baseline with UFW

For a home server, the standard modern approach is a default-deny firewall with a narrow allow list.

Install UFW:

```bash
sudo apt install -y ufw
```

Set the default policy:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow only the necessary inbound services. If your server is on a trusted LAN, allow SSH from your local network only:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
```

If you use a VPN, allow the VPN interface or port:

```bash
sudo ufw allow 51820/udp
```

Allow DNS and NTP if your server needs them:

```bash
sudo ufw allow out 53
sudo ufw allow out 123/udp
```

Optional: allow HTTPS when serving web content locally:

```bash
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
```

Enable the firewall:

```bash
sudo ufw enable
sudo ufw status verbose
```

Recommended policy:
- deny all inbound by default
- allow only SSH from trusted LAN ranges
- allow WireGuard from trusted clients only
- allow outbound access only for necessary services

### Step 3.3: Fail2Ban for repeated attack protection

Install Fail2Ban:

```bash
sudo apt install -y fail2ban
```

Create a basic config file:

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Add a simple SSH jail:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
backend = auto
action = %(action_)s
```

Start and enable the service:

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

This blocks repeated failed SSH login attempts without making the server harder to use on a trusted network.

### Step 3.4: WireGuard VPN for remote administration

If you need secure remote access, use a VPN instead of exposing SSH directly to the internet.

Install WireGuard:

```bash
sudo apt install -y wireguard resolvconf
```

Create the server keys:

```bash
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```

Create the server config:

```bash
sudo nano /etc/wireguard/wg0.conf
```

Example server config:

```ini
[Interface]
Address = 10.10.10.1/24
ListenPort = 51820
PrivateKey = <server_private_key_here>
SaveConfig = true

[Peer]
PublicKey = <client_public_key_here>
AllowedIPs = 10.10.10.2/32
```

Set permissions and start it:

```bash
sudo chmod 600 /etc/wireguard/privatekey
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
sudo systemctl status wg-quick@wg0 --no-pager
```

Client-side config example:

```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.10.10.2/32
DNS = 1.1.1.1, 1.0.0.1

[Peer]
PublicKey = <server_public_key>
Endpoint = your-public-ip:51820
AllowedIPs = 10.10.10.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

Recommended practice:
- never expose SSH directly to the internet unless you intentionally want that risk
- prefer VPN access to the LAN and then SSH from inside the tunnel

### Step 3.5: Automatic updates

Install and configure unattended upgrades:

```bash
sudo apt install -y unattended-upgrades apt-listchanges
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Check the config file:

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Recommended minimum settings:

```conf
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}";
  "${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Mail "root";
```

Enable the service:

```bash
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades
```

This gives you patching without needing to manually run package upgrades every time.

### Step 3.6: Optional monitoring and DNS filtering

If you want to keep the server visible and healthy:

Install Netdata:

```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait
```

Optional Pi-hole DNS filtering:

```bash
curl -sSL https://install.pi-hole.net | bash
```

If you use Pi-hole, set your router or clients to point DNS traffic to the server, and only allow DNS from trusted devices or your VPN.

### Step 3.7: Full hardening checklist

Before you leave the server exposed on the network, confirm all of this:

```bash
sudo ufw status verbose
sudo fail2ban-client status
sudo systemctl status ssh --no-pager
sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers|port'
sudo systemctl status wg-quick@wg0 --no-pager
```

You want to see:
- SSH disabled for root
- SSH using keys only
- firewall default deny incoming
- fail2ban active
- VPN running if you enabled it

---

## 4. Recommended home-server baseline

The simplest reasonable setup is:

1. install the server OS
2. configure a static IP or DHCP reservation
3. enable SSH securely with key-based auth only
4. restrict SSH to a trusted LAN or VPN network
5. enable a firewall with default deny incoming
6. enable Fail2Ban
7. enable automatic security updates
8. add WireGuard if you need remote access
9. optionally add Pi-hole and monitoring

---

## 5. Security notes

- Do not expose SSH to the whole internet unless you intentionally want that risk.
- Use key-based SSH authentication instead of passwords.
- Keep `AllowUsers` limited to only your admin accounts.
- Back up important config files before editing them.
- Reboot after any kernel, storage, or USB changes.
- If your server is remote, prefer WireGuard or another VPN for access.
- Keep logs and update history reviewed regularly.
- If possible, use a router-level firewall and a server-level firewall together.

---

## 6. Final practical flow

Use this order:

1. Install the base system and establish a stable local address.
2. Confirm SSH works from a trusted client using an SSH key.
3. Validate `sshd_config`, then disable password authentication.
4. Apply the default-deny firewall and verify access from a second session.
5. Enable Fail2Ban and automatic security updates.
6. Add WireGuard before allowing remote administration.
7. Review listening services, logs, and backups regularly.

This is the simplest way to reason about the process, and it keeps the server setup understandable for a beginner while still giving a stronger baseline for real-world use.

---

## 7. Daily administration

Connect from another trusted computer:

```bash
ssh youruser@192.168.1.50
```

Copy a file to the server:

```bash
scp file.txt youruser@192.168.1.50:/home/youruser/
```

Apply routine updates:

```bash
sudo apt update
sudo apt upgrade -y
```

Review listening services and investigate anything unexpected:

```bash
sudo ss -tulpn
```

Review recent SSH authentication activity:

```bash
sudo journalctl -u ssh --since today
```

## 8. Final result

Before treating the server as ready, confirm that it has:

- a stable local address
- a normal administrative user
- SSH key authentication
- password login disabled after key testing
- root login disabled
- SSH restricted with `AllowUsers`
- a default-deny inbound firewall
- SSH limited to the LAN or VPN
- Fail2Ban enabled when SSH is reachable from a wider network
- automatic security updates enabled
- no unexpected listening services

This provides a practical private home-server baseline without exposing unnecessary services to the internet.
