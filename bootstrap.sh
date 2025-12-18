#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
CONFIG_DIR="$HOME/.config"

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

# --- Helpers ---
info() { echo -e "📦 $1"; }
ok()   { echo -e "✅ $1"; }
err()  { echo -e "❌ $1" >&2; exit 1; }

# --- Preconditions ---
command -v stow >/dev/null 2>&1 || err "GNU Stow is not installed"
mkdir -p "$CONFIG_DIR"

cd "$DOTFILES_DIR"

# --- Stow ~/.config packages ---
for pkg in "${CONFIG_PACKAGES[@]}"; do
  [[ -d "$pkg" ]] || err "Missing package: $pkg"

  info "Stowing $pkg → ~/.config"
  stow --target="$CONFIG_DIR" "$pkg"
  ok "$pkg stowed"
done

# --- Stow $HOME packages (zsh, etc.) ---
for pkg in "${HOME_PACKAGES[@]}"; do
  [[ -d "$pkg" ]] || err "Missing package: $pkg"

  info "Stowing $pkg → ~/"
  stow --target="$HOME_DIR" "$pkg"
  ok "$pkg stowed"
done

echo "🎉 All dotfiles stowed successfully"
