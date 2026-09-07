#!/bin/bash
# Claude Code: its settings - including the hooks that chime when a turn ends
# and when a permission prompt is waiting - and the applet that answers that
# prompt without leaving the app you are in.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

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

# ~/.claude also holds sessions, projects and telemetry, so link the one file
# we own rather than the directory.
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# Bind this app to a system-wide key to answer a prompt without leaving the
# app you are in. It holds the Accessibility grant, so it is what macOS lists.
#
# Do not bind it to a shortcut containing Control. Holding Control as an
# AppleScript applet launches forces its Run/Quit startup screen, whatever
# OSAAppletShowStartupScreen says.
build_applet claude-approve "Claude Approve"
