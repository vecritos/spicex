#!/bin/bash
# Emergency TTY Dashboard Full Installation Script
# Creates user, firewall script, dashboard script, systemd service

set -e

# -------------------------
# CONFIGURATION
# -------------------------
DASHBOARD_USER=ttydashboard
DASHBOARD_HOME=/home/$DASHBOARD_USER
TTY_NUMBER=1
PROCESSES_TO_SHOW=20
REFRESH_PLUGGED=5
REFRESH_BATTERY=1
SLEEP_INTERVAL=2
HELP_MESSAGE='Enter "F2 username password" to perform emergency actions'

# -------------------------
# CREATE USER
# -------------------------
if ! id -u $DASHBOARD_USER >/dev/null 2>&1; then
    sudo adduser --disabled-password --gecos "" $DASHBOARD_USER
fi
sudo mkdir -p $DASHBOARD_HOME/bin
sudo chown -R $DASHBOARD_USER:$DASHBOARD_USER $DASHBOARD_HOME

# -------------------------
# CREATE FIREWALL SCRIPT
# -------------------------
FIREWALL_SCRIPT=$DASHBOARD_HOME/bin/firewall-battery.sh
cat << EOF | sudo tee $FIREWALL_SCRIPT
#!/bin/bash
ac_online=0
for supply in /sys/class/power_supply/*; do
    type=\$(cat \$supply/type)
    if [ "\$type" = "Mains" ]; then
        online=\$(cat \$supply/online)
        if [ "\$online" -eq 1 ]; then ac_online=1; fi
    fi
 done

if [ "\$ac_online" -eq 0 ]; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
else
    sudo ufw default allow incoming
    sudo ufw default allow outgoing
    sudo ufw --force reload
fi
EOF
sudo chmod +x $FIREWALL_SCRIPT

# Grant passwordless sudo for firewall script
SUDOERS_LINE="$DASHBOARD_USER ALL=(ALL) NOPASSWD: $FIREWALL_SCRIPT"
if ! sudo grep -qF "$SUDOERS_LINE" /etc/sudoers; then
    echo "$SUDOERS_LINE" | sudo EDITOR='tee -a' visudo
fi

# -------------------------
# CREATE DASHBOARD SCRIPT
# -------------------------
DASHBOARD_SCRIPT=$DASHBOARD_HOME/bin/tty-dashboard.sh
cat << EOF | sudo tee $DASHBOARD_SCRIPT
#!/bin/bash
##########################
# GLOBAL PARAMETERS
TTY_NUMBER=$TTY_NUMBER
PROCESSES_TO_SHOW=$PROCESSES_TO_SHOW
REFRESH_PLUGGED=$REFRESH_PLUGGED
REFRESH_BATTERY=$REFRESH_BATTERY
SLEEP_INTERVAL=$SLEEP_INTERVAL
FIREWALL_SCRIPT=$FIREWALL_SCRIPT
HELP_MESSAGE='$HELP_MESSAGE'
##########################

# ANSI colors
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"
TTY_PATH="/dev/tty\$TTY_NUMBER"

while true; do
    clear > \$TTY_PATH
    echo -e "\${GREEN}===== EMERGENCY TTY DASHBOARD =====\${RESET}" > \$TTY_PATH
    echo -e "\${CYAN}HELP: \$HELP_MESSAGE\${RESET}" > \$TTY_PATH
    echo "" > \$TTY_PATH

    refresh=\$SLEEP_INTERVAL
    on_battery=0

    # AC and battery detection
    if [ -d /sys/class/power_supply ]; then
        ac_online=0
        battery_level=100
        for supply in /sys/class/power_supply/*; do
            type=\$(cat \$supply/type)
            if [ "\$type" = "Mains" ]; then
                online=\$(cat \$supply/online)
                if [ "\$online" -eq 1 ]; then ac_online=1; fi
            elif [ "\$type" = "Battery" ]; then
                battery_level=\$(cat \$supply/capacity)
            fi
        done

        if [ "\$ac_online" -eq 1 ]; then
            on_battery=0
            echo -e "AC Power: \${GREEN}Plugged in\${RESET}" > \$TTY_PATH
        else
            on_battery=1
            echo -e "AC Power: \${RED}Unplugged\${RESET}" > \$TTY_PATH
        fi

        if [ "\$battery_level" -ge 50 ]; then
            bat_color=\$GREEN
        elif [ "\$battery_level" -ge 20 ]; then
            bat_color=\$YELLOW
        else
            bat_color=\$RED
        fi
        echo -e "Battery: \${bat_color}\${battery_level}%\${RESET}" > \$TTY_PATH
        echo "" > \$TTY_PATH
    fi

    if [ "\$on_battery" -eq 1 ]; then
        refresh=\$REFRESH_BATTERY
    else
        refresh=\$REFRESH_PLUGGED
    fi

    bash \$FIREWALL_SCRIPT

    # Top CPU processes
    echo -e "\${GREEN}=== Top Processes ===\${RESET}" > \$TTY_PATH
    ps aux --sort=-%cpu | head -n \$PROCESSES_TO_SHOW | while read line; do
        cpu=\$(echo "\$line" | awk '{print \$3}' | cut -d. -f1)
        if [ "\$cpu" -ge 80 ]; then
            echo -e "\${RED}\$line\${RESET}" > \$TTY_PATH
        elif [ "\$cpu" -ge 50 ]; then
            echo -e "\${YELLOW}\$line\${RESET}" > \$TTY_PATH
        else
            echo "\$line" > \$TTY_PATH
        fi
    done

    # Memory usage
    echo -e "\${GREEN}=== Memory Usage ===\${RESET}" > \$TTY_PATH
    mem_total=\$(free -m | awk '/Mem:/ {print \$2}')
    mem_used=\$(free -m | awk '/Mem:/ {print \$3}')
    mem_pct=\$(( mem_used * 100 / mem_total ))
    if [ "\$mem_pct" -ge 80 ]; then mem_color=\$RED
    elif [ "\$mem_pct" -ge 50 ]; then mem_color=\$YELLOW
    else mem_color=\$GREEN
    fi
    free -h | awk -v color="\$mem_color" -v reset="\$RESET" 'NR==1{print \$0} NR==2{print color \$0 reset}' > \$TTY_PATH

    # Logged-in users
    echo -e "\${GREEN}=== Logged In Users ===\${RESET}" > \$TTY_PATH
    who > \$TTY_PATH

    # Disk usage
    echo -e "\${GREEN}=== Disk Usage ===\${RESET}" > \$TTY_PATH
    df -h | grep -v tmpfs | while read line; do
        used_pct=\$(echo \$line | awk '{print \$5}' | tr -d '%')
        if [ "\$used_pct" -ge 90 ]; then echo -e "\${RED}\$line\${RESET}" > \$TTY_PATH
        elif [ "\$used_pct" -ge 75 ]; then echo -e "\${YELLOW}\$line\${RESET}" > \$TTY_PATH
        else echo "\$line" > \$TTY_PATH
        fi
    done

    # Network interfaces
    echo -e "\${GREEN}=== Network Interfaces ===\${RESET}" > \$TTY_PATH
    ip -br addr | while read line; do
        if echo \$line | grep -q "DOWN"; then
            echo -e "\${RED}\$line\${RESET}" > \$TTY_PATH
        else
            echo -e "\${GREEN}\$line\${RESET}" > \$TTY_PATH
        fi
    done

    echo "Press Ctrl+C to quit (systemd restarts automatically)" > \$TTY_PATH
    sleep \$refresh
 done
EOF

sudo chmod +x $DASHBOARD_SCRIPT

# -------------------------
# CREATE SYSTEMD SERVICE
# -------------------------
SERVICE_FILE=/etc/systemd/system/tty-dashboard.service
cat << EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Emergency TTY Dashboard
After=getty@tty1.service

[Service]
ExecStart=$DASHBOARD_SCRIPT
StandardInput=tty
StandardOutput=tty
Restart=always
User=$DASHBOARD_USER
Group=tty

[Install]
WantedBy=multi-user.target
EOF

# -------------------------
# ENABLE AND START SERVICE
# -------------------------
sudo systemctl daemon-reload
sudo systemctl enable tty-dashboard.service
sudo systemctl start tty-dashboard.service

echo "Emergency TTY Dashboard installed and running on /dev/tty$TTY_NUMBER"
