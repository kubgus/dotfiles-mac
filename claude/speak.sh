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

case "$EVENT" in
  PermissionRequest)
    # PreToolUse fires first and has already described the call for the tools
    # it matches. PermissionRequest carries no tool_use_id to correlate on, so
    # compare the phrase itself - it is derived from tool_name and tool_input,
    # which both events do carry.
    WHAT=$(describe_tool)
    if [ -n "$WHAT" ] && [ "$WHAT" = "$(cat "$S/announced" 2>/dev/null)" ]; then
      MSG="Claude needs your permission."
    else
      MSG="Claude needs your permission. $WHAT"
    fi ;;
  Notification)
    MSG="Claude needs your attention." ;;
  PreToolUse)
    MSG=$(describe_tool)
    printf '%s' "$MSG" > "$S/announced" ;;
  Stop)
    MSG=$(jq -r '.last_assistant_message // "Done"' <<<"$INPUT" \
      | awk '/^```/{f=!f; next} !f' \
      | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g; s/`([^`]*)`/\1/g; s/\*+([^*]*)\*+/\1/g; s/^#+ //; s#https?://[^ ]*# link #g' \
      | tr -s ' \n' ' ')
esac

[ -n "$MSG" ] && printf '%s' "$MSG" \
  > "$Q/$(perl -MTime::HiRes=time -e 'printf "%.6f", time')"
exit 0
