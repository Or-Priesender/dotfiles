#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(zsh git tmux ghostty nvim sketchybar k9s)

command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh"; exit 1; }

brew bundle install --file="$DOTFILES_DIR/Brewfile"
git -C "$DOTFILES_DIR" submodule update --init --recursive

mkdir -p "$HOME/.config"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "${PACKAGES[@]}"

if [ ! -f "$HOME/.secrets" ]; then
    cp "$DOTFILES_DIR/.secrets.template" "$HOME/.secrets"
    chmod 600 "$HOME/.secrets"
    echo "Created ~/.secrets from template. Add your real values."
fi

echo "Done. Run 'exec zsh' to reload the shell."
