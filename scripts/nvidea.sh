#!/usr/bin/env bash
set -e

echo "======================================"
echo " NVIDIA Driver Install (Arch) "
echo "======================================"

# -------------------------------
# Safety checks
# -------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run this script as root (use sudo)"
  exit 1
fi

if ! command -v pacman >/dev/null; then
  echo "ERROR: This script is for Arch Linux only"
  exit 1
fi

# -------------------------------
# Detect kernel
# -------------------------------
KERNEL="$(uname -r)"

echo "Detected kernel: $KERNEL"

INSTALL_PKGS=(
  nvidia
  nvidia-utils
  nvidia-settings
  linux-headers
)

if [[ "$KERNEL" == *"lts"* ]]; then
  INSTALL_PKGS+=(
    nvidia-lts
    linux-lts-headers
  )
fi

# -------------------------------
# System update
# -------------------------------
echo "==> Updating system"
pacman -Syu --noconfirm

# -------------------------------
# Install NVIDIA drivers
# -------------------------------
echo "==> Installing NVIDIA packages"
pacman -S --needed --noconfirm "${INSTALL_PKGS[@]}"

# -------------------------------
# Blacklist nouveau
# -------------------------------
echo "==> Blacklisting nouveau"
cat >/etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

# -------------------------------
# NVIDIA DRM (Wayland support)
# -------------------------------
echo "==> Enabling NVIDIA DRM modeset"
cat >/etc/modprobe.d/nvidia.conf <<EOF
options nvidia-drm modeset=1
EOF

# -------------------------------
# Update GRUB (if present)
# -------------------------------
if [[ -f /etc/default/grub ]]; then
  echo "==> Updating GRUB kernel parameters"

  if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
  fi

  grub-mkconfig -o /boot/grub/grub.cfg
else
  echo "==> GRUB not detected, skipping bootloader config"
fi

# -------------------------------
# Regenerate initramfs
# -------------------------------
echo "==> Regenerating initramfs"
mkinitcpio -P

# -------------------------------
# Vulkan + 32-bit support (gaming)
# -------------------------------
echo "==> Installing Vulkan + 32-bit NVIDIA support"
pacman -S --needed --noconfirm \
  vulkan-icd-loader \
  lib32-nvidia-utils \
  lib32-vulkan-icd-loader

# -------------------------------
# Hyprland environment variables
# -------------------------------
echo "==> Writing Hyprland NVIDIA environment variables"

REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

HYPR_ENV_DIR="$REAL_HOME/.config/hypr/config"
HYPR_ENV_FILE="$HYPR_ENV_DIR/environment.conf"

mkdir -p "$HYPR_ENV_DIR"
touch "$HYPR_ENV_FILE"
chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.config/hypr"

add_env() {
  local line="$1"
  grep -qxF "$line" "$HYPR_ENV_FILE" || echo "$line" >> "$HYPR_ENV_FILE"
}

add_env "env = LIBVA_DRIVER_NAME,nvidia"
add_env "env = GBM_BACKEND,nvidia-drm"
add_env "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
add_env "env = XDG_SESSION_TYPE,wayland"

echo "==> Hyprland environment variables written to:"
echo "    $HYPR_ENV_FILE"

# -------------------------------
# Done
# -------------------------------
echo
echo "======================================"
echo " NVIDIA install complete"
echo " REBOOT REQUIRED"
echo "======================================"
