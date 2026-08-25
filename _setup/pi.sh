#!/bin/bash
# Pi agent: only the portable config. auth.json, sessions/ and npm/ are machine
# state and stay local.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for f in settings.json models.json; do
    link_file "$DOTFILES_DIR/pi/agent/$f" "$HOME/.pi/agent/$f"
done
