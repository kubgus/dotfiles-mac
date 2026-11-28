#!/bin/bash
# Session notifications: play a system sound, then ring the terminal bell.
#
# Usage: notify.sh [SystemSoundName]     e.g. notify.sh Submarine
# With no argument it rings the bell only. Silence the sound with:
#     touch ~/.claude/mute
#
# Not `set -e`. A hook must never break the tool call that triggered it, so
# every path here reaches `exit 0` - including a session with no terminal to
# ring, like a background job or a cloud run.
set -uo pipefail

sound="${1:-}"

if [ -n "$sound" ] && [ ! -f "$HOME/.claude/mute" ]; then
    file="/System/Library/Sounds/${sound}.aiff"
    # Detached: afplay blocks for the length of the sound, and a hook must not.
    [ -r "$file" ] && { afplay "$file" >/dev/null 2>&1 & }
fi

# The bell is what marks a tab unread, so it has to reach the terminal device:
# a hook's stdout is captured by Claude Code, not printed. BEL is a bare control
# character rather than part of the OSC sequence the app writes to set the tab
# title, so the two never collide.
#
# The controlling terminal is inherited down the hook's process chain, so this
# script's own tty is Claude's tty. CLAUDE_PID is the fallback for a chain that
# was detached from it somewhere along the way.
tty_of() {
    local t
    t="$( { ps -o tty= -p "$1" | tr -d " "; } 2>/dev/null )"
    case "$t" in '' | *'?'*) return 1 ;; esac
    printf '/dev/%s' "$t"
}

for pid in "$$" "${PPID:-}" "${CLAUDE_PID:-}"; do
    [ -n "$pid" ] || continue
    tty="$(tty_of "$pid")" || continue
    if [ -w "$tty" ]; then
        printf '\a' > "$tty"
        break
    fi
done

exit 0
