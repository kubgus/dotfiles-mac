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

# The clean filter that keeps /model and /effort out of the repo. Git will not
# read filter definitions out of a repository - they run arbitrary commands, so
# they are per-clone local config - which makes registering one setup's job.
# Until this has run, staging claude/settings.json quietly commits both keys:
# git ignores an attribute naming a filter it does not know. `required` covers
# the other half, failing the stage loudly if the filter itself ever breaks -
# and it is why the smudge half has to be spelled out as `cat`. An undefined
# direction is a pass-through for an optional filter but a hard failure for a
# required one, and a checkout that fails partway leaves nothing behind, which
# through the symlink means deleting the live ~/.claude/settings.json.
set_git_config() {
    local key="$1" want="$2" have
    have="$(git -C "$DOTFILES_DIR" config --local --get "$key" || true)"
    if [ "$have" != "$want" ]; then
        echo "Setting git config $key -> $want"
        git -C "$DOTFILES_DIR" config --local "$key" "$want"
    fi
}

if git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    set_git_config filter.claude-settings.clean "$DOTFILES_DIR/claude/settings-clean.sh"
    set_git_config filter.claude-settings.smudge cat
    set_git_config filter.claude-settings.required true
fi
