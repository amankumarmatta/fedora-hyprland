#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────
info() { echo -e "📦 $1"; }
ok()   { echo -e "✅ $1"; }
err()  { echo -e "❌ $1" >&2; exit 1; }

# ─────────────────────────────────────────────
# System-level: fstab / mount
# ─────────────────────────────────────────────
update_fstab() {
    local UUID="2D5D808922F7E507"
    local USERNAME="$(id -un)"
    local HOME_DIR="/home/$USERNAME"
    local MOUNT_POINT="$HOME_DIR/HDD"

    local ENTRY="UUID=$UUID  $MOUNT_POINT  ntfs-3g  defaults,uid=1000,gid=1000,umask=022  0  0"

    info "Preparing HDD mount point at $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
    sudo chown "$USERNAME:$USERNAME" "$MOUNT_POINT"

    if ! grep -q "^UUID=$UUID" /etc/fstab; then
        info "Adding HDD entry to /etc/fstab"
        echo -e "\n# HDD ($UUID)\n$ENTRY" | sudo tee -a /etc/fstab >/dev/null
        ok "fstab entry added"
    else
        info "fstab entry already exists — skipping"
    fi

    sudo systemctl daemon-reload
    sudo mount -a
    ok "fstab validated and HDD mounted"
}

# ─────────────────────────────────────────────
# User-level: Git configuration
# ─────────────────────────────────────────────
configure_git_if_needed() {
    command -v git >/dev/null 2>&1 || err "Git is not installed"

    local existing_name
    local existing_email

    existing_name=$(git config --global user.name || true)
    existing_email=$(git config --global user.email || true)

    if [[ -n "$existing_name" && -n "$existing_email" ]]; then
        ok "Git already configured as: $existing_name <$existing_email>"
        return
    fi

    info "Git is not configured. Let's set it up."

    while [[ -z "${GIT_NAME:-}" ]]; do
        read -rp "Enter your Git user.name: " GIT_NAME
    done

    while [[ -z "${GIT_EMAIL:-}" ]]; do
        read -rp "Enter your Git user.email: " GIT_EMAIL
    done

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch main

    ok "Git configured as $GIT_NAME <$GIT_EMAIL>"
}

# ─────────────────────────────────────────────
# User-level: dotfiles + stow
# ─────────────────────────────────────────────
stow_dotfiles() {
    command -v stow >/dev/null 2>&1 || err "GNU Stow is not installed"

    local DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local CONFIG_DIR="$HOME/.config"

    CONFIG_PACKAGES=(
      hypr
      waybar
      kitty
      fastfetch
      rofi
      wlogout
      gtk-3.0
      gtk-4.0
    )

    HOME_PACKAGES=(
      zsh
    )

    mkdir -p "$CONFIG_DIR"
    cd "$DOTFILES_DIR"

    info "Stowing ~/.config packages"
    for pkg in "${CONFIG_PACKAGES[@]}"; do
        [[ -d "$pkg" ]] || err "Missing package: $pkg"
        stow --target="$CONFIG_DIR" "$pkg"
        ok "$pkg stowed → ~/.config"
    done

    info "Preparing home-level dotfiles"

    # ----------------------------------------------------------
    # Handle existing ~/.zshrc safely
    # ----------------------------------------------------------
    if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        warn "~/.zshrc exists and is not a symlink — removing it before stowing"
        rm "$HOME/.zshrc"
    fi

    info "Stowing home-level packages"
    for pkg in "${HOME_PACKAGES[@]}"; do
        [[ -d "$pkg" ]] || err "Missing package: $pkg"
        stow --target="$HOME" "$pkg"
        ok "$pkg stowed → ~/"
    done
}

# ─────────────────────────────────────────────
# Main execution flow
# ─────────────────────────────────────────────
main() {
    info "Starting bootstrap"

    update_fstab
    configure_git_if_needed
    stow_dotfiles

    ok "Bootstrap completed successfully 🎉"
}

main "$@"
