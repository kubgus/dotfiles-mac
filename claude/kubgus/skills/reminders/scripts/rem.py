#!/usr/bin/env python3
"""Read the macOS Reminders store directly. Read-only, stdlib only.

Reminders keeps one Core Data store per account under a single group container, plus
a couple of empty decoys. This picks the live one, snapshots it, and reads the
snapshot - so it can never write to your reminders and never prompts for Automation
access. See SKILL.md for the traps this encodes.
"""

from __future__ import annotations

import argparse
import contextlib
import glob
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from datetime import date, datetime, timedelta, timezone

STORE_DIR = os.path.expanduser(
    "~/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores"
)

# Deliberately inert: with no config the script hides nothing beyond what is provably
# gone (tombstones), so what you see is what the store holds. Every opinion about
# which lists are noise lives in config.toml, the one file allowed to be personal.
DEFAULTS = {
    "hide_lists": [],
    "hide_matching": [],
    "hide_smart_lists": True,
    "nest_subtasks": True,
    "due_window": "today",
    "done_window": "-7d",
}


def load_config(explicit: str | None = None) -> dict:
    path = (
        explicit
        or os.environ.get("CLAUDE_REMINDERS_CONFIG")
        or os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config.toml"
        )
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
    """Whether the config says this list is noise.

    Matched against the group and account as well as the list name, so one pattern
    can retire a whole branch of the sidebar - hiding the group "Work" takes every
    list under it without naming them, including ones added later.
    """
    if (row["list_name"] or "") in cfg["hide_lists"]:
        return True
    if cfg["hide_smart_lists"] and row["is_smart"]:
        return True
    haystack = "\n".join(
        str(row[k] or "") for k in ("list_name", "group_name", "account")
    ).lower()
    return any(p.lower() in haystack for p in cfg["hide_matching"])


MAC_EPOCH = 978307200  # 2001-01-01T00:00:00Z, Apple's reference date

# 0/1/5/9 is Apple's CalDAV priority scale, not a 1-3 enum. Nothing in between is
# used by Reminders.app, but the column is an int and a synced client could write one.
PRIORITY_MARK = {1: "!!!", 5: "!!", 9: "!"}
PRIORITY_NAME = {1: "high", 5: "medium", 9: "low"}

# EKRecurrenceFrequency ordering. Only daily and weekly appear in this store, so the
# monthly and yearly labels are inferred from the enum rather than observed.
FREQUENCY = {0: "daily", 1: "weekly", 2: "monthly", 3: "yearly"}
PROXIMITY = {1: "arriving at", 2: "leaving"}

UUID_RE = re.compile(
    r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
)


# --- time -------------------------------------------------------------------------
#
# Two conventions in one column, exactly as in the Calendar store. A timed reminder's
# due date is a real UTC instant and carries a real ZTIMEZONE. An all-day reminder's
# is naive wall clock - the literal number for "midnight on the 26th" - so converting
# it to local time shifts it by your UTC offset and lands it on the wrong day.


def local(ts: float) -> datetime:
    """A real instant -> local wall clock."""
    return datetime.fromtimestamp(ts + MAC_EPOCH)


def floating(ts: float) -> datetime:
    """A naive/floating value -> the wall clock it literally encodes."""
    return datetime.fromtimestamp(ts + MAC_EPOCH, timezone.utc).replace(tzinfo=None)


def elsewhere(tz: str, when: datetime) -> bool:
    """True if `tz` is a real zone whose clock differs from yours at that moment."""
    if not tz or tz in ("_float", "GMT"):
        return False
    try:
        from zoneinfo import ZoneInfo

        theirs = when.replace(tzinfo=None).astimezone(ZoneInfo(tz)).utcoffset()
        return theirs != when.astimezone().utcoffset()
    except Exception:
        return False


def due_at(row) -> datetime | None:
    if row["due"] is None:
        return None
    return (floating if row["all_day"] else local)(row["due"])


# --- store access -----------------------------------------------------------------


