#!/usr/bin/env python3
"""Read the macOS Calendar store directly. Read-only, stdlib only.

Everything lives in one SQLite file that Calendar.app keeps in sync. This reads a
snapshot of it, so it can never corrupt the store and never prompts for Automation
access. See SKILL.md for the timestamp traps this encodes.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from datetime import date, datetime, timedelta, timezone

STORE = os.path.expanduser(
    "~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"
)

# Deliberately inert: with no config the script hides nothing and filters nothing, so
# what you see is what the store holds. Every opinion about which calendars are noise
# lives in config.toml, which is the file that is allowed to be personal.
DEFAULTS = {
    "hide_titles": [],
    "hide_matching": [],
    "hide_free": False,
    "hide_declined": False,
    "keep_accepted": True,
    "day_window": "09:00-21:00",
}


def load_config(explicit: str | None = None) -> dict:
    path = (
        explicit
        or os.environ.get("CLAUDE_CALENDAR_CONFIG")
        or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config.toml")
    )
    cfg = dict(DEFAULTS)
    if os.path.exists(path):
        import tomllib

        with open(path, "rb") as fh:
            cfg.update(tomllib.load(fh))
    elif explicit:
        sys.exit(f"No config at {path}")
    return cfg


def hidden(row, cfg) -> bool:
    """Whether the config says this calendar is noise.

    `hide_matching` is tested against the CalDAV path as well as the name, which is
    what lets a pattern outlive the thing it describes - a whole class of calendars,
    such as every Google room, shares a path fragment long before anyone knows what
    the next room will be called.
    """
    if (row["calendar"] or "") in cfg["hide_titles"]:
        return True
    haystack = "\n".join(
        str(row[k] or "") for k in ("calendar", "account", "cal_external_id")
    ).lower()
    return any(p.lower() in haystack for p in cfg["hide_matching"])

# ----------------------------------------------------------------------------------

MAC_EPOCH = 978307200  # 2001-01-01T00:00:00Z, Apple's reference date

STATUS = {0: "", 1: "confirmed", 2: "tentative", 3: "cancelled"}
# Observed in this store rather than documented by Apple; --json exposes the raw code.
PARTICIPANT_STATUS = {0: "no reply", 1: "accepted", 2: "declined", 3: "tentative"}
PARTICIPANT_TYPE = {0: "group", 1: "person", 2: "room", 3: "resource"}

# Google wraps its dial-in block in two identical tilde rules and asks you not to edit
# between them, which makes it exactly the thing to drop from a summary.
MEET_BOILERPLATE = re.compile(r"^-::~:~:.*?^-::~:~:[^\n]*$", re.S | re.M)
CONF_LINK = re.compile(
    r"https://(?:meet\.google\.com/[\w-]+"
    r"|[\w.-]*zoom\.us/j/[^\s>\"]+"
    r"|teams\.microsoft\.com/l/meetup-join/[^\s>\"]+"
    r"|[\w.-]*whereby\.com/[^\s>\"]+)"
)
UUID_RE = re.compile(r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}")


# --- time -------------------------------------------------------------------------
#
# Two different conventions live in this database and mixing them up is the whole
# game. A timed event's start_date is a real UTC instant. An all-day event's
# start_date is naive wall clock (its tz reads `_float`), so converting it to local
# time shifts it by the UTC offset and you land a day early or late. OccurrenceCache
# is uniform: every column there is a real instant, and `day` is local midnight.


def local(ts: float) -> datetime:
    """A real instant -> local wall clock."""
    return datetime.fromtimestamp(ts + MAC_EPOCH)


def floating(ts: float) -> datetime:
    """A naive/floating value -> the wall clock it literally encodes.

    Read at UTC and stripped back to naive, because the number is not an instant at
    all: it is "midnight", and which midnight depends on where you are standing.
    """
    return datetime.fromtimestamp(ts + MAC_EPOCH, timezone.utc).replace(tzinfo=None)


def mac(dt: datetime) -> float:
    """Local wall clock -> a real instant in Apple reference time."""
    return dt.timestamp() - MAC_EPOCH


def elsewhere(tz: str, when: datetime) -> bool:
    """True if `tz` is a real zone whose clock differs from yours at that moment."""
    if not tz or tz in ("_float", "GMT"):
        return False
    try:
        from zoneinfo import ZoneInfo

        theirs = when.replace(tzinfo=None).astimezone(ZoneInfo(tz)).utcoffset()
        mine = when.astimezone().utcoffset()
        return theirs != mine
    except Exception:
        return False


def item_span(row) -> tuple[datetime, datetime]:
    """Start and end of a CalendarItem, honouring the all-day convention."""
    conv = floating if row["all_day"] else local
    return conv(row["start_date"]), conv(row["end_date"])


# --- store access -----------------------------------------------------------------


def snapshot() -> str:
    """Copy the store (plus its WAL) somewhere disposable and return the copy.

    The live file is WAL-mode and locked by Calendar.app, and recent changes sit in
    the -wal sidecar rather than the main file. Copying all three and opening the
    copy read-write lets SQLite replay the WAL, so the snapshot is current.
    """
    if not os.path.exists(STORE):
        sys.exit(
            f"No calendar store at {STORE}\n"
            "Open Calendar.app once to create it, or grant this terminal Full Disk Access."
        )

    src_wal = STORE + "-wal"
    stamp = str(
        (
            os.path.getmtime(STORE),
            os.path.getsize(STORE),
            os.path.getmtime(src_wal) if os.path.exists(src_wal) else 0,
        )
    )
    cache = os.path.join(tempfile.gettempdir(), "claude-calendar-snapshot")
    db = os.path.join(cache, "Calendar.sqlitedb")
    stamp_path = os.path.join(cache, "stamp")

    if os.path.exists(stamp_path) and open(stamp_path).read() == stamp:
        return db

    shutil.rmtree(cache, ignore_errors=True)
    os.makedirs(cache, exist_ok=True)
    for suffix in ("", "-wal", "-shm"):
        if os.path.exists(STORE + suffix):
            shutil.copy2(STORE + suffix, db + suffix)
    with open(stamp_path, "w") as fh:
        fh.write(stamp)
    return db


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(snapshot())
    conn.row_factory = sqlite3.Row
    return conn


def store_age(conn) -> str:
    wal = STORE + "-wal"
    newest = max(
        os.path.getmtime(STORE),
        os.path.getmtime(wal) if os.path.exists(wal) else 0,
    )
    delta = datetime.now() - datetime.fromtimestamp(newest)
    if delta > timedelta(hours=12):
        return f"store last written {datetime.fromtimestamp(newest):%Y-%m-%d %H:%M}"
    return ""


def cache_window(conn) -> tuple[date, date]:
    lo, hi = conn.execute("select min(day), max(day) from OccurrenceCache").fetchone()
    return local(lo).date(), local(hi).date()


# --- date ranges ------------------------------------------------------------------


def parse_when(text: str | None) -> tuple[date, date]:
    """Return an inclusive [first, last] local date range."""
    today = date.today()
    if not text:
        return today, today

    t = text.strip().lower()
    simple = {
        "today": (0, 0),
        "tomorrow": (1, 1),
        "yesterday": (-1, -1),
    }
    if t in simple:
        lo, hi = simple[t]
        return today + timedelta(days=lo), today + timedelta(days=hi)

    if t in ("week", "this-week", "thisweek"):
        start = today - timedelta(days=today.weekday())
        return start, start + timedelta(days=6)
    if t in ("next-week", "nextweek"):
        start = today - timedelta(days=today.weekday()) + timedelta(days=7)
        return start, start + timedelta(days=6)
    if t in ("last-week", "lastweek"):
        start = today - timedelta(days=today.weekday()) - timedelta(days=7)
        return start, start + timedelta(days=6)
    if t in ("month", "this-month"):
        start = today.replace(day=1)
        nxt = (start + timedelta(days=32)).replace(day=1)
        return start, nxt - timedelta(days=1)

    if ".." in t:
        a, b = t.split("..", 1)
        return parse_when(a)[0], parse_when(b)[1]

    m = re.fullmatch(r"([+-])(\d+)d", t)
    if m:
        n = int(m.group(2))
        return (today, today + timedelta(days=n)) if m.group(1) == "+" else (today - timedelta(days=n), today)

    return date.fromisoformat(t), date.fromisoformat(t)


# --- reading occurrences ----------------------------------------------------------

OCC_SQL = """
select
    oc.event_id, oc.day, oc.occurrence_date, oc.occurrence_end_date, 0 as from_rule,
    (select p.status from Participant p where p.ROWID = ci.self_attendee_id) as my_status,
    ci.summary, ci.description, ci.all_day, ci.status, ci.availability,
    ci.start_date, ci.end_date, ci.start_tz, ci.url, ci.UUID as uuid,
    ci.external_id, ci.has_recurrences, ci.has_attendees, ci.organizer_id,
    c.title as calendar, c.symbolic_color_name as color,
    c.external_id as cal_external_id, s.name as account,
    l.title as location, l.address
