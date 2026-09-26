# Events > Create

Making a new event at `https://skauting.tee-pee.com/events/create`, reached from
**Podujatia** (`/events`) via the `+` icon at the top right of the list.

Read `SKILL.md` first for access and the site-wide mechanics.

Verified end to end on 2026-09-26, creating events 269384, 269385 and 269386 from
calendar entries. `scripts/events-create.js` bundles the working mechanics - inject it and
use `window.__teepeeNew` rather than re-deriving how each control wants to be driven.

## Decide before filling

Two fields have no obvious right answer, and both are required. Kubo's conventions:

| Field | Default | When |
|---|---|---|
| **Typ** | `1. iné` | Planning sessions, staff meetings, anything internal |
| | `2. jednodňové podujatia pre deti a mládež` | An event for kids lasting one day - a výlet, an etapovka |
| | `3. viacdňové podujatia pre deti a mládež` | The same but spanning more than one day |
| **Kategória** | `3. regionálna, miestna` | Unless told otherwise |

The jednodňové/viacdňové split follows from the dates, so read it off `Od` and `Do`
rather than asking. Everything else about these two fields is a judgement call: **if the
event does not clearly fit, ask rather than picking.** A wrong Typ quietly misreports the
unit's activity in the annual dotácia statistics, which is what the field exists for.

`0. Testovacie podujatie (nepouživať)` is last in the list and, as the name says, is not
for real events.

## Fields

Most controls carry stable, readable ids - a relief after the attendee dialog. The three
that do not are marked; match those by their label or text, because a generated id shifts
whenever the form changes.

| Field | Selector | Notes |
|---|---|---|
| Photo | `#addEventPhotoBtnId` | Opens an upload dialog. Skipped, the event gets a default tipi image |
| Názov podujatia\* | `#eventNameId` | |
| Miesto\* | `#eventLocationId_input`, hidden `#eventLocationId_hinput` | Autocomplete, see below |
| Od\* | `#eventStartDateId_input` + `#eventStartTimeId_input` | `DD.MM.YYYY` and `HH:MM` |
| Do\* | `#eventEndDateId_input` + `#eventEndTimeId_input` | |
| Celodenné podujatie | checkbox, **generated id** (`j_idt47_input` at time of writing) | Ticking it hides the time fields and makes the event 00:00-23:59 |
| Začiatok registrácie | `#eventRegStartDateId_input` + `#eventRegStartTimeId_input` | See Registration below |
| Koniec registrácie | `#eventRegEndDateId_input` + `#eventRegEndTimeId_input` | |
| Popis | `#eventDescriptionId` | textarea |
| Webstránka | `#eventUrlId` | One only, as the label says |
| Link na online podujatie | `#eventOnlineEventLinkId` | |
| Typ\* | `#eventTypeId_input` (native `<select>`), widget `#eventTypeId` | |
| Kategória\* | `#eventCategoryId_input`, widget `#eventCategoryId` | |
| Kontaktná osoba | `#contactPersonComboId_input`, hidden `_hinput` | Prefilled with the logged-in user |
| Kontaktný E-mail | `#contactEmailId` | Prefilled |
| Kontaktné telefónne číslo | `#contactPhoneNumberId` | Prefilled |
| Jednotka\* | `#orgUnitComboId_input`, hidden `_hinput` | Autocomplete, starts empty |
| Zverejniť podujatie celej organizácii? | `#publicEventSwitchId_input` | Off: shared only within the unit |
| Sprístupniť len registrovaným členom? | `#membersOnlySwitchId_input` | Off: open to non-members too |
| Podujatie hradené z dotácie MŠVVaŠ SR | `#externalFoundedSwitchId_input` | Off |
| Uložiť ako rozpracované | `<a>` with that text, **generated id** (`j_idt110`) | Saves as a draft |
| Publikovať | `<button type=submit>` with that text, **generated id** (`j_idt112`) | |

The three switches all default to off, and their sub-labels state the current meaning in
words (`Aktuálna voľba: Podujatie sa zdieľa len v rámci jednotky`). Read that line back
after toggling rather than trusting the switch graphic.

## Registration

Leave both registration fields empty unless Kubo asks for a window. The detail page then
reads **`Registrácia bola ukončená`**, which looks alarming and is not: people can still
be added to the event by hand through Prihlásení. The banner only governs self-signup.

Empty does not mean "open until the event ends" - that was a guess in an earlier draft of
this file and it was wrong. Empty means closed.

## The controls that need care

**Autocompletes** (`Miesto`, `Jednotka`, `Kontaktná osoba`) are PrimeFaces widgets with a
visible `_input` and a hidden `_hinput` carrying the real value. Typing into `_input`
alone leaves `_hinput` empty and the field does not count as filled. Type, wait for the
panel, and click a suggestion so the widget sets both.

`Miesto` is backed by a places lookup and offers a geocoded address plus a literal
fallback, `Použiť "<what you typed>"`. Prefer the geocoded one - it is what puts the event
on a map - and fall back to the literal only for somewhere the lookup does not know, like
a táborisko.

**Dropdowns** (`Typ`, `Kategória`) are PrimeFaces `selectonemenu`: a styled div plus a
real hidden `<select>`. Their `value` attributes are internal debug strings
(`EventType with id: 6 and name: 1. iné`, `com.teepee.core.event.model.EventCategory@3`),
so look the value up by visible option text at run time and never hardcode one.
`PF('widget_eventTypeId').selectValue(<value>)` works and updates both the widget and the
server; read `.ui-selectonemenu-label` back to confirm.

**Dates and times** go through the calendar widget, not the input:
`PF('widget_eventStartDateId').setDate(new Date(y, m-1, d, hh, mi))`. Writing
`#eventStartDateId_input.value` leaves the widget's internal date unset and the form
submits as if the field were blank. The time fields are separate widgets
(`widget_eventStartTimeId`) that take the same Date.

**The all-day checkbox** has a generated id and ignores clicks on its hidden `<input>` -
click the `.ui-chkbox-box` beside it. Ticking it hides both time fields and makes the
event 00:00-23:59, so tick it before setting dates.

## Imported titles

An event coming from Kubo's calendar keeps its name verbatim, with one exception: strip
emoji. `🌧️ Dážď Planning Session` goes in as `Dážď Planning Session`. Tee-pee is the
official org record and other units read these names.

## Draft or publish

Two ways out of the form, and the difference is visible afterwards:

- **Uložiť ako rozpracované** saves a draft. The event detail page then carries a grey
  `NÁVRH` badge next to the title.
- **Publikovať** publishes it.

Creating an event is a write other people see, and a published one may notify or appear in
their lists. **Confirm with Kubo which of the two before submitting**, and when in doubt
save the draft - promoting a draft later is cheap, unpublishing something people have
already seen is not.

On success the browser lands on `/events/<id>/details#eventData`. Read the new id from the
URL and report it; that is what every later task needs.
