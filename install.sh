#!/bin/bash
# New Mac: bash -c "$(curl -fsSL https://raw.githubusercontent.com/Or-Priesender/dotfiles/main/install.sh)"
# Safe to run again on an existing machine.
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
REPO_URL="https://github.com/Or-Priesender/dotfiles.git"
PACKAGES=(zsh git tmux ghostty nvim sketchybar k9s)
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

if [ ! -x /opt/homebrew/bin/brew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    git clone --recurse-submodules "$REPO_URL" "$DOTFILES_DIR"
fi
git -C "$DOTFILES_DIR" submodule update --init --recursive

# Some casks or App Store apps can fail; do not stop the rest of the setup.
brew bundle install --file="$DOTFILES_DIR/Brewfile" || echo "WARNING: some Brewfile entries failed, check the output above."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in tom-auger/cmdtime zsh-users/zsh-autosuggestions; do
    [ -d "$ZSH_CUSTOM/plugins/${plugin#*/}" ] || git clone --depth 1 "https://github.com/$plugin" "$ZSH_CUSTOM/plugins/${plugin#*/}"
done

# Stow does not overwrite real files, so move them out of the way first.
mkdir -p "$HOME/.config"
for pkg in "${PACKAGES[@]}"; do
    for src in "$DOTFILES_DIR/$pkg"/.[!.]* "$DOTFILES_DIR/$pkg"/.config/*; do
        [ -e "$src" ] || continue
        [ "$(basename "$src")" = ".config" ] && continue
        target="$HOME/${src#"$DOTFILES_DIR/$pkg/"}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
            echo "Moved existing $target to $BACKUP_DIR"
        fi
    done
done
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "${PACKAGES[@]}"

if [ ! -f "$HOME/.secrets" ]; then
    cp "$DOTFILES_DIR/.secrets.template" "$HOME/.secrets"
    chmod 600 "$HOME/.secrets"
    echo "Created ~/.secrets from template. Add your real values."
fi

echo
echo "Done. Next steps:"
echo "  1. Fill in ~/.secrets"
echo "  2. Copy the Torq files from the old Mac: ~/.torq.zsh ~/.gcloud-aliases ~/.scripts/"
echo "  3. Run 'exec zsh'"