from OccurrenceCache oc
join CalendarItem ci on ci.ROWID = oc.event_id
join Calendar c on c.ROWID = oc.calendar_id
left join Store s on s.ROWID = c.store_id
left join Location l on l.ROWID = ci.location_id
where oc.day >= ? and oc.day < ?
"""


def event_key(row) -> str:
    """Identity of the underlying real-world event, across calendars.

    The same meeting is a separate CalendarItem on every calendar it touches - your
    own, the shared one, and one per room it booked. CalDAV hangs all of them off the
    same server-side event id, which is the last path segment of external_id.
    """
    ext = row["external_id"] or ""
    m = re.search(r"/events/(.+?)(?:\.ics)?$", ext)
    if m:
        return m.group(1)
    return f"{row['summary']}|{row['all_day']}"


# A multi-day event only reveals its true length if the rows either side of the
# requested range come along too, so every query is padded and trimmed afterwards.
PAD = timedelta(days=45)


def fetch_range(conn, first: date, last: date, args, prefer=None) -> list[dict]:
    lo = mac(datetime.combine(first - PAD, datetime.min.time()))
    hi = mac(datetime.combine(last + PAD, datetime.min.time()))
    rows = list(conn.execute(OCC_SQL, (lo, hi)).fetchall())
    seen = {(r["event_id"], round(r["occurrence_end_date"] or 0)) for r in rows}
    rows += uncached(conn, first, last)
    rows += expand_series(conn, first - PAD, last + PAD, seen)
    return shape(rows, first, last, args, prefer)


def uncached(conn, first: date, last: date) -> list[dict]:
    """One-off events from outside the pre-expanded window, read off CalendarItem."""
    lo, hi = cache_window(conn)
    if first >= lo and last <= hi:
        return []

    window_lo = mac(datetime.combine(first, datetime.min.time())) - 86400
    window_hi = mac(datetime.combine(last + timedelta(days=1), datetime.min.time())) + 86400
    rows = conn.execute(
        ITEM_SQL.format(where="ci.has_recurrences = 0 and ci.end_date >= ? and ci.start_date <= ?"),
        (window_lo, window_hi),
    ).fetchall()

    out = []
    for r in rows:
        start, _ = item_span(r)
        if lo <= start.date() <= hi:
            continue  # the cache already has this one
        out.extend(synthetic(r))
    return out


# --- recurrence ---------------------------------------------------------------------
#
# OccurrenceCache is incomplete: Calendar.app fills it in its own time, so a series
# synced yesterday can sit there with zero rows while being perfectly live. Trusting it
# alone silently drops real commitments, which is the worst thing a calendar reader can
# do - in this store 21 live series had no rows at all, among them three weekly classes.
#
# But where the cache does have an opinion it is worth more than ours. A Google series
# whose individual 2026 meetings were re-created as separate events is cached with those
# dates missing, and nothing in Recurrence or ExceptionDate says why. Expanding such a
# series by rule invents meetings that were moved or replaced. So the rule here is
# narrow on purpose: expand only series the cache has never touched, and defer to it
# everywhere else.

WEEKDAYS = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}
MAX_OCCURRENCES = 20000  # a guard against a malformed rule spinning forever

RECUR_SQL = """
select ci.*,
       (select p.status from Participant p where p.ROWID = ci.self_attendee_id) as my_status,
       c.title as calendar, c.symbolic_color_name as color,
       c.external_id as cal_external_id, s.name as account,
       l.title as location, l.address,
       r.frequency, r.interval, r.count, r.specifier, r.end_date as rec_end
