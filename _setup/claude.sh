#!/bin/bash
# Claude Code: the global context file, its settings, the status line they point
# at, and the kubgus plugin that carries everything else - house style, skills,
# the notification sounds and the personal MCP servers.
set -euo pipefail
# shellcheck source=_setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~/.claude also holds sessions, projects and telemetry, so link the files we
# own rather than the directory. CLAUDE.md is the one context file loaded in
# every session regardless of where it starts, which is the whole point of it
# living here rather than in any one project.
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# The plugin is not linked. claude/settings.json declares the marketplace under
# extraKnownMarketplaces and enables the plugin, so Claude Code loads it from
# this repo directly - which means an edit here is live without a reinstall, and
# a fresh machine picks it up from the settings link above with no CLI step.
# The path there has to be absolute, because relative marketplace paths resolve
# against the session's working directory rather than the settings file.

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

# Point the plugin cache at the source instead of a copy of it.
#
# `claude plugin install` copies the plugin into
# ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/ and then reads only
# that copy, so an edit here is invisible until the version in plugin.json
# changes - `install` and `update` both no-op on an unchanged version. Replacing
# the version directory with a symlink makes edits live, which is what you want
# for a plugin you are editing rather than consuming. Claude Code follows it and
# leaves it alone across install, update and list.
link_plugin_cache() {
    local src="$DOTFILES_DIR/claude/plugins/kubgus" version dest
    command -v jq >/dev/null 2>&1 || return 0
    version="$(jq -r '.version' "$src/.claude-plugin/plugin.json" 2>/dev/null)" || return 0
    [ -n "$version" ] && [ "$version" != "null" ] || return 0

    dest="$HOME/.claude/plugins/cache/kubgus/kubgus/$version"
    [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ] && return 0

    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Replacing plugin cache copy with a link to the source"
        rm -rf "$dest"
    else
        echo "Linking plugin cache -> $src"
    fi
    ln -s "$src" "$dest"
}

link_plugin_cache
