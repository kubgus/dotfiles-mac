---
name: scouting-teepee
description: Working with tee-pee, the Slovenský skauting membership system at skauting.tee-pee.com - events, people, units, rosters and reports - by driving it in the browser. Use this whenever a task touches tee-pee at all: any skauting.tee-pee.com URL, or talk of prihlásení, pozvaní, prezenčná listina, an event or podujatie id, a turnus roster, an oddiel or zbor, or registering people for a camp. Use it even when the request sounds like a couple of manual clicks, because tee-pee is a PrimeFaces app whose selection state, ViewState and person matching all fail quietly rather than loudly. Read this for access and site-wide mechanics, then the reference file for the specific area.
---

# Tee-pee

Tee-pee (`https://skauting.tee-pee.com`) is Slovenský skauting's membership and event
system. This skill covers driving it through the browser, since there is no public API.

It grows one area at a time. Read this file for access and the mechanics that hold
everywhere, then the reference file for the area you are in.

| Area | Reference | Covers |
|---|---|---|
| Events > Create | `references/events-create.md` + `scripts/events-create.js` | Making a new event: the form, Kubo's conventions for Typ and Kategória, draft against publish |
| Events > Attendees | `references/events-attendees.md` | Putting a list of names onto an event's Prihlásení tab: roster, name resolution, disambiguation, commit, verification |

Nothing else is covered yet. A task outside the table is not a reason to stop - drive it
by hand with the mechanics below - but say that the skill does not cover it rather than
implying it does, and it is worth writing up afterwards.

## Access

Requires the Playwright MCP (`mcp__plugin_kubgus_playwright__*`) and a tee-pee session
already authenticated in that browser.

**Never handle the password.** If a navigation lands on `/login`, stop and ask Kubo to log
in to the automation browser himself. The session is his; typing a credential on his
behalf is not a shortcut worth taking.

Sessions drop without warning and a stale one redirects mid-task, so check the landing URL
after every navigation rather than assuming it held. It sometimes comes back on its own -
a later navigation lands on `/user/profile` instead of `/login` - so re-test before
concluding you are locked out.

## Site mechanics

Tee-pee is PrimeFaces on JSF. Five consequences apply on every page, and each of them
fails silently rather than loudly:

**One ajax request at a time.** Overlapping requests stale the JSF ViewState; the next one
returns 500 and whatever dialog you were in is gone, taking any pending state with it.
Serialise on both `jQuery.active` and `PrimeFaces.ajax.Queue.isEmpty()` - the queue matters
because a queued-but-unsent request leaves `jQuery.active` at zero.

**The DOM is replaced, not updated.** Any container an ajax call targets is detached and
rebuilt, so a node reference never survives a request and a `querySelector` landing
mid-update returns `null`. Re-query every time, and wait for the container to be back
before reading it.

**Visible text often belongs to a wrapper, not the control.** The attendee dialog's submit
is the clearest case: `[id$="addButtonId"]` is a `<div>` whose `innerText` reads
`Pridať (61)`, while the button that actually submits is `[id$="addPeopleBtnId"]` inside
it. Clicking the wrapper looks like it worked and does nothing. Before trusting a click,
confirm the element you hit carries the handler.

**Search fields match substrings, across more than you expect.** The person search matches
nicknames and unit names as well as names, diacritics-insensitively. `Lup` returns
Lupták and Halupková; `Kométa` returns everyone in the unit of that name. A search
hit is never an identification on its own.

**People are stored `Surname Firstname [Middle]`.** Hand-kept lists say
`Firstname Lastname - Nickname`. Anything comparing the two needs normalising, and
diacritics are dropped on the way in often enough (`Kralik` for `Králik`, `Riecan` for
`Riečan`) that the comparison should ignore them.

## Writing to tee-pee

It is a shared org system other people read, and most of its writes have no undo beyond
doing the inverse by hand. Two habits, both learned the expensive way:

- **Act only where the match is unambiguous.** Where it is not, ask Kubo with the
  candidates and enough context to answer - the unit each candidate belongs to, and who
  else from that unit is already involved. Guessing a near-match to avoid a question is
  the one thing not to do.
- **Close the arithmetic at the end.** `input = written + already there + skipped`, every
  skipped item named and explained. A count that closes is the only cheap proof nothing
  was silently dropped.

## Finding your way around

Anchors that hold across pages, for an area not yet covered above:

| Thing | Selector |
|---|---|
| Tab links | `a[href*="TabId"]`, e.g. `a[href$="attendeesTabId"]` |
| List rows in a dialog | `.ui-panel`, name in `.BoldGray`, unit in `.ListItemDesc` |
| List rows in a datagrid | `.ui-datagrid-column .ui-panel`, name in `.ListItemName` |
| Paginated grid | `PF('<widgetName>').getPaginator()`, with `cfg.rowCount` and `cfg.pageCount` |
| Person detail link | `a[href^="/persons/"]` |
| Autocomplete | `#<name>_input` visible, `#<name>_hinput` hidden and authoritative |
| Dropdown | `#<name>_input` native `<select>`, `#<name>` the styled widget |

The widget name for a `PF()` lookup is in the `data-widget` attribute on the component, or
in the inline `PrimeFaces.ab({...})` handler of anything that refreshes it.

Ids come in two flavours and the difference matters. Readable ones (`eventNameId`,
`orgUnitComboId_input`) are authored and stable enough to hardcode. Generated ones
(`j_idt112`, `j_idt47_input`) shift whenever the page changes, so match those elements by
their label or button text instead.

A datagrid paginator turns pages with `setPage(i)`, but the grid can still show the
previous page when the ajax goes quiet. Wait for the content to actually change before
reading it, or you will double-count a row.
