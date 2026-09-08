#!/bin/bash
# Ring the terminal bell from a Claude Code hook.
#
# The bell is what marks a tab unread, so it has to reach the terminal device:
# a hook's stdout is captured by Claude Code, not printed. Claude Code owns the
# terminal title itself again, and that costs nothing here - BEL is a bare
# control character, not part of the OSC sequence the app writes to set a
# title, so the two never collide.
#
# A hook must never break the tool call that triggered it, so every path here
# exits 0 - including a session with no terminal to ring, like a background job
# or a cloud run.
set -uo pipefail

# The controlling terminal is inherited down the hook's process chain, so this
# script's own tty is Claude's tty. CLAUDE_PID is the fallback for a chain that
# was detached from it somewhere along the way.
tty_of() {
    local t
    t="$(ps -o tty= -p "$1" 2>/dev/null | tr -d ' ')"
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
