#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Paranoid live-system health check
# Runs the standard root, firmware, and hygiene checks for a
# security-minded Linux user on a live boot or personal system.
# ============================================================

echo "======================================"
echo "PARANOID SYSTEM HEALTH CHECK"
echo "======================================"

risk=0

function low(){ echo "[LOW] $1"; }
function med(){ echo "[MEDIUM] $1"; risk=$((risk+1)); }
function high(){ echo "[HIGH] $1"; risk=$((risk+3)); }
function crit(){ echo "[CRITICAL] $1"; risk=$((risk+6)); }

echo
echo "===== SYSTEM INFORMATION ====="
uname -a
dmidecode -t system | grep -E "Manufacturer|Product|Version" || true

echo
echo "===== SECURE BOOT STATUS ====="
if command -v mokutil &>/dev/null; then
  mokutil --sb-state || med "Unable to read secure boot state"
fi

echo
echo "===== UEFI BOOT ENTRIES ====="
if command -v efibootmgr &>/dev/null; then
  efibootmgr -v
fi

echo
echo "===== DISK STRUCTURE ====="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
fdisk -l || true

echo
echo "===== FIND EFI PARTITION ====="
ESP=$(lsblk -o NAME,FSTYPE | grep vfat | head -n1 | awk '{print $1}' || true)
if [ -z "$ESP" ]; then
  high "EFI system partition not detected"
else
  echo "EFI partition: /dev/$ESP"
fi

mkdir -p /mnt/esp
mount /dev/$ESP /mnt/esp 2>/dev/null || true

echo
echo "===== EFI DIRECTORY TREE ====="
find /mnt/esp 2>/dev/null || true

echo
echo "===== HASHING EFI BINARIES ====="
mkdir -p /tmp/efi
find /mnt/esp -name "*.efi" -type f 2>/dev/null | while read -r file; do
  sha512sum "$file"
done > /tmp/efi/disk_hashes.txt
cat /tmp/efi/disk_hashes.txt

echo
echo "===== FIRMWARE UPDATE STATUS ====="
if command -v fwupdmgr &>/dev/null; then
  fwupdmgr get-devices
  fwupdmgr get-updates
fi

echo
echo "===== TPM MEASUREMENTS ====="
if command -v tpm2_pcrread &>/dev/null; then
  tpm2_pcrread
else
  low "TPM tools not installed"
fi

echo
echo "===== PCI DEVICE INSPECTION ====="
lspci

echo
echo "===== INTEL ME / AMD PSP ====="
if lspci | grep -i "management engine"; then
  echo "Intel ME detected"
fi
if lspci | grep -i "psp"; then
  echo "AMD Platform Security Processor detected"
fi

echo
echo "===== SPI FLASH PROTECTION ====="
if command -v chipsec_main.py &>/dev/null; then
  echo "Running CHIPSEC SPI checks..."
  chipsec_main.py -m common.spi_lock || med "SPI flash may not be locked"
  chipsec_main.py -m common.bios_wp || med "BIOS write protection not enabled"
  chipsec_main.py -m common.secureboot.variables || med "Secure boot variables suspicious"
else
  med "CHIPSEC not installed — skipping firmware integrity tests"
fi

echo
echo "===== BOOT GUARD CHECK ====="
if command -v chipsec_main.py &>/dev/null; then
  chipsec_main.py -m common.bios_ts || true
fi

echo
echo "===== ROOT / PRIVILEGE ACTIVITY ====="
if command -v auditctl &>/dev/null; then
  auditctl -l || true
else
  low "Audit tools not installed"
fi

if command -v sudo &>/dev/null; then
  echo
  echo "===== SUDO / PRIVILEGE POLICY ====="
  sudo -l || true
fi

if command -v ausearch &>/dev/null; then
  echo
  echo "===== AUDIT EVENT SUMMARY ====="
  ausearch -ts recent -m USER_CMD -i 2>/dev/null | head -n 20 || true
fi

echo
echo "===== NETWORK / FIREWALL STATUS ====="
if command -v nft &>/dev/null; then
  nft list ruleset || true
elif command -v iptables &>/dev/null; then
  iptables -S || true
fi

if command -v ufw &>/dev/null; then
  ufw status verbose || true
fi

echo
echo "===== ACTIVE SERVICES ====="
systemctl list-unit-files --type=service --state=enabled --no-pager 2>/dev/null | head -n 40 || true

echo
echo "===== BOOT LOG / RECENT FAILURES ====="
journalctl -p err -b --no-pager 2>/dev/null | tail -n 30 || true

echo
echo "===== FINAL RISK SCORE ====="
echo "Risk score: $risk"
if [ "$risk" -eq 0 ]; then
  echo "Assessment: CLEAN"
elif [ "$risk" -lt 5 ]; then
  echo "Assessment: LOW RISK"
elif [ "$risk" -lt 10 ]; then
  echo "Assessment: MEDIUM RISK"
else
  echo "Assessment: HIGH RISK"
fi

echo
echo "Health check completed."
