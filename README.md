# Dotfiles

macOS configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a Stow package. Its content mirrors `$HOME`, and Stow links it into place.
The real files live in this repo, and `$HOME` has only symlinks, so edits go straight into git.

| Package | Links |
|---|---|
| `zsh` | `~/.zshrc`, `~/.aliases` |
| `git` | `~/.gitconfig`, `~/.gitconfig-torq`, `~/.gitattributes`, `~/.config/git` |
| `tmux` | `~/.config/tmux` |
| `ghostty` | `~/.config/ghostty` |
| `nvim` | `~/.config/nvimk` ([kickstart.nvim fork](https://github.com/Or-Priesender/kickstart.nvim), git submodule, used via `NVIM_APPNAME=nvimk`) |
| `sketchybar` | `~/.config/sketchybar` |
| `k9s` | `~/.config/k9s` |

`Brewfile` lists all Homebrew packages. It is not a Stow package.

## Install

```bash
git clone --recurse-submodules https://github.com/Or-Priesender/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

The script installs the Brewfile, links all packages and creates `~/.secrets` from `.secrets.template`.
Stow does not overwrite real files. If a target exists, move it away first.

## Daily use

```bash
# Add a new config (example: lazygit)
mkdir -p ~/dotfiles/lazygit/.config
mv ~/.config/lazygit ~/dotfiles/lazygit/.config/
stow -d ~/dotfiles -t ~ lazygit

# Update the Brewfile after installing or removing packages
brew bundle dump --file=~/dotfiles/Brewfile --force

# Remove the links of a package
stow -d ~/dotfiles -t ~ -D k9s
```

Neovim changes are committed in the submodule first, then the new submodule commit in this repo.

## Secrets

This repo is public. Secrets go in `~/.secrets` (git-ignored, sourced by `.zshrc`).
Torq work config is in `~/.torq.zsh` (sourced by `.zshrc` if it exists), with `~/.gcloud-aliases` and `~/.scripts`. These are not in this repo. Copy them manually to a new machine.
