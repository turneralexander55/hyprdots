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
# Stage 2: Deploy configuration files
# ------------------------------------------------------------

echo "==> Stage 2: Deploying configuration files"
echo

"$SCRIPT_DIR/deploy-configs.sh" --force

echo
echo "==> Configuration deployment complete"
echo

# ------------------------------------------------------------
# Stage 3: Deploy shell configuration
# ------------------------------------------------------------

echo "==> Stage 3: Deploying shell configuration"
echo

"$SCRIPT_DIR/deploy-shell.sh" --force

echo
echo "==> Shell configuration complete"
echo

# ------------------------------------------------------------
# Stage 4: First-time user initialization
# ------------------------------------------------------------

echo "==> Stage 4: Initializing user environment"
echo

"$SCRIPT_DIR/init-user.sh"

echo
echo "============================================================"
echo " Hyprdots installation complete"
echo
echo " Rebooting."
echo "============================================================"

reboot
