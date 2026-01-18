#!/usr/bin/env bash
set -e

# ------------------------------------------------------------
# Self-escalate via sudo (prompt only when needed)
# ------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "==> Elevation required for SDDM installation"
  exec sudo "$0" "$@"
fi

echo "======================================"
echo " Installing SDDM (Session Manager)"
echo "======================================"

# ------------------------------------------------------------
# Sanity check
# ------------------------------------------------------------
if ! command -v pacman >/dev/null; then
  echo "ERROR: This script is intended for Arch Linux"
  exit 1
fi

# ------------------------------------------------------------
# Install packages
# ------------------------------------------------------------
echo "==> Installing SDDM and Wayland support"
pacman -S --needed --noconfirm \
  sddm \
  qt6-wayland

# ------------------------------------------------------------
# Disable other display managers (best-effort)
# ------------------------------------------------------------
echo "==> Disabling other display managers (if present)"
systemctl disable gdm lightdm greetd ly 2>/dev/null || true

# ------------------------------------------------------------
# Enable SDDM
# ------------------------------------------------------------
echo "==> Enabling SDDM"
systemctl enable sddm

# ------------------------------------------------------------
# Install custom SDDM theme: blackglass
# ------------------------------------------------------------

echo "==> Installing custom SDDM theme: blackglass"

REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

THEME_SRC="$REAL_HOME/hyprdots/assets/SDDM/blackglass"
THEME_DST="/usr/share/sddm/themes/blackglass"

if [[ ! -d "$THEME_SRC" ]]; then
  echo "ERROR: SDDM theme source not found:"
  echo "  $THEME_SRC"
  exit 1
fi

rm -rf "$THEME_DST"
cp -r "$THEME_SRC" "$THEME_DST"

echo "==> Blackglass theme installed to:"
echo "  $THEME_DST"

# ------------------------------------------------------------
# Install and set default theme
# ------------------------------------------------------------
THEME_NAME="blackglass"
THEME_DIR="/usr/share/sddm/themes/${THEME_NAME}"

echo "==> Ensuring default SDDM theme: ${THEME_NAME}"

if [[ ! -d "$THEME_DIR" ]]; then
  echo "==> Theme not found locally, installing package"
  pacman -S --needed --noconfirm sddm-theme-breeze
fi

mkdir -p /etc/sddm.conf.d

cat >/etc/sddm.conf.d/theme.conf <<EOF
[Theme]
Current=${THEME_NAME}
EOF

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
echo
echo "======================================"
echo " SDDM installation complete"
echo " Theme set to '${THEME_NAME}'"
echo " Reboot required to activate SDDM"
echo "======================================"
