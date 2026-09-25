---
name: deliverables
description: How Kubo wants generated files built, named and handed over. Use whenever you are about to create a document, note, export or deliverable - a PDF, Word or docx, Excel or xlsx, PowerPoint or pptx, Markdown note, report, memo, agenda, invitation or handout - or when naming a file you created, or deciding where a finished file goes. Triggers on "make a pdf", "export this", "save this as", "write it to a file", "generate a report", "what should I call this file", "put it in a document". Not for source code, which follows its own language's conventions.
---

# Deliverables

## Decide before building

- **Ambiguous format?** Ask once through AskUserQuestion, then proceed. A "report" could
  be `.md`, `.docx` or `.pdf`, and the choice is his.
- **Read the format's own skill first** - `docx`, `pdf`, `xlsx`, `pptx`.
- **Name the build approach, never pick it silently.** The axis is a Python library
  (openpyxl, python-docx) against hand-built OOXML plus `zip`. He may not want Python in
  play, and that is a decision rather than an implementation detail.
- **Write for the document's audience, not your defaults.** A Slovak-audience document
  takes `DD.MM.YYYY` and Slovak conventions throughout.
- **Clean and professional** - neither overdesigned nor bare. No decoration that carries
  no information.

## Naming

`Title Case With Spaces` for documents, notes and exports. Acronyms survive untouched
(`VV`, `PK`, `AI`), short words are capitalised too, extensions stay lowercase. A
deliberate ` - ` between segments is fine; `-` or `_` as a word separator is not.

Never rename an imported file. Adding a segment before the extension is not a rename, so
`export.xlsx` to `export.pii.xlsx` is fair game when something has to act on that fact.

Exempt: source code, tool names (`CLAUDE.md`, `SKILL.md`, `.gitignore`), fixed-name
scripts. A project's own convention always wins over this one.

## Handing over

Write it into the project and link a relative path. That file is the source of truth; a
copy in chat is visibility, never a second place to edit.

Third-party PII: ask before committing, naming the files.
