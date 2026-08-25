# Dotfiles

macOS configuration, kept in one place and applied by symlink.

Everything here is the real file; what lives in `$HOME` points back at it. Edit
in the repo, and the change is live - no copying step, no drift between the two.
The exceptions are the two things macOS refuses to read through a symlink, and
both are noted below.

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
| `claude/` | Claude Code settings and the hands-free speech scripts. |
| `pi/` | Pi agent config. |
| `applescript/` | Sources for apps built at setup time. |
| `launchd/` | Launch agent templates. |
| `zprofile` | Linked to `~/.zprofile`. |

## Domains

Each is a script in `_setup/`, runnable on its own:

- **`config`** - `~/.config`
- **`shell`** - `~/.zprofile`, and everything in `bin/`
- **`claude`** - Claude Code settings, the speech scripts, the approve applet,
  and the launch agent that keeps the speaker daemon alive
- **`pi`** - Pi agent config

`_setup/lib.sh` holds `link_file`, the one helper every domain needs. A helper
used by a single domain lives in that domain's script instead - `install_agent`
and `build_applet` are only ever called by `claude`, so that is where they are.

## Things that are not obvious

**`config/` is opt-in.** `.gitignore` ignores `config/*` and whitelists the
directories worth keeping. `~/.config` is one symlink to the whole directory,
so anything not whitelisted still works locally, it just isn't tracked.

**`~/.claude` and `~/.pi/agent` are linked file by file.** Both are mostly
session state, telemetry and caches. Only the portable files are tracked;
`auth.json`, `sessions/` and `npm/` stay machine-local.

**Launch agents are copied, not linked.** launchd refuses to load a symlinked
plist - it fails with `Bootstrap failed: 5: Input/output error`. The templates
in `launchd/` use `__HOME__` in place of a hardcoded path and are rendered into
`~/Library/LaunchAgents` at setup. Because it is a copy, **editing the installed
file does nothing**: change the template and re-run setup.

**The approve applet is an app for a reason.** macOS grants Accessibility to
whatever sends a keystroke. Run through `/usr/bin/osascript` the grant would
have to go to `osascript` itself, which would let any script on the machine
type. Compiling to an app scopes the grant to that one job. It is rebuilt only
when its source changes, because a rebuild changes the signature and macOS then
reads it as a different app - **so a source change means re-granting
Accessibility**: remove the entry and add it back.

**Don't bind the applet to a shortcut containing Control.** Holding Control as
an AppleScript applet launches forces its Run/Quit startup screen, whatever
`OSAAppletShowStartupScreen` is set to. The script cannot suppress it, so the
binding has to avoid Control - which rules out the otherwise ideal `⌃⌥⌘` layer.

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
shellcheck -x _setup.sh _setup/*.sh bin/*
```

## Keeping this current

This file is part of the repo, not a snapshot of it. When the layout changes,
a domain is added, or something acquires a non-obvious reason for being the way
it is, update the relevant section in the same commit. The sections above are
worth having only while they still describe what is actually here.
