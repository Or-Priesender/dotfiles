#!/usr/bin/env bash
# Rex port of tmux-agent-status pick.sh: jump to an open session, or open a
# ~/dev repo as a new session. $1 is the Rex client ID to switch.
# $2 = "sessions" lists open sessions only (no repos).
self=$(realpath "$0")
repos_dir=${REX_REPOS_DIR:-$HOME/dev}

if [ "$1" = preview ]; then
  if [ "$2" = s ]; then
    rex capture -s "$3" --trim 2>/dev/null | tail -n 80
  else
    git -C "$3" log --oneline --color=always -20 2>/dev/null || ls "$3"
  fi
  exit 0
fi

# Strongest program status (OSC 7501) in a session: blocked > error > working > done.
session_status() {
  local b
  for b in $(rex block ls -s "$1" --json | jq -r '.blocks[] | select(.creator_name == "com.superlogical.terminal") | .block_id'); do
    rex block call -s "$1" -b "$b" program_status 2>/dev/null | jq -r '.records[].state'
  done | awk '
    BEGIN { p["blocked"] = 4; p["error"] = 3; p["working"] = 2; p["done"] = 1 }
    p[$1] > best { best = p[$1]; s = $1 }
    END { print s }'
}

icon() {
  case $1 in
    blocked) printf '\e[33m ●\e[0m' ;;
    error)   printf '\e[31m ✗\e[0m' ;;
    working) printf '\e[32m ◐\e[0m' ;;
    done)    printf '\e[38;5;67m ✓\e[0m' ;;
  esac
}

client=$1
mode=$2
T=$'\t'
open=$(rex ls --json | jq -r --arg cur "$REX_SESSION" \
  '.sessions[] | "\(.session_id)\t\(.label)\t\(if .session_id == $cur then "▌" else " " end)"' |
  while IFS="$T" read -r id label mark; do
    printf 's\t%s\t%s\t%s %s%s\n' "$id" "$label" "$mark" "$label" "$(icon "$(session_status "$id")")"
  done)
names=$(cut -f3 <<<"$open")

repos=
if [ "$mode" != sessions ]; then
  repos=$(for g in "$repos_dir"/*/.git; do
    d=${g%/.git}
    grep -qxF "${d##*/}" <<<"$names" || printf 'r\t%s\t%s\t\e[90m  + %s\e[0m\n' "$d" "${d##*/}" "${d##*/}"
  done)
fi

sel=$(printf '%s\n%s\n' "$open" "$repos" | grep -v '^$' |
  fzf --ansi --delimiter="$T" --with-nth=4 --prompt='open> ' --no-sort \
      --preview="$self preview {1} {2}" --preview-window=right,60%) || exit 0

IFS="$T" read -r kind target name _ <<<"$sel"
if [ "$kind" = r ]; then
  target=$(rex new "$name" -c "$target" --json | jq -r '.session_id') || exit 1
fi
if ! rex ${client:+-C "$client"} do go_to_session session_id="$target"; then
  read -rsn1 -p 'Switch failed. Press any key to close.'
fi