def probe(path: str) -> int:
    """How many reminders a candidate store holds, or -1 if it is not one."""
    try:
        conn = sqlite3.connect(f"file:{path}?mode=ro&immutable=1", uri=True)
    except sqlite3.OperationalError:
        return -1
    try:
        return conn.execute("select count(*) from ZREMCDREMINDER").fetchone()[0]
    except sqlite3.Error:
        return -1
    finally:
        conn.close()


def pick_store(explicit: str | None = None) -> str:
    """The one store that actually holds reminders.

    There are typically four files here and three of them are empty: a local store,
    a SiriFoundInApps store, and a stub for an account that never synced. They all
    carry the same schema, so anything that picks by filename or by first match has
    a three-in-four chance of reporting an empty task list as an empty task list.
    """
    chosen = explicit or os.environ.get("CLAUDE_REMINDERS_STORE")
    if chosen:
        return os.path.expanduser(chosen)
    if not os.path.isdir(STORE_DIR):
        sys.exit(
            f"No reminders container at {STORE_DIR}\n"
            "Open Reminders.app once to create it, or grant this terminal Full Disk Access."
        )
    best, count = None, 0
    for path in sorted(glob.glob(os.path.join(STORE_DIR, "Data-*.sqlite"))):
        n = probe(path)
        if n > count:
            best, count = path, n
    if best is None:
        sys.exit(
            f"Every store under {STORE_DIR} is empty or unreadable.\n"
            "Most likely this terminal lacks Full Disk Access, or Reminders has never synced."
        )
    return best


@contextlib.contextmanager
def connect(path: str):
    """Snapshot the live store into a private temp file and hand back a connection.

    SQLite's own backup API rather than a file copy: it is atomic, so it cannot catch
    Reminders mid-checkpoint and produce a snapshot whose -wal disagrees with its main
    file; it opens the source mode=ro, so this cannot write to your reminders even
    with a bug in it; and it lands one file instead of three, in a directory removed
    on the way out whatever happens.
    """
    work = tempfile.mkdtemp(prefix="claude-reminders-")
    try:
        uri = "file:" + path.replace("?", "%3f").replace("#", "%23") + "?mode=ro"
        try:
            source = sqlite3.connect(uri, uri=True)
        except sqlite3.OperationalError as exc:
            sys.exit(f"Cannot read {path}: {exc}\nMost likely this terminal lacks Full Disk Access.")
        conn = sqlite3.connect(os.path.join(work, "snapshot.sqlite"))
        try:
            source.backup(conn)
        finally:
            source.close()
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()
    finally:
        shutil.rmtree(work, ignore_errors=True)


def store_age(path: str) -> str:
    newest = max(
        os.path.getmtime(path),
        *(os.path.getmtime(path + s) for s in ("-wal", "-shm") if os.path.exists(path + s)),
    )
    if datetime.now() - datetime.fromtimestamp(newest) > timedelta(hours=12):
        return f"store last written {datetime.fromtimestamp(newest):%Y-%m-%d %H:%M}"
    return ""


def entities(conn) -> dict[str, int]:
    """Core Data's entity ids are assigned per store, not fixed by Apple.

    Z_ENT is an index into Z_PRIMARYKEY, and a macOS update that adds an entity
    renumbers everything after it. Resolving by name costs one query and means a
    hardcoded 34 never silently starts meaning something else.
    """
    return {
        name: ent for ent, name in conn.execute("select Z_ENT, Z_NAME from Z_PRIMARYKEY")
    }


# --- date ranges ------------------------------------------------------------------


def parse_when(text: str | None) -> tuple[date, date]:
    """Return an inclusive [first, last] local date range."""
    today = date.today()
    if not text:
        return today, today

    t = text.strip().lower()
    simple = {"today": (0, 0), "tomorrow": (1, 1), "yesterday": (-1, -1)}
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
    if t in ("all", "ever"):
        return date(1970, 1, 1), date(2999, 12, 31)

    if ".." in t:
        a, b = t.split("..", 1)
        return parse_when(a)[0], parse_when(b)[1]

    m = re.fullmatch(r"([+-])(\d+)d", t)
    if m:
        n = int(m.group(2))
        if m.group(1) == "+":
            return today, today + timedelta(days=n)
        return today - timedelta(days=n), today

    return date.fromisoformat(t), date.fromisoformat(t)


