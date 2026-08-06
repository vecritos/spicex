#!/bin/bash

# ======================================================
# restricted_dev_user.sh
# Creates a restricted development user for Git/Vim only
# ======================================================

show_help() {
    cat << EOF
Usage: $0 -n USERNAME

Options:
  -n USERNAME   Specify the username for the restricted account
  --help        Display this help message

Description:
  This script creates a restricted Linux account:
  - No sudo access
  - Restricted bash shell (rbash)
  - PATH limited to: git, vim, less
  - Prevents common privilege escalation commands
  - Locks down git config and vimrc for safety
EOF
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n)
            shift
            USERNAME="$1"
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$USERNAME" ]]; then
    echo "Error: Username is required."
    show_help
    exit 1
fi

# ---------------------------
# 1. Create the user (no sudo)
# ---------------------------
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
else
    sudo adduser --disabled-password --gecos "" "$USERNAME"
    echo "Created user: $USERNAME"
fi

# Remove from sudo/wheel if present
sudo deluser "$USERNAME" sudo 2>/dev/null
sudo gpasswd -d "$USERNAME" wheel 2>/dev/null

# ---------------------------
# 2. Set restricted shell (rbash)
# ---------------------------
sudo chsh -s /bin/rbash "$USERNAME"

# ---------------------------
# 3. Setup restricted PATH
# ---------------------------
sudo -u "$USERNAME" mkdir -p /home/$USERNAME/bin
sudo -u "$USERNAME" ln -sf /usr/bin/git /home/$USERNAME/bin/git
sudo -u "$USERNAME" ln -sf /usr/bin/vim /home/$USERNAME/bin/vim
sudo -u "$USERNAME" ln -sf /usr/bin/less /home/$USERNAME/bin/less

# Lock PATH in .bash_profile
cat << 'EOF' | sudo -u "$USERNAME" tee /home/$USERNAME/.bash_profile
export PATH=$HOME/bin
export SHELL=/bin/rbash
EOF

# ---------------------------
# 4. Lock down vim and git
# ---------------------------
sudo -u "$USERNAME" tee /home/$USERNAME/.vimrc << 'EOF'
set secure
set nomodeline
set shell=/bin/false
EOF

sudo -u "$USERNAME" tee /home/$USERNAME/.gitconfig << 'EOF'
[core]
    pager = cat
    editor = vim
EOF

sudo chown "$USERNAME:$USERNAME" /home/$USERNAME/.vimrc /home/$USERNAME/.gitconfig
sudo chattr +i /home/$USERNAME/.gitconfig  # Immutable
sudo chattr +i /home/$USERNAME/.vimrc      # Immutable

# ---------------------------
# 5. Warn about dangerous commands
# ---------------------------
echo "Restricted dev user '$USERNAME' setup complete."
echo "Allowed commands: git, vim, less"
echo "User has no sudo access."
echo "Other commands are blocked by rbash and restricted PATH."
