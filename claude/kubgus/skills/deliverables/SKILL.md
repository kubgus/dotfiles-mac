---
name: deliverables
description: How Kubo wants generated files built, edited, named and handed over. Use whenever you are about to create or change a document, note, export, page or deliverable - a PDF, Word or docx, Excel or xlsx, PowerPoint or pptx, Apple Pages or .pages, Markdown note, HTML page, report, memo, dashboard, agenda, invitation or handout - including editing, restyling, extending, rewriting or fixing one that already exists, whether he wrote it or you did; or when naming a file you created, or deciding where a finished file goes, or deciding whether a page ships as a local file or a published artifact. Triggers on "make a pdf", "summarize in HTML", "HTML summary of", "export this", "save this as", "write it to a file", "generate a report", "visualize this", "make me a page", "what should I call this file", "put it in a document", and equally on "edit this page", "change the styling", "add a section", "fix this document", "update that html", "rename it", "republish it", or a path to an existing .html, .md, .pdf, .docx, .xlsx, .pptx or .pages handed over with a change to make. Use it even when the format looks obvious, the file looks trivial or the edit looks like a one-line tweak - the naming, the placement, the look and the publish-or-keep-local call are his conventions, not defaults. Not for source code, which follows its own language's conventions.
---

# Deliverables

## Decide before building

- **Editing an existing deliverable is the same job.** Everything below applies to a file
  that already exists: read the format's skill and reference before touching it, keep its
  name unless he asks for a new one, and keep a local page local. A small edit does not
  downgrade the conventions - it inherits them.
- **Ambiguous format?** Ask once, then proceed. A "report" could be `.md`, `.html`,
  `.docx` or `.pdf`, and the choice is his.
- **Read the format's own skill first**, then its reference under *Formats*. `dataviz`
  comes before the first line of any chart, in any medium.
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

## Formats

| Format | Skill | Reference |
|---|---|---|
| HTML page | `frontend-design`, `artifact-design` | `references/html.md` - also HTML responses and notes on a page |
| PDF | `pdf` | `references/pdf.md` - reading and rendering one back |
| Pages | none | `references/pages.md` |
| Word, Excel, PowerPoint | `docx`, `xlsx`, `pptx` | none yet |

A format earns a reference when a session learns something about it the skill does not
say. Add one then, not before.
