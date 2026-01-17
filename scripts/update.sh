#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# update.sh
#
# Updates:
#  - Repo (git pull)
#  - Pacman packages
#  - Paru (AUR) packages
# ------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

echo "==> Starting hyprdots update"

# ------------------------------------------------------------
# Ensure we are running on Arch Linux
# ------------------------------------------------------------

if [[ ! -f /etc/arch-release ]]; then
  echo "ERROR: This script is intended for Arch Linux only."
  exit 1
fi

# ------------------------------------------------------------
# Ensure git exists
# ------------------------------------------------------------

if ! command -v git &>/dev/null; then
  echo "ERROR: git not found. Please install git first."
  exit 1
fi

# ------------------------------------------------------------
# Pull latest repo changes
# ------------------------------------------------------------

echo "==> Updating repo..."

git -C "$REPO_ROOT" pull --ff-only

echo "==> Repo updated successfully."

# ------------------------------------------------------------
# Ensure pacman exists
# ------------------------------------------------------------

if ! command -v pacman &>/dev/null; then
  echo "ERROR: pacman not found. Is this an Arch-based system?"
  exit 1
fi

# ------------------------------------------------------------
# Update pacman packages
# ------------------------------------------------------------

echo "==> Updating pacman packages..."

sudo pacman -Syu --noconfirm

echo "==> Pacman packages updated successfully."

echo

# ------------------------------------------------------------
# Update AUR packages with paru
# ------------------------------------------------------------

if ! command -v paru &>/dev/null; then
  echo "ERROR: paru not found. Please install paru before updating AUR packages."
  exit 1
fi

echo "==> Updating AUR packages with paru..."

paru -Sua --noconfirm

echo "==> AUR packages updated successfully."
