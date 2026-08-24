#!/bin/bash
Q="$HOME/.claude/speech-queue"
H="$HOME/.claude/speech-history"
W="$HOME/.claude/speech-work"
APPS=("Music" "Spotify")
DUCK=20          # percent of original volume while speaking
mkdir -p "$Q" "$H" "$W"

# Anything left here was interrupted mid-sentence by a crash or a restart.
rm -f "$W"/*

SAVED=()

duck() {
  SAVED=()
  for app in "${APPS[@]}"; do
    v=$(osascript -e "if application \"$app\" is running then tell application \"$app\" to get sound volume" 2>/dev/null)
    [ -z "$v" ] && continue
    SAVED+=("$app:$v")
    osascript -e "if application \"$app\" is running then tell application \"$app\" to set sound volume to $(( v * DUCK / 100 ))" 2>/dev/null
  done
}

unduck() {
  for entry in "${SAVED[@]}"; do
    osascript -e "if application \"${entry%%:*}\" is running then tell application \"${entry%%:*}\" to set sound volume to ${entry##*:}" 2>/dev/null
  done
  SAVED=()
}

prune() {
  ls -1 "$H" | sort -rn | tail -n +21 | while read -r old; do rm -f "$H/$old"; done
}

trap 'unduck; exit' INT TERM
prune

while true; do
  for f in "$Q"/*; do
    [ -e "$f" ] || continue
    # Claim it before speaking. speak.sh cancels queued announcements that a
    # permission request is about to supersede, and the move is what settles
    # who won: if it fails, the message is already gone and must not be said.
    n=$(basename "$f")
    mv "$f" "$W/$n" 2>/dev/null || continue
    duck
    afplay -t 0.3 /System/Library/Sounds/Glass.aiff 2>/dev/null
    say -f "$W/$n"
    unduck
    mv -f "$W/$n" "$H/$n"
    prune
  done
  sleep 0.3
done
