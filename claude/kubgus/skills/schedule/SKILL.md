---
name: schedule
description: Read what Kubo has committed to - events on his macOS Calendar, tasks in his macOS Reminders, or both at once. Use this whenever a question touches what he is doing, attending, owes or has agreed to: "what do I have today", "am I free Thursday afternoon", "what's on my plate", "what do I need to do", "what's overdue", "am I forgetting anything", "when is the next Družinovka", "who accepted that invite", "what clashes on Saturday", "what did I get done this week", "co mam dnes", "co mam spravit", "kedy mam cas", "na co som zabudol", or a bare `ical://`, `x-apple-calevent://` or `x-apple-reminderkit://` link pasted with no explanation. Use it for any planning question that needs to know what he is already committed to, and use it even when one glance at Calendar.app or Reminders.app looks like it would answer - both stores keep things two or three times over, both store all-day dates in a different convention from timed ones, and reading either by eye or by hand-written SQL is where this goes wrong, not the querying. Read-only. Not for creating, editing or completing anything.
---

# Schedule

Two macOS stores, one question: what has he already committed to. Events live in
Calendar, tasks live in Reminders, and a planning question often wants both.

| Store | Script | Reference | Answers |
|---|---|---|---|
| Calendar | `scripts/cal.py` | `references/calendar.md` | What is on, when he is free, what clashes, who accepted |
| Reminders | `scripts/rem.py` | `references/reminders.md` | What is due, what is overdue, what is open, what got done |

Read the reference for the store you are querying before you query it. Each one covers
its schema, its traps and its command surface. What follows holds for both.

**A question about his day usually wants both.** "What is on my plate Thursday" is an
agenda and a due list; answering with one and calling it the answer is the common
failure here. Run both, and say which store each line came from only where it is not
obvious.

## Both stores read the same way

Neither script uses EventKit or AppleScript. Each opens the live store `mode=ro`, takes
an atomic SQLite backup into a private temp directory, reads the copy and deletes it on
the way out. So neither races the app that owns the file, neither trips an Automation
prompt, neither leaves anything on disk, and neither can write even with a bug in it -
the source handle refuses writes at the SQLite level rather than by convention.

`when` takes the same vocabulary on both: `today`, `tomorrow`, `yesterday`, `week`,
`next-week`, `last-week`, `month`, `2026-10-03`, `2026-10-01..2026-10-07`, `+14d`,
`-30d`, and mixed ranges like `today..+14d`. Flags work on either side of the
subcommand, and `--json` and `--config PATH` exist on both.

## Both stores share one trap

**Two timestamp conventions in the same column.** Every date in both stores is seconds
from 2001-01-01, but a timed thing is a real UTC instant while an all-day thing is naive
wall clock - the literal number for midnight on that date. Convert the second one to
local time and you shift it by the UTC offset, landing it on the wrong day and always in
the same direction.

Both scripts already handle it. It matters here because it is the failure you would
reintroduce the moment you query either store directly, and because it is silent - the
answer is plausible, just a day out. Each reference says what its store does about it,
and they differ: one has a cache of real instants to fall back on and the other has
nothing.

## Reporting back

**Relay the lines.** Both scripts already print the shape he wants, grouped under day or
list headings. Pass that through rather than rebuilding it as prose with bold headers
and a paragraph per day.

**Do not interpret the answer.** No "the cleanest option", no "the most urgent is", no
ranking, no advice about what to do first or what to put where, no observing that
something has been open a long time. A free slot and a due date are facts; what to do
with them is his call, and he makes it faster from a list than from a recommendation.

**Trust notes are the exception, and they earn a line each**, because they are about
whether the answer is the whole answer rather than about what to do with it. Both scripts
print a staleness note when a store has not been written in over twelve hours - if the
owning app has not run, something he changed on his phone an hour ago is simply not here
yet. Each store has one of its own besides - the count of occurrences that came from rule expansion, and the
count of open reminders carrying no due date. Pass all of them on as printed.

## Looking one thing up

Hand a pasted link straight to `cal.py event` or `rem.py show`. Both pull the id out of
any link form, a raw UUID, or a foreign id, so there is no parsing to do first.

**A single lookup deliberately ignores the filters** in both stores. He named this thing,
so it shows whatever calendar or list it lives on and whatever its status is, including
completed. A lookup is not an agenda and must not come back empty because of a hidden
list or a free/busy flag.

## What gets hidden

Neither script has opinions of its own. Every judgement about what counts as noise lives
in the config file beside it - `calendar.config.toml` and `reminders.config.toml` - which
are the parts of this skill allowed to be personal. Each reference lists its keys.

**A filtered row is a decision he already made.** Do not run a second pass with the
filters off to find what was hidden, do not list the hidden things as though they might
really count, and do not caveat an answer with what is nominally sitting in it. The
widening flags are for a different question, asked deliberately, not a safety net.

## Writing

There is none, by design, on either store. If he wants an event created or a reminder
completed, say so and let him do it in the app or with Siri. A write path would need
Automation access and could race the sync engine; on Reminders in particular, completing
a recurring item is a server-side operation that materialises the next instance, and
faking it in SQL would corrupt the series.

He has said a write path is likelier on Reminders than on Calendar. When it happens it
goes through AppleScript or the `reminders` CLI as a separate command, never as SQL
against either store, and the read paths stay exactly as they are.
