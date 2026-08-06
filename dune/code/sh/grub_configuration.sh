#!/usr/bin/env bash

CONFIG="/etc/default/grub"

get_entries() {
    grep "menuentry '" /boot/grub/grub.cfg | sed "s/menuentry '//;s/' .*//"
}

list_entries() {
    echo "Detected GRUB entries:"
    get_entries | nl
}

find_windows() {
    get_entries | grep -i windows | head -n1
}

find_linux() {
    get_entries | grep -iv windows | head -n1
}

show_config() {
    echo "Current GRUB configuration:"
    echo "--------------------------------"
    grep '^GRUB_' "$CONFIG"
    echo
}

setup_grub() {

    show_config
    list_entries
    echo

    WINDOWS=$(find_windows)

    if [[ -n "$WINDOWS" ]]; then
        echo "Detected Windows entry:"
        echo "  $WINDOWS"
        echo
    fi

    read -p "Apply hardened hidden-boot configuration? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 0

    read -p "Choose initial default entry number: " entrynum

    DEFAULT_ENTRY=$(get_entries | sed -n "$((entrynum))p")

    if [[ -z "$DEFAULT_ENTRY" ]]; then
        echo "Invalid selection."
        exit 1
    fi

    echo
    echo "Selected default: $DEFAULT_ENTRY"
    read -p "Write configuration to $CONFIG ? (y/N): " writeconfirm
    [[ "$writeconfirm" != "y" && "$writeconfirm" != "Y" ]] && exit 0

    sudo cp "$CONFIG" "$CONFIG.backup"

    sudo tee "$CONFIG" > /dev/null <<EOF
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true

GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=0
GRUB_RECORDFAIL_TIMEOUT=0

GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo Debian\`

GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""

GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=false

GRUB_TERMINAL=console

GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
EOF

    sudo grub-set-default "$DEFAULT_ENTRY"
    sudo update-grub

    echo
    echo "Setup complete."
    echo
    help_menu
}

switch_windows() {

    WINDOWS=$(find_windows)

    if [[ -z "$WINDOWS" ]]; then
        echo "No Windows entry detected."
        exit 1
    fi

    sudo grub-set-default "$WINDOWS"
    echo "Default boot set to Windows:"
    echo "$WINDOWS"
}

switch_linux() {

    LINUX=$(find_linux)

    if [[ -z "$LINUX" ]]; then
        echo "No Linux entry detected."
        exit 1
    fi

    sudo grub-set-default "$LINUX"
    echo "Default boot set to Linux:"
    echo "$LINUX"
}

help_menu() {

cat <<EOF

GRUB MANAGEMENT TOOL
--------------------

Usage:

  ./grub-tool --setup
      Interactive configuration

  ./grub-tool --list
      Show detected boot entries

  ./grub-tool --switch windows
      Set Windows as default boot

  ./grub-tool --switch linux
      Set Linux as default boot

  ./grub-tool --help
      Show this help menu


Admin tricks:

Boot Windows once:

  sudo grub-reboot "Windows Boot Manager"
  sudo reboot

Show GRUB menu during boot:

  Hold ESC while booting

Restore previous config:

  sudo cp /etc/default/grub.backup /etc/default/grub
  sudo update-grub

EOF
}

case "$1" in
    --setup)
        setup_grub
        ;;
    --list)
        list_entries
        ;;
    --switch)
        case "$2" in
            windows)
                switch_windows
                ;;
            linux)
                switch_linux
                ;;
            *)
                echo "Specify 'windows' or 'linux'"
                ;;
        esac
        ;;
    --help|"")
        help_menu
        ;;
    *)
        echo "Unknown option. Use --help"
        ;;
esac
