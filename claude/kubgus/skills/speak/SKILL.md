---
name: speak
description: Speaks Claude's last response aloud using macOS text-to-speech (say). Use whenever the user asks Claude to speak, say something out loud, read a response aloud, or narrate what it just said - e.g. "say that", "read that to me", "speak it".
---

Look at your own previous response in this conversation (the assistant message immediately
before this request).

If there is no prior assistant message, say so and stop.

Otherwise:

1. Take that response's text and strip Markdown formatting - headers, bullet markers, code
   fences, links, bold and italic asterisks - so only natural spoken language remains. If
   it contains large code blocks, summarize them briefly rather than reading them verbatim.
2. Write the cleaned text to `"${TMPDIR:-/tmp}/claude-speak.txt"`. Use `$TMPDIR` rather
   than a bare `/tmp` path: `/tmp` is world-writable, so a fixed name there can be
   pre-created by another user as a symlink.
3. Run it detached so it does not block the response:

   ```sh
   nohup say -f "${TMPDIR:-/tmp}/claude-speak.txt" >/dev/null 2>&1 &
   ```

   Do not use the Bash tool's background mode for this - the speech should just start and
   be forgotten, with no completion notification. Report that speech started and continue
   immediately; do not wait for it to finish.
