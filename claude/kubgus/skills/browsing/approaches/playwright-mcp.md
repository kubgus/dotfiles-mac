# Approach: Playwright MCP

The default approach, and the only one currently wired up. Tools are the
`mcp__plugin_kubgus_playwright__*` set - `browser_navigate`, `browser_snapshot`,
`browser_click`, `browser_evaluate` and the rest.

Everything below was read off `--help` of the pinned server rather than remembered.
Re-check it when the server moves: flags are added and defaults change between releases,
and a flag that quietly does nothing looks exactly like a flag that worked.

## First run of a fresh profile

A fresh Chromium profile raises a **macOS keychain prompt** on first launch and blocks
until it is answered. Launched in the background it looks like a hang, because the dialog
is behind whatever window has focus. `--use-mock-keychain` suppresses it, which is the
right answer for automation that stores nothing worth keychain protection.

## Local files are blocked by default, and the default is narrow

`browser_navigate` refuses `file://` URLs out of the box. It is not a hard restriction:
the server confines file access to its **workspace roots, or its working directory when
no roots are configured**, and `--allow-unrestricted-file-access` lifts both that and the
`file://` block together.

This bites harder than it reads, because the server is launched with its working directory
set to a scratch directory rather than to a project. The effective workspace root is that
scratch directory, so nothing in any real project is reachable even before the `file://`
rule applies. A page written into a project and opened for a look is therefore **out of
reach through this approach as configured** - which is worth knowing up front, since that
is exactly what a locally built HTML deliverable is.

Two honest ways out, in order:

1. **Open it yourself.** Hand over the path and let him open it. For a page built to be
   looked at, that was the plan anyway.
2. **Drive Playwright directly** from a script rather than through the MCP, where none of
   this sandbox applies. See below.

## Sessions do not survive a restart as configured

`--isolated` keeps the browser profile in memory and never writes it to disk, so every
login dies with the server. Anything that assumes a site is still authenticated from an
earlier session is assuming something this configuration does not provide.

If a site needs a login to persist, the flags that do it are `--user-data-dir` for a real
profile on disk and `--storage-state` for a saved session under `--isolated`. Both are
configuration changes to his machine, so name them and let him decide rather than
proposing a run with different flags as if it were free.

## Dropping to raw Playwright

The MCP is a convenience layer over a library that is fully available on its own. When the
layer is the thing in the way - the `file://` sandbox above is the usual reason - write a
short script against Playwright directly and run it. Nothing is lost but the snapshot
formatting.

Do not reach for **headless Chrome's `--dump-dom`** as the lightweight alternative. It has
been observed hanging on every invocation and producing no output at all, with no error to
explain it. Time spent debugging that is time not spent on the task; driving Playwright
directly is the path that works.

## Timing

The server settles for **500ms after each action** by default before returning, which is
generous for a static page and nowhere near enough for an application that fires its own
requests afterwards. `--timeout-settle` moves it, but raising a global timeout to fix one
slow page is a blunt instrument: prefer waiting for the specific thing you expect to
change, as the skill's general rules say.

Navigation allows 60s and an action 5s by default. An action timing out at 5s usually
means the element was not ready rather than that the site is slow, so re-read the page
before reaching for a bigger number.