from CalendarItem ci
join Recurrence r on r.owner_id = ci.ROWID
join Calendar c on c.ROWID = ci.calendar_id
left join Store s on s.ROWID = c.store_id
left join Location l on l.ROWID = ci.location_id
where ci.has_recurrences = 1 and ci.start_date <= ?
  and not exists (select 1 from OccurrenceCache oc where oc.event_id = ci.ROWID)
"""


def expand_series(conn, first: date, last: date, seen: set) -> list[dict]:
    window_hi = mac(datetime.combine(last + timedelta(days=1), datetime.min.time()))
    out = []
    for r in conn.execute(RECUR_SQL, (window_hi,)).fetchall():
        start, end = item_span(r)
        duration = end - start
        until = None
        if r["rec_end"]:
            until = (floating if r["all_day"] else local)(r["rec_end"])
            if until.date() < first:
                continue

        skip = {
            (floating if r["all_day"] else local)(e[0])
            for e in conn.execute(
                "select date from ExceptionDate where owner_id = ?", (r["ROWID"],)
            )
        }

        for when in series_dates(start, r, first, last, until):
            if when in skip:
                continue
            occ_end = when + duration
            if (r["ROWID"], round(mac(occ_end))) in seen:
                continue
            out.extend(occurrence_rows(r, when, occ_end))
    return out


def series_dates(start: datetime, rule, first: date, last: date, until):
    """Occurrence starts of one series that land in [first, last].

    Walks from the real start rather than from the window, because `count` is counted
    from the beginning of the series - jumping straight to the window would lose track
    of how many occurrences have already been spent.
    """
    freq = rule["frequency"]
    step = max(1, rule["interval"] or 1)
    spec = rule["specifier"] or ""
    limit = rule["count"] or 0
    clock = start.time()

    emitted = 0
    for day in _candidates(start.date(), freq, step, spec, last):
        if until and datetime.combine(day, clock) > until:
            return
        emitted += 1
        if limit and emitted > limit:
            return
        if emitted > MAX_OCCURRENCES:
            return
        if day > last:
            return
        if day >= first:
            yield datetime.combine(day, clock)


def _candidates(start: date, freq: int, step: int, spec: str, last: date):
    if freq == 1:  # daily
        day = start
        while day <= last:
            yield day
            day += timedelta(days=step)
        return

    if freq == 2:  # weekly, optionally on several named days
        days = [WEEKDAYS[d[-2:]] for d in spec[2:].split(",") if d[-2:] in WEEKDAYS] or [
            start.weekday()
        ]
        week = start - timedelta(days=start.weekday())
        while week <= last:
            for wd in sorted(days):
                day = week + timedelta(days=wd)
                if start <= day <= last:
                    yield day
            week += timedelta(weeks=step)
        return

    if freq == 3:  # monthly, either on a day number or an ordinal weekday
        m = re.fullmatch(r"D=([+-]\d+)([A-Z]{2})", spec)
        months = (last.year - start.year) * 12 + (last.month - start.month) + 1
        for k in range(0, max(months, 0) + 1, step):
            y, mo = divmod(start.month - 1 + k, 12)
            y, mo = start.year + y, mo + 1
            day = (
                _nth_weekday(y, mo, int(m.group(1)), WEEKDAYS[m.group(2)])
                if m
                else _clamp(y, mo, start.day)
            )
            if day and start <= day <= last:
                yield day
        return

    if freq == 4:  # yearly
        m = re.search(r"M=(\d+)", spec)
        o = re.search(r"O=(\d+)", spec)
        mo = int(o.group(1)) if o else start.month
        dom = int(m.group(1)) if m else start.day
        for y in range(start.year, last.year + 1, step):
            day = _clamp(y, mo, dom)
            if day and start <= day <= last:
                yield day


def _clamp(y: int, m: int, d: int):
    try:
        return date(y, m, d)
    except ValueError:
        return None  # e.g. the 31st of a 30-day month: that month has no occurrence


def _nth_weekday(y: int, m: int, ordinal: int, weekday: int):
    """+1MO = first Monday, -2SA = second-to-last Saturday."""
    first_of = date(y, m, 1)
    days = []
    day = first_of + timedelta(days=(weekday - first_of.weekday()) % 7)
    while day.month == m:
        days.append(day)
        day += timedelta(days=7)
    idx = ordinal - 1 if ordinal > 0 else ordinal
    return days[idx] if -len(days) <= idx < len(days) else None


def occurrence_rows(row, start: datetime, end: datetime) -> list[dict]:
    """Shape an expanded occurrence the way OccurrenceCache would have."""
    base = {k.lower(): row[k] for k in row.keys()}
    base["event_id"] = row["ROWID"]
    base["occurrence_date"] = mac(start)
    base["occurrence_end_date"] = mac(end)
    base["from_rule"] = 1
    span = daterange(start.date(), end.date()) if row["all_day"] else [start.date()]
    return [
        dict(base, day=mac(datetime.combine(d, datetime.min.time()))) for d in span
    ]


def shape(rows, first: date, last: date, args, prefer=None) -> list[dict]:
    keep = []
    for r in rows:
        if not args.all and hidden(r, args.cfg):
            continue
        if args.calendar and not any(
            c.lower() in (r["calendar"] or "").lower() for c in args.calendar
        ):
            continue
        # You said yes to it, so it is a commitment whatever the source system
        # flagged it as. This is the difference between "Google defaulted this series
        # to Free" and "I am going to be there".
        accepted = r["my_status"] == 1
        if r["my_status"] == 2 and args.cfg["hide_declined"] and not args.show_declined:
            continue
        if (
            r["availability"] == 1
            and args.cfg["hide_free"]
            and not args.show_free
            and not (accepted and args.cfg["keep_accepted"])
        ):
            continue
        if r["status"] == 3:
            continue
        keep.append(r)

    # One entry per real occurrence. A multi-day all-day event emits one cache row per
    # day it covers, all sharing an end instant; a weekly series gives every occurrence
    # its own end. Keying on (event, end) therefore collapses the former and keeps the
    # latter apart.
    groups: dict[tuple, dict] = {}
    for r in keep:
        key = (event_key(r), round(r["occurrence_end_date"] or 0))
        if args.no_dedupe:
            key = (key, r["calendar"])
        g = groups.setdefault(
            key,
            {
                "row": r,
                "days": [],
                "calendars": [],
                "free": r["availability"] == 1,
            },
        )
        g["days"].append(local(r["day"]).date())
        if r["calendar"] not in g["calendars"]:
            g["calendars"].append(r["calendar"])
        # Whoever asked for a specific event wins; otherwise prefer a calendar that is
        # actually yours over a room booking.
        if prefer is not None and r["event_id"] == prefer:
            g["row"] = r
        elif not hidden(r, args.cfg) and hidden(g["row"], args.cfg):
            if g["row"]["event_id"] != prefer:
                g["row"] = r

    out = []
    for g in groups.values():
        r = g["row"]
        days = sorted(set(g["days"]))
        visible = [d for d in days if first <= d <= last]
        if not visible:
            continue

        if r["all_day"]:
            start = datetime.combine(days[0], datetime.min.time())
            end = local(r["occurrence_end_date"])
            span_total = len(days)
        else:
            start = local(r["occurrence_date"])
            end = local(r["occurrence_end_date"])
            span_total = 1

        # A multi-day all-day event gets a line on every day it covers. Printing it
        # only on the first would leave the rest of a long weekend looking empty,
        # which is the opposite of what someone scanning a week needs to see.
        anchors = visible if (r["all_day"] and span_total > 1) else visible[:1]
        for anchor in anchors:
            span_index = (anchor - days[0]).days + 1 if span_total > 1 else None
            out.append(shaped(r, g, start, end, anchor, visible, span_total, span_index))

    out.sort(key=lambda e: (e["anchor"], not e["all_day"], e["start"]))
    return out


def shaped(r, g, start, end, anchor, visible, span_total, span_index) -> dict:
    return (
            {
                "summary": r["summary"] or "(no title)",
                "start": start,
                "end": end,
                "all_day": bool(r["all_day"]),
                "anchor": anchor,
                "days_in_range": visible,
                "span_total": span_total,
                "span_index": span_index,
                "calendar": r["calendar"],
                "also_on": [c for c in g["calendars"] if c != r["calendar"]],
                "account": r["account"],
                "location": tidy(r["location"] or r["address"] or ""),
                "free": g["free"],
                "status": STATUS.get(r["status"], ""),
                "tz": r["start_tz"] or "",
                "from_rule": bool(r["from_rule"]),
                "rsvp": PARTICIPANT_STATUS.get(r["my_status"], ""),
                "uuid": r["uuid"],
                "event_id": r["event_id"],
                "recurring": bool(r["has_recurrences"]),
                "has_attendees": bool(r["has_attendees"]),
                "notes": r["description"] or "",
                "url": r["url"] or "",
            }
    )


# --- notes ------------------------------------------------------------------------


def clean_notes(text: str) -> tuple[str, list[str]]:
    """Strip the auto-generated conferencing block, return (notes, links)."""
    links = list(dict.fromkeys(CONF_LINK.findall(text or "")))
    body = MEET_BOILERPLATE.sub("", text or "")
    body = re.sub(r"\n{3,}", "\n\n", body).strip()
    return body, links


# --- rendering --------------------------------------------------------------------


def tidy(text: str) -> str:
    """One line, no runs of whitespace. Locations arrive with embedded newlines."""
    return re.sub(r"\s+", " ", (text or "")).strip()


def short_location(text: str, limit: int = 44) -> str:
    """Enough of a location to recognise it.

    Google appends every booked room to the street address, so a scout meeting's
    location can run past 120 characters and wreck the column. The street line is
    the part that tells you where to go; the rooms are already implied by the event.
    """
    if len(text) <= limit:
        return text
    head = text.split(",")[0].strip()
    return head if len(head) <= limit else head[: limit - 1] + "…"


def fmt_time(e) -> str:
    if e["all_day"]:
        if e["span_total"] > 1:
            return f"all-day ({e['span_index']}/{e['span_total']})"
        return "all-day"
    return f"{e['start']:%H:%M}-{e['end']:%H:%M}"


def render_agenda(events, first, last, note=""):
    if not events:
        span = f"{first:%Y-%m-%d}" if first == last else f"{first:%Y-%m-%d}..{last:%Y-%m-%d}"
        print(f"Nothing on {span}.")
        if note:
            print(f"({note})")
        return

    width = max(len(fmt_time(e)) for e in events)
    current = None
    for e in events:
        if e["anchor"] != current:
            current = e["anchor"]
            print(f"\n{current:%a %Y-%m-%d}")
        cal = e["calendar"]
        if e["also_on"]:
            cal += f" +{len(e['also_on'])}"
        tail = [cal]
        if e["location"]:
            tail.append(short_location(e["location"]))
        if e["status"] == "tentative":
            tail.append("tentative")
        print(f"  {fmt_time(e):<{width}}  {tidy(e['summary'])}  -  {' · '.join(tail)}")
    if note:
        print(f"\n({note})")


def render_event(conn, e, args):
    notes, links = clean_notes(e["notes"])
    print(e["summary"])

    if e["all_day"]:
        when = f"{e['start']:%a %Y-%m-%d}"
        if e["span_total"] > 1:
            when += f" .. {e['end']:%a %Y-%m-%d} (all-day, {e['span_total']} days)"
        else:
            when += " (all-day)"
    else:
        mins = round((e["end"] - e["start"]).total_seconds() / 60)
        dur = f"{mins} min" if mins < 90 else f"{mins / 60:g} h"
        when = f"{e['start']:%a %Y-%m-%d %H:%M}-{e['end']:%H:%M} ({dur})"
        # Times always print in your local zone. Naming the event's own zone is only
        # worth the line when it actually resolves to a different clock - Prague,
        # Bratislava, Vienna and Berlin are all the same afternoon.
        if elsewhere(e["tz"], e["start"]):
            when += f"  [set in {e['tz']}]"
    rows = [("when", when)]

    cal = e["calendar"]
    if e["also_on"]:
        cal += "   also on: " + ", ".join(e["also_on"])
    rows.append(("calendar", f"{cal}  [{e['account']}]"))

    flags = [f for f in (e["status"], "free" if e["free"] else "busy", "recurring" if e["recurring"] else "") if f]
    rows.append(("status", ", ".join(flags)))
    if e["location"]:
        rows.append(("where", e["location"]))
    for link in links:
        rows.append(("call", link))
    if e["url"]:
        rows.append(("url", e["url"]))

    people = participants(conn, e["event_id"])
    if people:
        org = [p["label"] for p in people if p["organizer"]]
        if org:
            rows.append(("organizer", ", ".join(org)))
        me = next((p for p in people if p["self"]), None)
        if me:
            rows.append(("you", me["status"]))
        others = [p for p in people if not p["organizer"] and not p["self"]]
        for i, p in enumerate(others):
            rows.append(("attendees" if i == 0 else "", f"{p['label']} - {p['status']}"))

    rows.append(("link", f"ical://occurrence/{e['uuid']}?method=show&options=more"))

    width = max(len(k) for k, _ in rows)
    for k, v in rows:
        print(f"  {k:<{width}}  {v}")

    if notes:
        print("\n  notes")
        for line in notes.splitlines():
            print(f"    {line}")


def participants(conn, event_id):
    """Attendees, with the organizer and you picked out.

    CalendarItem names both by Participant ROWID, which beats guessing from role
    codes - on a Google shared calendar the organizer is the calendar itself, not a
    person, and role alone will not tell you that.
    """
    item = conn.execute(
        "select organizer_id, self_attendee_id from CalendarItem where ROWID = ?", (event_id,)
    ).fetchone()
    organizer_id = item["organizer_id"] if item else None
    self_id = item["self_attendee_id"] if item else None

    rows = conn.execute(
        """
        select p.ROWID, p.email, p.type, p.status, p.role, i.display_name
        from Participant p
        left join Identity i on i.ROWID = p.identity_id
        where p.owner_id = ?
        order by p.ROWID
        """,
        (event_id,),
    ).fetchall()

    out = []
    for r in rows:
        if r["type"] in (2, 3):  # rooms and projectors are not people
            continue
        name = (r["display_name"] or "").strip()
        email = (r["email"] or "").strip()
        label = f"{name} <{email}>" if name and name != email else (email or name or "?")
        is_self = r["ROWID"] == self_id
        out.append(
            {
                "label": label + (" (you)" if is_self else ""),
                "email": email,
                "status": PARTICIPANT_STATUS.get(r["status"], f"status {r['status']}"),
                "raw_status": r["status"],
                "organizer": r["ROWID"] == organizer_id,
                "self": is_self,
                "type": PARTICIPANT_TYPE.get(r["type"], str(r["type"])),
            }
        )
    return out


def jsonable(e):
    d = dict(e)
    d["start"] = e["start"].isoformat()
    d["end"] = e["end"].isoformat()
    d["anchor"] = e["anchor"].isoformat()
    d["days_in_range"] = [x.isoformat() for x in e["days_in_range"]]
    d["notes"], d["links"] = clean_notes(e["notes"])
    return d


# --- commands ---------------------------------------------------------------------


def cmd_agenda(conn, args):
    first, last = parse_when(args.when)
    events = fetch_range(conn, first, last, args)
    if args.json:
        print(json.dumps([jsonable(e) for e in events], ensure_ascii=False, indent=2))
        return
    render_agenda(events, first, last, coverage_note(conn, first, last, events))


def coverage_note(conn, first, last, events=()) -> str:
    notes = []
    # Worth saying out loud: these came from a recurrence rule because Calendar.app has
    # never indexed the series. The rule is honest but the series may be dead in
    # practice - a weekly reminder nobody ever ended still recurs forever on paper.
    n = sum(1 for e in events if e.get("from_rule"))
    if n:
        notes.append(f"{n} expanded from a recurrence rule Calendar.app has not indexed")
    age = store_age(conn)
    if age:
        notes.append(age)
    return "; ".join(notes)


def cmd_search(conn, args):
    first, last = parse_when(args.range)
    lo = mac(datetime.combine(first - PAD, datetime.min.time()))
    hi = mac(datetime.combine(last + PAD, datetime.min.time()))
    needle = f"%{args.text}%"
    rows = conn.execute(
        OCC_SQL
        + """
        and (ci.summary like ? or ci.description like ? or l.title like ?
             or exists (select 1 from Participant p where p.owner_id = ci.ROWID
                        and (p.email like ? or p.ROWID in
                             (select p2.ROWID from Participant p2
                              join Identity i2 on i2.ROWID = p2.identity_id
                              where p2.ROWID = p.ROWID and i2.display_name like ?))))
        """,
        (lo, hi, needle, needle, needle, needle, needle),
    ).fetchall()
    events = shape(rows, first, last, args)
    if args.json:
        print(json.dumps([jsonable(e) for e in events], ensure_ascii=False, indent=2))
        return
    if not events:
        print(f'Nothing matching "{args.text}" between {first} and {last}.')
        return
    render_agenda(events, first, last, coverage_note(conn, first, last, events))


def cmd_event(conn, args):
    ident = extract_id(args.ident)
    row = find_item(conn, ident)
    if row is None:
        sys.exit(f"No event matches {ident!r}. Paste the whole ical:// link if you have it.")

    # Rebuild it through the same pipeline so display matches the agenda exactly. A
    # single lookup always shows the event whatever its calendar or free/busy flag -
    # you asked for this one by name, so the agenda's noise filters do not apply.
    start, end = item_span(row)
    lo, hi = start.date(), end.date()
    args.all, args.show_free, args.no_dedupe = True, True, False
    args.calendar = None
    events = fetch_range(conn, lo, hi, args, prefer=row["ROWID"])
    match = [e for e in events if e["event_id"] == row["ROWID"]]
    if not match:
        match = shape(synthetic(row), lo, hi, args)
    if not match:
        sys.exit(f"Found {row['summary']!r} in the store but could not place it in time.")
    e = match[0]

    if args.json:
        e = jsonable(e)
        e["participants"] = participants(conn, row["ROWID"])
        print(json.dumps(e, ensure_ascii=False, indent=2))
        return

    render_event(conn, e, args)
    if row["has_recurrences"]:
        print("\n  (recurring - this is the series; `agenda` shows individual occurrences)")
    note = store_age(conn)
    if note:
        print(f"\n  ({note})")

    if args.open:
        subprocess.run(
            ["open", f"ical://occurrence/{row['UUID']}?method=show&options=more"], check=False
        )


def synthetic(row) -> list[dict]:
    """Wrap a CalendarItem as if it had come from OccurrenceCache.

    Only needed for events outside the expanded window, where the cache has nothing.
    The cache emits one row per day an event covers, so this does too, otherwise a
    multi-day event would report itself as one day long.
    """
    start, end = item_span(row)
    base = {k.lower(): row[k] for k in row.keys()}
    base["event_id"] = row["ROWID"]
    base["occurrence_date"] = mac(start)
    base["occurrence_end_date"] = mac(end)
    return [
        dict(base, day=mac(datetime.combine(d, datetime.min.time())))
        for d in daterange(start.date(), end.date())
    ]


def extract_id(text: str) -> str:
    m = UUID_RE.search(text or "")
    if m:
        return m.group(0)
    return (text or "").strip().rstrip("/").split("/")[-1].split("?")[0]


ITEM_SQL = """
select ci.*, 0 as from_rule,
       (select p.status from Participant p where p.ROWID = ci.self_attendee_id) as my_status,
       c.title as calendar, c.symbolic_color_name as color,
       c.external_id as cal_external_id, s.name as account,
       l.title as location, l.address
