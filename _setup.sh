#!/bin/bash
# Set up this machine from the dotfiles.
#
# With no arguments every domain in _setup/ runs. Name one or more to run just
# those - ./_setup.sh claude - which is the quicker loop when you have changed
# one thing and want it applied.
#
# Each domain is idempotent and quiet, so a run that prints nothing is a run
# that found everything already in place.
set -euo pipefail

# Resolve this file through any symlink chain before anchoring on it. A link in
# ~/Bin would otherwise make this resolve to ~ rather than the repo, silently.
# `readlink -f` and `realpath` are GNU-only, so walk the chain by hand.
_src="${BASH_SOURCE[0]}"
while [ -L "$_src" ]; do
    _dir="$(cd -P "$(dirname "$_src")" && pwd)"
    _src="$(readlink "$_src")"
    case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SETUP_DIR="$(cd -P "$(dirname "$_src")/_setup" && pwd)"
unset _src _dir

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
