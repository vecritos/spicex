#!/bin/bash
# === Home Server Physical Hardening Script ===

# 1️⃣ Disable USB storage
echo "Disabling USB storage..."
BLACKLIST_FILE="/etc/modprobe.d/blacklist-usb.conf"

sudo bash -c "cat > $BLACKLIST_FILE <<EOF
# Disable USB storage devices
blacklist usb_storage
EOF"

sudo update-initramfs -u
echo "USB storage disabled."

# 2️⃣ Make closing the lid do nothing
echo "Configuring lid close behavior..."
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action 'nothing'
echo "Lid close behavior set to 'do nothing'."

# 3️⃣ Optional: verify settings
echo "Verifying configuration..."
if grep -q "blacklist usb_storage" "$BLACKLIST_FILE"; then
    echo "✅ USB storage blacklist applied."
else
    echo "❌ USB storage blacklist NOT applied."
fi

LID_AC=$(gsettings get org.gnome.settings-daemon.plugins.power lid-close-ac-action)
LID_BATT=$(gsettings get org.gnome.settings-daemon.plugins.power lid-close-battery-action)
echo "Lid AC action: $LID_AC"
echo "Lid battery action: $LID_BATT"

echo "All done. Reboot recommended to fully enforce USB disable."
