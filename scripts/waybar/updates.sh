#!/usr/bin/env bash

# ------------------------------------------------------------
# waybar-updates.sh
# Checks for available system updates (pacman + AUR)
# Returns JSON for waybar custom module
# ------------------------------------------------------------

set -euo pipefail

# Count official repo updates
UPDATES=0
if command -v checkupdates &>/dev/null; then
    if PACMAN_UPDATES=$(checkupdates 2>/dev/null | wc -l); then
        UPDATES=$PACMAN_UPDATES
    fi
fi

# Count AUR updates if paru is installed
AUR_UPDATES=0
if command -v paru &>/dev/null; then
    if AUR_COUNT=$(paru -Qua 2>/dev/null | wc -l); then
        AUR_UPDATES=$AUR_COUNT
    fi
fi

TOTAL=$((UPDATES + AUR_UPDATES))

# Build tooltip
if [[ $TOTAL -eq 0 ]]; then
    TOOLTIP="System is up to date"
else
    TOOLTIP="Updates available:\\n"
    [[ $UPDATES -gt 0 ]] && TOOLTIP+="Pacman: $UPDATES\\n"
    [[ $AUR_UPDATES -gt 0 ]] && TOOLTIP+="AUR: $AUR_UPDATES"
fi

# Add CSS class if updates are available
if [[ $TOTAL -gt 0 ]]; then
    echo "{\"text\":\"$TOTAL\",\"tooltip\":\"$TOOLTIP\",\"class\":\"has-updates\"}"
else
    echo "{\"text\":\"$TOTAL\",\"tooltip\":\"$TOOLTIP\"}"
fi
