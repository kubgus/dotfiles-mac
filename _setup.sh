#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# launchd refuses to load a symlinked plist, so agents are rendered as real
# copies. Edit the template in launchd/ and re-run this script to apply changes.
install_agent() {
    local label="$1"
    local src="$DOTFILES_DIR/launchd/$label.plist"
    local dest="$HOME/Library/LaunchAgents/$label.plist"
    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' RETURN

    sed "s#__HOME__#$HOME#g" "$src" > "$tmp"

    # Also require the service to be loaded, so a renamed Label or a manually
    # unloaded agent is repaired instead of silently skipped.
    if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$tmp" "$dest" \
        && launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
        return
    fi

    echo "Installing launch agent $label"
    mkdir -p "$(dirname "$dest")"
    rm -f "$dest"
    cp "$tmp" "$dest"

    launchctl bootout "gui/$UID/$label" 2>/dev/null || true
    launchctl bootstrap "gui/$UID" "$dest"
}

link_file "$DOTFILES_DIR/config" "$HOME/.config"
link_file "$DOTFILES_DIR/zprofile" "$HOME/.zprofile"

# Claude Code: settings + hands-free speech scripts.
# ~/.claude also holds sessions, projects and telemetry, so link file by file.
for f in settings.json speak.sh say-again.sh speaker-daemon.sh; do
    link_file "$DOTFILES_DIR/claude/$f" "$HOME/.claude/$f"
done

# Pi agent: only the portable config. auth.json, sessions/ and npm/ stay local.
for f in settings.json models.json; do
    link_file "$DOTFILES_DIR/pi/agent/$f" "$HOME/.pi/agent/$f"
done

# Scripts meant to be run by name from anywhere.
for f in claude-approve; do
    link_file "$DOTFILES_DIR/bin/$f" "$HOME/Bin/$f"
done

# Keeps the speaker daemon alive across logins.
install_agent com.gustafik.claude-speaker
