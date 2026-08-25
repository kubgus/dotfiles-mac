#!/bin/bash
# Set up this machine from the dotfiles.
#
# With no arguments every domain in setup/ runs. Name one or more to run just
# those - ./_setup.sh claude - which is the quicker loop when you have changed
# one thing and want it applied.
#
# Each domain is idempotent and quiet, so a run that prints nothing is a run
# that found everything already in place.
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/setup" && pwd)"

available() {
    local f name
    for f in "$SETUP_DIR"/*.sh; do
        name="$(basename "$f" .sh)"
        [ "$name" = "lib" ] && continue
        printf '%s\n' "$name"
    done
}

if [ $# -eq 0 ]; then
    while read -r name; do
        set -- "$@" "$name"
    done < <(available)
fi

for name in "$@"; do
    script="$SETUP_DIR/$name.sh"
    if [ ! -f "$script" ]; then
        echo "Unknown domain: $name" >&2
        echo "Available: $(available | tr '\n' ' ')" >&2
        exit 1
    fi
    bash "$script"
done
