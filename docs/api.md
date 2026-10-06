# Tessra API

Tessra depends only on `Base` from the official Bend toolchain. Import paths
are relative to the calling file. An application next to the `Tessra`
directory uses:

```bend
import Base
import ./Tessra/main.bend as L
import ./Tessra/geometry.bend as G
```

## Geometry (`geometry.bend`)

```bend
Size{width: F32, height: F32}
Rect{x: F32, y: F32, width: F32, height: F32}
Insets{left: F32, top: F32, right: F32, bottom: F32}
```

Coordinates and lengths are logical `F32` units, origin at the top left,
x to the right and y down. Converting to physical pixels belongs to the backend
adapter.

| Function | Contract |
| --- | --- |
| `valid_coord(v)` | `v` in `[-1000000, 1000000]`. Rejects NaN and infinity without bit reinterpretation. |
| `valid_length(v)` | `v` in `[0, 1000000]`. |
| `valid_size(s)`, `valid_insets(i)` | Every component is a valid length. |
| `valid_rect(r)` | Valid x/y, valid width/height, and valid right/bottom edges. |
| `contains(r, x, y)` | Hit test: includes the left/top edges, excludes the right/bottom edges. |
| `equal(a, b)` | Exact component equality. |
| `inset(r, insets)` | Shrinks `r`; never produces a negative size. |

Kairo and Mokko use these helpers, so their names and the file path are part
of the cross-library contract.

## Layout (`main.bend`)

```bend
Axis:        Row{} | Column{}
Justify:     Leading{} | Middle{} | Trailing{} | Between{}
Align:       Start{} | Center{} | End{} | Stretch{}
Constraints{min: G.Size, max: G.Size}
Child{id: U32, preferred: G.Size, limits: Constraints}
Config{axis: Axis, padding: G.Insets, gap: F32, justify: Justify, align: Align}
Placement{id: U32, rect: G.Rect}
Layout{content: G.Rect, children: +List<Placement>, overflow: Bool}
Error:       InvalidContainer{} | InvalidConfig{} | InvalidChild{id: U32} | NumericRange{}
```

| Function | Contract |
| --- | --- |
| `layout(container, config, children)` | Returns `Result<&2, &2, Error, Layout>`. |
| `find(placements, id)` | `Maybe<&2, G.Rect>`: the first placement with that id. |
| `unconstrained()` | Min `0x0`, max `1000000x1000000`. |

### Behavior

- The content box is the container inset by the padding. Padding larger than
  the container gives a zero-sized content box, never a negative one.
- Each child's size is its preferred size clamped by its min/max.
- Main axis: children follow input order, separated by `gap`. `Leading`,
  `Middle`, and `Trailing` place the group at the start, center, or end of the
  free space. `Between` adds the free space evenly between children; with zero
  or one child it adds nothing.
- Cross axis: `Start`, `Center`, and `End` position each child in the content
  box. `Stretch` uses the full cross extent clamped by the child's min/max.
- Overflow: children are never shrunk on the main axis. If any placement leaves
  the content box, `overflow` is `True` and sizes and spacing are preserved.
- Ids are carried through; uniqueness is not required. `find` returns the
  first match.

### Errors

| Error | Cause |
| --- | --- |
| `InvalidContainer` | Negative, non-finite, or out-of-domain container rectangle. |
| `InvalidConfig` | Negative, NaN, infinite, or out-of-domain gap or padding. |
| `InvalidChild{id}` | Invalid preferred size, or a min larger than its max. |
| `NumericRange` | A resulting position falls outside the coordinate domain. |

## Cost and scope

The solver makes linear passes over the child list (O(n) time and output, by
code inspection). There is no internal parallelism, recursion over a tree,
pixel rounding, clipping, or rendering. Content sizes come from the caller.
The API is not stable yet.