# --- reading ----------------------------------------------------------------------

REMINDER_SQL = """
select
    r.Z_PK                              as pk,
    r.ZTITLE                            as title,
    r.ZNOTES                            as notes,
    r.ZDUEDATE                          as due,
    r.ZSTARTDATE                        as start,
    r.ZALLDAY                           as all_day,
    r.ZCOMPLETED                        as completed,
    r.ZCOMPLETIONDATE                   as completed_at,
    r.ZCREATIONDATE                     as created,
    r.ZLASTMODIFIEDDATE                 as modified,
    r.ZPRIORITY                         as priority,
    r.ZFLAGGED                          as flagged,
    r.ZPARENTREMINDER                   as parent,
    r.ZTIMEZONE                         as tz,
    coalesce(r.ZCKIDENTIFIER, r.ZDACALENDARITEMUNIQUEIDENTIFIER) as uuid,
    lower(hex(r.ZIDENTIFIER))           as local_id,
    l.Z_PK                              as list_pk,
    l.ZNAME                             as list_name,
    (l.Z_ENT = :smart)                  as is_smart,
    g.ZNAME                             as group_name,
    a.ZNAME                             as account
from ZREMCDREMINDER r
left join ZREMCDBASELIST l on l.Z_PK = r.ZLIST
left join ZREMCDBASELIST g on g.Z_PK = l.ZPARENTLIST
left join ZREMCDOBJECT   a on a.Z_PK = l.ZACCOUNT and a.Z_ENT = :account
where r.ZMARKEDFORDELETION = 0
  and r.ZLIST is not null
  and coalesce(l.ZMARKEDFORDELETION, 0) = 0
"""


def fetch(conn, ent, cfg, args, *, completed=False) -> list[dict]:
    """Every live reminder, decorated with tags, recurrence and location alarms.

    Three small side queries rather than three left joins, because a reminder with
    two tags and a location alarm would otherwise arrive as four rows and every
    count downstream would be wrong.
    """
    rows = conn.execute(
        REMINDER_SQL + " and r.ZCOMPLETED = :done",
        {"smart": ent["REMCDSmartList"], "account": ent["REMCDAccount"], "done": int(completed)},
    ).fetchall()

    tags, recur, places = decorations(conn, ent)
    wanted = [w.lower() for w in (args.list or [])]

    out = []
    for row in rows:
        if not args.all and hidden(row, cfg):
            continue
        if wanted and not any(
            w in (row["list_name"] or "").lower() or w in (row["group_name"] or "").lower()
            for w in wanted
        ):
            continue
        r = dict(row)
        r["due_dt"] = due_at(row)
        r["tags"] = tags.get(row["pk"], [])
        r["recurrence"] = recur.get(row["pk"])
        r["places"] = places.get(row["pk"], [])
        r["children"] = []
        out.append(r)
    return out


def decorations(conn, ent) -> tuple[dict, dict, dict]:
    tags: dict[int, list[str]] = {}
    for pk, name in conn.execute(
        "select h.ZREMINDER3, lbl.ZNAME from ZREMCDOBJECT h"
        " join ZREMCDHASHTAGLABEL lbl on lbl.Z_PK = h.ZHASHTAGLABEL"
        " where h.Z_ENT = ? and h.ZREMINDER3 is not null",
        (ent["REMCDHashtag"],),
    ):
        tags.setdefault(pk, []).append(name)

    recur: dict[int, str] = {}
    for pk, freq, step in conn.execute(
        "select ZREMINDER4, ZFREQUENCY, ZINTERVAL from ZREMCDOBJECT"
        " where Z_ENT = ? and ZREMINDER4 is not null",
        (ent["REMCDRecurrenceRule"],),
    ):
        word = FREQUENCY.get(freq, f"freq{freq}")
        recur[pk] = word if (step or 1) == 1 else f"every {step} {word.rstrip('ly')}s"

    places: dict[int, list[str]] = {}
    for pk, title, prox in conn.execute(
        "select al.ZREMINDER, t.ZTITLE, t.ZPROXIMITY from ZREMCDOBJECT al"
        " join ZREMCDOBJECT t on t.ZALARM = al.Z_PK and t.Z_ENT = ?"
        " where al.Z_ENT = ? and al.ZREMINDER is not null",
        (ent["REMCDAlarmLocationTrigger"], ent["REMCDAlarm"]),
    ):
        places.setdefault(pk, []).append(f"{PROXIMITY.get(prox, 'near')} {title}")

    return tags, recur, places


