#!/usr/bin/env bash

# Source Gruvbox colors
source "$CONFIG_DIR/tokens/gruvbox_colors.sh"

# Get the currently focused workspace from AeroSpace
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

# Get all workspaces and update each one
ALL_WORKSPACES=$(aerospace list-workspaces --all)

# Update all workspace indicators
for workspace in $ALL_WORKSPACES; do
  if [ "$workspace" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set space.$workspace background.drawing=on label.color=$GRUVBOX_BG0_HARD
  else
    sketchybar --set space.$workspace background.drawing=off label.color=$GRUVBOX_FG1
  fi
done