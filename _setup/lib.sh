#!/bin/bash
# The one helper every domain needs. Sourced, not run.
#
# Anything used by a single domain belongs in that domain's script instead -
# this file is for what is genuinely shared, not for helpers in general.
#
# link_file is idempotent and quiet: a second run prints nothing and changes
# nothing, so any output means something actually happened.

# Read by the domain scripts that source this, not used here.
# shellcheck disable=SC2034
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

link_file() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

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
