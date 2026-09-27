# Notes on a page

Only add notes when he asks for them. When he does, this is the shape, because the whole
point is that what he types survives the page being regenerated:

- **Store them in `localStorage`, keyed by the thing's own identity** - a person's name, a
  row's label - never by position or index. He will ask for the page to be rebuilt with
  new data, and notes keyed by identity reattach themselves while notes keyed by row
  number silently land on the wrong item.
- **Wrap every read and write in try/catch** and render correctly with storage blocked.
  A private window or cleared site data must degrade to a page that still works, not a
  blank one. Say so on the page when it happens. A browser that refuses `localStorage` on
  `file://` swallows every note silently otherwise, and Export is then the only way
  anything at all survives the tab closing.
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

## Export as page

Copy and Import move text. **Export as page** moves the whole thing: one HTML file with
the notes already in it, openable by someone who never touches this browser. It sits in
the same corner, third after Copy and Import. That is his call and it overrides the
reasoning that would put a document-level action in the page header; what follows is the
three places the corner costs something.

- **Export is hidden until he opens "Notes as text".** The corner is inside the collapsed
  panel, so the one control that gets a note to another person is behind a toggle, and
  nobody finds it by looking. Say so in the handover, every time.
- **The confirmation has to outlive the panel.** Reset collapses the panel before
  serializing, so the button closes the surface it is standing on. Put the export status
  on a line outside the panel, or it vanishes in the same frame it is written.
- **Refuse to export while Import is armed.** Export ships what storage holds, and an
  armed field means the block on screen says something storage has not been told. Putting
  the button beside that field makes this the easy accident rather than the rare one. Say
  which it is and let him import first or discard, but never hand him a file quietly
  missing the lines he is looking at as he clicks. The check runs first, before any part
  of the reset, or the reset has already blanked the evidence. And because closing the
  panel does not disarm Import - only reopening does - the field can be armed while it is
  out of sight: open the panel and put the cursor in it before refusing. A refusal that
  points at something he cannot see is not a refusal, it is an error message.
- **Bake the notes as data, never as rendered markup.** One
  `<script type="application/json">` block holding the same shape `localStorage` holds,
  and the page boots from it. Serializing the live DOM alone loses every `<textarea>` he
  typed into, because a typed value never reaches `outerHTML` - it is exactly the content
  being exported that goes missing. Escape `<` as `\u003c` on the way in, or the first
  note containing a closing script tag ends the block early and takes the page with it.
  Written here as `<\/script>` on purpose: the bare form terminates a `<script>` element
  from inside a string or a comment just as readily, so this warning copied verbatim into
  the page is itself the bug.
- **Exactly one baked block, replaced rather than appended.** The export rebuilds it from
  current storage, which is what makes an export of an export carry the notes as they are
  now. Append instead and a few generations down which block wins is a coin flip.
- **Write the per-row values into the markup as well**, then boot idempotently over them.
  Idempotent structurally and not only by value: an exported file already carries the note
  boxes in its markup, so a boot that creates one per row appends a second. Reuse the box
  that is there, create only where none is. The few bytes buy a file that still reads
  correctly when the script does not run at all.
- **Reset transient state before serializing** - close the panel, drop focus, clear any
  mid-edit styling, or the file opens frozen in whatever the moment of export happened to
  look like. The text block is derived, so clear it outright - `textContent`, not just
  `value` - and let boot rebuild it. Bake the render as it stood and the field ships
  disagreeing with the data behind it.
- **Baked notes seed storage only when the page has none.** Namespace the store by the
  page's own identity rather than its filename, so a renamed or moved export still finds
  its notes. The price is that an export opened beside its original meets the notes
  already there - and on a browser that pools every `file://` document into one origin,
  that is the ordinary case for a local file rather than a rare one. So the collision
  costs a glance, never a dismissal: the browser's notes stay live and untouched, one
  quiet line at the top says what the file carries and offers to take it instead, and
  ignoring that line is a correct way to use the page. Never merge silently - that is the
  Import failure again - but never make him clear something away to read his own page.
- **Name it as a deliverable** - `Title Case With Spaces - YYYY-MM-DD.html`. The date
  earns its place here, because he will export the same page more than once.
- **The download can fail.** It is inert inside the Artifact sandbox and a blocked blob
  URL fails quietly. Catch it, say so, and point at the text block, which still works.

Say plainly in the handover that the notes live in that one browser until he exports or
copies them out, and that an exported file is a snapshot: edit it and edit the original
and the two diverge with nothing to reconcile them. He chose that trade knowingly;
leaving it unsaid is what makes it a trap.