def nest(items: list[dict], cfg, args) -> list[dict]:
    """Hang subtasks under their parent and return only the top level.

    Roughly one reminder in seven here is a subtask. Printed flat they read as
    independent tasks - "Napisat mail" with no sign that it belongs to the thing
    two lines up - and they inflate every count. A subtask whose parent is not in
    the current selection is promoted rather than dropped, or completing a parent
    would hide live work.
    """
    if not cfg["nest_subtasks"] or args.flat:
        return items
    by_pk = {i["pk"]: i for i in items}
    top = []
    for item in items:
        parent = by_pk.get(item["parent"]) if item["parent"] else None
        if parent is not None:
            parent["children"].append(item)
        else:
            top.append(item)
    return top


# --- rendering --------------------------------------------------------------------


def tidy(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "")).strip()


def first_line(text: str, limit: int = 60) -> str:
    line = tidy((text or "").split("\n")[0])
    return line if len(line) <= limit else line[: limit - 1] + "…"


def fmt_due(item, *, with_date=True) -> str:
    dt = item["due_dt"]
    if dt is None:
        return ""
    if item["all_day"]:
        return f"{dt:%a %Y-%m-%d}" if with_date else "all-day"
    return f"{dt:%a %Y-%m-%d %H:%M}" if with_date else f"{dt:%H:%M}"


def tail_bits(item, *, show_list=True) -> list[str]:
    bits = []
    if show_list:
        bits.append(item["list_name"] or "(no list)")
    if item["recurrence"]:
        bits.append(item["recurrence"])
    for place in item["places"]:
        bits.append(place)
    for tag in item["tags"]:
        bits.append(f"#{tag}")
    if item["flagged"]:
        bits.append("flagged")
    # Only ever set when a command deliberately mixes states - `search --done` puts an
    # open and a finished reminder on adjacent lines, and they must not read alike.
    if item["completed"]:
        bits.append(
            f"done {local(item['completed_at']):%Y-%m-%d}" if item["completed_at"] else "done"
        )
    if item["notes"]:
        bits.append(first_line(item["notes"], 44))
    return bits


def line(item, when: str, width: int, *, indent=2, show_list=True) -> str:
    mark = PRIORITY_MARK.get(item["priority"] or 0, "")
    title = tidy(item["title"]) + (f" {mark}" if mark else "")
    bits = tail_bits(item, show_list=show_list)
    tail = f"  -  {' · '.join(bits)}" if bits else ""
    # No date column at all when nothing in the group is dated, so an undated
    # list does not indent every line as if it were a subtask.
    stamp = f"{when:<{width}}  " if width else ""
    return f"{' ' * indent}{stamp}{title}{tail}"


def render_group(heading: str, items: list[dict], *, dated: bool, show_list=True):
    print(f"\n{heading}")
    whens = [fmt_due(i, with_date=not dated) if i["due_dt"] else "" for i in items]
    width = max((len(w) for w in whens), default=0)
    for item, when in zip(items, whens):
        print(line(item, when, width, show_list=show_list))
        for kid in item["children"]:
            kid_when = fmt_due(kid, with_date=not dated) if kid["due_dt"] else ""
            print(line(kid, kid_when, width, indent=4, show_list=False))


def note_line(*parts):
    parts = [p for p in parts if p]
    if parts:
        print(f"\n({'; '.join(parts)})")


