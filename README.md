# Dotfiles

Personal configuration files for macOS development environment.

## Contents

- `.zshrc` - Zsh shell configuration with oh-my-zsh
- `.aliases` - Custom shell aliases and functions
- `.gitconfig` - Git configuration and aliases
- `.gitattributes` - Git attributes configuration
- `.secrets.template` - Template for environment variables (API keys, tokens)
- `install.sh` - Installation script that creates symlinks

## Features

### Zsh Configuration
- oh-my-zsh with robbyrussell theme
- Plugins: cmdtime, git, zsh-autosuggestions
- Auto-start tmux on shell start
- Auto-create tmux sessions (default, k9s)
- Zoxide for smart directory navigation
- fzf for fuzzy finding

### Git Configuration
- User: Or-Priesender
- Useful aliases: co, br, ci, st, amend, lg
- diff-so-fancy for better diffs
- Auto-setup remote branches on push/pull

### Custom Aliases
- Git shortcuts and helpers
- Kubernetes aliases (k, ctx, k8s, k9)
- Torq-specific utilities (tq-whois, tq-dump-all-accounts, bq-fetch-workflow)
- System utilities (reload, vim -> nvim, whoseport)

## Installation

### First Time Setup

1. Clone this repository:
   ```bash
   git clone <your-repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

3. Edit `~/.secrets` with your actual API keys:
   ```bash
   vim ~/.secrets
   ```

4. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

### What the Install Script Does

- Creates symlinks from `~/` to `~/dotfiles/` for all configuration files
- Backs up existing files to `~/dotfiles_backup_TIMESTAMP/`
- Copies `.secrets.template` to `~/.secrets` (if it doesn't exist)
- Preserves your existing configuration safely

## Prerequisites

### Required
- Zsh shell
- oh-my-zsh
- Git

### Recommended
- tmux
- neovim
- fzf
- zoxide
- diff-so-fancy
- zsh-syntax-highlighting
- zsh-autosuggestions
- kubecolor (for Kubernetes aliases)

### Installation Commands
```bash
# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install with Homebrew
brew install tmux neovim fzf zoxide diff-so-fancy zsh-syntax-highlighting zsh-autosuggestions kubecolor
```

## Machine-Specific Configuration

The `.zshrc` references some machine-specific paths that may not exist on all machines:
- `~/dev/personal/gpt-shell/install.sh` (line 80)
- `/Users/orp/dev/app/local_env/app_dotfile.sh` (line 136)

You may need to comment these out or update the paths for your environment.

## Security Notes

- **NEVER** commit the actual `.secrets` file - it's in `.gitignore`
- The `.secrets.template` contains only placeholder values
- Review all API keys and tokens before committing changes
- Consider using a password manager for sensitive credentials

## Updating

After making changes to files in `~/dotfiles/`:

```bash
cd ~/dotfiles
git add .
git commit -m "Update configuration"
git push
```

Changes will be immediately reflected in your home directory via symlinks.

## Related Repositories

- Neovim configuration: [nvim repository]

## License

Personal configuration files - use at your own risk!
