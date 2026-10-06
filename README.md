# Tessra

**Row and column layout for the AMAGE UI ecosystem, in Bend 2.**

Tessra computes sizes and positions for interface elements: rows and columns
with per-side padding, gaps, main-axis justification, cross-axis alignment,
preferred sizes and min/max constraints. It is pure Bend with no external
layout engine and no IO. Its geometry module (`Size`, `Rect`, `Insets`, hit
testing) is the shared geometry of Kairo, Mokko, and other AMAGE libraries.

**Status:** early implementation, tested with **Bend 2.0.35** on Linux. The
first priority is a polished, reliable experience on the development Linux
machine. Compatibility layers will follow proven progress.

## What works today

- `Row` and `Column` axes, per-side padding, and a fixed gap between children.
- Main-axis justification: `Leading`, `Middle`, `Trailing`, `Between`.
- Cross-axis alignment: `Start`, `Center`, `End`, `Stretch`.
- Preferred sizes clamped by per-child min/max constraints; `Stretch` fills the
  cross axis and also respects min/max.
- Explicit overflow: the main axis never shrinks children to hide overflow.
  The result keeps sizes and spacing and reports `overflow = True`.
- Padding larger than the container yields a zero-sized content box, never a
  negative one. `Between` with zero or one child does not divide by zero.
- Validation of containers, configuration, and children, with typed errors.
- Hit testing that includes the left/top edges and excludes the right/bottom
  edges.

The native suite has **20 checks**: computed row/column coordinates,
padding/gap, center/end/between/stretch, min/max, overflow, an empty zero-size
viewport, relayout at a changed viewport, negative inputs, contradictory
min/max, NaN/infinity rejection, and exclusive edges. Mokko's demo tests also
lay out real text measured from Liberation Sans and relayout it from 480 to
180 logical units wide.

## Quick start

Requirements: the [Bend 2 toolchain](https://bend-lang.com) and Clang 14 or
newer. No display is needed and Tessra has no sibling dependencies.

```sh
git clone https://github.com/amage-si/tessra.git Tessra
cd Tessra
export BEND_NO_TELEMETRY=1
bend version
mkdir -p build
bend tests.bend -o build/tests
./build/tests --threads 2 --gpu off
```

Run the toolbar example, which lays out the same row at two widths:

```sh
bend examples/toolbar.bend -o build/toolbar
./build/toolbar --threads 2 --gpu off
```

```text
360x48 viewport (fits)
  child 1: x=8 y=8 w=48 h=32
  child 2: x=120 y=12 w=120 h=24
  child 3: x=304 y=8 w=48 h=32
200x48 viewport (overflow)
  child 1: x=8 y=8 w=48 h=32
  child 2: x=64 y=12 w=120 h=24
  child 3: x=192 y=8 w=48 h=32
```

## The layout contract

```bend
import Base
import ./Tessra/main.bend as L
import ./Tessra/geometry.bend as G

def report(result: Result<&2, &2, L.Error, L.Layout>) -> IO(Unit):
  match result:
    case Fail{e}: IO.die(Unit, 1, "layout rejected")
    case Done{L.Layout{content, placements, overflow}}: IO.print("laid out")

def main() -> IO(Unit):
  report(L.layout(G.Rect{0.0, 0.0, 200.0, 100.0},
    L.Config{L.Row{}, G.Insets{10.0, 10.0, 10.0, 10.0}, 8.0, L.Leading{}, L.Center{}},
    [L.Child{1, G.Size{40.0, 20.0}, L.unconstrained()}]))
```

`layout(container, config, children)` returns
`Result<&2, &2, Error, Layout>`. A `Layout` holds the content box after
padding, one `Placement{id, rect}` per child in input order, and the overflow
flag. `find(placements, id)` returns the first rectangle with that id.

Coordinates and lengths are logical `F32` units with the origin at the top
left, x to the right and y down. Converting to physical pixels belongs to the
backend adapter; Tessra does no pixel rounding. Read the
[API reference](docs/api.md) for every type, error, and numeric bound.

## Current boundaries

- One level per call. Nested layouts are composed by successive calls; there
  is no recursive tree solver, flex grow/shrink distribution, wrapping, or grid.
- No clipping or rendering. Content measurements are supplied by the caller;
  Mokko's demo obtains them from Syllo with a real font.
- Accepted lengths are `[0, 1000000]`; coordinates and resulting edges are
  `[-1000000, 1000000]`. These bounds are deliberate, not full `F32` support.
- Ids are carried through without a uniqueness check (Kairo requires unique,
  non-zero ids).
- The algorithm makes linear passes over the child list: O(n) time and output,
  by code inspection. Throughput on large layouts has not been measured.
- Relayout at a new viewport works and is tested without a window. Resizing a
  real window is not available: the official Bend window effect keeps a fixed
  size and does not report a new one.

`ALL PROOFS CHECK` from the Bend checker covers types and termination of the
programs. No formal specification of the layout laws has been written; the
tests are separate, partial evidence.

## Repository map

| Path | Purpose |
| --- | --- |
| [main.bend](main.bend) | Axes, alignment, constraints, the `layout` solver, `find`. |
| [geometry.bend](geometry.bend) | `Size`, `Rect`, `Insets`, validation, `contains`, `inset`, `equal`. |
| [tests.bend](tests.bend) | Native checks; no display needed. |
| [test_support.bend](test_support.bend) | The `expect` helper shared by Tessra, Kairo, and Mokko tests. |
| [examples/toolbar.bend](examples/toolbar.bend) | A row laid out at two widths, printed to the terminal. |
| [docs/api.md](docs/api.md) | Types, errors, bounds, and behavior. |

## Used by

[Kairo](https://github.com/amage-si/kairo) and
[Mokko](https://github.com/amage-si/mokko) import `geometry.bend` and
`test_support.bend` as `../Tessra/...`, so Tessra must be cloned beside them
with its capitalized directory name. Keep these file paths stable.

## Direction

Next: flex-style distribution, a layout tree, coordinated clipping, wrapping
and overflow policies, and real window resizing once the platform layer
reports it. These are goals, not supported features.

See [CONTRIBUTING.md](CONTRIBUTING.md) for development rules. The API is
experimental and may change. A distribution license has not yet been selected.
