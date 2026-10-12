# HTML pages

A page he opens and reads is a deliverable like any other, so everything in `SKILL.md`
applies - `Title Case With Spaces.html`, written into the project, handed over as a
relative path. Three skills split a page between them, with no overlap:

- **`frontend-design`** owns the look - palette, typefaces, the hero, the layout concept,
  the copy on the page.
- **`artifact-design`** owns the page contract - tokens, both themes, libraries, layout,
  the responsive floor, title and favicon. It also calls how much design effort the page
  deserves; let that call set how heavy the `frontend-design` pass is.
- **This file** owns what neither covers: where the file ends up and what breaks once it
  is a local file. `page-design.md` holds the rest: what to cut.

## Local file or published artifact

Default to a local file in the project, even though the Artifact tool leans hard the other
way. Publishing sends the content to claude.ai, where a link shares it further, and most
of what he asks for is his own working material.

Publish only when he asks, or when the page is plainly for other people and carries
nothing private. **Ask first - always - when the page carries third-party personal data:**
names of minors, parents' phone numbers, anything from a roster or a form. Build it
locally, say why, and offer the artifact in one line. His standing rule that PII is his to
share and not yours holds here exactly as it does for a commit.

## The look

`frontend-design` is the default for any page with an audience - anything he sends,
presents or keeps. Run its two-pass process: a compact token and layout plan first,
checked against its list of generated-page tells, then the code. Skip only the step it
opens with, because the subject and the audience are his and already known - propose
nothing, confirm nothing, just build from what he asked for.

Skip the skill entirely for a page that exists to be read once and closed. A table dumped
to HTML because the terminal mangles it is not a design brief.

*Clean and professional* is not a licence for timidity. Spend boldness in one place and
keep everything around it quiet; a page that reads as a template is the failure the
design skill exists to prevent.

Then **read `page-design.md`** before putting anything on the page. It is a check to run
as each element goes in, not a pass at the end.

## What changes off `file://`

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

## HTML responses

When he wants a reply as a page - "summarize in HTML", "an HTML summary of the previous
message" - it is a page like any other, with four rules of its own.

- **Know which reply.** "The previous message" may mean the substantive answer two turns
  back, not the report just above it. If the source is not certain, ask.
- **Ask where it goes**, once per project, and write the answer into that project's
  `CLAUDE.md` so the question does not come back. Offer `Responses/NN Title Case Name.html`,
  numbered from 01 as the highest existing number plus one, never overwriting an earlier
  one. With no project folder, ask every time.
- **Restructure, do not transcribe.** Group findings by what they affect, not by label
  number. Actions become next steps, risks become open risks, decisions keep their cost.
  The page is a file, so the reply conventions stay behind: no label ids, no STE. Its
  language follows the source reply. A footer names the source files and the date.
- **Light on design.** Such a page is read, not presented: skip `frontend-design`, keep
  the `artifact-design` contract and `page-design.md`. Check phone width and dark mode in
  a browser before handing it over, or say that you did not.

## Notes on a page

Only when he asks for them. Then read `notes-on-a-page.md` and follow it before building -
the shape is specific, and a round-trip built by instinct overwrites what he typed
without telling him.
