#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# CONFIG
# ----------------------------
ROOT="/crypt/git-secure"
REPO_ROOT="$ROOT/repos"
LOG_DIR="$ROOT/logs"

mkdir -p "$REPO_ROOT" "$LOG_DIR"
chmod 700 "$REPO_ROOT" "$LOG_DIR"

log() {
    local msg="$1"
    # Logs both to syslog and encrypted log file
    logger -t git-wrapper "$msg"
    echo "$(date -Is) $msg" >> "$LOG_DIR/git-wrapper.log"
}

deny() {
    local msg="$1"
    log "DENIED: $msg"
    exit 1
}

# ----------------------------
# REPO CREATION (example: git-create <name>)
# ----------------------------
if [[ $# -ge 2 && "$1" == "git-create" ]]; then
    repo_name="$2"

    # Generate per-repo pepper
    pepper=$(openssl rand -hex 32)

    # Compute hash-based directory
    hash=$(printf "%s%s" "$repo_name" "$pepper" | sha256sum | awk '{print $1}')
    repo_path="$REPO_ROOT/$hash"

    mkdir -p "$repo_path"
    chmod 700 "$repo_path"

    echo "$pepper" > "$repo_path/pepper.secret"
    chmod 600 "$repo_path/pepper.secret"

    git init --bare "$repo_path"

    log "CREATED repo $repo_name -> $hash"
    echo "Repo '$repo_name' created at hashed path: $hash"

    exit 0
fi

# ----------------------------
# SSH / GIT COMMAND HANDLER
# ----------------------------
cmd="${SSH_ORIGINAL_COMMAND:-}"
[[ -n "$cmd" ]] || deny "empty SSH command"

case "$cmd" in
    git-upload-pack*|git-upload-archive*|git-receive-pack*)
        ;;
    *)
        deny "invalid command: $cmd"
        ;;
esac

# Extract repo name from command
repo=$(echo "$cmd" | sed -E "s/^[^ ]+ '?([^']+)'?/\1/")
repo=$(basename "$repo")

# ----------------------------
# PER-REPO PEPPER & HASH VERIFICATION
# ----------------------------
repo_path=""
for dir in "$REPO_ROOT"/*; do
    [[ -f "$dir/pepper.secret" ]] || continue
    pepper=$(cat "$dir/pepper.secret")
    computed_hash=$(printf "%s%s" "$repo" "$pepper" | sha256sum | awk '{print $1}')
    if [[ "$(basename "$dir")" == "$computed_hash" ]]; then
        repo_path="$dir"
        break
    fi
done

[[ -n "$repo_path" ]] || deny "unknown repository: $repo"

# ----------------------------
# Optional per-command logging
# ----------------------------
log "ALLOWED: $repo -> $repo_path, command: $cmd, user: $USER, from $SSH_CONNECTION"

# ----------------------------
# Execute Git command
# ----------------------------
exec git-shell -c "$cmd"
