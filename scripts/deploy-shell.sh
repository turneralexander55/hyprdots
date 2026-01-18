#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# deploy-shell.sh
#
# Deploy shell configuration files (e.g. .zshrc)
# Copies files into $HOME with guarded overwrites
# Requires --force and per-file confirmation
# ------------------------------------------------------------

FORCE=false

# ------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
elif [[ $# -gt 0 ]]; then
  echo "ERROR: Unknown argument: $1"
  echo
  echo "Usage:"
  echo "  $0 --force"
  exit 1
fi

if [[ "$FORCE" != true ]]; then
  echo "ERROR: This script will overwrite shell config files."
  echo "You must run it with --force to proceed."
  echo
  echo "Example:"
  echo "  ./scripts/deploy-shell.sh --force"
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/../shell"
HOME_DIR="$HOME"

echo "==> deploy-shell.sh running in FORCE mode"
echo

# ------------------------------------------------------------
# Deploy .zshrc
# ------------------------------------------------------------

SRC="$DOTFILES_DIR/zshrc"
DEST="$HOME_DIR/.zshrc"

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: zshrc not found in repo at $SRC"
  exit 1
fi

if [[ -f "$DEST" ]]; then
  echo ".zshrc already exists at $DEST"
  read -r -p "Overwrite ~/.zshrc? A backup will be created. [y/N] " reply
  echo

  case "$reply" in
    y|Y|yes|YES)
      echo "Backing up existing .zshrc to ~/.zshrc.bak"
      cp "$DEST" "$DEST.bak"
      ;;
    *)
      echo "Skipping .zshrc"
      exit 0
      ;;
  esac
fi

echo "Installing .zshrc"
cp "$SRC" "$DEST"

echo "==> Shell configuration deployment complete."
