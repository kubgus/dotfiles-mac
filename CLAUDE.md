# Dotfiles

Every tracked file is the real one; `$HOME` links back to it. `README.md` holds the why -
read it before changing the layout, a setup domain or how the plugin loads.

- **`claude/operator.md`** is the global context file, linked as `~/.claude/CLAUDE.md`.
  Never name a file `CLAUDE.md` under `claude/`: this repo would load it a second time.
- **`claude/kubgus/`** is the `kubgus` plugin, read in place - no install, no version
  bump. Skill bodies and references are read when used, so an edit is live at once.
  Skill descriptions, the output style, `operator.md`, hooks and `.mcp.json` load at
  session start; a new session picks them up.
- **`settings.json` is not tracked**, deliberately. Do not bring it back.
- **Setup**: `./_setup.sh <domain>`. Silence means nothing changed. After moving or
  renaming a linked file, run its domain so the link follows - setup never prunes.
- **Shell**: `shellcheck`-clean, checked with the command in the README.
- **Commits**: `type(scope): summary` - lowercase, present tense, scope the top-level
  area (`claude`, `bin`, `config`, `shell`). The body says why.
- **The README is part of the change.** Layout, a new domain or a new non-obvious reason
  goes into it in the same commit.
