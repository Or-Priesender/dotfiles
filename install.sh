#!/bin/bash

# Dotfiles installation script
# This script creates symlinks from home directory to dotfiles directory

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing dotfiles...${NC}"

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Files to symlink
files=(".zshrc" ".aliases" ".gitconfig" ".gitattributes")

# Create symlinks
for file in "${files[@]}"; do
    source_file="$DOTFILES_DIR/$file"
    target_file="$HOME/$file"

    if [ -f "$source_file" ] || [ -d "$source_file" ]; then
        # Backup existing file if it exists and is not already a symlink
        if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
            echo -e "${YELLOW}Backing up existing $file${NC}"
            mv "$target_file" "$BACKUP_DIR/"
        elif [ -L "$target_file" ]; then
            echo -e "${YELLOW}Removing existing symlink $file${NC}"
            rm "$target_file"
        fi

        # Create symlink
        echo -e "${GREEN}Creating symlink for $file${NC}"
        ln -s "$source_file" "$target_file"
    else
        echo -e "${RED}Warning: $source_file not found, skipping${NC}"
    fi
done

# Handle .config directories
echo -e "${GREEN}Setting up .config directories...${NC}"
mkdir -p "$HOME/.config"

config_dirs=("aerospace" "k9s" "lazygit" "tmux" "sketchybar" "tms" "iterm2" "gh-dash" "nvim")

for config_dir in "${config_dirs[@]}"; do
    source_dir="$DOTFILES_DIR/config/$config_dir"
    target_dir="$HOME/.config/$config_dir"

    if [ -d "$source_dir" ] || [ -L "$source_dir" ]; then
        # Backup existing directory if it exists and is not already a symlink
        if [ -e "$target_dir" ] && [ ! -L "$target_dir" ]; then
            echo -e "${YELLOW}Backing up existing .config/$config_dir${NC}"
            mv "$target_dir" "$BACKUP_DIR/"
        elif [ -L "$target_dir" ]; then
            echo -e "${YELLOW}Removing existing symlink .config/$config_dir${NC}"
            rm "$target_dir"
        fi

        # Create symlink
        echo -e "${GREEN}Creating symlink for .config/$config_dir${NC}"
        ln -s "$source_dir" "$target_dir"
    else
        echo -e "${RED}Warning: $source_dir not found, skipping${NC}"
    fi
done

# Handle .secrets separately (copy template, don't symlink)
if [ ! -f "$HOME/.secrets" ]; then
    echo -e "${YELLOW}Creating .secrets from template...${NC}"
    cp "$DOTFILES_DIR/.secrets.template" "$HOME/.secrets"
    echo -e "${RED}IMPORTANT: Edit ~/.secrets and add your actual API keys!${NC}"
else
    echo -e "${GREEN}.secrets already exists, skipping${NC}"
fi

# Remove backup directory if empty
if [ -z "$(ls -A $BACKUP_DIR)" ]; then
    rmdir "$BACKUP_DIR"
    echo -e "${GREEN}No backups needed${NC}"
else
    echo -e "${YELLOW}Backups saved to: $BACKUP_DIR${NC}"
fi

# Initialize git submodules (for nvim config)
if [ -f "$DOTFILES_DIR/.gitmodules" ]; then
    echo -e "${GREEN}Initializing git submodules...${NC}"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
fi

echo -e "${GREEN}Dotfiles installation complete!${NC}"
echo -e "${YELLOW}Run 'source ~/.zshrc' to reload your shell configuration${NC}"
