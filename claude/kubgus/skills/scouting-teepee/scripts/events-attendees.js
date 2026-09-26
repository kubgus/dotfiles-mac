/*
 * Browser-side driver for the tee-pee "Pridanie ludi na podujatie" dialog.
 *
 * Part of the scouting-teepee skill; see references/events-attendees.md.
 *
 * Injected whole as the body of a browser_evaluate call, it installs window.__teepee.
 * It exists because the dialog is PrimeFaces/JSF: the DOM is replaced on every update,
 * overlapping requests stale the ViewState, and the visible "Pridat (N)" text belongs to
 * a wrapper div rather than to the button that actually submits. Driving that by hand
 * means rediscovering the same traps every time.
 *
 * Everything is diacritics-insensitive, because the source list is typed by humans and
 * the directory is not: Kralik/Králik, Riecan/Riečan, Studeny/Studený.
 */
() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const norm = (s) =>
    (s || '')
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .toLowerCase()
      .replace(/\s+/g, ' ')
      .trim();

  const LIST = '[id$="eventPersonListId"]';
  const SEARCH = '[id$="eventPersonSearchId"]';
  const SELECTED = '[id$="selectedPersonListId"]';
  const SUBMIT = '[id$="addPeopleBtnId"]';

  // Wait until no ajax is in flight. PrimeFaces queues requests, so jQuery.active alone
  // is not enough - a queued-but-unsent request leaves it at zero.
  async function idle(timeoutMs = 15000) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      await sleep(100);
      const q = window.PrimeFaces && PrimeFaces.ajax && PrimeFaces.ajax.Queue;
      if (!((window.jQuery && jQuery.active > 0) || (q && !q.isEmpty()))) {
        await sleep(200);
        return true;
      }
    }
    return false;
  }

  // Same, but also waits for the dialog's person list to be re-attached. The container
  // is detached mid-update, so a querySelector landing in that window returns null.
  async function idleList(timeoutMs = 15000) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      if (!(await idle(deadline - Date.now()))) return false;
      if (document.querySelector(LIST)) return true;
      await sleep(100);
    }
    return false;
  }

  const count = () => {
    const s = document.querySelector(SELECTED);
    const m = s && s.innerText.match(/\((\d+)\)/);
    return m ? +m[1] : -1;
  };

  // "Pridaj 100 ludi z aktualneho listu (14,393 vsetkych ludi)" - the parenthesised
  // number is the true hit count, while the list itself caps at 100.
  const totalHits = () => {
    const a = document.querySelector(LIST + ' a.ui-commandlink');
    const m = a && a.innerText.match(/\(([\d,]+)\s/);
    return m ? +m[1].replace(/,/g, '') : null;
  };

  const rows = () =>
    Array.from(document.querySelectorAll(LIST + ' .ui-panel')).map((p) => ({
      name: ((p.querySelector('.BoldGray') || {}).innerText || '').trim(),
      unit: ((p.querySelector('.ListItemDesc') || {}).innerText || '').trim(),
      link: p.querySelector('a.ui-commandlink'),
    }));

  async function search(query) {
    const inp = document.querySelector(SEARCH);
    if (!inp) throw new Error('add-people dialog is not open');
    inp.value = query;
    inp.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true }));
    await sleep(700); // the field debounces at 500ms before it fires
    if (!(await idleList())) throw new Error('search timed out: ' + query);
    return { rows: rows(), total: totalHits() };
  }

  // Sheet side is "Firstname [Middle] Lastname - Nickname"; the directory stores
  // "Lastname Firstname [Middle]" and does not show the nickname in this dialog. Search
  // on the surname alone - it is the narrowest query the field accepts, since a full-name
  // query matches any token and returns hundreds of unrelated people. The nickname is
  // kept for disambiguation, not for lookup; see nicknameNarrow below.
  function parse(input) {
    const s = String(input);
    const i = s.indexOf(' - ');
    const bare = i === -1 ? s : s.slice(0, i);
    const nick = i === -1 ? null : s.slice(i + 3).trim() || null;
    const t = bare.split(/\s+/).filter(Boolean);
    return {
      input: s,
      nick,
      surname: t[t.length - 1],
      given: t.slice(0, -1).join(' '),
      want: norm(t[t.length - 1] + ' ' + t.slice(0, -1).join(' ')),
    };
  }

  const key = (x) => norm(x.name) + '|' + norm(x.unit);

  // The search field also matches nicknames, diacritics-insensitively, and returns the
  // person under their full name and primary unit. That makes a nickname a good second
  // opinion - "Rybár" gives three people, "Kaktus" gives one of them - but a poor lookup
  // its own, because the field matches substrings of surnames and unit names too:
  // "Lup" pulls in Lupták and Halupková, "Kométa" pulls in everyone in the unit
  // of that name. So only ever intersect: keep the candidate the nickname and the surname
  // agree on, and ignore everything the nickname found on its own.
  async function nicknameNarrow(nick, candidates) {
    if (!nick || candidates.length < 2) return null;
    const { rows: r } = await search(nick);
    const hit = new Set(r.map(key));
    const both = candidates.filter((c) => hit.has(key(c)));
    return both.length === 1 ? both[0] : null;
  }

  async function lookup(input) {
    const p = parse(input);
    const { rows: r, total } = await search(p.surname);
    const exact = r.filter((x) => norm(x.name) === p.want);
    const sameSurname = r.filter((x) => norm(x.name).split(' ')[0] === norm(p.surname));
    const l = {
      input: p.input,
      nick: p.nick,
      query: p.surname,
      exact,
      sameSurname,
      total,
      truncated: total != null && total > r.length,
      viaNick: null,
    };
    if (exact.length !== 1) {
      l.viaNick = await nicknameNarrow(p.nick, exact.length > 1 ? exact : sameSurname);
    }
    return l;
  }

  function verdict(l) {
    if (l.exact.length === 1) return 'MATCH';
    if (l.viaNick) return 'MATCH_BY_NICKNAME';
    if (l.exact.length > 1) return 'AMBIGUOUS';
    if (l.truncated) return 'TRUNCATED';
    return 'NO_MATCH';
  }

  const chosen = (l) => (l.exact.length === 1 ? l.exact[0] : l.viaNick);

  const shape = (x) => ({ name: x.name, unit: x.unit });

  async function clickRow(row) {
    const before = count();
    row.link.click();
    await sleep(300);
    await idleList();
    for (let i = 0; i < 15 && count() !== before + 1; i++) await sleep(250);
    return count() === before + 1;
  }

  const GRID = '[id$="eventPersonsGridId"]';

  const rosterPage = () =>
    Array.from(document.querySelectorAll(GRID + ' .ui-datagrid-column .ui-panel')).map((p) => {
      const n = p.querySelectorAll('.ListItemName');
      return {
        name: ((n[0] || {}).innerText || '').trim(),
        nick: n[1] ? (n[1].innerText || '').trim().replace(/^\(|\)$/g, '') : null,
        unit: ((p.querySelector('.ListItemDesc') || {}).innerText || '').trim(),
      };
    });

  window.__teepee = {
    /* Who is already on the event. Read this before resolving anything: tee-pee hides
       people who are already attendees from the add-people dialog, so an existing
       attendee looks like NO_MATCH, and - worse - a name with two directory hits can
       look like a clean MATCH once the right one has been hidden. Subtract this set from
       the input list first and both failure modes disappear. */
    async roster() {
      const tab = document.querySelector('a[href$="attendeesTabId"]');
      if (tab) tab.click();
      for (let i = 0; i < 40; i++) {
        await sleep(200);
        if (document.querySelector(GRID)) break;
      }
      const w = window.PF && PF('eventAttendeesListGrid');
      if (!w) return { ok: false, error: 'attendee grid widget not found' };
      const pg = w.getPaginator();
      const expected = pg.cfg.rowCount;
      const byKey = new Map();
      for (let i = 0; i < pg.cfg.pageCount; i++) {
        const before = (rosterPage()[0] || {}).name;
        pg.setPage(i);
        await sleep(300);
        // Wait for the page to actually turn, not just for ajax to go quiet - the grid
        // can still be showing the previous page when jQuery.active hits zero, which
        // double-counts a row and silently inflates the roster.
        for (let t = 0; t < 60; t++) {
          await sleep(150);
          if (window.jQuery && jQuery.active > 0) continue;
          if (i === 0 || (rosterPage()[0] || {}).name !== before) break;
        }
        for (const r of rosterPage()) byKey.set(norm(r.name) + '|' + norm(r.unit), r);
      }
      pg.setPage(0);
      await idle();
      const people = Array.from(byKey.values());
      return {
        ok: people.length === expected,
        expected,
        collected: people.length,
        people,
        names: people.map((p) => p.name),
      };
    },

    /* Open the Prihlaseni tab and the add-people dialog. */
    async open() {
      const tab = document.querySelector('a[href$="attendeesTabId"]');
      if (tab) tab.click();
      for (let i = 0; i < 40; i++) {
        await sleep(200);
        if (document.querySelector('a[title="Pridat"]') || document.querySelector('a[title="Pridať"]')) break;
      }
      const add =
        document.querySelector('a[title="Pridať"]') || document.querySelector('a[title="Pridat"]');
      if (!add) return { ok: false, error: 'no Pridat link - is this an event details page?' };
      add.click();
      for (let i = 0; i < 60; i++) {
        await sleep(200);
        if (document.querySelector(LIST + ' .ui-panel')) break;
      }
      return { ok: !!document.querySelector(LIST), selected: count() };
    },

    /* Read-only: what does the directory hold for each of these names? */
    async resolve(names) {
      const out = [];
      for (const n of names) {
        const l = await lookup(n);
        const c = chosen(l);
        out.push({
          input: l.input,
          status: verdict(l),
          match: c ? shape(c) : null,
          candidates: c ? null : l.sameSurname.slice(0, 12).map(shape),
          total: l.total,
        });
        await sleep(150);
      }
      return { selected: count(), results: out };
    },

    /* Resolve and select in one pass, but only where exactly one person matches.
       Anything else comes back untouched for a human to rule on. */
    async selectAuto(names) {
      const out = [];
      for (const n of names) {
        const l = await lookup(n);
        const v = verdict(l);
        const c = chosen(l);
        if (c) {
          const ok = await clickRow(c);
          out.push({
            input: l.input,
            status: ok ? 'SELECTED' : 'CLICK_FAILED',
            via: v === 'MATCH_BY_NICKNAME' ? 'nickname ' + l.nick : 'name',
            match: shape(c),
          });
        } else {
          out.push({
            input: l.input,
            status: v,
            candidates: l.sameSurname.slice(0, 12).map(shape),
            total: l.total,
          });
        }
        await sleep(150);
      }
      const results = out;
      return {
        selected: count(),
        selectedNow: results.filter((r) => r.status === 'SELECTED').length,
        unresolved: results.filter((r) => r.status !== 'SELECTED'),
        results,
      };
    },

    /* Select named people explicitly, once a human has picked between candidates.
       Pass [{name: "Dubovec Michal", unit: "Sovy"}, ...] using the directory's
       own spelling, taken verbatim from a resolve/selectAuto candidate list. */
    async selectExact(targets) {
      const out = [];
      for (const t of targets) {
        const query = t.query || t.name.split(/\s+/)[0];
        const { rows: r } = await search(query);
        const hit = r.filter(
          (x) => norm(x.name) === norm(t.name) && (!t.unit || norm(x.unit) === norm(t.unit))
        );
        if (hit.length === 1) {
          const ok = await clickRow(hit[0]);
          out.push({ target: t.name, status: ok ? 'SELECTED' : 'CLICK_FAILED', match: shape(hit[0]) });
        } else {
          out.push({
            target: t.name,
            status: hit.length ? 'STILL_AMBIGUOUS' : 'NOT_FOUND',
            saw: r.slice(0, 12).map(shape),
          });
        }
        await sleep(150);
      }
      return { selected: count(), results: out };
    },

    count,

    /* Submit. This is a real form POST, so the page navigates and every in-page handle
       - including window.__teepee - is destroyed. Expect browser_evaluate to report a
       destroyed execution context; that is success, not an error. Re-read the tab
       label afterwards to confirm. */
    commit() {
      const b = document.querySelector(SUBMIT);
      if (!b) return { ok: false, error: 'submit button not found' };
      if (b.disabled) return { ok: false, error: 'nothing selected' };
      const n = count();
      b.click();
      return { ok: true, submitted: n };
    },
  };

  return 'teepee driver ready';
}
