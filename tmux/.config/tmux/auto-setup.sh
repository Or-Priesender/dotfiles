#!/bin/bash

# Get the current pane's working directory
path="$1"

# Log for debugging (optional - comment out after testing)
# echo "Auto-setup checking path: $path" >> /tmp/tmux-auto-setup.log

# Check if path matches our target directories
case "$path" in
  "$HOME/dev/"*|"$HOME/.config/"*)
    # Only set up brand-new sessions (single window, single pane).
    # Prevents extra vim/pi panes from being added to already-arranged sessions.
    pane_count=$(tmux list-panes -t "$2" 2>/dev/null | wc -l | tr -d ' ')
    window_count=$(tmux list-windows -t "$2" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$pane_count" != "1" ] || [ "$window_count" != "1" ]; then
      exit 0
    fi

    sleep 0.2
    # Start with vim in the first pane
    tmux send-keys -t "$2:1.0" "vim ." Enter

    # Split vertically (below) to create terminal pane at bottom - 25% height
    tmux split-window -t "$2:1.0" -v -p 25 -c "$path"

    # Select the top pane (vim)
    tmux select-pane -t "$2:1.0"

    # Split top pane horizontally (right) for pi - 30% width
    tmux split-window -t "$2:1.0" -h -p 30 -c "$path"

    # Send pi command to the right pane (pane 1 after the split)
    sleep 0.5
    tmux send-keys -t "$2:1.1" "pi"
    sleep 0.1
    tmux send-keys -t "$2:1.1" Enter

    # Select vim pane to focus
    tmux select-pane -t "$2:1.0"
    ;;
esac
