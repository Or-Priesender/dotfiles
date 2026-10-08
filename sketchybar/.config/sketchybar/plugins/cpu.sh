#!/usr/bin/env bash

# Get CPU usage percentage
CPU_USAGE=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')

# If CPU_USAGE is empty or not a number, default to 0
if ! [[ "$CPU_USAGE" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    CPU_USAGE="0"
fi

# Round to integer
CPU_USAGE=$(printf "%.0f" "$CPU_USAGE")

sketchybar --set $NAME label="${CPU_USAGE}%" 