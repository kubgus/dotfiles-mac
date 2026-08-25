#!/bin/bash
# ~/.config, linked as a whole directory. .gitignore whitelists the parts worth
# tracking, so everything else living there stays local to the machine.
set -euo pipefail
# shellcheck source=setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

link_file "$DOTFILES_DIR/config" "$HOME/.config"
