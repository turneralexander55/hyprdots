#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Hyprdots install script
# Stage 1: Pacman packages
# ------------------------------------------------------------

echo "==> Starting hyprdots install (stage 1)"

# Ensure we are running on Arch Linux
if [[ ! -f /etc/arch-release ]]; then
  echo "ERROR: This script is intended for Arch Linux only."
  exit 1
fi

# Ensure pacman exists
if ! command -v pacman &>/dev/null; then
  echo "ERROR: pacman not found. Is this an Arch-based system?"
  exit 1
fi

# Ensure package list exists# ------------------------------------------------------------
# Pass 3: Final confirmation + deploy
# ------------------------------------------------------------

echo "==> Final confirmation"
echo "The following configuration directories WILL be overwritten:"
echo

for cfg in "${APPROVED_CONFIGS[@]}"; do
  echo "  - $cfg"
done

echo
read -r -p "Proceed with deploying these configurations? [y/N] " final_reply
echo

case "$final_reply" in
  y|Y|yes|YES)
    echo "==> Proceeding with deployment..."
    ;;
  *)
    echo "Deployment aborted. No changes were made."
    exit 0
    ;;
esac

echo

# Perform the actual deployment
for cfg in "${APPROVED_CONFIGS[@]}"; do
  SRC="$DOTFILES_DIR/$cfg"
  DEST="$TARGET_DIR/$cfg"

  echo "==> Deploying $cfg"

  # Remove existing destination if it exists
  if [[ -e "$DEST" ]]; then
    rm -rf "$DEST"
  fi

  # Copy config from repo into ~/.config
  cp -a "$SRC" "$DEST"
done

echo
echo "==> Configuration deployment complete."

# ------------------------------------------------------------
# Install .example configs (only if missing)
# ------------------------------------------------------------

echo "==> Installing default config templates (.example)"

find "$TARGET_DIR/hypr" -name "*.example" | while read -r example; do
  target="${example%.example}"

  if [[ -e "$target" ]]; then
    echo "Skipping $(basename "$target") (already exists)"
    continue
  fi

  echo "Installing $(basename "$target") from template"
  cp "$example" "$target"
done
PACMAN_LIST="$(dirname "$0")/../packages/pacman.txt"

if [[ ! -f "$PACMAN_LIST" ]]; then
  echo "ERROR: pacman package list not found at $PACMAN_LIST"
  exit 1
fi

echo "==> Installing pacman packages..."

mapfile -t PACMAN_PACKAGES < <(
  grep -Ev '^\s*#|^\s*$' "$PACMAN_LIST"
)

if [[ "${#PACMAN_PACKAGES[@]}" -eq 0 ]]; then
  echo "No pacman packages to install."
else
  sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
fi

echo "==> Pacman packages installed successfully."


# ------------------------------------------------------------
# Stage 2: AUR helper (paru) + AUR packages
# ------------------------------------------------------------

echo "==> Starting AUR setup (stage 2)"

# Ensure git exists (required for AUR builds)
if ! command -v git &>/dev/null; then
  echo "==> Installing git..."
  sudo pacman -S --needed --noconfirm git
fi

# Ensure base-devel exists (required for makepkg)
if ! pacman -Qi base-devel &>/dev/null; then
  echo "==> Installing base-devel..."
  sudo pacman -S --needed --noconfirm base-devel
fi

# Ensure paru is installed
if ! command -v paru &>/dev/null; then
  echo "==> Paru not found. Bootstrapping paru..."

  PARU_DIR="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$PARU_DIR/paru"
  pushd "$PARU_DIR/paru" >/dev/null

  makepkg -si --noconfirm

  popd >/dev/null
  rm -rf "$PARU_DIR"

  echo "==> Paru installed successfully."
else
  echo "==> Paru already installed. Skipping bootstrap."
fi

# Ensure AUR package list exists
AUR_LIST="$(dirname "$0")/../packages/aur.txt"

if [[ ! -f "$AUR_LIST" ]]; then
  echo "ERROR: AUR package list not found at $AUR_LIST"
  exit 1
fi

echo "==> Installing AUR packages..."

mapfile -t AUR_PACKAGES < <(
  grep -Ev '^\s*#|^\s*$' "$AUR_LIST"
)

if [[ "${#AUR_PACKAGES[@]}" -eq 0 ]]; then
  echo "No AUR packages to install."
else
  paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
fi

echo "==> AUR packages installed successfully."

# ------------------------------------------------------------
# Stage 3: Deploy dotfiles into ~/.config
# ------------------------------------------------------------

DEPLOY_SCRIPT="$(dirname "$0")/deploy-configs.sh"

if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
  echo "ERROR: deploy-configs.sh not found or not executable."
  exit 1
fi

echo "==> Deploying dotfiles into ~/.config"
"$DEPLOY_SCRIPT" --force
