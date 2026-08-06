#!/usr/bin/env bash
set -euo pipefail

echo "== Multi-Identity Git Bootstrap =="

BASE_DIR="$HOME/git"
SSH_DIR="$HOME/.ssh"
TEMPLATE_DIR="$HOME/.git-templates"

PERSONAS=("work" "personal" "oss" "throwaway")

echo "[1/7] Creating directory structure..."
for p in "${PERSONAS[@]}"; do
    mkdir -p "$BASE_DIR/$p"
done

echo "[2/7] Ensuring SSH directory exists..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

generate_key () {
    local name="$1"
    local keyfile="$SSH_DIR/id_ed25519_${name}"

    if [[ -f "$keyfile" ]]; then
        echo "  • SSH key exists for $name — skipping"
    else
        echo "  • Generating SSH key for $name"
        ssh-keygen -t ed25519 -f "$keyfile" -N "" -C "git-${name}"
    fi
}

echo "[3/7] Generating per-persona SSH keys..."
for p in "${PERSONAS[@]}"; do
    generate_key "$p"
done

echo "[4/7] Writing SSH config entries..."
SSH_CONFIG="$SSH_DIR/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

add_ssh_host () {
    local host="$1"
    local key="$2"

    if grep -q "Host github-${host}" "$SSH_CONFIG"; then
        echo "  • SSH host github-${host} exists — skipping"
    else
        cat >> "$SSH_CONFIG" <<EOF

Host github-${host}
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_${host}
    IdentitiesOnly yes
EOF
    fi
}

for p in "${PERSONAS[@]}"; do
    add_ssh_host "$p" "$p"
done

echo "[5/7] Writing persona git configs..."

write_gitconfig () {
    local name="$1"
    local email="$2"
    local persona="$3"
    local sign="$4"

    cat > "$HOME/.gitconfig-${persona}" <<EOF
[user]
    name = ${name}
    email = ${email}

[commit]
    gpgsign = ${sign}

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_${persona}
EOF
}

write_gitconfig "Work User" "work@example.com" "work" "true"
write_gitconfig "Personal User" "personal@example.com" "personal" "true"
write_gitconfig "OSS Alias" "oss@example.com" "oss" "true"
write_gitconfig "temp" "temp@invalid.local" "throwaway" "false"

echo "[6/7] Updating global git router..."

git config --global includeIf.gitdir:~/git/work/.path ~/.gitconfig-work
git config --global includeIf.gitdir:~/git/personal/.path ~/.gitconfig-personal
git config --global includeIf.gitdir:~/git/oss/.path ~/.gitconfig-oss
git config --global includeIf.gitdir:~/git/throwaway/.path ~/.gitconfig-throwaway

echo "[7/7] Installing safety hook template..."

mkdir -p "$TEMPLATE_DIR/hooks"

cat > "$TEMPLATE_DIR/hooks/pre-commit" <<'EOF'
#!/usr/bin/env bash
set -e

repo_path="$(pwd)"
email="$(git config user.email || true)"

if [[ "$repo_path" == *"/git/work/"* ]]; then
    if [[ "$email" != *"work@"* ]]; then
        echo "❌ Wrong identity for WORK repo"
        exit 1
    fi
fi

if [[ "$repo_path" == *"/git/personal/"* ]]; then
    if [[ "$email" != *"personal@"* ]]; then
        echo "❌ Wrong identity for PERSONAL repo"
        exit 1
    fi
fi

exit 0
EOF

chmod +x "$TEMPLATE_DIR/hooks/pre-commit"
git config --global init.templateDir "$TEMPLATE_DIR"

echo
echo "✅ Bootstrap complete."
echo
echo "NEXT STEPS:"
echo "1. Add each ~/.ssh/id_ed25519_*.pub to the correct GitHub account"
echo "2. Clone using:"
echo "     git clone git@github-work:ORG/REPO.git"
echo
echo "Stay sharp."
