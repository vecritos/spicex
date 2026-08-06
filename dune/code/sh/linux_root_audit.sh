#!/bin/bash
#
# Scripts to setup auditd things 
#

# /etc/audit/rules.d/root.rules
# -w /usr/bin/sudo -p x -k root_activity

#!/bin/bash
# ausearch -k root_activity -m EXECVE -i -f /var/log/audit/audit.log | while read line; do
#   DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
#   notify-send "ALERT: Root command executed!"
# done

# PAM 
# /etc/pam.d/sudo or /etc/pam.d/su
# session optional pam_exec.so /usr/local/bin/root_alert.sh
#
# /usr/local/bin/root_alert.sh
# echo "ALERT: $PAM_USER used sudo/root!" | wall
#
