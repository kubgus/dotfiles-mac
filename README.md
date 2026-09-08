# Dotfiles

macOS configuration, kept in one place and applied by symlink.

Everything here is the real file; what lives in `$HOME` points back at it. Edit
in the repo, and the change is live - no copying step, no drift between the two.

## Applying it

```bash
./_setup.sh
```

Runs every domain. Name one or more to run just those, which is the quicker
loop when you have changed a single thing:

```bash
./_setup.sh claude
```

Setup is idempotent and quiet, so **a run that prints nothing found everything
already in place**. Output means something actually changed. It is safe to run
whenever; it repairs a missing or misdirected symlink rather than complaining.

## Layout

| Path | What it holds |
|---|---|
| `_setup.sh` | Entry point. Dispatches to the domains. |
| `_setup/` | One script per domain, plus `lib.sh`. |
| `bin/` | Commands, linked into `~/Bin` (already on `PATH`). |
| `config/` | Linked wholesale to `~/.config`. |
| `claude/` | Claude Code settings. |
| `pi/` | Pi agent config. |
| `zprofile` | Linked to `~/.zprofile`. |

## Domains

Each is a script in `_setup/`, runnable on its own:

- **`config`** - `~/.config`
- **`shell`** - `~/.zprofile`, and everything in `bin/`
- **`claude`** - Claude Code settings
- **`pi`** - Pi agent config

`_setup/lib.sh` holds `link_file`, the one helper every domain needs. A helper
used by a single domain belongs in that domain's script rather than here.

## Things that are not obvious

**`config/` is opt-in.** `.gitignore` ignores `config/*` and whitelists the
directories worth keeping. `~/.config` is one symlink to the whole directory,
so anything not whitelisted still works locally, it just isn't tracked.

**`~/.claude` and `~/.pi/agent` are linked file by file.** Both are mostly
session state, telemetry and caches. Only the portable files are tracked;
`auth.json`, `sessions/` and `npm/` stay machine-local.

**`claude-pick` switches Claude Code accounts by moving `CLAUDE_CONFIG_DIR`.**
Claude Code derives its Keychain item from a hash of that path, so pointing the
variable at `~/.claude-accounts/<id>` is the entire account switch - no logging
out, no credential shuffling, and the script only ever reads the Keychain.
Everything portable is symlinked from each account directory back into
`~/.claude`, so `CLAUDE.md`, agents, skills, commands, plugins, settings and
session transcripts are the same files whichever account is live; only identity
and machine state are per account. Accounts name themselves by the email they
are signed in as; the id you pass to `claude-pick add work` is only a handle,
and because it names the directory the Keychain item is keyed on, it must not
move once that account is signed in. `claude-pick link` re-applies the symlinks
after adding a new shared directory. The accounts themselves are machine-local
and untracked - this repo holds the command, not the logins.

**The notification sounds have an off switch outside the repo.** Two hooks
chime: `Submarine` when a permission prompt is waiting, `Glass` when a turn
ends. They sit in different frequency registers so they stay apart over music.
`touch ~/.claude/mute` silences both; delete the file to bring them back. It is
deliberately untracked - per-machine, per-mood state rather than configuration.

**Nothing is ever pruned.** Setup creates and repairs symlinks but never
removes them. Delete something from `bin/` and its link in `~/Bin` is left
dangling; clean it up by hand.

## Adding to it

- **A new command** - drop it in `bin/` and run `./_setup.sh shell`. The domain
  globs the directory, so there is no list to update.
- **A new domain** - add `_setup/<name>.sh`, source `lib.sh`, make it
  executable. `_setup.sh` finds it by globbing; nothing else needs editing.
- **A new config directory** - whitelist it in `.gitignore` under `config/`.

Shell scripts here should be `shellcheck`-clean, and start with
`set -euo pipefail` unless there is a reason not to. Check them with:

```bash
shellcheck -x -e SC1071 _setup.sh _setup/*.sh bin/*
```

`bin/claude-pick` is Python rather than shell - it needs JSON, HTTPS, Unicode
normalisation and a handful of concurrent requests, which is more than shell
should be asked to carry. `-e SC1071` is what stops `shellcheck` complaining
about its shebang.

## Keeping this current

This file is part of the repo, not a snapshot of it. When the layout changes,
a domain is added, or something acquires a non-obvious reason for being the way
it is, update the relevant section in the same commit. The sections above are
worth having only while they still describe what is actually here.
