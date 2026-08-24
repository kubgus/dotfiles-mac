#!/bin/bash
INPUT=$(cat)
EVENT=$(jq -r '.hook_event_name // empty' <<<"$INPUT")
Q="$HOME/.claude/speech-queue"; mkdir -p "$Q"

case "$EVENT" in
  PermissionRequest|Notification)
    MSG="Claude needs you. $(jq -r '.tool_name // .message // ""' <<<"$INPUT")" ;;
  PreToolUse)
    TOOL=$(jq -r '.tool_name' <<<"$INPUT")
    case "$TOOL" in
      Bash)       MSG="Running $(jq -r '.tool_input.command' <<<"$INPUT" | cut -c1-50)" ;;
      Edit|Write) MSG="Editing $(basename "$(jq -r '.tool_input.file_path' <<<"$INPUT")")" ;;
      *)          MSG="Using $TOOL" ;;
    esac ;;
  Stop)
    MSG=$(jq -r '.last_assistant_message // "Done"' <<<"$INPUT" \
      | awk '/^```/{f=!f; next} !f' \
      | sed -E 's/`([^`]*)`/\1/g; s/\*+([^*]*)\*+/\1/g; s/^#+ //; s#https?://[^ ]*# link #g' \
      | tr -s ' \n' ' ')
esac

[ -n "$MSG" ] && printf '%s' "$MSG" \
  > "$Q/$(perl -MTime::HiRes=time -e 'printf "%.6f", time')"
exit 0
