#!/bin/bash

set -u

RECIPIENT="isadiewei@pm.me"
HOSTNAME="$(hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
LOGDIR="securityscans"
LOGFILE="$LOGDIR/securityscan$(date '+%Y%m%d%H%M%S').log"

mkdir -p "$LOGDIR"

exec > >(tee -a "$LOGFILE") 2>&1

echo "========================================"
echo "Daily Security Scan"
echo "Host: $HOSTNAME"
echo "Started: $DATE"
echo "========================================"
echo

FAIL=0

echo "===== CLAMAV ====="
echo

# Avoid scanning virtual kernel filesystems.
clamscan -r -i / \
    --exclude-dir='^/proc' \
    --exclude-dir='^/sys' \
    --exclude-dir='^/dev' \
    --exclude-dir='^/run' \
    --exclude-dir='^/snap' \
    --exclude-dir='^/var/lib/docker' \
    --exclude-dir='^/var/lib/containers'

CLAM_EXIT=$?

if [ "$CLAM_EXIT" -eq 1 ]; then
    echo
    echo "WARNING: ClamAV found infected files."
    FAIL=1
elif [ "$CLAM_EXIT" -gt 1 ]; then
    echo
    echo "WARNING: ClamAV encountered an error."
    FAIL=1
else
    echo
    echo "ClamAV: clean."
fi

echo
echo "===== RKHUNTER ====="
echo

rkhunter --check --skip-keypress --report-warnings-only

RKH_EXIT=$?

if [ "$RKH_EXIT" -ne 0 ]; then
    echo
    echo "WARNING: rkhunter reported warnings or errors."
    FAIL=1
fi

echo
echo "===== CHKROOTKIT ====="
echo

chkrootkit

CHK_EXIT=$?

if [ "$CHK_EXIT" -ne 0 ]; then
    echo
    echo "WARNING: chkrootkit reported warnings or errors."
    FAIL=1
fi

echo
echo "========================================"
echo "Scan completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

if [ "$FAIL" -eq 0 ]; then
    SUBJECT="[SECURITY] $HOSTNAME - clean"
else
    SUBJECT="[SECURITY] $HOSTNAME - WARNING"
fi

# Email the complete report.
mail -s "$SUBJECT" "$RECIPIENT" < "$LOGFILE"

exit "$FAIL"
