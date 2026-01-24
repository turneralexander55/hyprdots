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
  qt6-5compat \
  qt6-virtualkeyboard

# ------------------------------------------------------------
# Disable other display managers (best-effort)
# ------------------------------------------------------------
echo "==> Disabling other display managers (if present)"
systemctl disable gdm lightdm greetd ly 2>/dev/null || true

# ------------------------------------------------------------
# Install Hyprland session file FIRST
# ------------------------------------------------------------
echo "==> Installing Hyprland Wayland session file"

SESSION_SRC="$REAL_HOME/hyprdots/assets/SDDM/hyprland.desktop"
SESSION_DST="/usr/share/wayland-sessions/hyprland.desktop"

mkdir -p /usr/share/wayland-sessions

if [[ -f "$SESSION_SRC" ]]; then
  cp "$SESSION_SRC" "$SESSION_DST"
  chmod 644 "$SESSION_DST"
  echo "==> Hyprland session file installed"
else
  echo "WARNING: Session file not found at $SESSION_SRC"
  echo "==> Creating default Hyprland session file"

  cat >"$SESSION_DST" <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF

  chmod 644 "$SESSION_DST"
fi

# ------------------------------------------------------------
# Install custom SDDM theme: blackglass
# ------------------------------------------------------------
echo "==> Installing custom SDDM theme: blackglass"

THEME_SRC="$REAL_HOME/hyprdots/assets/SDDM/blackglass"
THEME_DST="/usr/share/sddm/themes/blackglass"
THEME_NAME="blackglass"

if [[ -d "$THEME_SRC" ]]; then
  echo "==> Found custom theme at $THEME_SRC"

  # Verify theme has required files
  if [[ ! -f "$THEME_SRC/Main.qml" ]]; then
    echo "ERROR: Theme missing Main.qml - theme is incomplete"
    echo "==> Falling back to breeze theme"
    THEME_NAME="breeze"
  elif [[ ! -f "$THEME_SRC/metadata.desktop" ]]; then
    echo "ERROR: Theme missing metadata.desktop - theme is incomplete"
    echo "==> Falling back to breeze theme"
    THEME_NAME="breeze"
  else
    # Theme looks valid, install it
    rm -rf "$THEME_DST"
    cp -r "$THEME_SRC" "$THEME_DST"

    # Set correct permissions
    chmod 755 "$THEME_DST"
    find "$THEME_DST" -type f -exec chmod 644 {} \;
    find "$THEME_DST" -type d -exec chmod 755 {} \;

    if [[ -d "$THEME_DST" ]]; then
      echo "==> Blackglass theme installed successfully"
    else
      echo "WARNING: Theme copy failed, falling back to breeze"
      THEME_NAME="breeze"
    fi
  fi
else
  echo "WARNING: Custom theme not found at $THEME_SRC"
  echo "==> Falling back to breeze theme"
  THEME_NAME="breeze"
fi

# Install breeze if needed
if [[ "$THEME_NAME" == "breeze" ]]; then
  pacman -S --needed --noconfirm sddm-breeze
fi

# ------------------------------------------------------------
# Configure SDDM
# ------------------------------------------------------------
echo "==> Configuring SDDM"

mkdir -p /etc/sddm.conf.d

# Main SDDM configuration
cat >/etc/sddm.conf.d/hyprdots.conf <<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Theme]
Current=${THEME_NAME}

[Wayland]
# SDDM will use its built-in Wayland compositor
# Leave empty to use default (most reliable)

[Users]
# Allow all users
MaximumUid=60513
MinimumUid=1000
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

  # Verify theme structure
  if [[ "$THEME_NAME" == "blackglass" ]]; then
    if [[ -f "/usr/share/sddm/themes/blackglass/Main.qml" ]]; then
      echo "  ✓ Main.qml found"
    else
      echo "  ✗ WARNING: Main.qml missing"
    fi

    if [[ -f "/usr/share/sddm/themes/blackglass/metadata.desktop" ]]; then
      echo "  ✓ metadata.desktop found"
    else
      echo "  ✗ WARNING: metadata.desktop missing"
    fi
  fi
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
echo "  Config: /etc/sddm.conf.d/hyprdots.conf"
echo
echo "To test SDDM without rebooting:"
echo "  sudo systemctl start sddm"
echo
echo "To view SDDM logs if issues occur:"
echo "  journalctl -u sddm -b"
echo
