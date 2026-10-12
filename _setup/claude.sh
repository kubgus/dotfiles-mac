#!/bin/bash
# Claude Code: the global context file, the status line, and the kubgus plugin
# that carries everything else - house style, skills, the notification sounds
# and the personal MCP servers.
#
# settings.json is deliberately absent. See the README: Claude Code owns that
# file and rewrites it in place, so tracking it was a fight rather than a sync.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~/.claude also holds sessions, projects and telemetry, so link the files we
# own rather than the directory. ~/.claude/CLAUDE.md is the one context file
# loaded in every session regardless of where it starts, which is the whole
# point of it living here rather than in any one project. Its source is not
# named CLAUDE.md on purpose: Claude Code also loads any CLAUDE.md under the
# working directory, so a session in this repo would read the file twice, the
# second time as if it were this subtree's project instructions.
link_file "$DOTFILES_DIR/claude/operator.md" "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# The plugin is discovered, not installed. Anything under ~/.claude/skills/<name>
# loads as <name>@skills-dir, read in place - which is what `claude plugin init`
# scaffolds and what a plugin you edit rather than consume wants. Installing it
# from a marketplace instead would copy it into ~/.claude/plugins/cache/ and read
# only that copy, so an edit here would stay invisible until the version changed.
# ~/.claude/skills is already shared into every account dir by bin/claudeswitch,
# so this reaches all of them without being taught about it.
link_file "$DOTFILES_DIR/claude/kubgus" "$HOME/.claude/skills/kubgus"
