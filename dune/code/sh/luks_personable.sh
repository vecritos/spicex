#!/bin/bash
# luks_triple_key_hardening_offline.sh
# Triple-key LUKS2 setup with passkeys viewable for offline capture
# No dead-man switches or time locks

set -euo pipefail

# --- CONFIG ---
DISK="/dev/sdX"                         # Target device
HEADER_BACKUP1="/secure/location/header1.img"
HEADER_BACKUP2="/secure/location/header2.img"
HEADER_BACKUP3="/secure/location/header3.img"
SEGMENT_HEADERS=false                    # true = remove headers from disk

# --- SAFETY CHECK ---
if [ ! -b "$DISK" ]; then
    echo "Error: $DISK is not a valid block device."
    exit 1
fi

# --- GENERATE AND DISPLAY STRONG PASSKEYS ---
declare -A PASSKEYS
for i in 1 2 3; do
    # Generate 128-bit random hex (32 characters)
    key=$(openssl rand -hex 32)
    PASSKEYS[$i]="$key"
    echo "-----------------------------"
    echo "Passkey $i (copy offline!)"
    echo "${PASSKEYS[$i]}"
    echo "-----------------------------"
done

echo "Please copy these keys offline (paper, symbolic, encrypted file) before proceeding."
read -p "Press ENTER to continue after you have stored the keys securely..." dummy

# --- SAVE KEYS TO TEMP FILES (used internally only) ---
for i in 1 2 3; do
    tmpfile="/tmp/luks_passkey$i.txt"
    echo "${PASSKEYS[$i]}" > "$tmpfile"
    chmod 600 "$tmpfile"
    PASSKEYS[$i]="$tmpfile"   # Replace array entry with file path for cryptsetup
done

# --- CREATE LUKS2 VOLUME ---
echo "Creating LUKS2 volume on $DISK with Argon2id KDF..."
sudo cryptsetup luksFormat "$DISK" \
    --type luks2 \
    --pbkdf argon2id \
    --pbkdf-memory 2097152 \
    --pbkdf-parallel 4 \
    --pbkdf-force-iterations 4M \
    --key-file "${PASSKEYS[1]}"

# --- ADD SECOND AND THIRD KEY SLOTS ---
sudo cryptsetup luksAddKey "$DISK" --key-file "${PASSKEYS[1]}" "${PASSKEYS[2]}"
sudo cryptsetup luksAddKey "$DISK" --key-file "${PASSKEYS[1]}" "${PASSKEYS[3]}"

# --- OPEN THE VOLUME FOR TEST ---
MAPPED_NAME="securedata"
sudo cryptsetup open "$DISK" "$MAPPED_NAME" --key-file "${PASSKEYS[1]}"

# --- BACKUP HEADERS (Independent, Always Available) ---
for i in 1 2 3; do
    HEADER_VAR="HEADER_BACKUP$i"
    echo "Backing up header for key $i to ${!HEADER_VAR}..."
    # Restore original header first
    sudo cryptsetup luksHeaderRestore "$DISK" --header-backup-file "$HEADER_BACKUP1" || true
    sudo cryptsetup luksHeaderBackup "$DISK" --header-backup-file "${!HEADER_VAR}"
    chmod 600 "${!HEADER_VAR}"
done

# --- OPTIONAL: Remove disk header (physical segmentation) ---
if [ "$SEGMENT_HEADERS" = true ]; then
    echo "Removing LUKS header from disk (volume cannot be accessed without any backup)..."
    sudo cryptsetup luksHeaderErase "$DISK"
    echo "Keep all header backups safe!"
fi

# --- CLOSE VOLUME ---
sudo cryptsetup close "$MAPPED_NAME"

# --- CLEANUP TEMP PASSKEY FILES ---
for i in 1 2 3; do
    rm -f "${PASSKEYS[$i]}"
done

echo "Triple-key LUKS2 volume setup complete."
echo "All headers and keys are fully independent; no dead-man or time-lock dependencies exist."
echo "Keys were displayed for offline capture; ensure they are stored securely."
