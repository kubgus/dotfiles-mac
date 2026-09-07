#!/bin/bash
# Claude Code: its settings, including the hooks that chime when a turn ends
# and when a permission prompt is waiting.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~/.claude also holds sessions, projects and telemetry, so link the one file
# we own rather than the directory.
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
