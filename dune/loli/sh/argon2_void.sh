#!/bin/bash
set -euo pipefail

OUTPUT_FILE="argon_hashes.txt"
ENTROPY_FILE="random256.bin"

# Argon2 parameters (tune as needed)
MEMORY=19     # 512 MB (2^19 KB)
TIME=3
THREADS=1

# ---------- sanity checks ----------
if [ ! -f "$ENTROPY_FILE" ]; then
    echo "ERROR: $ENTROPY_FILE not found."
    echo "You must supply 256 bytes of trusted entropy."
    exit 1
fi

if [ "$(stat -c%s "$ENTROPY_FILE")" -lt 256 ]; then
    echo "ERROR: entropy file must be at least 256 bytes."
    exit 1
fi

echo "Kernel-independent Argon2id mode."
echo "Press Ctrl+C to exit."
echo "----------------------------------"

while true; do
    read -r -s -p "Enter string: " input
    echo

    if [ -z "$input" ]; then
        echo "Empty input skipped."
        continue
    fi

    # ---------- derive per-run salt from trusted entropy ----------
    ARGON_SALT=$(dd if="$ENTROPY_FILE" bs=16 count=1 2>/dev/null | base64)

    # ---------- create randomized mixing buffer ----------
    MIX_FILE=$(mktemp)
    trap 'rm -f "$MIX_FILE"' EXIT

    entropy_size=$(stat -c%s "$ENTROPY_FILE")
    input_len=${#input}

    e_pos=0
    i_pos=0

    # Interleave until both streams exhausted
    while [ $e_pos -lt $entropy_size ] || [ $i_pos -lt $input_len ]; do

        # entropy chunk (128–512 bytes)
        if [ $e_pos -lt $entropy_size ]; then
            e_chunk=$(( (RANDOM % 385) + 128 ))
            dd if="$ENTROPY_FILE" bs=1 skip=$e_pos count=$e_chunk \
                2>/dev/null >> "$MIX_FILE" || true
            e_pos=$((e_pos + e_chunk))
        fi

        # input chunk (1–8 chars)
        if [ $i_pos -lt $input_len ]; then
            i_chunk=$(( (RANDOM % 8) + 1 ))
            printf "%s" "${input:$i_pos:$i_chunk}" >> "$MIX_FILE"
            i_pos=$((i_pos + i_chunk))
        fi

    done

    # ---------- Argon2id hash ----------
    hash=$(argon2 "$ARGON_SALT" -id -t "$TIME" -m "$MEMORY" -p "$THREADS" < "$MIX_FILE")

    {
        printf "%s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
        printf "%s\n\n" "$hash"
    } >> "$OUTPUT_FILE"

    echo "✔ Hash stored."

    # ---------- cleanup ----------
    shred -u "$MIX_FILE" 2>/dev/null || rm -f "$MIX_FILE"
    unset input hash ARGON_SALT
done