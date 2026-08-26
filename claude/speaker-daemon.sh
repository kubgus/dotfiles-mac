#!/bin/bash
Q="$HOME/.claude/speech-queue"
H="$HOME/.claude/speech-history"
W="$HOME/.claude/speech-work"
LOCK="$HOME/.claude/speaker-daemon.pid"
APPS=("Music" "Spotify")
DUCK=20          # percent of original volume while speaking
PERM_TTL=60      # seconds a permission request stays worth announcing
SAY_TIMEOUT=30   # seconds before a wedged `say` is killed, so a stuck audio
                 # device can't strand the loop (and the duck) indefinitely
mkdir -p "$Q" "$H" "$W"

# Two instances ducking/unducking the same apps desync which volume counts as
# "original" - refuse to start alongside one that's still alive.
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  echo "speaker-daemon already running (pid $(cat "$LOCK"))" >&2
  exit 1
fi
echo $$ > "$LOCK"

# Anything left here was interrupted mid-sentence by a crash or a restart.
rm -f "$W"/*

# Skip whatever piled up while the daemon was down - start fresh, not backlogged.
rm -f "$Q"/*

SAVED=()
SAY_PID=

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

# Runs `say` in the background so a TERM/INT signal interrupts it right away
# instead of queueing behind it, and kills it if it wedges - so a stuck audio
# device can't strand the daemon (and the duck) until someone force-kills it.
speak() {
  say -f "$1" &
  SAY_PID=$!
  ( sleep "$SAY_TIMEOUT"; kill "$SAY_PID" 2>/dev/null ) &
  local watcher=$!
  wait "$SAY_PID" 2>/dev/null
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  SAY_PID=
}

trap '[ -n "$SAY_PID" ] && kill "$SAY_PID" 2>/dev/null; unduck; rm -f "$LOCK"; exit' INT TERM
prune

while true; do
  for f in "$Q"/*; do
    [ -e "$f" ] || continue
    # Claim it before speaking. speak.sh cancels queued announcements that a
    # permission request is about to supersede, and the move is what settles
    # who won: if it fails, the message is already gone and must not be said.
    n=$(basename "$f")
    mv "$f" "$W/$n" 2>/dev/null || continue

    # speak.sh drops a permission request once the call it guarded has run.
    # A manual denial has no such signal, so age it out instead: a prompt sat
    # on this long is answered, or is on screen where it can be read.
    if [ "${n##*.}" = "perm" ] && [ $(( $(date +%s) - ${n%%.*} )) -ge "$PERM_TTL" ]; then
      rm -f "$W/$n"
      continue
    fi

    duck
    speak "$W/$n"
    unduck
    mv -f "$W/$n" "$H/$n"
    prune
  done
  sleep 0.3
done
