#!/bin/bash
H="$HOME/.claude/speech-history"
Q="$HOME/.claude/speech-queue"
D="$HOME/.claude/speaker-daemon.pid"
N="${1:-1}"
# Unlike the hooks, this one is asked for directly - say why nothing happened.
[ -f "$D" ] && kill -0 "$(cat "$D" 2>/dev/null)" 2>/dev/null \
  || { echo "speaker-daemon is not running"; exit 1; }
f=$(ls -1 "$H" 2>/dev/null | sort -rn | sed -n "${N}p")
[ -z "$f" ] && { echo "nothing to replay"; exit 1; }
cp "$H/$f" "$Q/$(perl -MTime::HiRes=time -e 'printf "%.6f", time')"
afplay -t 0.3 /System/Library/Sounds/Glass.aiff 2>/dev/null &
