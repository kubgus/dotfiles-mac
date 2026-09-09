#!/bin/bash
# Git clean filter for claude/settings.json: the committed form of a file that
# Claude Code writes to while it runs.
#
# /model and /effort persist the live choice straight into the settings file,
# and that file is this repo's by symlink, so switching model used to register
# as a working-tree change. Those two keys are session state, not configuration,
# so git is never shown them: the working file keeps them, the blob does not,
# and a commit taken after a day of switching models is empty.
#
# The rest is normalised rather than passed through. Claude Code edits the file
# in place and indents what it inserts with four spaces where the file uses two,
# so re-emitting from jq at a fixed indent is what stops a formatting difference
# from reading as a change. Keys are sorted for the same reason - the blob is a
# canonical projection of the file, not a mirror of it, and only a real edit
# should show up as a diff.
#
# Reads the file on stdin and writes the committed form to stdout, which is the
# contract git expects. Registered per clone by _setup/claude.sh: git will not
# take a filter definition out of the repository that ships it, because filters
# run arbitrary commands.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    echo "settings-clean.sh: jq is required to stage claude/settings.json" >&2
    exit 1
fi

jq -S --indent 2 'del(.model, .effortLevel)'
