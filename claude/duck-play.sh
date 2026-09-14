#!/bin/bash
# Play an alert sound with the system volume ducked up, then restore it.
#
# afplay shares the same output as everything else, so there is no way to
# silence other apps individually - the only lever macOS exposes is the
# system output volume. Push it up before the sound and put it back after,
# so the alert cuts through whatever else is playing.
#
# No `set -e`: the whole point of this script is that the volume gets
# restored even if osascript or afplay fails partway through, so failures
# are swallowed (`2>/dev/null`) and restore runs via a trap instead of a
# final line that a mid-script error could skip.
set -uo pipefail

sound="$1"

current="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"

restore() {
    case "$current" in '' | *[!0-9]*) return ;; esac
    osascript -e "set volume output volume $current" >/dev/null 2>&1
}
trap restore EXIT

osascript -e 'set volume output volume 100' >/dev/null 2>&1
afplay "$sound" >/dev/null 2>&1
