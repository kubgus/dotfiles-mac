#!/bin/bash
# Claude Code: its settings, plus the two scripts they point at - the status
# line and the bell the notification hooks ring.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~/.claude also holds sessions, projects and telemetry, so link the one file
# we own rather than the directory.
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
link_file "$DOTFILES_DIR/claude/bell.sh" "$HOME/.claude/bell.sh"
