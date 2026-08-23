#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Routine live-instance developer bootstrap
# Purpose: install the essentials for a standard code checkin
# workflow with Python and Git, without home-server-specific
# hardening or services.
# ============================================================

export DEBIAN_FRONTEND=noninteractive

echo "[*] Starting routine developer bootstrap..."

sudo apt-get update

sudo apt-get install -y \
    ca-certificates \
    curl \
    git \
    git-lfs \
    openssh-client \
    dnsutils \
    tmux \
    neovim \
    python3-neovim \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-tk \
    python-is-python3 \
    jq \
    ripgrep \
    unzip \
    xclip \
    stellarium \
    pandoc \
    texlive \
    tor \
    openvpn \
    ufw \
    iptables \
    chipsec \
    efibootmgr \
    fwupd \
    tpm2-tools \
    pciutils \
    dmidecode

mkdir -p "$HOME/.venvs"
if [ ! -d "$HOME/.venvs/dev" ]; then
    python3 -m venv "$HOME/.venvs/dev"
fi

# shellcheck disable=SC1090
. "$HOME/.venvs/dev/bin/activate"
python -m pip install --upgrade pip setuptools wheel
python -m pip install \
    black \
    flake8 \
    isort \
    mypy \
    pytest \
    pillow \
    reportlab \
    google-api-python-client \
    google-auth \
    python-dotenv \
    pandas \
    tqdm \
    ffmpeg-python

if ! git config --global user.name >/dev/null 2>&1; then
    read -p "Enter git author name: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi

if ! git config --global user.email >/dev/null 2>&1; then
    read -p "Enter git author email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "nvim"

mkdir -p "$HOME/bin"
cat > "$HOME/bin/quick-checkin" <<'QCHECK'
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: quick-checkin <commit message>"
    exit 1
fi

git status
git add -A
git commit -m "$*"

echo "[*] Ready to push with: git push"
QCHECK
chmod +x "$HOME/bin/quick-checkin"

mkdir -p "$HOME/.bashrc.d"
cat > "$HOME/.bashrc.d/dev-env.sh" <<'ENVRC'
export PATH="$HOME/bin:$PATH"
export VIRTUAL_ENV="$HOME/.venvs/dev"
export PATH="$VIRTUAL_ENV/bin:$PATH"
ENVRC

if ! grep -q 'dev-env.sh' "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# Routine developer environment\nif [ -f "$HOME/.bashrc.d/dev-env.sh" ]; then\n  . "$HOME/.bashrc.d/dev-env.sh"\nfi\n' >> "$HOME/.bashrc"
fi

# ----------------------------------------------------------------
# Wi-Fi static configuration helper (from interactive static bootstrap)
# ----------------------------------------------------------------
if command -v nmcli >/dev/null 2>&1; then
    echo "[*] NetworkManager detected; static Wi-Fi bootstrap helper is available."
    cat > "$HOME/bin/wifi-static-bootstrap" <<'WIFI'
#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

ROUTER_IP="$(ip route | grep default | awk '{print $3}' | head -n1 || true)"
if [ -z "$ROUTER_IP" ]; then
    read -p "Cannot detect default gateway. Enter your router IP: " ROUTER_IP
fi

echo "Detected router IP: $ROUTER_IP"
echo

echo "Scanning for available Wi-Fi networks..."
nmcli device wifi rescan >/dev/null
NETWORKS=$(nmcli -f SSID,BSSID,SIGNAL,SECURITY device wifi list)
echo "$NETWORKS" | nl -w2 -s'. '
read -p "Enter the index of the Wi-Fi network to configure: " NET_IDX
SELECTED_LINE=$(echo "$NETWORKS" | sed -n "${NET_IDX}p")
SSID=$(echo "$SELECTED_LINE" | awk '{print $1}')

if [ -z "$SSID" ]; then
  echo "Invalid selection. Exiting."
  exit 1
fi

BSSID_LIST=$(echo "$NETWORKS" | awk -v ss="$SSID" '$1==ss {print $2, $3}' | sort -k2 -nr)
STRONGEST_BSSID=$(echo "$BSSID_LIST" | head -n1 | awk '{print $1}')
read -p "Enter desired static IP (e.g., 192.168.1.50): " STATIC_IP
read -p "Enter DNS servers (comma-separated, e.g., 1.1.1.1,8.8.8.8): " DNS
WIFI_IFACE=$(nmcli device status | awk '$2=="wifi"{print $1; exit}')
CON_NAME="$SSID"
if ! nmcli connection show | grep -q "^$CON_NAME$"; then
    nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" ssid "$SSID"
