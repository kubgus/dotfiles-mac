#!/bin/bash
# Claude Code terminal title: one glyph of session state plus the project name.
#
#   title.sh 🌀            working
#   title.sh 🔴 bell       waiting on you
#   title.sh 💤 bell       turn finished
#   title.sh               clear it
#
# Claude Code's own title is disabled (CLAUDE_CODE_DISABLE_TERMINAL_TITLE), so
# the hooks in settings.json are the only writer and the glyph is the whole
# point: a tab strip tells working from waiting from done without switching to
# it. `bell` also rings the terminal, which is what marks a tab unread.
#
# Those hooks are a state machine, and every way out of 🔴 needs a hook of
# its own or the red sticks around long after you have answered. Red is
# entered at PermissionRequest and left again by PostToolUse and
# PostToolUseFailure (approved, and the tool has now run or died), Stop (the
# turn ended), UserPromptSubmit (you typed again) and PermissionDenied - which
# despite the name only fires when auto mode's classifier refuses a tool, not
# when you do. Refusing at the prompt fires nothing, so PreToolUse carries that
# case: it runs before the permission check, so the next tool Claude reaches
# for clears the red without ever painting over a prompt that is still waiting.
#
# A hook must never break the tool call that triggered it, so every path here
# exits 0 - including a session with no terminal to write to, like a
# background job or a cloud run.
set -uo pipefail

glyph="${1-}"
bell="${2-}"

# The controlling terminal is inherited down the hook's process chain, so this
# script's own tty is Claude's tty. CLAUDE_PID is the fallback for a chain that
# was detached from it somewhere along the way.
tty_of() {
    local t
    t="$(ps -o tty= -p "$1" 2>/dev/null | tr -d ' ')"
    case "$t" in '' | *'?'*) return 1 ;; esac
    printf '/dev/%s' "$t"
}

target=""
for pid in "$$" "${PPID:-}" "${CLAUDE_PID:-}"; do
    [ -n "$pid" ] || continue
    candidate="$(tty_of "$pid")" || continue
    if [ -w "$candidate" ]; then
        target="$candidate"
        break
    fi
done
[ -n "$target" ] || exit 0

if [ -n "$glyph" ]; then
    project="${CLAUDE_PROJECT_DIR:-$PWD}"
    printf '\033]0;%s %s\007' "$glyph" "${project##*/}" > "$target"
else
    printf '\033]0;\007' > "$target"
fi

[ "$bell" = bell ] && printf '\a' > "$target"

exit 0
