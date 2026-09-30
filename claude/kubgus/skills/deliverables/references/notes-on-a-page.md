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
- **Let him type a note next to the thing it is about**, in a box that is always on the
  row and always showing what it holds - never a form at the bottom, never something he
  opens. Drop the key entirely when the note is emptied, so a round-trip out and back
  changes nothing. "The box" below has the form, and it is not negotiable down to a
  popover.
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

## What a note attaches to

**A box attaches to something that has a row.** That is the test: a list of people, a
table of items, a checklist - each line is a row, each row gets a box. A dense grid, a
matrix or a heat map has no row to put a box on, a cell being a few characters wide and a
note being a sentence. That is a limit on the box and not on the note. **A cell has no
room for a box. It has plenty of room for a note.** Those are two claims and they are
easy to collapse into one, which is how a page ends up refusing to hold something he
wants to write down.

**A matrix carries three kinds of note.** Its two axes have rows, so they get boxes - one
per row entity, one per column entity, as their own lists beside or below the grid rather
than inside it. Its cells have no rows, so a cell note is typed into the canonical text
block and surfaces on the grid as a marker plus the cell's existing hover tooltip. That
is not the box rule watered down. It is the one place the box rule cannot reach, and the
text block was already the way data enters the page.

**Three kinds of note, one flat store.** Per-item, per-group and per-cell notes live in
the same keyed object rather than three, so there is one namespace to serialize, one to
import, one to bake. Prefix the per-group keys with the marker the text format itself uses
for them, `## `, so the kinds cannot collide and a note body can never be read back as a
key; a cell key is then its group key joined to its item key, already unmistakable because
the group half carries the prefix. A prefix invented for the store alone would be a second
format to keep in step with the first.

**The line format is canonical, because Import parses it.**

- `- Item: note` at the top level for a per-item note.
- `> note` under a `## Heading` for that group's own note. The `> ` marker is there so a
  note that itself opens with a dash cannot read back as an item line.
- `- Item: note` under a `## Heading` for the cell where that heading's axis meets that
  item. A line's kind is set by what it sits under, so one heading kind and two line kinds
  carry all three sorts of note and a matrix needs no syntax a flat list does not have.
- Newlines flatten to ` / ` on the way out. One note is one line, always, or the parser is
  left guessing where a note ends.

## The box

**Permanently visible, sitting on the row.** A textarea, always there, always showing what
it holds. Never a popover, a modal, a dialog or anything that opens on click - a note you
have to open is a note nobody reads, and the page stops being something he scans. A marker
icon with a hover tooltip is a different feature, not a lighter version of this one: it
says a note exists without saying what it says. On a cell that is the whole of what a
marker can do and it is enough. On a row it is a substitution, and the answer is the box.

**One auto-growing field.** `rows=1`, `resize: none`, `overflow: hidden`, height set from
`scrollHeight` on input. It sits on the input well surface with no border and a
placeholder - `page-design.md` owns the rest of that.

**Re-measure that height on everything that can change the width.** `fonts.ready`,
`resize`, `orientationchange`, and a `ResizeObserver` on the container rather than on the
textarea. `page-design.md` states the trap in general; this is where it bites, because
`overflow: hidden` turns a stale height into a clipped note and nothing on screen admits
it.

**Autosave, debounced at around 400ms, and no Save button on the row.** A button per row
is a hundred buttons, and one note lost every time he clicks away from a row without
finding it.

**The confirmation lives in the field's own corner** - a small saved marker that fades
after about a second. Anywhere else and he has to look up from what he just typed to
learn it was kept. **That same flag is the failure channel**: when storage refuses the
write it stays up and carries the reason instead of fading. One place to look, and
silence means saved.

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
  already there. Chrome pools every `file://` document into one origin whatever directory
  it sits in - tested, not assumed - so on his machine that is the ordinary case for a
  local file and not a rare one. Safari is unverified and may refuse `file://` storage
  outright rather than share it, which the try/catch rule above already absorbs. So the
  collision costs a glance and never a dismissal: the browser's notes stay live and
  untouched, one quiet line at the top says what the file carries and offers to take it
  instead, and ignoring that line is a correct way to use the page. Never merge silently -
  that is the Import failure again - but never make him clear something away to read his
  own page.
- **Name it as a deliverable** - `Title Case With Spaces - YYYY-MM-DD.html`. The date
  earns its place here, because he will export the same page more than once.
- **The download can fail.** It is inert inside the Artifact sandbox and a blocked blob
  URL fails quietly. Catch it, say so, and point at the text block, which still works.

Say plainly in the handover that the notes live in that one browser until he exports or
copies them out, and that an exported file is a snapshot: edit it and edit the original
and the two diverge with nothing to reconcile them. He chose that trade knowingly;
leaving it unsaid is what makes it a trap.
