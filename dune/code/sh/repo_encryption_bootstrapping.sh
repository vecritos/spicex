#!/bin/bash
# secure-git-sandbox.sh
# Prototype: sandboxed ephemeral access to a Git repo

# CONFIGURATION
REPO_URL="git@example.com:yourrepo.git"    # Remote Git repo
SANDBOX_DIR="/dev/shm/git_sandbox"        # RAM disk for ephemeral access
EPHEMERAL_KEY_FILE="/dev/shm/ephemeral_key" # Temporary SSH key or token
PEPPER_FILE="/dev/shm/repo_pepper"        # Temporary pepper

# CLEANUP FUNCTION
cleanup() {
    echo "[*] Cleaning up sandbox..."
    rm -rf "$SANDBOX_DIR"
    rm -f "$EPHEMERAL_KEY_FILE"
    rm -f "$PEPPER_FILE"
}
trap cleanup EXIT

# 1️⃣ Setup sandbox RAM disk
echo "[*] Setting up sandbox in RAM..."
mkdir -p "$SANDBOX_DIR"
chmod 700 "$SANDBOX_DIR"

# 2️⃣ Generate ephemeral key / pepper
echo "[*] Generating ephemeral access key..."
# For SSH example: generate temporary key
ssh-keygen -t ed25519 -f "$EPHEMERAL_KEY_FILE" -N "" -q
# Pepper can be anything random
head -c 32 /dev/urandom > "$PEPPER_FILE"

# 3️⃣ Restrict shell access inside sandbox
echo "[*] Launching restricted shell..."
# rbash example (restricted bash)
export SANDBOX_DIR
export PATH="$SANDBOX_DIR/bin"   # Only allow commands in sandbox
mkdir -p "$SANDBOX_DIR/bin"

# Copy minimal Git binary to sandbox if needed
cp "$(which git)" "$SANDBOX_DIR/bin/"

# 4️⃣ Clone repo into sandbox using ephemeral key
echo "[*] Cloning repo into sandbox..."
GIT_SSH_COMMAND="ssh -i $EPHEMERAL_KEY_FILE -o StrictHostKeyChecking=no" \
    git clone "$REPO_URL" "$SANDBOX_DIR/repo"

# 5️⃣ Enter sandboxed work environment
echo "[*] Entering sandboxed environment..."
cd "$SANDBOX_DIR/repo" || exit 1
echo "You are now in a sandboxed Git environment."
echo "All changes will be wiped when this shell exits."

# Optional: restricted RBASH
rbash

# 6️⃣ On exit, cleanup is triggered automatically by trap
