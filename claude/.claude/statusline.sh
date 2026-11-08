#!/bin/bash
IFS=$'\t' read -r model pct dir < <(jq -r '[.model.display_name, (.context_window.used_percentage // 0 | floor), .workspace.current_dir] | @tsv')
dim='\033[2m'; yellow='\033[33m'; red='\033[31m'; reset='\033[0m'

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
[ -n "$branch" ] && [ -n "$(git -C "$dir" status --porcelain -uno 2>/dev/null | head -1)" ] && branch+="*"

if [ "$pct" -ge 90 ]; then c=$red; elif [ "$pct" -ge 70 ]; then c=$yellow; else c=$dim; fi

printf "%s${dim}%s${reset}${c}%s%%${reset}\n" "${branch:+$branch · }" "$model · " "$pct"
