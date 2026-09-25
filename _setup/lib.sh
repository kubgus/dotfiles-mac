#!/bin/bash
# The one helper every domain needs. Sourced, not run.
#
# Anything used by a single domain belongs in that domain's script instead -
# this file is for what is genuinely shared, not for helpers in general.
#
# link_file is idempotent and quiet: a second run prints nothing and changes
# nothing, so any output means something actually happened.
#
# No `set -euo pipefail` here on purpose: this file is sourced, and setting shell
# options in a sourced file changes the caller's shell rather than this one. Each
# domain script sets them for itself.

# Resolve this file through any symlink chain before anchoring on it. A link in
# ~/Bin would otherwise make this resolve to ~ rather than the repo, silently.
# `readlink -f` and `realpath` are GNU-only, so walk the chain by hand.
_src="${BASH_SOURCE[0]}"
while [ -L "$_src" ]; do
    _dir="$(cd -P "$(dirname "$_src")" && pwd)"
    _src="$(readlink "$_src")"
    case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done

# Read by the domain scripts that source this, not used here.
# shellcheck disable=SC2034
DOTFILES_DIR="$(cd -P "$(dirname "$_src")/.." && pwd)"
unset _src _dir

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