def jsonable(item) -> dict:
    out = {
        k: item[k]
        for k in (
            "title", "notes", "priority", "flagged", "completed",
            "list_name", "group_name", "account", "uuid", "tags",
            "recurrence", "places", "all_day", "tz",
        )
    }
    out["due"] = item["due_dt"].isoformat() if item["due_dt"] else None
    out["completed_at"] = local(item["completed_at"]).isoformat() if item["completed_at"] else None
    out["created"] = local(item["created"]).isoformat() if item["created"] else None
    out["children"] = [jsonable(k) for k in item["children"]]
    return out


def emit_json(items):
    print(json.dumps([jsonable(i) for i in items], ensure_ascii=False, indent=2))


# --- commands ---------------------------------------------------------------------


def cmd_due(conn, args):
    """Dated work in a window, with everything already overdue on top.

    Overdue is included by default because a task manager that answers "what is due
    today" without mentioning the three things that were due last week is answering
    a question nobody asked.
    """
    ent = entities(conn)
    first, last = parse_when(args.when)
    items = [i for i in fetch(conn, ent, args.cfg, args) if i["due_dt"]]

    overdue = [i for i in items if i["due_dt"].date() < date.today()]
    inrange = [i for i in items if first <= i["due_dt"].date() <= last]
    if args.no_overdue:
        overdue = []
    else:
        inrange = [i for i in inrange if i["due_dt"].date() >= date.today()]

    if args.json:
        emit_json(sorted(overdue + inrange, key=lambda i: i["due_dt"]))
        return

    if not overdue and not inrange:
        span = f"{first:%Y-%m-%d}" if first == last else f"{first:%Y-%m-%d}..{last:%Y-%m-%d}"
        print(f"Nothing due {span}.")
        note_line(store_age(args.store), undated_note(conn, ent, args))
        return

    if overdue:
        render_group("Overdue", nest(sorted(overdue, key=lambda i: i["due_dt"]), args.cfg, args), dated=False)

    days: dict[date, list[dict]] = {}
    for item in sorted(inrange, key=lambda i: i["due_dt"]):
        days.setdefault(item["due_dt"].date(), []).append(item)
    for day, group in days.items():
        render_group(f"{day:%a %Y-%m-%d}", nest(group, args.cfg, args), dated=True)

    note_line(store_age(args.store), undated_note(conn, ent, args))


def undated_note(conn, ent, args) -> str:
    """How much open work carries no date at all.

    Most of this store is undated, so a date-windowed answer is a slice of the task
    list rather than the task list. One trailing count says so without listing them.
    """
    n = sum(1 for i in fetch(conn, ent, args.cfg, args) if not i["due_dt"])
    return f"{n} open with no due date - `rem.py open` for those" if n else ""


def cmd_open(conn, args):
    """Everything open, grouped by list. The default view of the task list."""
    ent = entities(conn)
    items = fetch(conn, ent, args.cfg, args)
    if args.undated:
        items = [i for i in items if not i["due_dt"]]
    if args.json:
        emit_json(items)
        return
    if not items:
        print("Nothing open.")
        note_line(store_age(args.store))
        return

    lists: dict[str, list[dict]] = {}
    for item in items:
        lists.setdefault(item["list_name"] or "(no list)", []).append(item)

    for name, group in sorted(lists.items()):
        group = nest(sorted(group, key=sort_key), args.cfg, args)
        render_group(f"{name} ({len(group)})", group, dated=False, show_list=False)
    note_line(store_age(args.store))


def sort_key(item):
    """Dated before undated, then by date, then by priority, then by age."""
    return (
        item["due_dt"] is None,
        item["due_dt"] or datetime.max,
        {1: 0, 5: 1, 9: 2}.get(item["priority"] or 0, 3),
        item["created"] or 0,
    )


def cmd_search(conn, args):
    ent = entities(conn)
    needle = args.text.lower()
    pool = fetch(conn, ent, args.cfg, args)
    if args.done or args.all_states:
        pool += fetch(conn, ent, args.cfg, args, completed=True)

    hits = [
        i
        for i in pool
        if needle in (i["title"] or "").lower()
        or needle in (i["notes"] or "").lower()
        or needle in (i["list_name"] or "").lower()
        or any(needle in t.lower() for t in i["tags"])
    ]
    if args.json:
        emit_json(sorted(hits, key=sort_key))
        return
    if not hits:
        print(f"No reminder matches {args.text!r}.")
        if not (args.done or args.all_states):
            print("(open reminders only - pass --done to search completed ones too)")
        return

    render_group(f"{len(hits)} matching {args.text!r}", nest(sorted(hits, key=sort_key), args.cfg, args), dated=False)
    note_line(store_age(args.store))


