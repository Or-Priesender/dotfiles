#!/bin/bash
win="$1"

descendants() {
  for c in $(pgrep -P "$1"); do
    descendants "$c"
    echo "$c"
  done
}

pids=""
for p in $(tmux list-panes -t "$win" -F '#{pane_pid}'); do
  pids="$pids $(descendants "$p") $p"
done

kill -TERM $pids 2>/dev/null
sleep 1
kill -KILL $pids 2>/dev/null
tmux kill-window -t "$win"
