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

echo "==> Stage 2: Initializing user environment"
echo

"$SCRIPT_DIR/init-user.sh"

echo
echo "==> Initialization complete"
echo

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

# ------------------------------------------------------------
# Stage 5:  NVIDIA Drivers
# ------------------------------------------------------------

echo
read -r -p "Do you want to install NVIDIA drivers? [y/N] " install_nvidia
echo

case "$install_nvidia" in
  y|Y|yes|YES)
    echo "==> NVIDIA install selected"

    NVIDIA_SCRIPT="./scripts/nvidia.sh"

    if [[ ! -f "$NVIDIA_SCRIPT" ]]; then
      echo "ERROR: NVIDIA install script not found at:"
      echo "  $NVIDIA_SCRIPT"
      exit 1
    fi

    chmod +x "$NVIDIA_SCRIPT"

    if [[ $EUID -ne 0 ]]; then
      sudo "$NVIDIA_SCRIPT"
    else
      "$NVIDIA_SCRIPT"
    fi
    ;;
  *)
    echo "==> Skipping NVIDIA driver installation"
    ;;
esac

echo "======================================"
echo " Hyprdots installation complete"
echo
echo " System will reboot in 5 seconds"
echo " Press Ctrl+C to cancel"
echo "======================================"
echo

sleep 5

if [[ $EUID -ne 0 ]]; then
  sudo reboot
else
  reboot
fi