def cmd_done(conn, args):
    ent = entities(conn)
    first, last = parse_when(args.when or args.cfg["done_window"])
    items = [
        i
        for i in fetch(conn, ent, args.cfg, args, completed=True)
        if i["completed_at"] and first <= local(i["completed_at"]).date() <= last
    ]
    if args.json:
        emit_json(sorted(items, key=lambda i: i["completed_at"]))
        return
    if not items:
        print(f"Nothing completed {first:%Y-%m-%d}..{last:%Y-%m-%d}.")
        return
    days: dict[date, list[dict]] = {}
    for item in sorted(items, key=lambda i: i["completed_at"]):
        days.setdefault(local(item["completed_at"]).date(), []).append(item)
    for day, group in days.items():
        print(f"\n{day:%a %Y-%m-%d}")
        for item in group:
            bits = tail_bits(item)
            print(f"  {tidy(item['title'])}  -  {' · '.join(bits)}")
    note_line(store_age(args.store))


def cmd_show(conn, args):
    """One reminder in full, ignoring the config's list filters.

    He named this reminder, so it shows whatever list it lives on and whether it is
    completed - a lookup is not an agenda and should not quietly come back empty.
    """
    ent = entities(conn)
    ident = extract_id(args.ident)
    pool = fetch(conn, ent, args.cfg, args) + fetch(conn, ent, args.cfg, args, completed=True)
    hit = next(
        (
            i
            for i in pool
            if (i["uuid"] or "").lower() == ident or (i["local_id"] or "") == ident.replace("-", "")
        ),
        None,
    )
    if hit is None:
        sys.exit(f"No reminder with id {args.ident}")
    if args.json:
        emit_json([hit])
        return

    print(tidy(hit["title"]))
    rows = [("list", " / ".join(p for p in (hit["group_name"], hit["list_name"]) if p))]
    if hit["due_dt"]:
        when = fmt_due(hit) + (" (all-day)" if hit["all_day"] else "")
        if not hit["all_day"] and elsewhere(hit["tz"], hit["due_dt"]):
            when += f"  [set in {hit['tz']}]"
        rows.append(("due", when))
    if hit["recurrence"]:
        rows.append(("repeats", hit["recurrence"]))
    if hit["places"]:
        rows.append(("where", ", ".join(hit["places"])))
    if hit["priority"]:
        rows.append(("priority", PRIORITY_NAME.get(hit["priority"], str(hit["priority"]))))
    if hit["flagged"]:
        rows.append(("flagged", "yes"))
    if hit["tags"]:
        rows.append(("tags", " ".join(f"#{t}" for t in hit["tags"])))
    rows.append(
        ("status", f"completed {local(hit['completed_at']):%Y-%m-%d}" if hit["completed"] else "open")
    )
    if hit["created"]:
        rows.append(("created", f"{local(hit['created']):%Y-%m-%d}"))
    if hit["uuid"]:
        rows.append(("id", hit["uuid"]))

    width = max(len(k) for k, _ in rows)
    for key, value in rows:
        print(f"  {key:<{width}}  {value}")
    if hit["notes"]:
        print("\n" + tidy_block(hit["notes"]))

    if args.open:
        reveal(hit)


def tidy_block(text: str) -> str:
    return "\n".join("  " + ln for ln in re.sub(r"\n{3,}", "\n\n", text.strip()).split("\n"))


def reveal(hit):
    """Best effort. The per-reminder URL scheme is undocumented and may not resolve."""
    if not hit["uuid"]:
        return
    subprocess.run(["open", f"x-apple-reminderkit://REMCDReminder/{hit['uuid']}"], check=False)


def extract_id(text: str) -> str:
    m = UUID_RE.search(text or "")
    if m:
        return m.group(0).lower()
    return (text or "").strip().lower().rsplit("/", 1)[-1]


