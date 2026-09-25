---
name: shell-scripts
description: Conventions for writing, reviewing or fixing a shell script for Kubo - bash or zsh, a one-off, a dotfiles helper, or anything that ends up on his PATH. Use when asked to "write a script", "make this a script", "add a command", "automate this", "wrap this in a shell script", "fix this bash", or when editing any .sh file. Covers strict mode, shellcheck, symlink-safe path resolution and macOS/Linux portability.
---

# Shell scripts

- **`set -euo pipefail`** immediately after the header comment, unless there is a stated
  reason not to - and state it in a comment when you deviate. A hook handler is the usual
  exception, because it must never fail the tool call that invoked it.
- **`shellcheck`-clean is the bar, not the aspiration.** Any disable is inline and carries
  a comment saying why (`# shellcheck disable=SC2034`, `# shellcheck source=...`).
- **He symlinks scripts onto PATH** - `~/Bin` holds links into several repos. Resolve
  `BASH_SOURCE` through its full symlink chain before anchoring any path, and never rely
  on the current working directory.
- **macOS and Linux are both first-class.** BSD against GNU divergence is where
  portability actually breaks: `sed -i`, `date`, `stat`, `readlink`, `mktemp`. There is no
  `timeout(1)` on macOS. Test the assumption or avoid the tool.
- **Quote everything**: `"$var"`, `"${var:-}"` for possibly-unset. `local` declarations at
  the top of a function.
- **A `--help` that lists the real flags**, and quiet on success - a script that prints
  nothing found nothing to do.
- **Idempotency is compare-then-act**: check the current state, act only on a difference,
  print only when something changed.

## House style already in the repo

Match these rather than inventing a dialect:

- `~/Dotfiles/_setup/lib.sh` - the `link_file` helper, and how repo root is resolved.
- `~/Dotfiles/_setup/claude.sh` - a domain script, and `set_git_config` as the template
  for non-symlink idempotency.
- `~/Dotfiles/claude/bell.sh` - a hook handler, and why it deviates from strict mode.
- `~/Dotfiles/bin/clc` - the larger end, Bash 3.2 compatible on purpose.

Shell scripts in `~/Dotfiles` are checked with:

```sh
shellcheck -x -e SC1071 _setup.sh _setup/*.sh claude/*.sh bin/*
```
