# Reminders

A Core Data store per account under one group container:

```
~/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores/Data-<UUID>.sqlite
```

```
scripts/rem.py due [when]           what is due, overdue on top   (default today)
scripts/rem.py open [--undated]     everything open, grouped by list
scripts/rem.py search <text>        title, notes, list, tag       (--done widens it)
scripts/rem.py show <id or link>    one reminder in full
scripts/rem.py done [when]          what was completed, and when  (default last 7 days)
scripts/rem.py lists                lists and groups, marking hidden ones
```

`when` also takes `all` here. Beyond the shared flags: `--all` (drop the list filter),
`--list Frontline` (repeatable, substring, matches groups too), `--flat` (subtasks on
their own lines), `--store PATH`.

## What actually goes wrong

Not the SQL. Six things, and `rem.py` already handles all six - this section is so you
recognise the symptoms if you ever query the store directly.

**Three of the four stores are empty and they all carry the same schema.** Alongside
the live iCloud store sit `Data-local.sqlite`, a `SiriFoundInApps` store and a stub for
an account that never synced. Anything that picks by filename or takes the first match
has a three-in-four chance of reporting an empty task list as an empty task list, with
no error to tell you apart from a man who has finished everything. `rem.py` picks the
store with the most reminders in it, and `--store` overrides.

**92% of the store is done.** 633 of 685 reminders here are completed, another 20 are
`ZMARKEDFORDELETION` tombstones that read as perfectly normal rows, and 19 more are
orphans whose list is gone but whose reminder was never purged. 685 becomes 33. Every
command filters all three before you see anything; only `done` and `search --done` look
at completed rows, and they mark them as done on the line so an open and a finished
reminder can never be confused when they sit adjacent.

**The timestamp trap here has no way out.** A timed reminder's `ZDUEDATE` is a real UTC
instant carrying a real `ZTIMEZONE`, while an all-day reminder's is naive wall clock.
Nothing papers over it - there is no cache of pre-expanded instances to fall back on.
Most dated reminders are all-day, so this is the failure you would hit first.

**Lists, groups and smart lists share one table.** `ZREMCDBASELIST` holds all three,
plus deleted ones that are still present. "Tasks" and "Inbox" are groups, not lists;
`Frontline`, `Waiting`, `Backlog`, `Leads` and `Planned` hang off "Tasks" via
`ZPARENTLIST`. Smart lists are saved searches whose contents already live on a real
list, so counting them double-counts. `rem.py lists` shows the hierarchy and marks what
the config hides.

**Subtasks are reminders.** Printed flat they read as independent tasks with no sign of
what they belong to, and they inflate every count. `rem.py` hangs them under their
parent - but promotes a subtask whose parent is not in the current selection, because
otherwise completing a parent hides live work. `--flat` turns it off.

**`Z_ENT` is assigned per store, not fixed by Apple.** It is an index into
`Z_PRIMARYKEY`, and a macOS update that inserts an entity renumbers everything after
it. A hardcoded `34` for the recurrence rule silently starts meaning something else.
`rem.py` resolves every entity by name in one query up front.

## Reading a pasted link

Hand any of it to `rem.py show` - a raw UUID, an `x-apple-reminderkit://` URL, or the
last path segment of anything UUID-shaped. It pulls the id out itself and matches
against both the CloudKit identifier and the local one.

## Hidden lists

Nothing here is noise by construction - no subscribed feeds, no entries conjured by a
service he never opted into. So as shipped it hides only smart lists, which is a
correctness call rather than a taste one. `Long-term` is named as a commented-out
candidate and nothing else; do not add to that list on his behalf.

Keys in `reminders.config.toml`: `hide_lists` (exact names), `hide_matching`
(substrings, tested against list name, group and account), `hide_smart_lists`,
`nest_subtasks`, `due_window`, `done_window`. `--config PATH` or
`$CLAUDE_REMINDERS_CONFIG` point somewhere else.

## Limits worth stating out loud

**Alarm times are not decoded.** A reminder's notification time lives in
`ZDATECOMPONENTSDATA`, an archived `NSDateComponents` blob, not a column. For an
all-day reminder that is the only place the "remind me at 09:00" lives. Location alarms
are decoded and shown - `arriving at Jakub's Home` - because those sit in plain
columns.

**Recurrence labels are partly inferred.** The frequency code is read as
`EKRecurrenceFrequency` (0 daily, 1 weekly, 2 monthly, 3 yearly); only daily and weekly
appear in this store, so the monthly and yearly labels are unverified. Reminders
materialises the next instance when you complete a recurring one, so there is nothing
to expand and no risk of conjuring occurrences that were never really there.

**Sections are not grouped.** The store has them, but a reminder's membership lives in
a binary plist on the list rather than as a foreign key, so `open` groups by list only.

**Priority is Apple's CalDAV scale**, not a 1-3 enum: 0 none, 1 high, 5 medium, 9 low,
rendered `!!!` / `!!` / `!`. A synced third-party client could write something in
between; `--json` carries the raw number.

**`show --open` is best effort.** `x-apple-reminderkit://REMCDReminder/<uuid>` is
undocumented. LaunchServices accepts it, but which reminder it lands on has not been
confirmed by eye. Only pass it when he asks to see it in the app; it steals focus.
