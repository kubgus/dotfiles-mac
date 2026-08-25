#!/bin/bash
# Claude Code, and the hands-free setup around it: speak.sh announces what
# Claude is about to do, the daemon reads the queue aloud, and the applet
# answers the permission prompt you just heard without leaving the app you
# are in.
#
# The pieces are not separable - the hooks that drive the speech live in
# settings.json, so splitting the voice control out would mean splitting a
# single file across two domains.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# launchd refuses to load a symlinked plist, so the agent is rendered as a real
# copy. Edit the template in launchd/ and re-run this to apply changes.
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

# ~/.claude also holds sessions, projects and telemetry, so link file by file.
for f in settings.json speak.sh say-again.sh speaker-daemon.sh; do
    link_file "$DOTFILES_DIR/claude/$f" "$HOME/.claude/$f"
done

# Bind this app to a system-wide key to answer a prompt without leaving the
# app you are in. It holds the Accessibility grant, so it is what macOS lists.
build_applet claude-approve "Claude Approve"

# Keeps the speaker daemon alive across logins.
install_agent com.gustafik.claude-speaker