def cmd_lists(conn, args):
    """Lists and groups as the sidebar has them, marking what the config hides."""
    ent = entities(conn)
    rows = conn.execute(
        "select l.Z_PK pk, l.ZNAME list_name, l.ZISGROUP is_group, l.ZPARENTLIST parent,"
        "       (l.Z_ENT = ?) is_smart, g.ZNAME group_name, a.ZNAME account"
        " from ZREMCDBASELIST l"
        " left join ZREMCDBASELIST g on g.Z_PK = l.ZPARENTLIST"
        " left join ZREMCDOBJECT a on a.Z_PK = l.ZACCOUNT and a.Z_ENT = ?"
        " where l.ZMARKEDFORDELETION = 0 and l.ZNAME is not null"
        " order by coalesce(g.ZNAME, l.ZNAME), l.ZDADISPLAYORDER",
        (ent["REMCDSmartList"], ent["REMCDAccount"]),
    ).fetchall()

    counts: dict[int, int] = {}
    for pk, n in conn.execute(
        "select ZLIST, count(*) from ZREMCDREMINDER"
        " where ZMARKEDFORDELETION = 0 and ZCOMPLETED = 0 and ZLIST is not null group by ZLIST"
    ):
        counts[pk] = n

    for row in rows:
        mark = "-" if hidden(row, args.cfg) else " "
        kind = "group" if row["is_group"] else ("smart" if row["is_smart"] else "")
        n = counts.get(row["pk"], 0)
        label = row["list_name"]
        if row["group_name"]:
            label = f"{row['group_name']} / {label}"
        bits = [b for b in (kind, row["account"], f"{n} open" if n else "") if b]
        print(f"{mark} {label}  -  {' · '.join(bits)}" if bits else f"{mark} {label}")
    print("\n(- means hidden by config.toml; --all includes them)")


# --- cli --------------------------------------------------------------------------


def main():
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--all", action="store_true", help="include hidden lists")
    common.add_argument(
        "--list", action="append", help="restrict to lists or groups matching (repeatable)"
    )
    common.add_argument("--flat", action="store_true", help="subtasks on their own lines")
    common.add_argument("--json", action="store_true")
    common.add_argument("--config", help="path to a config.toml overriding the defaults")
    common.add_argument("--store", help="path to a specific Reminders store")

    p = argparse.ArgumentParser(
        prog="rem.py", description=__doc__.splitlines()[0], parents=[common]
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    d = sub.add_parser("due", parents=[common], help="dated work, overdue first")
    d.add_argument("when", nargs="?", default=None)
    d.add_argument("--no-overdue", action="store_true", help="only the window asked for")
    d.set_defaults(fn=cmd_due)

    o = sub.add_parser("open", parents=[common], help="everything open, grouped by list")
    o.add_argument("--undated", action="store_true", help="only reminders with no due date")
    o.set_defaults(fn=cmd_open)

    s = sub.add_parser("search", parents=[common], help="find by title, notes, list or tag")
    s.add_argument("text")
    s.add_argument("--done", action="store_true", help="search completed reminders too")
    s.add_argument("--all-states", action="store_true", help=argparse.SUPPRESS)
    s.set_defaults(fn=cmd_search)

    w = sub.add_parser("done", parents=[common], help="what was completed, and when")
    w.add_argument("when", nargs="?", default=None)
    w.set_defaults(fn=cmd_done)

    h = sub.add_parser("show", parents=[common], help="one reminder in full, from an id or link")
    h.add_argument("ident")
    h.add_argument("--open", action="store_true", help="also reveal it in Reminders.app")
    h.set_defaults(fn=cmd_show)

    k = sub.add_parser("lists", parents=[common], help="lists and groups, marking hidden ones")
    k.set_defaults(fn=cmd_lists)

    args = p.parse_args()
    args.cfg = load_config(args.config)
    if getattr(args, "when", None) is None and args.cmd == "due":
        args.when = args.cfg["due_window"]
    args.store = pick_store(args.store)
    with connect(args.store) as conn:
        args.fn(conn, args)


if __name__ == "__main__":
    main()
