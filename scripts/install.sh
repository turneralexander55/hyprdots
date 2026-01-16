#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Hyprdots installer orchestrator
# ------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo " Hyprdots Installer"
echo "============================================================"
echo

# ------------------------------------------------------------
# Stage 1: Install packages (pacman + AUR)
# ------------------------------------------------------------

echo "==> Stage 1: Installing packages"
echo

"$SCRIPT_DIR/install-packages.sh"

echo
echo "==> Package installation complete"
echo

# ------------------------------------------------------------
# Stage 2: First-time user initialization
# ------------------------------------------------------------

echo "==> Stage 3: Initializing user environment"
echo

"$SCRIPT_DIR/init-user.sh"

# ------------------------------------------------------------
# Stage 3: Deploy configuration files
# ------------------------------------------------------------

echo "==> Stage 3: Deploying configuration files"
echo

"$SCRIPT_DIR/deploy-configs.sh" --force

echo
echo "==> Configuration deployment complete"
echo

# ------------------------------------------------------------
# Stage 4: Deploy shell configuration
# ------------------------------------------------------------

echo "==> Stage 4: Deploying shell configuration"
echo

"$SCRIPT_DIR/deploy-shell.sh" --force

echo
echo "==> Shell configuration complete"
echo

echo "============================================================"
echo " Hyprdots installation complete"
echo
echo " Rebooting."
echo "============================================================"

reboot
