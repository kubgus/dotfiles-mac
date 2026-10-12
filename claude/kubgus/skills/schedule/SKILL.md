---
name: schedule
description: Read what Kubo has committed to - events on his macOS Calendar, tasks in his macOS Reminders, or both at once. Use this whenever a question touches what he is doing, attending, owes or has agreed to: "what do I have today", "am I free Thursday afternoon", "what's on my plate", "what do I need to do", "what's overdue", "am I forgetting anything", "when is the next Družinovka", "who accepted that invite", "what clashes on Saturday", "what did I get done this week", "co mam dnes", "co mam spravit", "kedy mam cas", "na co som zabudol", or a bare `ical://`, `x-apple-calevent://` or `x-apple-reminderkit://` link pasted with no explanation. Use it for any planning question that needs to know what he is already committed to, and use it even when one glance at Calendar.app or Reminders.app looks like it would answer - both stores keep things two or three times over, both store all-day dates in a different convention from timed ones, and reading either by eye or by hand-written SQL is where this goes wrong, not the querying. Read-only. Not for creating, editing or completing anything.
---

# Schedule

Two macOS stores, one question: what has he already committed to. Events live in
Calendar, tasks live in Reminders.

**A question about his day usually wants both.** "What is on my plate Thursday" is an
agenda and a due list; answering with one and calling it the answer is the common
failure here. Run both, and say which store each line came from only where it is not
obvious.

## Commands

```
scripts/cal.py agenda [when]                 what is on            (default today)
scripts/cal.py free [when] [--between HH:MM-HH:MM] [--min 30]
scripts/cal.py conflicts [when]              overlapping commitments
scripts/cal.py search <text> [--range when]  title, notes, location, attendees
scripts/cal.py event <link or id>            one event in full
scripts/cal.py calendars                     what exists, what is hidden

scripts/rem.py due [when]           what is due, overdue on top   (default today)
scripts/rem.py open [--undated]     everything open, grouped by list
scripts/rem.py search <text>        title, notes, list, tag       (--done widens it)
scripts/rem.py show <link or id>    one reminder in full
scripts/rem.py done [when]          what was completed, and when  (default last 7 days)
scripts/rem.py lists                lists and groups, marking hidden ones
```

`when`: `today`, `tomorrow`, `yesterday`, `week`, `next-week`, `last-week`, `month`,
`2026-10-03`, `2026-10-01..2026-10-07`, `+14d`, `-30d`, and mixed ranges like
`today..+14d`. `rem.py` also takes `all`. Flags work on either side of the subcommand;
`--json` and `--config PATH` exist on both.

- **Calendar**: `--calendar Skyro` (repeatable, substring), `--all` (drop the calendar
  filter), `--show-free`, `--show-declined`, `--no-dedupe`. `event --open` reveals it in
  Calendar.app - only when he asks, it steals focus.
- **Reminders**: `--list Frontline` (repeatable, substring, matches groups too), `--all`
  (drop the list filter), `--flat` (subtasks on their own lines), `--store PATH`.
  `show --open` is best effort and steals focus - only when he asks.

**Never query either store with your own SQL.** Both keep one thing two to five times
over, and both mix real UTC instants with naive all-day dates in one column. The scripts
correct both; hand-written SQL counts double and lands a day out. `references/calendar.md`
and `references/reminders.md` hold the schema, the traps and the limits - read them to
debug a result that looks wrong, to query a store directly anyway, or to change a script.
An ordinary question does not need them.

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
yet. Calendar also counts the occurrences that came from rule expansion, and Reminders
counts the open reminders with no due date. Pass all of them on as printed.

## Settled before you see a row

Do not reason about these, re-check them or narrate them:

- **Free means free, declined means gone.** An event marked Free is hidden unless he
  accepted it, and one he declined is dropped. `--show-free` answers a different
  question - "what is happening at the zbor this week" - and is not a safety net.
- **One meeting is one line.** Room and shared-calendar copies collapse into it, with
  the extras shown as `+2`.
- **All-day events do not block time** in `free`. They sit in the day's header as context.
- **Subtasks hang under their parent**, and a subtask whose parent is outside the
  selection is promoted. Completed reminders appear only in `done` and `search --done`,
  marked as done.
- **Reminder alarm times are not decoded**; location alarms are. Say so if he asks when
  a reminder will ring.

## Looking one thing up

Hand a pasted link straight to `cal.py event` or `rem.py show`. Both pull the id out of
any link form, a raw UUID or a foreign id, so there is no parsing to do first.

**A single lookup deliberately ignores the filters.** He named this thing, so it shows
whatever calendar or list it lives on and whatever its status is, including completed.
A lookup is not an agenda and must not come back empty because of a hidden list or a
free/busy flag.

## What gets hidden

Neither script has opinions of its own. Every judgement about noise lives in
`calendar.config.toml` and `reminders.config.toml`, the parts of this skill allowed to
be personal; each reference lists the keys.

**A filtered row is a decision he already made.** Do not run a second pass with the
filters off to find what was hidden, do not list the hidden things as though they might
really count, and do not caveat an answer with what is nominally sitting in it. The
widening flags are for a different question, asked deliberately.

## Writing

None, by design, on either store. If he wants an event created or a reminder completed,
say so and let him do it in the app or with Siri. A write path would need Automation
access and could race the sync engine; completing a recurring reminder is a server-side
operation that materialises the next instance, and faking it in SQL would corrupt the
series.

He has said a write path is likelier on Reminders than on Calendar. When it happens it
goes through AppleScript or the `reminders` CLI as a separate command, never as SQL
against either store, and the read paths stay exactly as they are.
