#!/bin/bash
# The daemon is the on switch. With it stopped there is nothing to read the
# queue, so anything written here would be discarded at its next start anyway -
# and the chime would be the one sound still escaping. Staying silent makes
# stopping the daemon a complete mute, which is the point.
D="$HOME/.claude/speaker-daemon.pid"
[ -f "$D" ] && kill -0 "$(cat "$D" 2>/dev/null)" 2>/dev/null || exit 0

INPUT=$(cat)
EVENT=$(jq -r '.hook_event_name // empty' <<<"$INPUT")
Q="$HOME/.claude/speech-queue"; mkdir -p "$Q"
S="$HOME/.claude/speech-state"; mkdir -p "$S"

# PermissionRequest and PreToolUse carry the same tool_name/tool_input, so
# both describe the pending call the same way - only the framing differs.
describe_tool() {
  local tool
  tool=$(jq -r '.tool_name // empty' <<<"$INPUT")
  case "$tool" in
    Bash)       echo "Running $(jq -r '.tool_input.description // empty' <<<"$INPUT")" ;;
    Edit|Write) echo "Editing $(basename "$(jq -r '.tool_input.file_path' <<<"$INPUT")")" ;;
    ?*)         echo "Using $tool" ;;
  esac
}

# Take back queued messages the daemon has not started speaking yet, matching
# $1 as a filename suffix and $2 as the phrase the message ends with. The move
# is the claim: if it fails the daemon already owns the file and it is too late.
cancel_queued() {
  local f found=1
  for f in "$Q"/*"$1"; do
    [ -e "$f" ] || continue
    case "$(cat "$f" 2>/dev/null)" in
      *"$2") ;;
      *) continue ;;
    esac
    mv "$f" "$S/cancelled" 2>/dev/null || continue
    rm -f "$S/cancelled"
    found=0
  done
  return $found
}

case "$EVENT" in
  PermissionRequest)
    # PreToolUse fires ~50ms earlier with the same description, so the useful
    # thing to say is the request itself - not a repeat of what was just said.
    # PermissionRequest carries no tool_use_id, so correlate on the phrase;
    # it derives from tool_name and tool_input, which both events do carry.
    WHAT=$(describe_tool)
    if [ "$WHAT" != "$(cat "$S/announced" 2>/dev/null)" ]; then
      MSG="Claude needs your permission $WHAT"   # nothing announced this
    elif cancel_queued .pre "$WHAT"; then
      MSG="Claude needs your permission $WHAT"   # pulled it back in time
    else
      MSG="Claude needs your permission."         # too late, already spoken
    fi
    SUFFIX=".perm" ;;
  PostToolUse|PostToolUseFailure)
    # The call ran, so its prompt is answered and gone. Anything still queued
    # about it is stale - which happens whenever a long spoken reply is still
    # playing while the next turn's prompts are already being approved.
    # Neither event fires on a manual denial; the daemon expires those on age.
    cancel_queued .perm "$(describe_tool)" || true ;;
  Notification)
    MSG="Claude needs your attention." ;;
  PreToolUse)
    MSG=$(describe_tool)
    SUFFIX=".pre"
    printf '%s' "$MSG" > "$S/announced" ;;
  Stop)
    MSG=$(jq -r '.last_assistant_message // "Done"' <<<"$INPUT" \
      | awk '/^```/{f=!f; next} !f' \
      | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g; s/`([^`]*)`/\1/g; s/\*+([^*]*)\*+/\1/g; s/^#+ //; s#https?://[^ ]*# link #g' \
      | tr -s ' \n' ' ')
esac

if [ -n "$MSG" ]; then
  printf '%s' "$MSG" > "$Q/$(perl -MTime::HiRes=time -e 'printf "%.6f", time')${SUFFIX:-}"
  # Chime the instant the message lands in the queue, not when its turn to be
  # spoken comes up - so it's heard right away even behind a long backlog.
  afplay -t 0.3 /System/Library/Sounds/Glass.aiff 2>/dev/null &
fi
exit 0
