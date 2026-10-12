---
name: deliverables
description: How Kubo wants documents and pages built, edited, named, placed and handed over - PDF, Word, Excel, PowerPoint, Apple Pages, Markdown notes, HTML pages and HTML summaries of a reply, reports, memos, dashboards, agendas, invitations, handouts. Use before creating or changing any of them, a one-line edit to an existing file included, and when naming a file you made, deciding where it goes, or choosing between a local file and a published artifact. Triggers: "make a pdf", "export this", "save this as", "write it to a file", "generate a report", "visualize this", "make me a page", "summarize in HTML", "HTML summary of", "what should I call this file", "edit this page", "change the styling", "add a section", "fix this document", "rename it", "republish it", or a path to an existing .html, .md, .pdf, .docx, .xlsx, .pptx or .pages with a change to make. Use it even when the format looks obvious - naming, placement, look and publish-or-local are his conventions, not defaults. Not for source code.
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
