#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# symlink-configs.sh
# Replaces ~/.config directories with symlinks to hyprdots
# OPTIONAL advanced mode — requires --force
# ------------------------------------------------------------

FORCE=false

# Explicit flag parsing (readable)
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
elif [[ $# -gt 0 ]]; then
  echo "Unknown argument: $1"
  echo "Usage: $0 --force"
  exit 1
fi

# Require --force
if [[ "$FORCE" != true ]]; then
  echo "ERROR: This script will replace config directories with symlinks."
  echo "This is an ADVANCED operation."
  echo
  echo "You must run it with --force to proceed."
  echo "Example:"
  echo "  ./scripts/symlink-configs.sh --force"
  exit 1
fi

DOTFILES_DIR="$(dirname "$0")/../config"
TARGET_DIR="$HOME/.config"

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

echo "==> Symlink mode enabled"
echo "==> The following directories may be replaced with symlinks:"
echo

for cfg in "${CONFIGS[@]}"; do
  echo "  - $cfg"
done

echo
read -r -p "Continue with symlink mode? [y/N] " global_reply
echo

case "$global_reply" in
  y|Y|yes|YES)
    ;;
  *)
    echo "Symlink operation aborted."
    exit 0
    ;;
esac

# Per-directory confirmation
for cfg in "${CONFIGS[@]}"; do
  SRC="$DOTFILES_DIR/$cfg"
  DEST="$TARGET_DIR/$cfg"

  if [[ ! -d "$SRC" ]]; then
    echo "Skipping $cfg (not present in repo)"
    continue
  fi

  # If already correct symlink, skip
  if [[ -L "$DEST" && "$(readlink -f "$DEST")" == "$(readlink -f "$SRC")" ]]; then
    echo "==> $cfg already correctly symlinked, skipping."
    continue
  fi

  echo
  echo "Config '$cfg':"
  echo "  Source:      $SRC"
  echo "  Destination: $DEST"
  read -r -p "Replace with symlink? [y/N] " reply

  case "$reply" in
    y|Y|yes|YES)
      echo "==> Linking $cfg"

      if [[ -e "$DEST" ]]; then
        rm -rf "$DEST"
      fi

      ln -s "$SRC" "$DEST"
      ;;
    *)
      echo "Skipping $cfg"
      ;;
  esac
done

echo
echo "==> Symlink operation complete."
