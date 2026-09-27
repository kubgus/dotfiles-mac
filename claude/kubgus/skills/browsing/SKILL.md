---
name: browsing
description: Driving a real browser to do something on a website - clicking, filling forms, reading a page that will not come out any other way, or automating a site with no API. Use whenever a task means operating a site rather than fetching from it: "log into", "click through", "fill this form", "scrape", "check what that page says", "automate this site", "drive the browser", or any request that names a URL and an action to perform on it. Covers the approach-agnostic discipline and points at the specific approach to use. Not for fetching a document a plain HTTP request would return, and not for opening a local HTML file, both of which have cheaper answers.
---

# Browsing

Driving a browser is the most expensive way to get anything done and the easiest to get
subtly wrong, so the first question is whether it is needed at all.

## Before automating anything

In order, stop at the first that works:

1. **An MCP server for the service itself.** If one is connected, it is already
   authenticated, already structured, and its results do not depend on a layout. Check
   what is connected before assuming there is nothing.
2. **An API, a CLI or a feed.** Most sites worth automating have one, and it is faster,
   stabler and readable afterwards.
3. **A plain HTTP fetch.** If the content arrives in the HTML, a request beats a browser.
4. **Asking him to do it.** One manual click beats twenty minutes of automation that
   breaks next month. Say so when that is the honest answer.
5. **A browser**, when the site is a real application, the state lives behind a session,
   or the markup only exists after scripts run.

Say which rung you are on and why the ones above it failed. "There is no API" is a finding
and belongs in the answer, not an assumption to skip past silently.

## Approaches

| Approach | File | Use when |
|---|---|---|
| Playwright MCP | `approaches/playwright-mcp.md` | The default, and the only one wired up |

Read the approach file before the first navigation. The mechanics below hold whichever one
is in play; everything version-specific and tool-specific lives in the approach file.

## Holds everywhere

**Never handle a credential.** Landing on a login page is a full stop: say so and ask him
to log in himself. The session is his. Typing a password on his behalf is not a shortcut
worth taking, and no task is urgent enough to change that.

**Verify where you landed.** A navigation that returns without error still may not have
gone where you asked - an expired session redirects, a soft 404 renders a normal-looking
page. Read the resulting URL after every navigation rather than assuming it held.

**Never cache a node across an action.** Anything that re-renders detaches the element you
were holding, and a selector that ran mid-update returns nothing rather than failing.
Re-query immediately before you act.

**Confirm the element you hit is the one that acts.** Visible text often belongs to a
wrapper rather than the control inside it, so a click can land, report success and do
nothing at all. Check that the thing you clicked carries the behaviour.

**Waiting for a spinner to stop is not waiting for the work to finish.** Wait for the
specific thing you expect to change, and re-read it. Anything else double-counts rows,
reads the previous page, or acts on state that is about to be replaced.

## Writing to a site

A write into someone else's system usually has no undo beyond doing the inverse by hand,
so it earns more care than a read.

- **Act only where the match is unambiguous.** Where it is not, ask with the candidates
  and enough context to choose between them. Guessing a near-match to avoid a question is
  the one thing not to do.
- **Close the arithmetic at the end.** `input = written + already there + skipped`, with
  every skipped item named. A count that closes is the only cheap proof that nothing was
  dropped on the way.
- **Dry-run first where the site allows it**, and say what you are about to do before you
  do it in bulk. A loop that runs twice because the first pass looked like it failed is
  the classic way to double-register a roster.
