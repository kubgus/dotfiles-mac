#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_file() {
    local src="$1"
    local dest="$2"

    # If dest exists and is not the correct symlink, back it up
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up $dest -> $dest.backup"
        mv "$dest" "$dest.backup"
    fi

    # If symlink exists but points elsewhere, replace it
    if [ -L "$dest" ]; then
        current="$(readlink "$dest")"
        if [ "$current" != "$src" ]; then
            echo "Updating symlink $dest -> $src"
            rm "$dest"
            ln -s "$src" "$dest"
        fi
    else
        echo "Creating symlink $dest -> $src"
        ln -s "$src" "$dest"
    fi
}

link_file "$DOTFILES_DIR/config" "$HOME/.config"
link_file "$DOTFILES_DIR/zprofile" "$HOME/.zprofile"
