/*
 * Browser-side driver for the tee-pee new-event form (/events/create).
 * Part of the scouting-teepee skill; see references/events-create.md.
 *
 * Injected whole as the body of a browser_evaluate call, it installs window.__teepeeNew.
 * Every control here needs a different trick - a checkbox that only responds to its
 * styled box, dates set through the widget, dropdowns looked up by visible text,
 * autocompletes that must be clicked so their hidden input gets set - and getting any
 * one of them wrong leaves a field that looks filled and submits empty.
 *
 * Verified end to end on 2026-09-26 creating events 269384, 269385 and 269386.
 */
() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

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

  const val = (id) => (document.getElementById(id) || {}).value;
  const menuLabel = (id) =>
    document.querySelector('#' + id + ' .ui-selectonemenu-label')?.innerText.trim() || null;

  // The all-day checkbox has a generated id, so find it by its label text. Clicking the
  // hidden <input> does nothing; PrimeFaces listens on the styled box beside it.
  function allDayBox() {
    const lab = [...document.querySelectorAll('label, span, div')].find(
      (e) => e.children.length === 0 && /^Celodenné podujatie$/.test(e.innerText.trim())
    );
    const chk = lab && lab.closest('tr, div')?.querySelector('input[type=checkbox]');
    return chk ? { chk, box: chk.closest('.ui-chkbox').querySelector('.ui-chkbox-box') } : null;
  }

  window.__teepeeNew = {
    /* Plain text fields: name, description, urls, contact overrides. */
    async text(fields) {
      for (const [id, v] of Object.entries(fields)) {
        const el = document.getElementById(id);
        if (!el) return { ok: false, error: 'no field ' + id };
        el.value = v;
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
      }
      return { ok: true, values: Object.fromEntries(Object.keys(fields).map((k) => [k, val(k)])) };
    },

    /* Tick or untick Celodenné podujatie. Ticking hides both time fields and makes the
       event run 00:00-23:59, so do it before setting dates. */
    async allDay(on = true) {
      const a = allDayBox();
      if (!a) return { ok: false, error: 'all-day checkbox not found' };
      if (a.chk.checked !== on) {
        a.box.click();
        await sleep(300);
        await idle();
      }
      return { ok: true, checked: allDayBox().chk.checked };
    },

    /* Dates and times, both through the calendar widget's own setDate - writing the
       input's value leaves the widget's internal date unset. For an all-day event pass
       only the dates; the time widgets are hidden and ignored. */
    async when({ start, end, regStart, regEnd }) {
      const set = async (widget, iso) => {
        if (!iso) return;
        const [d, t] = iso.split('T');
        const [y, m, dd] = d.split('-').map(Number);
        const [hh, mi] = (t || '00:00').split(':').map(Number);
        PF(widget).setDate(new Date(y, m - 1, dd, hh, mi));
        await sleep(250);
        await idle();
      };
      await set('widget_eventStartDateId', start);
      await set('widget_eventStartTimeId', start);
      await set('widget_eventEndDateId', end);
      await set('widget_eventEndTimeId', end);
      await set('widget_eventRegStartDateId', regStart);
      await set('widget_eventRegStartTimeId', regStart);
      await set('widget_eventRegEndDateId', regEnd);
      await set('widget_eventRegEndTimeId', regEnd);
      return {
        ok: true,
        od: val('eventStartDateId_input'), odCas: val('eventStartTimeId_input'),
        do: val('eventEndDateId_input'), doCas: val('eventEndTimeId_input'),
      };
    },

    /* Typ and Kategória, by visible option text. The option values are internal debug
       strings that change between deploys, so they are looked up at run time. */
    async choose({ typ, kategoria }) {
      const pick = async (widget, selectId, text) => {
        if (!text) return null;
        const o = [...document.querySelectorAll('#' + selectId + ' option')].find(
          (x) => x.textContent.trim() === text
        );
        if (!o)
          return {
            ok: false,
            error: 'no option ' + text,
            available: [...document.querySelectorAll('#' + selectId + ' option')]
              .map((x) => x.textContent.trim()).filter(Boolean),
          };
        PF(widget).selectValue(o.value);
        await sleep(250);
        await idle();
        return { ok: true, shown: menuLabel(selectId.replace('_input', '')) };
      };
      return {
        typ: await pick('widget_eventTypeId', 'eventTypeId_input', typ),
        kategoria: await pick('widget_eventCategoryId', 'eventCategoryId_input', kategoria),
      };
    },

    /* Autocomplete: query, then click a suggestion. Clicking is what sets the hidden
       _hinput; a typed value alone submits as empty. `match` is a predicate over the
       rendered items, so the caller decides which suggestion is the right one. */
    async autocomplete(widget, id, query, matchSource) {
      const match = typeof matchSource === 'string' ? new RegExp(matchSource) : null;
      document.getElementById(id + '_input').value = query;
      PF(widget).search(query);
      await sleep(1400);
      await idle();
      const items = [...document.querySelectorAll('#' + id + '_panel .ui-autocomplete-item')];
      const hit = items.find((i) =>
        match ? match.test(i.innerText) || match.test(i.getAttribute('data-item-value') || '') : false
      );
      if (!hit)
        return { ok: false, saw: items.map((i) => ({ label: i.innerText.trim(), value: i.getAttribute('data-item-value') })) };
      hit.click();
      await sleep(600);
      await idle();
      return { ok: true, shown: val(id + '_input'), hidden: val(id + '_hinput') };
    },

    /* Miesto. Prefer the geocoded suggestion - its data-item-value starts "Place id: ChIJ"
       - over the literal "Použiť ..." fallback, whose value is "Place id: null". */
    place(query) {
      return this.autocomplete('widget_eventLocationId', 'eventLocationId', query, 'Place id: ChIJ');
    },

    /* Jednotka. Pass enough of the unit name to be unambiguous. */
    unit(query, matchSource) {
      return this.autocomplete('widget_orgUnitComboId', 'orgUnitComboId', query, matchSource || query);
    },

    /* Everything the form will submit, for a read-back before committing. */
    review() {
      const sw = (id) => !!(document.getElementById(id) || {}).checked;
      const a = allDayBox();
      return {
        nazov: val('eventNameId'),
        miesto: { shown: val('eventLocationId_input'), hidden: val('eventLocationId_hinput') },
        od: val('eventStartDateId_input'), odCas: val('eventStartTimeId_input'),
        do: val('eventEndDateId_input'), doCas: val('eventEndTimeId_input'),
        celodenne: a ? a.chk.checked : null,
        regOd: val('eventRegStartDateId_input'), regDo: val('eventRegEndDateId_input'),
        popis: val('eventDescriptionId'),
        web: val('eventUrlId'), online: val('eventOnlineEventLinkId'),
        typ: menuLabel('eventTypeId'), kategoria: menuLabel('eventCategoryId'),
        kontakt: { osoba: val('contactPersonComboId_input'), email: val('contactEmailId'), tel: val('contactPhoneNumberId') },
        jednotka: { shown: val('orgUnitComboId_input'), hidden: val('orgUnitComboId_hinput') },
        zverejnit: sw('publicEventSwitchId_input'),
        lenClenom: sw('membersOnlySwitchId_input'),
        dotacia: sw('externalFoundedSwitchId_input'),
      };
    },

    /* Submit. Both controls have generated ids, so they are found by their text.
       Either one navigates to /events/<id>/details and destroys window.__teepeeNew;
       read the new id out of the URL afterwards. */
    submit(mode = 'draft') {
      if (mode === 'publish') {
        const b = [...document.querySelectorAll('button[type=submit]')].find((x) =>
          /Publikovať/.test(x.innerText)
        );
        if (!b) return { ok: false, error: 'Publikovať not found' };
        if (b.disabled) return { ok: false, error: 'Publikovať disabled' };
        b.click();
        return { ok: true, mode };
      }
      const a = [...document.querySelectorAll('a')].find((x) => /rozpracovan/.test(x.innerText));
      if (!a) return { ok: false, error: 'Uložiť ako rozpracované not found' };
      a.click();
      return { ok: true, mode: 'draft' };
    },
  };

  return 'teepee create driver ready';
}
