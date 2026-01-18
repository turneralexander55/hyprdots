#!/usr/bin/env bash

# ------------------------------------------------------------
# cpu.sh
# Detailed CPU monitoring with per-core stats and temps
# ------------------------------------------------------------

# Get overall CPU usage (simpler method)
CPU_USAGE=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}')

# Fallback if above fails
if [[ -z "$CPU_USAGE" ]] || [[ "$CPU_USAGE" == "0" ]]; then
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.0f", 100 - $1}')
fi

# Get CPU model name
CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)

# Get CPU frequency
CPU_FREQ=$(lscpu | grep "CPU MHz" | head -n1 | awk '{print $3}')
if [[ -n "$CPU_FREQ" ]]; then
    CPU_FREQ_GHZ=$(awk "BEGIN {printf \"%.2f\", $CPU_FREQ/1000}")
else
    CPU_FREQ_GHZ="N/A"
fi

# Build tooltip with CPU info
TOOLTIP="$CPU_MODEL\\n"
TOOLTIP+="━━━━━━━━━━━━━━━━━━━━\\n"
TOOLTIP+="Overall: ${CPU_USAGE}% @ ${CPU_FREQ_GHZ} GHz\\n"

# Get per-core usage using mpstat if available
if command -v mpstat &>/dev/null; then
    TOOLTIP+="\\nPer-Core Usage:\\n"

    # Get per-CPU stats
    CORE_STATS=$(mpstat -P ALL 1 1 2>/dev/null | grep -E "^[0-9]|Average.*[0-9]" | grep -v "Average.*all" | awk '{if (NF > 3) printf "  Core %s: %.0f%%\\n", $2, 100-$NF}')

    if [[ -n "$CORE_STATS" ]]; then
        TOOLTIP+="$CORE_STATS"
    else
        TOOLTIP+="  Unable to get core stats\\n"
    fi
else
    TOOLTIP+="\\nInstall sysstat for per-core stats\\n"
fi

# Get CPU temperatures using sensors if available
if command -v sensors &>/dev/null; then
    TOOLTIP+="\\nTemperatures:\\n"

    # Get all sensor output
    SENSOR_OUTPUT=$(sensors 2>/dev/null)

    # Try to get CPU package temp
    PACKAGE_TEMP=$(echo "$SENSOR_OUTPUT" | grep -i "Package id 0" | awk '{print $4}' | tr -d '+°C')
    if [[ -n "$PACKAGE_TEMP" ]]; then
        TOOLTIP+="  Package: ${PACKAGE_TEMP}°C\\n"
    fi

    # Get core temps
    CORE_TEMPS=$(echo "$SENSOR_OUTPUT" | grep -i "Core [0-9]" | awk '{printf "  %s %s %s\\n", $1, $2, $3}')
    if [[ -n "$CORE_TEMPS" ]]; then
        TOOLTIP+="$CORE_TEMPS"
    fi

    # If no temps found, try alternative format
    if [[ -z "$PACKAGE_TEMP" ]] && [[ -z "$CORE_TEMPS" ]]; then
        CPU_TEMP=$(echo "$SENSOR_OUTPUT" | grep -i "CPU" | head -n1 | awk '{print $2}' | tr -d '+°C')
        if [[ -n "$CPU_TEMP" ]]; then
            TOOLTIP+="  CPU: ${CPU_TEMP}°C\\n"
        else
            TOOLTIP+="  No sensors detected\\n"
        fi
    fi
else
    TOOLTIP+="\\nInstall lm_sensors for temps"
fi

# Output JSON
echo "{\"text\":\"${CPU_USAGE}%\",\"tooltip\":\"$TOOLTIP\"}"
