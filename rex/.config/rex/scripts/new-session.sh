#!/usr/bin/env bash
# Ask for a name, then open a new session with it. $1 is the Rex client ID to
# switch, $2 the session's folder.
client=$1
dir=${2:-$HOME/dev}

read -rp 'Session name: ' name || exit 0
name=$(printf '%s' "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

target=$(rex new ${name:+"$name"} -c "$dir" --json | jq -r '.session_id') || {
  read -rsn1 -p 'Could not create the session. Press any key to close.'
  exit 1
}
if ! rex ${client:+-C "$client"} do go_to_session session_id="$target"; then
  read -rsn1 -p 'Switch failed. Press any key to close.'
fi
