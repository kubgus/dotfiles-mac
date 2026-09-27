---
name: deliverables
description: How Kubo wants generated files built, named and handed over. Use whenever you are about to create a document, note, export, page or deliverable - a PDF, Word or docx, Excel or xlsx, PowerPoint or pptx, Markdown note, HTML page, report, memo, dashboard, agenda, invitation or handout - or when naming a file you created, or deciding where a finished file goes, or deciding whether a page ships as a local file or a published artifact. Triggers on "make a pdf", "export this", "save this as", "write it to a file", "generate a report", "visualize this", "make me a page", "what should I call this file", "put it in a document". Use it even when the format looks obvious and the file looks trivial - the naming, the placement and the publish-or-keep-local call are his conventions, not defaults. Not for source code, which follows its own language's conventions.
---

# Deliverables

## Decide before building

- **Ambiguous format?** Ask once, then proceed. A "report" could be `.md`, `.docx` or
  `.pdf`, and the choice is his.
- **Read the format's own skill first** - `docx`, `pdf`, `xlsx`, `pptx`; `dataviz` before
  the first line of any chart, in any medium; for HTML the pair named under *HTML pages*.
- **Name the build approach, never pick it silently.** The axis is a Python library
  (openpyxl, python-docx) against hand-built OOXML plus `zip`. He may not want Python in
  play, and that is a decision rather than an implementation detail.
- **Clean and professional** - neither overdesigned nor bare. No decoration that carries
  no information.

## Naming

`Title Case With Spaces` for documents, notes and exports. Acronyms survive untouched
(`VV`, `PK`, `AI`), short words are capitalised too, extensions stay lowercase. A
deliberate ` - ` between segments is fine; `-` or `_` as a word separator is not.

Never rename an imported file. Adding a segment before the extension is not a rename -
the original name stays legible and the format is untouched - so `export.xlsx` to
`export.draft.xlsx` is fair game when something has to act on that fact. What a marker
means is the project's to define.

Exempt: source code, tool names (`CLAUDE.md`, `SKILL.md`, `.gitignore`), fixed-name
scripts. A project's own convention always wins over this one.

## Handing over

Write it into the project and link a relative path. That file is the source of truth; a
copy in chat is visibility, never a second place to edit.

## HTML pages

A page he opens and reads is a deliverable like any other, so everything above applies -
`Title Case With Spaces.html`, written into the project, handed over as a relative path.
Three skills split a page between them, with no overlap:

- **`frontend-design`** owns the look - palette, typefaces, the hero, the layout concept,
  the copy on the page.
- **`artifact-design`** owns the page contract - tokens, both themes, libraries, layout,
  the responsive floor, title and favicon. It also calls how much design effort the page
  deserves; let that call set how heavy the `frontend-design` pass is.
- **This section** owns what neither covers: where the file ends up and what breaks once
  it is a local file. `references/page-design.md` holds the rest - what he cuts.

### Local file or published artifact

Default to a local file in the project, even though the Artifact tool leans hard the other
way. Publishing sends the content to claude.ai, where a link shares it further, and most
of what he asks for is his own working material.

Publish only when he asks, or when the page is plainly for other people and carries
nothing private. **Ask first - always - when the page carries third-party personal data:**
names of minors, parents' phone numbers, anything from a roster or a form. Build it
locally, say why, and offer the artifact in one line. His standing rule that PII is his to
share and not yours holds here exactly as it does for a commit.

### The look

`frontend-design` is the default for any page with an audience - anything he sends,
presents or keeps. Run its two-pass process: a compact token and layout plan first,
checked against its list of generated-page tells, then the code. Skip only the step it
opens with, because the subject and the audience are his and already known - propose
nothing, confirm nothing, just build from what he asked for.

Skip the skill entirely for a page that exists to be read once and closed. A table dumped
to HTML because the terminal mangles it is not a design brief.

*Clean and professional* above is not a licence for timidity. Spend boldness in one
place and keep everything around it quiet; a page that reads as a template is the failure
the design skill exists to prevent.

Then **read `references/page-design.md`** - his own corrections from real pages, and the
things he cuts. It is a check to run as you add each element, not a pass at the end.

### What changes off `file://`

The Artifact skeleton is not there, so the page has to stand alone:

- **Add `<meta charset="utf-8">` yourself.** Without it the browser guesses Windows-1252
  and every diacritic turns to mojibake - which is every Slovak page he will ever open.
- **Keep everything inline anyway.** The CDN allowlist does not apply locally, but one
  self-contained file survives being moved, copied and mailed. Google Fonts is the one
  reasonable exception, with a real fallback stack, since it degrades quietly.
- **`navigator.clipboard` is unreliable on `file://`.** Try it, fall back to
  `execCommand("copy")` on a visible textarea, and if that fails too, show the text and
  say "copy this manually". One of the three always works.
- **Downloads work locally but are inert inside the Artifact sandbox.** Fine to offer, but
  never as the only way to get data out of the page, or the page breaks silently if it is
  ever published.

### Notes on a page

Only when he asks for them. Then read `references/notes-on-a-page.md` and follow it before
building - the shape is specific, and a round-trip built by instinct overwrites what he
typed without telling him.
