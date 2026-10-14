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
| `CLAUDE.md` | Context for an agent working in this repo - the rules, not the reasons. |
| `_setup/` | One script per domain, plus `lib.sh`. |
| `bin/` | Commands, linked into `~/Bin` (already on `PATH`). |
| `config/` | Linked wholesale to `~/.config`. |
| `claude/` | Claude Code: the operator context (`operator.md`) and the status line. |
| `claude/kubgus/` | The `kubgus` plugin - output style, skills, hooks, MCP servers. |
| `pi/` | Pi agent config. |
| `zprofile` | Linked to `~/.zprofile`. |

## Domains

Each is a script in `_setup/`, runnable on its own:

- **`config`** - `~/.config`
- **`shell`** - `~/.zprofile`, and everything in `bin/`
- **`claude`** - Claude Code status line
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

**`settings.json` is deliberately not tracked.** Claude Code owns that file and
rewrites it in place - `/config`, `/model`, `/effort` and `/output-style` all write
to it, and an atomic write replaces a symlink with a real file rather than following
it. Tracking it cost a `clean` filter to hide the session state, a `.gitattributes`
entry, per-clone filter registration because git will not read filter definitions
out of the repository that ships them, and a link that broke silently every time
`/config` ran - after which the repo and the live file drifted with nothing to
signal it. That drift is what the filter was really hiding.

The settings are a handful of preferences and a few clicks to restore, so the repo
stopped having an opinion about them. What is worth keeping - the context file, the
status line script and the plugin - is linked individually, and Claude Code writes
to none of it.

**`claudeswitch` switches Claude Code accounts by moving `CLAUDE_CONFIG_DIR`.**
Claude Code derives its Keychain item from a hash of that path, so pointing the
variable at `~/.claude-accounts/<email>` is the entire account switch - no
logging out, no credential shuffling, and the script only ever reads the
Keychain. An account is named by its email and nothing else: the directory *is*
the address, the account list *is* what is in `~/.claude-accounts/`, and the
name on screen is read live from the account's own `.claude.json`, so there is
no second name to keep in step. `claudeswitch add kubo@example.com` creates one
and signs it in - the address has to be known up front, because renaming the
directory afterwards would orphan the credentials keyed on it. The accounts
are machine-local and untracked; this repo holds the command, not the logins.
The status line names the live account by the initials of its display name, and
reads `CLAUDE_CONFIG_DIR` to find it exactly as `claudeswitch` sets it, so the
two cannot drift apart.

**The switch is meant not to be felt, which is a denylist, not an allowlist.**
Every entry in `~/.claude` is symlinked into each account except the few that
cannot be shared, so transcripts, prompt history, file history, agents, skills,
plugins, running sessions and background jobs are one set of files - and
whatever a future Claude Code writes there is shared too, without
`claudeswitch` needing to be taught about it. What stays per account: `daemon*`
(a lock naming a live process, one per config dir), `policy-limits.json` and
`remote-settings.json` (fetched from whichever org the account is in),
`telemetry/`, `ide/` and `backups/`. The linking runs before every launch, so
there is nothing to remember; `claudeswitch link` just does it on demand.
`~/.claude.json` is the exception that cannot be symlinked, holding identity
next to every preference - it is merged key by key instead, pulled in before a
session and pushed back after, with `oauthAccount` and the org-scoped caches
left where they are. Two accounts running at once means last writer wins, which
is already true of that file between concurrent sessions of one account.

**The notification sounds have an off switch outside the repo.** Two hooks
chime: `Submarine` when a permission prompt is waiting, `Glass` when a turn
ends. They sit in different frequency registers so they stay apart over music.
`touch ~/.claude/mute` silences both; delete the file to bring them back. It is
deliberately untracked - per-machine, per-mood state rather than configuration.
They are plugin hooks now rather than `settings.json` hooks, so they play only
in kubgus mode. Plugin hooks and settings hooks both fire for
the same event, which is why the settings copies had to go: two definitions
meant every sound played twice.

**Everything personal is opt-in per session.** A session starts clean: no
`operator.md`, no `kubgus` plugin, no claude.ai connectors. Tab, `→` or `l`
(Shift-Tab, `←` or `h` back) in the `claudeswitch` picker cycles the mode for
that one launch:

- **clean** sets `ENABLE_CLAUDEAI_MCP_SERVERS=false` and nothing else.
- **kubgus** adds `--plugin-dir claude/kubgus`, `--append-system-prompt-file
  claude/operator.md` and `--settings` naming the output style, and leaves the
  connectors on.
- **caveman** is clean plus `--plugin-dir ~/Sources/caveman`, a clone of
  [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) pinned by
  hand like the MCP servers there. It is exclusive of kubgus because both
  shape the reply. Its hooks write state to `~/.claude/.caveman-*` and read
  `~/.config/caveman`, which `.gitignore` already leaves untracked.

The reason is context cost. The operator context, the output style, every skill
description and every connector's tool names ride in every turn of every
session, and most sessions use none of them. Plain `claude`, outside
`claudeswitch`, is clean too, except that it keeps the connectors.

Three things follow from it:

- **`outputStyle` is not in `settings.json`.** The style lives in the plugin, so
  a clean session would name a style that does not exist. The flag sets it
  only when the plugin is there.
- **`operator.md` goes into the system prompt, not `~/.claude/CLAUDE.md`.** A
  plugin cannot carry a context file. A plugin `SessionStart` hook could print
  it - caveman works that way - but the system prompt is the stronger slot and
  needs no hook.
- **Figma is off in every mode.** The Figma plugin stays installed but disabled
  in `settings.json`; its skill descriptions and server cost context in sessions
  that never touch a design. Enable it in `/plugin` for the work that needs it,
  and disable it again after - that toggle is global, not per session.

**The plugin is read in place, not installed.** `--plugin-dir` loads the
directory as it is, so an edit here is live in the next session with no
install, no version bump and no cache. Installing it from a marketplace
instead - which is the obvious-looking route - copies the plugin into
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` and then reads only
that copy. `install` and `update` both no-op on an unchanged version, so edits
stay invisible with no warning that they are being ignored.

**Nothing is ever pruned.** Setup creates and repairs symlinks but never
removes them. Delete something from `bin/` and its link in `~/Bin` is left
dangling; clean it up by hand.

## Adding to it

- **A new command** - drop it in `bin/` and run `./_setup.sh shell`. The domain
  globs the directory, so there is no list to update.
- **A new domain** - add `_setup/<name>.sh`, source `lib.sh`, make it
  executable. `_setup.sh` finds it by globbing; nothing else needs editing.
- **A new config directory** - whitelist it in `.gitignore` under `config/`.
- **A new skill, or an edit to the plugin** - work directly in
  `claude/kubgus/`. It is read in place, so there is nothing to reinstall.

Shell scripts here should be `shellcheck`-clean, and start with
`set -euo pipefail` unless there is a reason not to. Check them with:

```bash
shellcheck -x -e SC1071 _setup.sh _setup/*.sh claude/*.sh \
    claude/kubgus/hooks-handlers/*.sh bin/*
```

`bin/claudeswitch` is Python rather than shell - it needs JSON, HTTPS, Unicode
normalisation and a handful of concurrent requests, which is more than shell
should be asked to carry. `-e SC1071` is what stops `shellcheck` complaining
about its shebang.

## Keeping this current

This file is part of the repo, not a snapshot of it. When the layout changes,
a domain is added, or something acquires a non-obvious reason for being the way
it is, update the relevant section in the same commit. The sections above are
worth having only while they still describe what is actually here.
