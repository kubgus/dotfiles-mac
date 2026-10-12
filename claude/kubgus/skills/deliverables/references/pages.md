# Pages documents

There is no Pages skill, CLI or library. A `.pages` file is edited by driving the Pages
app through AppleScript with `osascript`. Everything below was learned on a Slovak
template with body paragraphs and two inline tables, on Pages 15.4.

## Finding the app

- **The app is not `/Applications/Pages.app`.** On his Mac it is
  `/Applications/Pages Creator Studio.app`, bundle id `com.apple.Pages`. The files in
  `~/Launcher/Apple/` are 800-byte launcher stubs, not apps.
- **Address it by bundle id:** `tell application id "com.apple.Pages"`. A path breaks the
  next time Apple renames the bundle.
- **AppleScript, not JXA.** JXA opened the document, then threw -1728 "Can't get object"
  on the open call and on `table.cells()`. JXA is fine for reading; write in AppleScript.

## Before the first write

Copy the `.pages` file to the scratchpad. It is a zip, and `save document 1` saves in
place with no undo once the app quits.

## Body text

- `set paragraph N of body text of document 1 to "..."` replaces the text and keeps the
  paragraph's style and its break. Test one paragraph first and confirm the paragraph count
  did not change.
- Pass Slovak text through a quoted UTF-8 heredoc (`osascript <<'EOF'`). Diacritics survive.
- Edit from the last paragraph backwards. The indices never shifted in practice, but a
  replacement that adds or removes a break would shift every later one.

## Tables

- An inline table shows up in body text as one U+FFFC character. Its cells are not in
  `paragraphs`.
- `value of cell C of row R of table T of document 1` reads and writes. Tables number in
  document order.

## The quiet failure: inherited style

An empty paragraph keeps the style it last had, and text written into it takes that style
with no error. In the template, the empty paragraph after the last heading was italic, so
the body text came out italic. A heading can also hide an embedded line break that shows
only in the raw text.

After each write, read back `font of paragraph N` and `size of paragraph N` and compare
them with a known-good body paragraph. Then check the render, below.

## Checking the render

poppler is not installed, and installing it is a global install he decides on. The Read
tool returns nothing visible for a PDF without it. Neither is needed:

- **Text of any PDF** - PDFKit through JXA:
  `ObjC.import("PDFKit"); var d = $.PDFDocument.alloc.initWithURL($.NSURL.fileURLWithPath(path)); d.pageAtIndex(i).string.js`
- **Every page as PNG** - PDFKit `thumbnailOfSizeForBox` at twice the media box, then
  `NSBitmapImageRep` to PNG into the scratchpad, then Read the images. Works on any PDF.
- **First page only, fast** - `qlmanage -t -s 1600 -o <dir> <file>` renders a PDF, and a
  `.pages` file's embedded preview at 1024 px. The preview is from the last save.

To see a `.pages` document in full, export it to PDF first, then render the PDF. Pages
`export document 1 to file ... as PDF` exists in the dictionary but has not been tested.
