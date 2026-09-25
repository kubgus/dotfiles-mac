---
name: deliverables
description: How Kubo wants generated files named, built and handed over. Use whenever you are about to create a document, note, export or deliverable - a PDF, Word or docx, Excel or xlsx, PowerPoint or pptx, Markdown note, report, memo, agenda, invitation or handout - or when naming a file you created, or deciding where a finished file goes. Triggers on "make a pdf", "export this", "save this as", "write it to a file", "generate a report", "what should I call this file", "put it in a document". Not for source code, which follows its own language's conventions.
---

# Deliverables

## Before building

- **If the format is ambiguous**, ask once through AskUserQuestion, then proceed. A
  "report" could be `.md`, `.docx` or `.pdf`, and the choice is his.
- **Read the relevant format skill first** (`docx`, `pdf`, `xlsx`, `pptx`).
- **Name the build approach** rather than picking silently. The axis is a Python library
  (openpyxl, python-docx) against hand-built OOXML plus `zip`. He may not want Python in
  play, and that is his call, not an implementation detail.
- **Clean professional formatting** - neither overdesigned nor bare.

## Naming files you create

- **`Title Case With Spaces`** for documents, notes and exports. Uppercase each word's
  first letter and leave the rest untouched so acronyms survive (`VV`, `PK`, `AI`).
  Capitalize even short words (`A`, `Pre`, `Na`, `The`). Single spaces between words.
  Don't use `-` or `_` *as* separators, though a deliberate ` - ` between name *segments*
  is fine (`Vedenie - Pred Taborom`). Extensions stay lowercase.
- **Never rename imported or external files** - Sheets exports, downloads, shared docs
  keep their original name and format.
- **Adding a segment before the extension is not a rename**, and is fair game even on
  imports: the original name stays legible underneath and the format is untouched, so
  `export-parents.xlsx` to `export-parents.pii.xlsx` is still plainly that export. Use it
  to put a fact *about* the file into its name when something has to act on that fact - a
  project's git-ignore rule being the usual reason. What each marker means is the
  project's to define.
- **Exempt**, leave in their required form: source code, which follows its language's
  conventions; tool and convention names (`CLAUDE.md`, `MEMORY.md`, `SKILL.md`,
  `.gitignore`); and fixed-name scripts.
- **A project's own naming convention always wins.** This is the default for loose
  documents, not a rule to impose on a codebase.

## Handing it over

Write the file into the project and link it with a clickable relative path. Wherever the
deliverable lands is the one source of truth - a copy pasted into chat is for visibility,
never a second place to edit.

If the file contains third-party PII, ask before committing it, naming the files. Mark it
as well where the project has a convention for that; the marker never discharges the ask.
