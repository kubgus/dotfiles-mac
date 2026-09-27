"""Shared plumbing for the two macOS stores this skill reads.

Everything here is store-agnostic: taking a safe snapshot, the two timestamp
conventions Apple mixes in one column, the date vocabulary both CLIs accept, and
config loading. Anything that knows a schema belongs in the script that owns it.

The two scripts had their own copy of all of this and the copies had started to
drift - different `-shm` handling, a `.lower()` on one side only. One home so the
next divergence has to be deliberate.
"""

from __future__ import annotations

import contextlib
import os
import re
import shutil
import sqlite3
import sys
import tempfile
from datetime import date, datetime, timedelta, timezone

MAC_EPOCH = 978307200  # 2001-01-01T00:00:00Z, Apple's reference date

UUID_RE = re.compile(
    r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
)


# --- the two timestamp conventions -------------------------------------------------
#
# Both stores keep dates as seconds from 2001-01-01 in a single column, but a timed
# thing is a real instant and an all-day thing is naive wall clock. Reading the second
# as the first shifts it by your UTC offset, which lands it on the wrong day and always
# in the same direction. These two functions are the whole fix; use the right one.


def local(ts: float) -> datetime:
    """A real instant -> local wall clock."""
    return datetime.fromtimestamp(ts + MAC_EPOCH)


def floating(ts: float) -> datetime:
    """A naive/floating value -> the wall clock it literally encodes.

    Read at UTC and stripped back to naive, because the number is not an instant at
    all: it is "midnight", and which midnight depends on where you are standing.
    """
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


def tidy(text: str) -> str:
    """One line, no runs of whitespace. Locations arrive with embedded newlines."""
    return re.sub(r"\s+", " ", (text or "")).strip()


# --- reading the store safely ------------------------------------------------------


@contextlib.contextmanager
def snapshot(path: str, prefix: str):
    """Snapshot the live store into a private temp file and hand back a connection.

    SQLite's own backup API rather than a file copy, for three reasons. It is atomic,
    so it cannot catch the owning app mid-checkpoint and produce a snapshot whose -wal
    disagrees with its main file. It opens the source `mode=ro`, so this cannot write
    to the store even by accident. And it lands one file instead of three, in a
    directory that is removed on the way out whatever happens.

    Snapshotting costs about 25 ms on an 18 MB store, which is cheap enough that
    caching it between runs is not worth leaving that much of his data sitting in the
    temp directory indefinitely.
    """
    work = tempfile.mkdtemp(prefix=prefix)
    try:
        uri = "file:" + path.replace("?", "%3f").replace("#", "%23") + "?mode=ro"
        try:
            source = sqlite3.connect(uri, uri=True)
        except sqlite3.OperationalError as exc:
            sys.exit(
                f"Cannot read {path}: {exc}\n"
                "Most likely this terminal lacks Full Disk Access."
            )
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


def store_age(path: str, suffixes: tuple[str, ...] = ("-wal",)) -> str:
    """How stale the store is, as a line to print, or empty if it is fresh enough.

    The sidecars matter as much as the main file: a change that has been written but
    not yet checkpointed lives in -wal, so a store whose main file is a week old can
    still be current.
    """
    newest = max(
        os.path.getmtime(path),
        *(os.path.getmtime(path + s) for s in suffixes if os.path.exists(path + s)),
    )
    if datetime.now() - datetime.fromtimestamp(newest) > timedelta(hours=12):
        return f"store last written {datetime.fromtimestamp(newest):%Y-%m-%d %H:%M}"
    return ""


# --- the shared command surface ----------------------------------------------------


def parse_when(text: str | None, allow_all: bool = False) -> tuple[date, date]:
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
    if allow_all and t in ("all", "ever"):
        return date(1970, 1, 1), date(2999, 12, 31)

    if ".." in t:
        a, b = t.split("..", 1)
        return parse_when(a, allow_all)[0], parse_when(b, allow_all)[1]

    m = re.fullmatch(r"([+-])(\d+)d", t)
    if m:
        n = int(m.group(2))
        if m.group(1) == "+":
            return today, today + timedelta(days=n)
        return today - timedelta(days=n), today

    return date.fromisoformat(t), date.fromisoformat(t)


def extract_id(text: str, lower: bool = False, strip_query: bool = False) -> str:
    """Pull an id out of a pasted link, a raw UUID, or a foreign id.

    The two stores want different normalisation: one matches a CloudKit identifier
    case-insensitively, the other carries Google event ids whose case is significant
    and query strings that are not part of the id.
    """
    m = UUID_RE.search(text or "")
    if m:
        return m.group(0).lower() if lower else m.group(0)
    tail = (text or "").strip().rstrip("/").split("/")[-1]
    if strip_query:
        tail = tail.split("?")[0]
    return tail.lower() if lower else tail


def load_config(defaults: dict, env_var: str, filename: str, explicit: str | None = None) -> dict:
    """Defaults, overlaid with the config file beside the skill if it is there.

    `explicit` is a path the user named, so a missing one is an error rather than a
    silent fall back to defaults - being told nothing is hidden when the file you
    asked for does not exist is the wrong kind of quiet.
    """
    path = (
        explicit
        or os.environ.get(env_var)
        or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), filename)
    )
    cfg = dict(defaults)
    if os.path.exists(path):
        import tomllib

        with open(path, "rb") as fh:
            cfg.update(tomllib.load(fh))
    elif explicit:
        sys.exit(f"No config at {path}")
    return cfg
