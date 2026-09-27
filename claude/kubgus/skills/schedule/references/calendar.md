# Calendar

Everything is in one SQLite file that Calendar.app keeps synced:

```
~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb
```

`~/Library/Calendars/` is empty on current macOS - it is the old location and a dead
end.

```
scripts/cal.py event <ical:// link or id>    one event in full
scripts/cal.py agenda [when]                 what is on            (default today)
scripts/cal.py search <text> [--range when]  title, notes, location, attendees
scripts/cal.py free [when] [--between HH:MM-HH:MM] [--min 30]
scripts/cal.py conflicts [when]              overlapping commitments
scripts/cal.py calendars                     what exists, what is hidden
```

Beyond the shared flags: `--all` (drop the calendar filter), `--show-free`,
`--show-declined`, `--calendar Skyro` (repeatable, substring), `--no-dedupe`.

## What actually goes wrong

Not the SQL. Four things, and `cal.py` already handles all four - this section is so
you recognise the symptoms if you ever query the store directly.

**`OccurrenceCache` is an index, not the truth, and it is incomplete.** It has every
recurring event pre-expanded, which is why this skill does not parse RRULEs for the
common case - but Calendar.app fills it on its own schedule, and a series synced
yesterday can sit there with zero rows while running weekly. In this store that hid 21
live series, among them three Skyro classes that simply did not exist in any agenda.
So `cal.py` also expands from `Recurrence` directly, but only for series the cache has
never touched. Where the cache does have rows it wins, because it encodes decisions the
rule cannot: a Google series whose individual meetings were re-created as separate
events is cached with those dates missing and nothing in `Recurrence` or `ExceptionDate`
explains the gap. Expanding such a series by rule conjures meetings that were moved
months ago. Anything that did come from a rule is counted in the trailing note and
carries `from_rule` in `--json` - worth passing on, since an open-ended weekly rule
nobody ever ended recurs forever on paper.

**The timestamp trap here has a way out.** A timed event's `start_date` is a real UTC
instant while an all-day event's is naive wall clock, and its `start_tz` reads `_float`.
`OccurrenceCache` is the sane table: every column there is a real instant and `day` is
local midnight.

**One event, three to five rows.** A scout meeting that books rooms exists as a
separate `CalendarItem` on his own calendar, the shared den calendar, and one per room
it reserved - so a plain query reports a Monday Družinovka four times. Two things fix
it: the room calendars are hidden outright, and what survives is grouped on the
server-side event id (the last path segment of `external_id`) paired with the occurrence
end. That pairing matters - group on the event id alone and a weekly series collapses
into a single line. Extras show as `+2` on the line.

**Free means free, and declined means gone.** Two filters settle this before you see a
row, so you do not have to reason about it and must not narrate it. Events marked Free
are hidden unless he personally accepted them - his RSVP on
`CalendarItem.self_attendee_id` outranks whatever the source system defaulted to, which
is what keeps an accepted three-day Potáborovica from vanishing. Events he declined are
dropped outright; on the Skyro timetable that is about half the week.

So a Free event that got filtered out is free. `--show-free` is for a different question
- "what is happening at the zbor this week" - and you use it when that is the question
asked, not as a safety net.

All of this is one query, not sixteen. You never need to loop `event` over an agenda to
read RSVPs.

## Reading a pasted link

A bare `ical://occurrence/<UUID>?method=show&options=more` is a Calendar.app "Copy
link". The UUID is `CalendarItem.UUID`; the query string just means "open it, expanded".
`cal.py event` pulls the id out of any of the link forms, a raw UUID, or a Google event
id.

`--open` also reveals it in Calendar.app. Only pass that when he asks to see it there;
it steals focus.

## Hidden calendars

As currently configured, `agenda` skips namedays, holidays and birthdays because they
are wallpaper, and every Google room and equipment calendar because they are duplicates
of a meeting that is already listed. Rooms are caught by matching
`resource.calendar.google.com` against the calendar's CalDAV path rather than by name,
so a room booked for the first time next month is hidden without anyone editing
anything.

Keys in `calendar.config.toml`: `hide_titles` (exact names), `hide_matching`
(substrings, tested against name, account and CalDAV path), `hide_free`,
`keep_accepted`, `hide_declined`, `day_window`. Edit them there rather than working
around them with flags. `--config PATH` or `$CLAUDE_CALENDAR_CONFIG` point somewhere
else. `cal.py calendars` marks hidden ones with `-`.

## Limits worth stating out loud

**Outside Calendar.app's pre-expanded window** - currently about two years back and two
forward - one-off events are read straight off `CalendarItem` and recurring ones come
from rule expansion. Both work, but the further out the date, the more the answer rests
on rules rather than on anything Calendar.app has agreed with.

**Participant status codes are read off this store, not documented by Apple**
(0 no reply, 1 accepted, 2 declined, 3 tentative). They match every case checked so far.
`--json` carries `raw_status` if something ever looks wrong. Organizer and "you" come
from `CalendarItem.organizer_id` and `self_attendee_id` rather than role codes, because
on a Google shared calendar the organizer is the calendar itself, not a person.

**All-day events do not block time** in `free`. An all-day "Bozin XXII." would otherwise
swallow every slot for three days; it is listed in the day's header as context instead.