from CalendarItem ci
join Calendar c on c.ROWID = ci.calendar_id
left join Store s on s.ROWID = c.store_id
left join Location l on l.ROWID = ci.location_id
where {where}
"""


def find_item(conn, ident: str):
    for where, params in (
        ("ci.UUID = ?", (ident,)),
        ("ci.unique_identifier = ?", (ident,)),
        ("ci.external_id like ?", (f"%/{ident}.ics",)),
        ("ci.external_id like ?", (f"%{ident}%",)),
    ):
        row = conn.execute(ITEM_SQL.format(where=where) + " limit 1", params).fetchone()
        if row:
            return row
    return None


def cmd_free(conn, args):
    first, last = parse_when(args.when)
    events = fetch_range(conn, first, last, args)
    lo_h, hi_h = parse_window(args.between)

    for day in daterange(first, last):
        # All-day entries mark the shape of a day without occupying clock time, so
        # they are context here rather than blockers - an all-day "conference" would
        # otherwise swallow every slot.
        busy = [
            (max(e["start"], datetime.combine(day, lo_h)), min(e["end"], datetime.combine(day, hi_h)))
            for e in events
            if not e["all_day"] and e["days_in_range"] and day in e["days_in_range"]
        ]
        busy = sorted((a, b) for a, b in busy if b > a)

        merged = []
        for a, b in busy:
            if merged and a <= merged[-1][1]:
                merged[-1] = (merged[-1][0], max(merged[-1][1], b))
            else:
                merged.append((a, b))

        gaps = []
        cursor = datetime.combine(day, lo_h)
        for a, b in merged:
            if (a - cursor).total_seconds() / 60 >= args.min:
                gaps.append((cursor, a))
            cursor = max(cursor, b)
        end_of_day = datetime.combine(day, hi_h)
        if (end_of_day - cursor).total_seconds() / 60 >= args.min:
            gaps.append((cursor, end_of_day))

        allday = [e["summary"] for e in events if e["all_day"] and day in e["days_in_range"]]
        header = f"{day:%a %Y-%m-%d}"
        if allday:
            header += f"   [{', '.join(allday)}]"
        print(f"\n{header}")
        if not gaps:
            print("  nothing free")
        for a, b in gaps:
            mins = round((b - a).total_seconds() / 60)
            print(f"  {a:%H:%M}-{b:%H:%M}  ({mins} min)")


def parse_window(text: str):
    a, b = text.split("-")
    return (
        datetime.strptime(a.strip(), "%H:%M").time(),
        datetime.strptime(b.strip(), "%H:%M").time(),
    )


def daterange(first, last):
    d = first
    while d <= last:
        yield d
        d += timedelta(days=1)


def cmd_conflicts(conn, args):
    first, last = parse_when(args.when)
    events = [e for e in fetch_range(conn, first, last, args) if not e["all_day"]]
    events.sort(key=lambda e: e["start"])

    clashes = []
    for i, a in enumerate(events):
        for b in events[i + 1 :]:
            if b["start"] >= a["end"]:
                break
            clashes.append((a, b))

    if not clashes:
        print(f"No overlaps between {first} and {last}.")
        return
    for a, b in clashes:
        overlap = round((min(a["end"], b["end"]) - b["start"]).total_seconds() / 60)
        print(f"\n{b['start']:%a %Y-%m-%d}  {overlap} min overlap")
        for e in (a, b):
            print(f"  {e['start']:%H:%M}-{e['end']:%H:%M}  {e['summary']}  -  {e['calendar']}")


def cmd_calendars(conn, args):
    rows = conn.execute(
        """
        select c.title as calendar, s.name as account, c.external_id as cal_external_id,
               (select count(*) from CalendarItem ci where ci.calendar_id = c.ROWID) as n
        from Calendar c left join Store s on s.ROWID = c.store_id
        order by s.name, c.title
        """
    ).fetchall()
    width = max(len(r["calendar"] or "") for r in rows)
    for r in rows:
        mark = "-" if hidden(r, args.cfg) else " "
        print(f"{mark} {r['calendar'] or '(untitled)':<{width}}  {r['n']:>5}  {r['account']}")
    lo, hi = cache_window(conn)
    print(f"\n  '-' hidden by default (--all to include).  Expanded occurrences: {lo}..{hi}")


# --- cli --------------------------------------------------------------------------


def main():
    # The shared flags hang off a parent parser so they work on either side of the
    # subcommand - `cal.py --all agenda week` and `cal.py agenda week --all` both read
    # naturally and it is not worth remembering which one argparse prefers.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--all", action="store_true", help="include hidden calendars")
    common.add_argument("--show-free", action="store_true", help="include events marked Free")
    common.add_argument(
        "--show-declined", action="store_true", help="include events you declined"
    )
    common.add_argument(
        "--calendar", action="append", help="restrict to calendars matching (repeatable)"
    )
    common.add_argument("--no-dedupe", action="store_true", help="one row per calendar copy")
    common.add_argument("--json", action="store_true")
    common.add_argument("--config", help="path to a config.toml overriding the defaults")

    p = argparse.ArgumentParser(
        prog="cal.py", description=__doc__.splitlines()[0], parents=[common]
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("agenda", parents=[common], help="what is on, for a day or a range")
    a.add_argument("when", nargs="?", default="today")
    a.set_defaults(fn=cmd_agenda)

    s = sub.add_parser(
        "search", parents=[common], help="find events by title, notes, location or attendee"
    )
    s.add_argument("text")
    s.add_argument("--range", default="-90d..+365d", help="window to search (default a year ahead)")
    s.set_defaults(fn=cmd_search)

    e = sub.add_parser("event", parents=[common], help="one event in full, from an ical:// link")
    e.add_argument("ident")
    e.add_argument("--open", action="store_true", help="also reveal it in Calendar.app")
    e.set_defaults(fn=cmd_event)

    f = sub.add_parser("free", parents=[common], help="gaps in the day")
    f.add_argument("when", nargs="?", default="today")
    f.add_argument("--between", help="clock window, default from config")
    f.add_argument("--min", type=int, default=30, help="ignore gaps shorter than this")
    f.set_defaults(fn=cmd_free)

    c = sub.add_parser("conflicts", parents=[common], help="overlapping events")
    c.add_argument("when", nargs="?", default="week")
    c.set_defaults(fn=cmd_conflicts)

    k = sub.add_parser("calendars", parents=[common], help="list calendars, marking hidden ones")
    k.set_defaults(fn=cmd_calendars)

    args = p.parse_args()
    args.cfg = load_config(args.config)
    if getattr(args, "between", None) is None and args.cmd == "free":
        args.between = args.cfg["day_window"]
    with connect() as conn:
        args.fn(conn, args)


if __name__ == "__main__":
    main()
