#!/usr/bin/env bash
set -euo pipefail

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
# Determine real user and paths
# ------------------------------------------------------------
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

echo "==> Configuring for user: $REAL_USER"

# ------------------------------------------------------------
# Install packages
# ------------------------------------------------------------
echo "==> Installing SDDM and dependencies"
pacman -S --needed --noconfirm \
  sddm \
  qt6-wayland \
  qt6-svg \
  qt6-declarative \
  qt6-5compat

# ------------------------------------------------------------
# Disable other display managers (best-effort)
# ------------------------------------------------------------
echo "==> Disabling other display managers (if present)"
systemctl disable gdm lightdm greetd ly 2>/dev/null || true

# ------------------------------------------------------------
# Install custom SDDM theme: blackglass
# ------------------------------------------------------------
echo "==> Installing custom SDDM theme: blackglass"

THEME_SRC="$REAL_HOME/hyprdots/assets/SDDM/blackglass"
THEME_DST="/usr/share/sddm/themes/blackglass"
THEME_NAME="blackglass"

if [[ -d "$THEME_SRC" ]]; then
  echo "==> Found custom theme at $THEME_SRC"

  rm -rf "$THEME_DST"
  cp -r "$THEME_SRC" "$THEME_DST"

  if [[ -d "$THEME_DST" ]]; then
    echo "==> Blackglass theme installed successfully"
  else
    echo "WARNING: Theme copy failed, falling back to breeze"
    THEME_NAME="breeze"
    pacman -S --needed --noconfirm qt6-svg
  fi
else
  echo "WARNING: Custom theme not found at $THEME_SRC"
  echo "==> Falling back to breeze theme"
  THEME_NAME="breeze"
  pacman -S --needed --noconfirm qt6-svg
fi

# ------------------------------------------------------------
# Configure SDDM theme
# ------------------------------------------------------------
echo "==> Setting SDDM theme to: ${THEME_NAME}"

mkdir -p /etc/sddm.conf.d

cat >/etc/sddm.conf.d/theme.conf <<EOF
[Theme]
Current=${THEME_NAME}
EOF

# ------------------------------------------------------------
# Install Hyprland session file
# ------------------------------------------------------------
echo "==> Installing Hyprland Wayland session file"

SESSION_SRC="$REAL_HOME/hyprdots/assets/SDDM/hyprland.desktop"
SESSION_DST="/usr/share/wayland-sessions/hyprland.desktop"

mkdir -p /usr/share/wayland-sessions

if [[ -f "$SESSION_SRC" ]]; then
  cp "$SESSION_SRC" "$SESSION_DST"
  echo "==> Hyprland session file installed"
else
  echo "ERROR: Session file not found at $SESSION_SRC"
  exit 1
fi

# ------------------------------------------------------------
# Configure SDDM for Wayland
# ------------------------------------------------------------
echo "==> Configuring SDDM for Wayland sessions"

cat >/etc/sddm.conf.d/wayland.conf <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1
EOF

# ------------------------------------------------------------
# Enable SDDM
# ------------------------------------------------------------
echo "==> Enabling SDDM service"
systemctl enable sddm

# ------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------
echo
echo "==> Verifying installation..."

# Check if sddm service exists
if systemctl list-unit-files sddm.service &>/dev/null; then
  echo "✓ SDDM service installed"
else
  echo "✗ SDDM service not found"
  exit 1
fi

# Check if Hyprland is installed
if command -v Hyprland >/dev/null; then
  echo "✓ Hyprland installed"
else
  echo "✗ WARNING: Hyprland not found - install it first!"
fi

# Check theme
if [[ -d "/usr/share/sddm/themes/${THEME_NAME}" ]]; then
  echo "✓ Theme '${THEME_NAME}' installed"
else
  echo "✗ WARNING: Theme '${THEME_NAME}' not found"
fi

# Check session file
if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  echo "✓ Hyprland session file created"
else
  echo "✗ ERROR: Hyprland session file missing"
fi

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
echo
echo "======================================"
echo " SDDM installation complete"
echo "======================================"
echo
echo "Configuration summary:"
echo "  Theme: ${THEME_NAME}"
echo "  Display server: Wayland"
echo "  Session: Hyprland"
echo

# Check if we should start SDDM now or reboot
if systemctl is-active --quiet graphical.target; then
  echo "==> System is in graphical mode"
  echo
  read -r -p "Start SDDM now? This will end your current session. [y/N] " reply
  echo

  case "$reply" in
    y|Y|yes|YES)
      echo "==> Starting SDDM..."
      systemctl start sddm
      ;;
    *)
      echo "SDDM not started. Start it manually with:"
      echo "  sudo systemctl start sddm"
      echo "or reboot your system."
      ;;
  esac
else
  echo "==> Starting SDDM service..."
  systemctl start sddm
fi

echo
echo "If black screen occurs, press Ctrl+Alt+F2"
echo "to access TTY and check logs:"
echo "  sudo journalctl -u sddm -n 50"
echo
echo "======================================"
