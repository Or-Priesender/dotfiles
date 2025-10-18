#!/bin/bash

# Get the current pane's working directory
path="$1"

# Log for debugging (optional - comment out after testing)
# echo "Auto-setup checking path: $path" >> /tmp/tmux-auto-setup.log

# Check if path matches our target directories
case "$path" in
  "$HOME/dev/"*|"$HOME/.config/"*)
    sleep 0.2
    tmux send-keys -t "$2:1.0" "vim ." Enter
    tmux split-window -t "$2:1.0" -v -p 35 -c "$path"
    sleep 0.5
    tmux send-keys -t "$2:1.1" "claude"
    sleep 0.1
    tmux send-keys -t "$2:1.1" Enter
    tmux split-window -t "$2:1.1" -h -p 33 -c "$path"
    tmux select-pane -t "$2:1.0"
    ;;
esac
