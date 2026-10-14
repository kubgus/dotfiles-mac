#!/bin/bash
# Claude Code: the status line. Everything personal - the operator context
# (claude/operator.md) and the kubgus plugin with its house style, skills,
# notification sounds and MCP servers - is opt-in per session through kubgus
# mode in bin/claudeswitch, so nothing here links it into ~/.claude.
#
# settings.json is deliberately absent. See the README: Claude Code owns that
# file and rewrites it in place, so tracking it was a fight rather than a sync.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~/.claude also holds sessions, projects and telemetry, so link the files we
# own rather than the directory.
link_file "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
