#!/bin/bash
# Claude Code, and the hands-free setup around it: speak.sh announces what
# Claude is about to do, the daemon reads the queue aloud, and the applet
# answers the permission prompt you just heard without leaving the app you
# are in.
#
# The pieces are not separable - the hooks that drive the speech live in
# settings.json, so splitting the voice control out would mean splitting a
# single file across two domains.
set -euo pipefail
# shellcheck source=setup/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ~/.claude also holds sessions, projects and telemetry, so link file by file.
for f in settings.json speak.sh say-again.sh speaker-daemon.sh; do
    link_file "$DOTFILES_DIR/claude/$f" "$HOME/.claude/$f"
done

# Bind this app to a system-wide key to answer a prompt without leaving the
# app you are in. It holds the Accessibility grant, so it is what macOS lists.
build_applet claude-approve "Claude Approve"

# Keeps the speaker daemon alive across logins.
install_agent com.gustafik.claude-speaker