fi
nmcli connection modify "$CON_NAME" ipv4.addresses "$STATIC_IP/24"
nmcli connection modify "$CON_NAME" ipv4.gateway "$ROUTER_IP"
nmcli connection modify "$CON_NAME" ipv4.dns "$DNS"
nmcli connection modify "$CON_NAME" ipv4.method manual
nmcli connection modify "$CON_NAME" 802-11-wireless.bssid "$STRONGEST_BSSID"
nmcli connection modify "$CON_NAME" connection.autoconnect yes
nmcli connection down "$CON_NAME" || true
nmcli connection up "$CON_NAME"

echo "Static IP setup finished for $SSID ($STRONGEST_BSSID)"
WIFI
    chmod +x "$HOME/bin/wifi-static-bootstrap"
fi

# ----------------------------------------------------------------
# Wi-Fi power-saving disable helper
# ----------------------------------------------------------------
if command -v nmcli >/dev/null 2>&1; then
    cat > "$HOME/bin/disable-wifi-powersave" <<'PWR'
#!/usr/bin/env bash
set -euo pipefail
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo $0"
  exit 1
fi
CONF_DIR="/etc/NetworkManager/conf.d"
CONF_FILE="$CONF_DIR/default-wifi-powersave-on.conf"
mkdir -p "$CONF_DIR"
if [ -f "$CONF_FILE" ]; then
    if grep -q "wifi.powersave *= *3" "$CONF_FILE"; then
        sed -i 's/wifi\.powersave *= *3/wifi.powersave = 2/' "$CONF_FILE"
    elif ! grep -q "wifi.powersave" "$CONF_FILE"; then
        echo "wifi.powersave = 2" | tee -a "$CONF_FILE" >/dev/null
    fi
else
    tee "$CONF_FILE" >/dev/null <<'EOF'
[connection]
wifi.powersave = 2
EOF
fi
systemctl restart NetworkManager
printf 'WiFi powersave disabled.\n'
PWR
    chmod +x "$HOME/bin/disable-wifi-powersave"
fi

# ----------------------------------------------------------------
# Security dashboard for TTY1 (from emergency dashboard installer)
# ----------------------------------------------------------------
cat > "$HOME/bin/tty-dashboard.sh" <<'TTY'
#!/usr/bin/env bash
set -euo pipefail
TTY_NUMBER=1
PROCESSES_TO_SHOW=20
REFRESH_PLUGGED=5
REFRESH_BATTERY=1
SLEEP_INTERVAL=2
HELP_MESSAGE='Enter "F2 username password" to perform emergency actions'
TTY_PATH="/dev/tty${TTY_NUMBER}"

while true; do
    clear > "$TTY_PATH"
    echo -e "\033[32m===== EMERGENCY TTY DASHBOARD =====\033[0m" > "$TTY_PATH"
    echo -e "\033[36mHELP: $HELP_MESSAGE\033[0m" > "$TTY_PATH"
    echo "" > "$TTY_PATH"

    ac_online=0
    battery_level=100
    for supply in /sys/class/power_supply/*; do
        type=$(cat "$supply/type" 2>/dev/null || true)
        if [ "$type" = "Mains" ]; then
            online=$(cat "$supply/online" 2>/dev/null || echo 0)
            if [ "$online" -eq 1 ]; then ac_online=1; fi
        elif [ "$type" = "Battery" ]; then
            battery_level=$(cat "$supply/capacity" 2>/dev/null || echo 100)
        fi
    done

    if [ "$ac_online" -eq 1 ]; then
        echo -e "AC Power: \033[32mPlugged in\033[0m" > "$TTY_PATH"
    else
        echo -e "AC Power: \033[31mUnplugged\033[0m" > "$TTY_PATH"
    fi
    echo -e "Battery: ${battery_level}%" > "$TTY_PATH"
    echo "" > "$TTY_PATH"
    ps aux --sort=-%cpu | head -n "$PROCESSES_TO_SHOW" > "$TTY_PATH"
    sleep "$SLEEP_INTERVAL"
done
TTY
chmod +x "$HOME/bin/tty-dashboard.sh"

printf '\n[*] Developer environment is ready.\n'
printf '[*] Activate it with: source "$HOME/.venvs/dev/bin/activate"\n'
printf '[*] Quick commit helper: $HOME/bin/quick-checkin "message"\n'
printf '[*] Git identity is configured.\n'
printf '[*] Optional helpers installed: wifi-static-bootstrap, disable-wifi-powersave, tty-dashboard.sh\n'
