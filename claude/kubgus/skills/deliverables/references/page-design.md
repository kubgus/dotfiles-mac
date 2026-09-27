# Page design

## The test

For every element on the page, ask what it tells the reader that nothing else already
tells them. If the answer is nothing, it is decoration and it goes.

**Run it as you add, not as a pass at the end.** Treated as a taste to apply afterwards,
every rule below gets broken first and found later - and some of them twice, because
nothing stops the second instance while the first is still on the page.

## Prose that should have been structure

A page explaining itself in grey text has not been laid out yet.

- **A caption identifies the thing. It does not interpret it.** Say what the chart is
  about, never what you concluded from it.
- **A sentence carrying figures is a stat tile.** The numbers are the payload and the
  sentence is packaging. A qualifier goes as small text under the number.
- **Provenance and as-of dates go in the footer**, never as a subtitle under the h1. They
  are there for correctness. The top of the page is for the content.
- **A legend is earned only when the encoding is arbitrary** - a colour standing for a
  category whose name appears nowhere near it. When the coloured thing sits beside its
  own label, the legend is decoration.
  - There is a second cost, and it is correctness rather than taste. A legend
    generalises, so it can assert something false about a set whose members were each
    labelled correctly - a category that covers none of them, a name nothing carries.

## One signal per level

- **One differentiator, not three.** A line that matters more than its neighbours gets
  heavier weight, or a colour, or an icon. Not all three. The second and third signals
  are noise that make the first harder to read.
- **An identity colour rides something already on the page** - the heading text, the
  existing surface. An element drawn only to carry the signal, a 4px border or a coloured
  rule, is decoration. The colour itself can be worth having; the bar drawn to hold it
  is not.

## Two palettes, not one

Reserve the semantic zones first - red for a conflict, amber for something missing, blue
for a change - then pick the identity palette from what is left. In practice that means
the greens and the violets.

Identity hues chosen for what a category *is* drift into those zones on their own: a rust
beside a red warning stripe, a teal beside a blue one, and the reader cannot tell whether
a colour means "this is category X" or "this needs attention". The same pass catches a
near-neutral slate that never read as a colour at all.

## Lines, not dense rows

- **One topic per line.** A name, a time and two meta facts crammed into a heading and a
  subtitle become four lines, each with a small icon. Two lines beat a separator, and a
  separator beats a gap.
- **One dominant element per heading line.**
- **Drop the label word when the position already says it.** A field whose place on the
  card identifies it does not also need naming in its own value.
- **Icons are welcome.** Inline SVG rather than emoji, so they take the theme colour.

## Depth from surfaces, not from lines

Express nesting as steps of background - page ground, container, item, input well - and
remove the borders. A border separating two levels is doing what the surface change
already did.

**Not everything is a card.** The test is whether each row is acted on or scanned. One
person to call, one note to write: a card. A line read down a column against its
neighbours: a table.

## Controls look like controls at rest

- **Hover never changes the box model.** Colour, yes. Size, spacing, borders, no. A
  border that appears on hover grows the card as the pointer crosses it.
- **An input looks like an input before it is touched.** An affordance hidden until hover
  does not exist on a touch screen. A quiet filled background with a permanent
  placeholder is enough; inside a card that already has a boundary, the surface step
  alone says "field" and no border is needed.
- **Capitalise the placeholder.** Lowercase as an aesthetic is legibility paid for style.

## Equal height follows equal content

Never stretch unequal items to match. If one tile has a third line and its neighbour does
not, the void under the shorter one is the symptom - the extra line belongs outside the
set, as a caption under the pair. Then both are equal because they are equal.

## Section rhythm

Every section gets a heading or none does. A single headed section among unheaded ones
reads as a stray label rather than as structure.

## Two mechanical traps

- **`overflow-x: auto` forces the other axis from `visible` to `auto`.** A horizontally
  scrollable element gets a vertical scrollbar it never needed. Pin the axis you do not
  intend to scroll with `overflow-y: hidden`.
- **A height measured from content is only valid at the width it was measured at.** Size
  a textarea from `scrollHeight` once at load and a rotate, or a column collapsing,
  silently clips it. A `ResizeObserver` on the container - not on the element you are
  resizing - catches every cause at once.
- **`nowrap` on anything that can hold a long string takes the row off the page.** A grid
  or flex child defaults to `min-width: auto`, so its min-content width forces the track
  wider than the viewport. `min-width: 0` on the child, and let it wrap.

Check at 320px, and rotate it.
