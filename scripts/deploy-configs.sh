#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# deploy-configs.sh
# Copies dotfiles into ~/.config with guarded overwrites
# Requires --force and prompts per directory
# ------------------------------------------------------------

FORCE=false

# Parse arguments (explicit and readable)
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
elif [[ $# -gt 0 ]]; then
  echo "Unknown argument: $1"
  echo "Usage: $0 --force"
  exit 1
fi

# Require --force
if [[ "$FORCE" != true ]]; then
  echo "ERROR: This script will overwrite files in ~/.config."
  echo "You must run it with --force to proceed."
  echo
  echo "Example:"
  echo "  ./scripts/deploy-configs.sh --force"
  exit 1
fi

echo "==> deploy-configs.sh running in FORCE mode"
echo "==> You will be prompted before each directory is overwritten"

# ------------------------------------------------------------
# Pass 2: Per-directory confirmation
# ------------------------------------------------------------

DOTFILES_DIR="$(dirname "$0")/../config"
TARGET_DIR="$HOME/.config"

# Ensure ~/.config exists (fresh installs may not have it)
mkdir -p "$TARGET_DIR"

# Explicit list of config directories we manage
CONFIGS=(
  hypr
  waybar
  rofi
  kitty
  fastfetch
  btop
  cava
  swaync
  zed
)

# Track which configs the user approved
APPROVED_CONFIGS=()

echo
echo "==> The following configuration directories may be overwritten:"
echo

for cfg in "${CONFIGS[@]}"; do
  SRC="$DOTFILES_DIR/$cfg"
  DEST="$TARGET_DIR/$cfg"

  # Skip if source does not exist in repo
  if [[ ! -d "$SRC" ]]; then
    echo "Skipping $cfg (not present in repo)"
    continue
  fi

  # If destination exists, ask before overwriting
  if [[ -e "$DEST" ]]; then
    echo "Config '$cfg' exists at $DEST"
    read -r -p "Overwrite this directory? [y/N] " reply
    echo

    case "$reply" in
      y|Y|yes|YES)
        APPROVED_CONFIGS+=("$cfg")
        ;;
      *)
        echo "Skipping $cfg"
        ;;
    esac
  else
    # Destination does not exist — safe to deploy automatically
    APPROVED_CONFIGS+=("$cfg")
  fi
done

# Nothing approved? Abort safely.
if [[ "${#APPROVED_CONFIGS[@]}" -eq 0 ]]; then
  echo "No configuration directories approved for deployment."
  echo "Nothing to do."
  exit 0
fi

echo "==> Approved configuration directories:"
for cfg in "${APPROVED_CONFIGS[@]}"; do
  echo "  - $cfg"
done
echo

# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Hyprpaper config (special-case location)
# ------------------------------------------------------------

HYPERPAPER_EXAMPLE="$TARGET_DIR/hypr/config/hyprpaper.conf.example"
HYPERPAPER_TARGET="$TARGET_DIR/hypr/hyprpaper.conf"

if [[ -f "$HYPERPAPER_EXAMPLE" && ! -f "$HYPERPAPER_TARGET" ]]; then
  echo "Installing hyprpaper.conf from template"
  cp "$HYPERPAPER_EXAMPLE" "$HYPERPAPER_TARGET"
fi

# ------------------------------------------------------------
# Stage 4: GTK theme activation
# ------------------------------------------------------------

echo "==> Applying GTK theme settings"

# Ensure gsettings is available
if ! command -v gsettings &>/dev/null; then
  echo "ERROR: gsettings not found. GTK theming cannot be applied."
  exit 1
fi

# GTK theme
gsettings set org.gnome.desktop.interface gtk-theme "Nordic-Darker"

# Icon theme
gsettings set org.gnome.desktop.interface icon-theme "Snow"

# Prefer dark color scheme
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

echo "==> GTK theme settings applied"
