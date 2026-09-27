# Notes on a page

Only add notes when he asks for them. When he does, this is the shape, because the whole
point is that what he types survives the page being regenerated:

- **Store them in `localStorage`, keyed by the thing's own identity** - a person's name, a
  row's label - never by position or index. He will ask for the page to be rebuilt with
  new data, and notes keyed by identity reattach themselves while notes keyed by row
  number silently land on the wrong item.
- **Wrap every read and write in try/catch** and render correctly with storage blocked.
  A private window or cleared site data must degrade to a page that still works, not a
  blank one.
- **Let him type a note next to the thing it is about.** A box on the row beats scrolling
  to a form at the bottom. Autosave it, confirm quietly, and drop the key entirely when
  the note is emptied so a round-trip out and back changes nothing.
- **One plain-text block holds all the notes, and it is canonical.** It lives behind a
  single toggle - "Notes as text" - rather than sitting open, because it is the way data
  leaves and enters the page, not the way he reads it day to day.
- **Copy and Import sit overlaid on that field**, top-right corner, not in a toolbar
  somewhere else. The buttons act on the text under them and should look like it.
  - Copy takes **what is in the field**, not a fresh render of the notes. Once the field
    is editable, copying something he cannot see is a bug.
  - Import starts **disabled** and arms the moment the field is edited, so it reads as
    "apply what I just changed" rather than a mystery action. Opening the panel refills
    the field and disarms it again.
  - On click it parses the whole text **before touching storage**. If any line fails,
    refuse the entire import and say which line and why - unparseable, a name that is not
    on the page, the same name twice. A partial import leaves him with some notes
    overwritten and no way to tell which.
  - Import replaces everything rather than merging, which is what makes it a real
    round-trip. Say so next to the button, because pasting a partial block then wipes the
    rest.
- **Keep the two views in step, but never fight him for the field.** An in-place edit can
  refresh the text block only while Import is still disarmed; once he has typed in the
  block, it is his until he imports or reopens it.

Say plainly in the handover that the notes live in that one browser and reach nobody until
he copies them out. He chose that trade knowingly; leaving it unsaid is what makes it a
trap.
