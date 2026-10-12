---
name: scouting-teepee
description: Tee-pee, the Slovenský skauting membership system at skauting.tee-pee.com - events, people, units, rosters and reports - driven in the browser. Use whenever a task touches tee-pee: a skauting.tee-pee.com URL, prihlásení, pozvaní, prezenčná listina, an event or podujatie id, a turnus roster, an oddiel or zbor, or registering people for a camp. Use it even when it sounds like a few manual clicks: tee-pee is a PrimeFaces app whose selection state, ViewState and person matching fail quietly.
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

Read the `browsing` skill first. Its rules hold here - never handle a credential, verify
every landing URL, re-query before acting, confirm the element you hit is the one that
acts, close the arithmetic after a write. This file is only what tee-pee adds.

The session drops without warning, and the approach may not keep it across a restart, so
expect to ask for a login more than once. A landing on `/login` means stop and ask Kubo to
log in to the automation browser. The session sometimes comes back on its own - a later
navigation lands on `/user/profile` instead - so re-test before you conclude you are
locked out.

## Site mechanics

Tee-pee is PrimeFaces on JSF. Four consequences apply on every page, and each of them
fails silently rather than loudly:

**One ajax request at a time.** Overlapping requests stale the JSF ViewState; the next one
returns 500 and whatever dialog you were in is gone, taking any pending state with it.
Serialise on both `jQuery.active` and `PrimeFaces.ajax.Queue.isEmpty()` - the queue matters
because a queued-but-unsent request leaves `jQuery.active` at zero.

**The DOM is replaced, not updated.** Any container an ajax call targets is detached and
rebuilt, so a node reference never survives a request and a `querySelector` landing
mid-update returns `null`. Re-query every time, and wait for the container to be back
before reading it.

**Search fields match substrings, across more than you expect.** The person search matches
nicknames and unit names as well as names, diacritics-insensitively. `Lup` returns
Lupták and Halupková; `Kométa` returns everyone in the unit of that name. A search
hit is never an identification on its own.

**People are stored `Surname Firstname [Middle]`.** Hand-kept lists say
`Firstname Lastname - Nickname`. Anything comparing the two needs normalising, and
diacritics are dropped on the way in often enough (`Kralik` for `Králik`, `Riecan` for
`Riečan`) that the comparison should ignore them.

## Writing to tee-pee

It is a shared org system other people read, so the `browsing` write rules apply in full.
What tee-pee adds: when a match is ambiguous, the question to Kubo carries the unit of
each candidate and who else from that unit is already involved. Without the unit, "which
Michal Dubovec" has no answer.

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
