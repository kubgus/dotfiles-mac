---
name: shell-scripts
description: Conventions for writing, reviewing or fixing a shell script for Kubo - bash or zsh, a one-off, a dotfiles helper, or anything that ends up on his PATH. Use when asked to "write a script", "make this a script", "add a command", "automate this", "wrap this in a shell script", "fix this bash", or when editing any .sh file. Covers strict mode, shellcheck, symlink-safe path resolution and macOS/Linux portability.
---

# Shell scripts

## Always

- `set -euo pipefail`, immediately after the header comment.
- `shellcheck`-clean. Every disable is inline and says why: `# shellcheck disable=SC2034`.
- Quote everything - `"$var"`, and `"${var:-}"` when it may be unset. `local` at the top
  of a function.
- Quiet on success. A script that prints nothing found nothing to do.
- `--help` lists the real flags, not a summary of them.
- A header comment saying why the file exists, in prose.

Two standing exceptions to strict mode, both stated in a comment where they apply:

| Case | Use | Why |
|---|---|---|
| Hook handler | `set -uo pipefail` | It must never fail the tool call that invoked it. |
| `/bin/sh` script | `set -eu` | `pipefail` is not POSIX. |
| Sourced library | none | Shell options set in a sourced file change the caller. |

## Anchoring paths

Scripts get symlinked onto `PATH`. Resolve the whole chain before anchoring anything, and
never rely on the working directory. `readlink -f` and `realpath` are GNU-only:

    _src="${BASH_SOURCE[0]}"
    while [ -L "$_src" ]; do
        _dir="$(cd -P "$(dirname "$_src")" && pwd)"
        _src="$(readlink "$_src")"
        case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    done
    ROOT="$(cd -P "$(dirname "$_src")" && pwd)"
    unset _src _dir

## Portability

macOS and Linux are both first-class. BSD against GNU is where it actually breaks:

| Trap | What bites |
|---|---|
| `sed -i` | BSD requires an argument: `sed -i ''`. Write through a temp file instead. |
| `readlink -f`, `realpath` | GNU-only. Walk the chain, as above. |
| `date`, `stat`, `mktemp` | Different flags entirely. Check before reaching for one. |
| `timeout(1)` | Does not exist on macOS. |
| `grep -P` | Not in BSD grep. |

## Idempotency

Compare, act, print - and only on a difference. A second run says nothing.

    set_thing() {
        local key="$1" want="$2" have
        have="$(read_current "$key" || true)"
        [ "$have" = "$want" ] && return 0
        echo "Setting $key -> $want"
        write_it "$key" "$want"
    }
