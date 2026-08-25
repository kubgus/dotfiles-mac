#!/bin/bash
# Helpers shared by the setup scripts. Sourced, not run.
#
# Every helper is idempotent and quiet: a second run should print nothing and
# change nothing, so any output means something actually happened.

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

# launchd refuses to load a symlinked plist, so agents are rendered as real
# copies. Edit the template in launchd/ and re-run setup to apply changes.
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

# AppleScript that sends keystrokes needs its own app identity: macOS grants
# Accessibility to whatever does the sending, and via /usr/bin/osascript that
# would be every script on the machine. Rebuilt only when the source changes,
# because recompiling makes macOS treat it as a new app and forget the grant.
build_applet() {
    local name="$1"
    local src="$DOTFILES_DIR/applescript/$name.applescript"
    local app="$HOME/Applications/$2.app"

    if [ -d "$app" ] && [ ! "$src" -nt "$app" ]; then
        return
    fi

    echo "Building applet $2"
    mkdir -p "$HOME/Applications"
    rm -rf "$app"
    osacompile -o "$app" "$src"

    # No dock icon, so triggering it doesn't pull focus away from Claude.
    /usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" \
        "$app/Contents/Info.plist" >/dev/null
    # osacompile leaves the bundle unidentified; TCC remembers a grant more
    # reliably against a stable identifier than against the path alone.
    /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.gustafik.$name" \
        "$app/Contents/Info.plist" >/dev/null

    # Editing Info.plist invalidates the signature osacompile applied, and
    # macOS refuses to launch a bundle whose seal is broken.
    codesign --force --sign - "$app" 2>/dev/null
}
