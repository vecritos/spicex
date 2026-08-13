#!/usr/bin/env bash

set -e

ISO="$1"

if [ -z "$ISO" ]; then
  echo "Usage: sudo $0 <reference_linux.iso>"
  exit 1
fi

echo "======================================"
echo "PARANOID FIRMWARE / PERSISTENCE AUDIT"
echo "======================================"

risk=0

function low(){ echo "[LOW] $1"; }
function med(){ echo "[MEDIUM] $1"; risk=$((risk+1)); }
function high(){ echo "[HIGH] $1"; risk=$((risk+3)); }
function crit(){ echo "[CRITICAL] $1"; risk=$((risk+6)); }

echo
echo "===== SYSTEM INFORMATION ====="
uname -a
dmidecode -t system | grep -E "Manufacturer|Product|Version"

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

ESP=$(lsblk -o NAME,FSTYPE | grep vfat | head -n1 | awk '{print $1}')

if [ -z "$ESP" ]; then
  high "EFI system partition not detected"
else
  echo "EFI partition: /dev/$ESP"
fi

mkdir -p /mnt/esp
mount /dev/$ESP /mnt/esp || true

echo
echo "===== EFI DIRECTORY TREE ====="
find /mnt/esp

echo
echo "===== HASHING EFI BINARIES ====="

mkdir -p /tmp/efi

find /mnt/esp -name "*.efi" -type f | while read file; do
  sha512sum "$file"
done > /tmp/efi/disk_hashes.txt

cat /tmp/efi/disk_hashes.txt

echo
echo "===== ISO REFERENCE HASHES ====="

mkdir -p /mnt/iso
mount -o loop "$ISO" /mnt/iso

find /mnt/iso -name "*.efi" -type f | while read file; do
  sha512sum "$file"
done > /tmp/efi/iso_hashes.txt

cat /tmp/efi/iso_hashes.txt

echo
echo "===== HASH COMPARISON ====="

while read line; do
  HASH=$(echo $line | awk '{print $1}')
  if ! grep -q "$HASH" /tmp/efi/iso_hashes.txt; then
    med "EFI binary not present in reference ISO: $line"
  fi
done < /tmp/efi/disk_hashes.txt

echo
echo "===== UNKNOWN EFI VENDORS ====="

KNOWN="BOOT ubuntu fedora Microsoft debian"

for dir in $(ls /mnt/esp/EFI 2>/dev/null); do
  if ! echo "$KNOWN" | grep -qi "$dir"; then
    med "Unknown EFI directory: $dir"
  fi
done

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
  chipsec_main.py -m common.bios_ts
fi

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
echo "Audit completed."
