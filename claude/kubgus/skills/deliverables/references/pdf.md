# PDF

Read the `pdf` skill for building and changing a PDF. This file covers checking one on his
Mac, which lacks the usual tools.

## Reading one back without poppler

poppler is not installed, and installing it is a global install he decides on. The Read
tool returns nothing visible for a PDF without it. Neither is needed:

- **Text** - PDFKit through JXA:
  `ObjC.import("PDFKit"); var d = $.PDFDocument.alloc.initWithURL($.NSURL.fileURLWithPath(path)); d.pageAtIndex(i).string.js`
- **Every page as PNG** - PDFKit `thumbnailOfSizeForBox` at twice the media box, then
  `NSBitmapImageRep` to PNG into the scratchpad, then Read the images.
- **First page only, fast** - `qlmanage -t -s 1600 -o <dir> <file>`.

Check the render of anything you build before handing it over. A PDF that was never looked
at is a guess.
