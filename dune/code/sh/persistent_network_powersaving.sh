#!/usr/bin/env bash
set -e

CONF_DIR="/etc/NetworkManager/conf.d"
CONF_FILE="$CONF_DIR/default-wifi-powersave-on.conf"

echo "Ensuring WiFi powersave is disabled..."

sudo mkdir -p "$CONF_DIR"

if [ -f "$CONF_FILE" ]; then
    # Replace value if set to 3
    if grep -q "wifi.powersave *= *3" "$CONF_FILE"; then
        sudo sed -i 's/wifi\.powersave *= *3/wifi.powersave = 2/' "$CONF_FILE"
    # Add setting if missing
    elif ! grep -q "wifi.powersave" "$CONF_FILE"; then
        echo "wifi.powersave = 2" | sudo tee -a "$CONF_FILE" > /dev/null
    fi
else
    sudo tee "$CONF_FILE" > /dev/null <<EOF
[connection]
wifi.powersave = 2
EOF
fi

sudo systemctl restart NetworkManager

echo "WiFi powersave disabled."
