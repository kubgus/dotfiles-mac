#!/bin/bash
# The shell itself: the profile, and the commands meant to be run by name.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

link_file "$DOTFILES_DIR/zprofile" "$HOME/.zprofile"

# ~/Bin is already on PATH and also holds links into other repos, so link each
# script rather than the directory. Anything dropped in bin/ is picked up here.
for f in "$DOTFILES_DIR"/bin/*; do
    link_file "$f" "$HOME/Bin/$(basename "$f")"
done
