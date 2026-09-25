#!/bin/bash
# Sound half of the session notifications: play a system sound, then ring the
# terminal bell. Split from bell.sh because they fail differently - a missing
# sound file is nothing, a missing terminal is nothing, and neither may take
# down the tool call that triggered the hook.
#
# Usage: notify.sh <SystemSoundName>     e.g. notify.sh Submarine
#
# Silence everything by creating the sentinel:  touch ~/.claude/mute
set -uo pipefail

sound="${1:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "$sound" ] && [ ! -f "$HOME/.claude/mute" ]; then
    file="/System/Library/Sounds/${sound}.aiff"
    # Detached: afplay blocks for the length of the sound, and a hook must not.
    [ -r "$file" ] && { afplay "$file" >/dev/null 2>&1 & }
fi

bash "$here/bell.sh"
exit 0
