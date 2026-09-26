# Events > Attendees

Putting a list of names onto an event's **Prihlásení** tab at
`https://skauting.tee-pee.com/events/<id>/details`. Where the list came from is the
caller's problem - a sheet, a CSV, a message - and by the time this starts it exists.

Read `SKILL.md` first for access and the site-wide mechanics; this file only covers what
is specific to attendees.

## What actually goes wrong

Not the clicking. The list and the directory disagree about names. Diacritics get dropped
on the way in (`Kralik` for `Králik`, `Riecan` for `Riečan`). First names arrive as
diminutives (`Zuzka` for `Zuzana`, `Katka` for `Katarína Mária`). And with ~14,000 people
in the directory, full names collide outright: two Michal Dubovecs, two Peter Rybárs, two
Juraj Studenýs.

## Read the roster first

The dialog hides people who are already attendees. That quietly corrupts matching in two
directions, so `roster()` comes before anything else and the already-present names get
subtracted from the input list:

- An existing attendee comes back `NO_MATCH`, which reads as "not in tee-pee" when they
  are in fact already done.
- Worse, a name with two directory hits can come back as a clean `MATCH` once the right
  one has been hidden - leaving the wrong twin looking unambiguous. A real run left two
  Michal Dubovecs ambiguous on the first pass; re-running afterwards matched `Dubovec
  Michal | Rysy` with full confidence, because the correct `Dubovec Michal | Sovy` was
  already an attendee and no longer on offer.

Subtract on the name alone. Roster units carry the parent unit too (`Sovy (7. oddiel
Kométa)`) while dialog units do not (`Sovy`), so they will not compare directly. If a
subtracted name is one you know has directory twins, say so rather than assuming the
roster holds the right one.

## Nicknames are the tie-breaker

Scout lists carry nicknames (`Adam Tomáš Rybár - Kaktus`) and the dialog does not show
them - but it does search them, and returns the person under their full name and primary
unit. That is exactly the second opinion an ambiguous surname needs: `Rybár` returns three
people, `Kaktus` returns one of them.

The driver does this automatically whenever a name fails to resolve and the input carried
a nickname, so pass names through with the nickname attached rather than stripping it
first. A hit is reported as `MATCH_BY_NICKNAME` with `via: "nickname Kaktus"`.

It only ever **intersects** the two result sets, and that restraint is the whole trick.
Because the field matches substrings of surnames and unit names too, a nickname alone is
unsafe: `Lup` pulls in Lupták, Lupčo and Halupková, and `Kométa` pulls in every member of
the unit called Kométa alongside the one person nicknamed that. Only the candidate both
queries agree on is trustworthy. When they agree on nobody the driver says nothing rather
than guessing - which is the right answer when the real person is already an attendee and
therefore hidden.

## The flow

1. **Navigate** to `https://skauting.tee-pee.com/events/<id>/details`. Confirm the page
   loaded and you are not at `/login`.
2. **Inject the driver.** Read `scripts/events-attendees.js` and pass its contents as the
   `function` argument of `browser_evaluate`. It installs `window.__teepee`.
3. **`__teepee.roster()`** - who is already on. It returns `ok: false` if the collected
   count disagrees with the grid's own total, which means a page did not turn in time;
   retry before trusting it. Subtract these names from the input list.
4. **`__teepee.open()`** - opens the Prihlásení tab and the add-people dialog.
5. **`__teepee.selectAuto(names)`** in batches of about 20. Each batch returns
   `selectedNow` and an `unresolved` list. Batching is not cosmetic: if a batch dies you
   lose twenty names of progress, not all of them.
6. **`__teepee.commit()`**, then re-read the tab label to confirm the count moved.
7. **Ask Kubo about everything unresolved**, through `AskUserQuestion`, one question per
   person, with each candidate's unit in the option description. The unit is what makes
   the choice answerable - "which Michal Dubovec" is unanswerable, "Sovy or Rysy, and
   these five other Sovy members are already on the event" is not.
8. **Re-open the dialog, `__teepee.selectExact(targets)`, commit again.** The page
   navigated in step 6, so `window.__teepee` is gone; re-inject it.
9. **Report** the arithmetic (below).

## Driver API

Everything is diacritics-insensitive and every returned `unit` is the directory's own
spelling, safe to pass straight back in.

| Call | Does |
|---|---|
| `roster()` | Who is already on the event, paginated and deduped, with a count check |
| `open()` | Prihlásení tab, then the add-people dialog |
| `resolve(names)` | Read-only. What the directory holds for each name, nothing clicked |
| `selectAuto(names)` | Selects where exactly one person matches, falling back to the nickname cross-check; returns the rest untouched |
| `selectExact(targets)` | Selects `[{name, unit}]` verbatim, after a human has chosen |
| `count()` | How many are currently selected |
| `commit()` | Submits. Navigates the page and destroys `window.__teepee` |

`resolve` is there for when the picture matters before anything is touched - a first run
against an unfamiliar list, or when Kubo asks what the matches look like. Default to
`selectAuto`; a dry run doubles the searches for no gain once the flow is trusted.

Statuses in an `unresolved` entry:

| Status | Means | Do |
|---|---|---|
| `AMBIGUOUS` | Several people share the exact name, and no nickname settled it | Ask, offering the units |
| `NO_MATCH` | Nothing matched exactly | Read `candidates`. One entry sharing the surname is almost always a diminutive or a dropped middle name - confirm it, do not assume it. Zero candidates usually means they are already an attendee, which `roster()` should already have caught |
| `TRUNCATED` | Over 100 hits, the match may be off-page | Re-query with `selectExact` and a narrower `query` |
| `CLICK_FAILED` | The row was found but the selection count did not move | Retry once, then report it |

## Traps

On top of the site-wide ones in `SKILL.md`:

| Trap | What to do |
|---|---|
| `[id$="addButtonId"]` is a wrapper `<div>`, not the button | Submit is `[id$="addPeopleBtnId"]`. The div's `innerText` still reads `Pridať (61)`, so a click on it looks like it worked and silently does nothing |
| Committing navigates the page | `browser_evaluate` reports a destroyed execution context. That is success. Re-read the tab label to confirm, and re-inject the driver before touching the dialog again |
| Reloading clears the selection | Select and commit within one page life. Never reload to "check on" a pending selection |
| Already-added and already-selected people vanish from the dialog | Subtract `roster()` from the input first; otherwise existing attendees read as `NO_MATCH` and their ambiguous twins read as confident matches |
| A full-name query matches any token | `adam kral` returns 537 people. The driver searches the surname alone on purpose |
| The dialog list caps at 100 rows | The header's own total is the truth. Over 100 hits, the match may be off-page - that is what `TRUNCATED` means |

## Reporting

End with arithmetic that closes:

    input names = committed + already on the event + skipped

State every skipped name and why. If the source list carried a distinction tee-pee has no
field for - participant against volunteer, `U` against `Dobroš` - say so plainly rather
than letting it disappear; everyone on the event now looks identical.

## Threat model

Trusts two things: the name list it is handed, and the session already open in the
browser. It authenticates nothing and touches no credential. Its only write is adding
existing directory people to an event - it creates no person records and edits nobody's
data - so the realistic failure is a wrong but real person added to a real event, which
is exactly what the ask-on-ambiguity rule exists to prevent.
