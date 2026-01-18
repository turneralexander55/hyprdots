#!/usr/bin/env bash

# ------------------------------------------------------------
# waybar-memory.sh
# Detailed memory monitoring with breakdown
# ------------------------------------------------------------

set -euo pipefail

# Get memory info from /proc/meminfo
MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
MEM_FREE=$(awk '/MemFree/ {print $2}' /proc/meminfo)
MEM_BUFFERS=$(awk '/^Buffers/ {print $2}' /proc/meminfo)
MEM_CACHED=$(awk '/^Cached/ {print $2}' /proc/meminfo)
SWAP_TOTAL=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
SWAP_FREE=$(awk '/SwapFree/ {print $2}' /proc/meminfo)

# Calculate used memory
MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))

# Convert to GB
MEM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_TOTAL/1024/1024}")
MEM_USED_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/1024/1024}")
MEM_AVAILABLE_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_AVAILABLE/1024/1024}")
MEM_FREE_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_FREE/1024/1024}")
MEM_BUFFERS_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_BUFFERS/1024/1024}")
MEM_CACHED_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_CACHED/1024/1024}")

# Calculate percentage
MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED/$MEM_TOTAL)*100}")

# Build tooltip
TOOLTIP="Memory Usage\\n"
TOOLTIP+="━━━━━━━━━━━━━━━━━━━━\\n"
TOOLTIP+="Used: ${MEM_USED_GB}G / ${MEM_TOTAL_GB}G (${MEM_PERCENT}%)\\n"
TOOLTIP+="Available: ${MEM_AVAILABLE_GB}G\\n"
TOOLTIP+="Free: ${MEM_FREE_GB}G\\n"
TOOLTIP+="Buffers: ${MEM_BUFFERS_GB}G\\n"
TOOLTIP+="Cached: ${MEM_CACHED_GB}G\\n"

# Add swap info if swap exists
if [[ $SWAP_TOTAL -gt 0 ]]; then
    SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
    SWAP_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_TOTAL/1024/1024}")
    SWAP_USED_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED/1024/1024}")
    SWAP_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($SWAP_USED/$SWAP_TOTAL)*100}")

    TOOLTIP+="\\nSwap Usage\\n"
    TOOLTIP+="━━━━━━━━━━━━━━━━━━━━\\n"
    TOOLTIP+="Used: ${SWAP_USED_GB}G / ${SWAP_TOTAL_GB}G (${SWAP_PERCENT}%)"
fi

# Get top memory-consuming processes
TOOLTIP+="\\n\\nTop Processes\\n"
TOOLTIP+="━━━━━━━━━━━━━━━━━━━━\\n"

TOP_PROCS=$(ps aux --sort=-%mem | awk 'NR>1 {printf "%s: %.1fG\\n", $11, $6/1024/1024}' | head -n 5)
TOOLTIP+="$TOP_PROCS"

echo "{\"text\":\"${MEM_USED_GB}G\",\"tooltip\":\"$TOOLTIP\"}"
