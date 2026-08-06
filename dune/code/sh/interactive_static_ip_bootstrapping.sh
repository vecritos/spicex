#!/bin/bash
# wifi_static_bootstrap_confirm.sh
# Fully interactive Wi-Fi static IP bootstrap with BSSID selection override and confirmation
# Run: sudo ./wifi_static_bootstrap_confirm.sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

echo "==== Wi-Fi Static IP Bootstrap Script ===="
echo

# Step 1: Detect router IP automatically
ROUTER_IP=$(ip route | grep default | awk '{print $3}')
if [ -z "$ROUTER_IP" ]; then
    read -p "Cannot detect default gateway. Enter your router IP: " ROUTER_IP
fi
echo "Detected router IP: $ROUTER_IP"
echo

# Step 2: Scan Wi-Fi networks
echo "Scanning for available Wi-Fi networks..."
nmcli device wifi rescan >/dev/null
NETWORKS=$(nmcli -f SSID,BSSID,SIGNAL,SECURITY device wifi list)
echo
echo "Available networks:"
echo "$NETWORKS" | nl -w2 -s'. '

# Step 3: Prompt user to select network by index
read -p "Enter the index of the Wi-Fi network to configure: " NET_IDX
SELECTED_LINE=$(echo "$NETWORKS" | sed -n "${NET_IDX}p")
SSID=$(echo "$SELECTED_LINE" | awk '{print $1}')

if [ -z "$SSID" ]; then
  echo "Invalid selection. Exiting."
  exit 1
fi

echo
echo "You selected SSID: $SSID"

# Step 4: List all BSSIDs for this SSID
BSSID_LIST=$(echo "$NETWORKS" | awk -v ss="$SSID" '$1==ss {print $2, $3}' | sort -k2 -nr)
echo
echo "Available BSSIDs for $SSID (strongest first):"
echo "$BSSID_LIST" | nl -w2 -s'. '
STRONGEST_BSSID=$(echo "$BSSID_LIST" | head -n1 | awk '{print $1}')
STRONGEST_SIGNAL=$(echo "$BSSID_LIST" | head -n1 | awk '{print $2}')

# Step 5: Let user choose BSSID or accept strongest
echo
read -p "Enter the index of the BSSID to use [default: strongest]: " BSSID_IDX
if [ -z "$BSSID_IDX" ]; then
    BSSID="$STRONGEST_BSSID"
    SIGNAL="$STRONGEST_SIGNAL"
else
    BSSID=$(echo "$BSSID_LIST" | sed -n "${BSSID_IDX}p" | awk '{print $1}')
    SIGNAL=$(echo "$BSSID_LIST" | sed -n "${BSSID_IDX}p" | awk '{print $2}')
fi

echo
echo "Using BSSID: $BSSID (Signal: $SIGNAL)"
echo

# Step 6: Prompt for static IP and DNS
read -p "Enter desired static IP (e.g., 192.168.1.50): " STATIC_IP
read -p "Enter DNS servers (comma-separated, e.g., 1.1.1.1,8.8.8.8): " DNS

# Step 7: Determine Wi-Fi interface
WIFI_IFACE=$(nmcli device status | awk '$2=="wifi"{print $1; exit}')
echo
echo "Using Wi-Fi interface: $WIFI_IFACE"
echo

# Step 8: Preview summary and confirmation
echo "=== Configuration Summary ==="
echo "SSID       : $SSID"
echo "BSSID      : $BSSID"
echo "Signal     : $SIGNAL"
echo "Wi-Fi iface: $WIFI_IFACE"
echo "Static IP  : $STATIC_IP/24"
echo "Gateway    : $ROUTER_IP"
echo "DNS        : $DNS"
echo "============================="
read -p "Apply this configuration? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Configuration aborted by user."
    exit 0
fi

# Step 9: Create or modify NetworkManager connection
CON_NAME="$SSID"
if ! nmcli connection show | grep -q "^$CON_NAME\$"; then
    echo "Creating new connection for SSID: $SSID"
    nmcli connection add type wifi ifname "$WIFI_IFACE" con-name "$CON_NAME" ssid "$SSID"
fi

# Step 10: Apply static IP, DNS, and chosen BSSID
echo "Applying static IP configuration..."
nmcli connection modify "$CON_NAME" ipv4.addresses "$STATIC_IP/24"
nmcli connection modify "$CON_NAME" ipv4.gateway "$ROUTER_IP"
nmcli connection modify "$CON_NAME" ipv4.dns "$DNS"
nmcli connection modify "$CON_NAME" ipv4.method manual
nmcli connection modify "$CON_NAME" 802-11-wireless.bssid "$BSSID"
nmcli connection modify "$CON_NAME" connection.autoconnect yes

# Step 11: Restart connection
echo
echo "Restarting connection..."
nmcli connection down "$CON_NAME" || true
nmcli connection up "$CON_NAME"

echo
echo "Configuration complete!"
ip addr show "$WIFI_IFACE" | grep inet
echo
echo "Static IP setup finished for $SSID ($BSSID)"
