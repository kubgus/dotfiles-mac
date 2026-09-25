---
name: speak
description: Speaks Claude's last response aloud using macOS text-to-speech (say). Use whenever the user asks Claude to speak, say something out loud, read a response aloud, or narrate what it just said - e.g. "say that", "read that to me", "speak it".
---

# Speak

Take your own previous response - the assistant message immediately before this request.
If there is none, say so and stop.

1. **Strip the markup.** Headers, bullet markers, code fences, links, bold and italic
   asterisks, label formatting. Leave natural spoken language. Summarise a large code
   block rather than reading it out.
2. **Write it to `"${TMPDIR:-/tmp}/claude-speak.txt"`.** Not a bare `/tmp` path - that is
   world-writable, so a fixed name there can be pre-created by someone else as a symlink.
3. **Run it detached:**

       nohup say -f "${TMPDIR:-/tmp}/claude-speak.txt" >/dev/null 2>&1 &

Do not use the Bash tool's background mode - speech should start and be forgotten, with no
completion notification. Say that it started, then carry on. Never wait for it to finish.
