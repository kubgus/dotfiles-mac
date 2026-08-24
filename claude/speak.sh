#!/bin/bash
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
    Bash)       echo "Running $(jq -r '.tool_input.description // .tool_input.command' <<<"$INPUT")" ;;
    Edit|Write) echo "Editing $(basename "$(jq -r '.tool_input.file_path' <<<"$INPUT")")" ;;
    ?*)         echo "Using $tool" ;;
  esac
}

# Take back a queued announcement the daemon has not started speaking yet.
# The move is the claim: if it fails the daemon already owns the file.
cancel_queued() {
  local f
  for f in "$Q"/*.pre; do
    [ -e "$f" ] || continue
    [ "$(cat "$f" 2>/dev/null)" = "$1" ] || continue
    mv "$f" "$S/cancelled" 2>/dev/null || return 1
    rm -f "$S/cancelled"
    return 0
  done
  return 1
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
    elif cancel_queued "$WHAT"; then
      MSG="Claude needs your permission $WHAT"   # pulled it back in time
    else
      MSG="Claude needs your permission."         # too late, already spoken
    fi ;;
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

[ -n "$MSG" ] && printf '%s' "$MSG" \
  > "$Q/$(perl -MTime::HiRes=time -e 'printf "%.6f", time')${SUFFIX:-}"
exit 0
