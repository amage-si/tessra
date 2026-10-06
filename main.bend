import Base
import ./geometry.bend as G

type Axis is Data:
  Row{}
  Column{}

type Align is Data:
  Start{}
  Center{}
  End{}
  Stretch{}

type Justify is Data:
  Leading{}
  Middle{}
  Trailing{}
  Between{}

type Constraints is Data:
  Constraints{min: G.Size, max: G.Size}

type Child is Data:
  Child{id: U32, preferred: G.Size, limits: Constraints}

type Config is Data:
  Config{axis: Axis, padding: G.Insets, gap: F32, justify: Justify, align: Align}

type Placement is Data:
  Placement{id: U32, rect: G.Rect}

type Layout is Data:
  Layout{content: G.Rect, children: +List<Placement>, overflow: Bool}

type Error is Data:
  InvalidContainer{}
  InvalidConfig{}
  InvalidChild{id: U32}
  NumericRange{}

def unconstrained() -> Constraints:
  Constraints{G.Size{0.0, 0.0}, G.Size{1000000.0, 1000000.0}}

def valid_constraints(c: Constraints) -> Bool:
  Constraints{G.Size{+lw, +lh}, G.Size{+hw, +hh}} = c
  G.valid_length(lw) && G.valid_length(lh) && G.valid_length(hw) && G.valid_length(hh) && (lw <= hw : F32) && (lh <= hh : F32)

def valid_child(c: Child) -> Bool:
  Child{id, preferred, limits} = c
  G.valid_size(preferred) && valid_constraints(limits)

def check_child(ok: Bool, id: U32, rest: Result<&2, &2, Error, Unit>) -> Result<&2, &2, Error, Unit>:
  match ok:
    case False{}:
      Fail{InvalidChild{id}}
    case True{}:
      rest

def check_children(cs: +List<Child>) -> Result<&2, &2, Error, Unit>:
  match cs:
    case Nil{}:
      Done{Unit{}}
    case Con{+c, rest}:
      Child{+id, p, l} = c
      check_child(valid_child(c), id, check_children(rest))

def resolve_size(c: Child) -> G.Size:
  Child{id, G.Size{w, h}, Constraints{G.Size{lw, lh}, G.Size{hw, hh}}} = c
  G.Size{F32.clamp(w, lw, hw), F32.clamp(h, lh, hh)}

def main_size(axis: Axis, size: G.Size) -> F32:
  match axis:
    case Row{}:
      G.Size{w, h} = size
      w
    case Column{}:
      G.Size{w, h} = size
      h

def cross_size(axis: Axis, size: G.Size) -> F32:
  match axis:
    case Row{}:
      G.Size{w, h} = size
      h
    case Column{}:
      G.Size{w, h} = size
      w

def dimensions(r: G.Rect) -> G.Size:
  G.Rect{x, y, w, h} = r
  G.Size{w, h}

def totals(cs: +List<Child>, +axis: Axis, count: U32, used: F32) -> U32 & F32:
  match cs:
    case Nil{}:
      (count, used)
    case Con{c, rest}:
      totals(rest, axis, (count + 1 : U32), (used + main_size(axis, resolve_size(c)) : F32))

def leading(j: Justify, free: F32) -> F32:
  match j:
    case Leading{}:
      0.0
    case Middle{}:
      (free / 2.0 : F32)
    case Trailing{}:
      free
    case Between{}:
      0.0

def safe_between(multiple: Bool, count: U32, free: F32) -> F32:
  match multiple:
    case False{}:
      0.0
    case True{}:
      (free / U32.to_f32((count - 1 : U32)) : F32)

def extra_gap(j: Justify, +count: U32, free: F32) -> F32:
  match j:
    case Between{}:
      safe_between((count > 1 : U32), count, free)
    case _:
      0.0

def cross_offset(a: Align, free: F32) -> F32:
  match a:
    case Center{}:
      (free / 2.0 : F32)
    case End{}:
      free
    case _:
      0.0

def cross_extent(a: Align, c: Child, +axis: Axis, available: F32) -> F32:
  match a:
    case Stretch{}:
      Child{id, p, Constraints{lo, hi}} = c
      F32.clamp(available, cross_size(axis, lo), cross_size(axis, hi))
    case _:
      cross_size(axis, resolve_size(c))

def positioned(axis: Axis, r: G.Rect, along: F32, across: F32, m: F32, c: F32) -> G.Rect:
  match axis:
    case Row{}:
      G.Rect{x, y, w, h} = r
      G.Rect{(x + along : F32), (y + across : F32), m, c}
    case Column{}:
      G.Rect{x, y, w, h} = r
      G.Rect{(x + across : F32), (y + along : F32), c, m}

def place(cs: +List<Child>, +axis: Axis, +align: Align, +content: G.Rect, cursor: F32, +gap: F32) -> +List<Placement>:
  match cs:
    case Nil{}:
      Nil{}
    case Con{+child, rest}:
      Child{id, pref, limits} = child
      +m = main_size(axis, resolve_size(child))
      +available = cross_size(axis, dimensions(content))
      +c = cross_extent(align, child, axis, available)
      offset = cross_offset(align, F32.max(0.0, (available - c : F32)))
      +at = cursor
      rect = positioned(axis, content, at, offset, m, c)
      Con{Placement{id, rect}, place(rest, axis, align, content, (at + m + gap : F32), gap)}

def inside(+outer: G.Rect, inner: G.Rect) -> Bool:
  G.Rect{+ox, +oy, ow, oh} = outer
  G.Rect{+x, +y, w, h} = inner
  (x >= ox : F32) && (y >= oy : F32) && (x + w <= ox + ow : F32) && (y + h <= oy + oh : F32)

def any_overflow(ps: +List<Placement>, +content: G.Rect) -> Bool:
  match ps:
    case Nil{}:
      False{}
    case Con{Placement{id, r}, rest}:
      Bool.not(inside(content, r)) || any_overflow(rest, content)

def valid_placements(ps: +List<Placement>) -> Bool:
  match ps:
    case Nil{}:
      True{}
    case Con{Placement{id, r}, rest}:
      G.valid_rect(r) && valid_placements(rest)

def checked_layout(ok: Bool, content: G.Rect, children: +List<Placement>, overflow: Bool) -> Result<&2, &2, Error, Layout>:
  match ok:
    case False{}:
      Fail{NumericRange{}}
    case True{}:
      Done{Layout{content, children, overflow}}

def solve_totals(total: U32 & F32, content: G.Rect, config: Config, children: +List<Child>) -> Result<&2, &2, Error, Layout>:
  (+count, used) = total
  Config{+axis, padding, +gap, +justify, align} = config
  +inner = content
  gaps = U32.to_f32(U32.sub(count, U32.min(count, 1)))
  +free = F32.max(0.0, (main_size(axis, dimensions(inner)) - used - gap * gaps : F32))
  +places = place(children, axis, align, inner, leading(justify, free), (gap + extra_gap(justify, count, free) : F32))
  checked_layout(valid_placements(places), inner, places, any_overflow(places, inner))

def solve(content: G.Rect, +config: Config, +children: +List<Child>) -> Result<&2, &2, Error, Layout>:
  Config{axis, padding, gap, justify, align} = config
  solve_totals(totals(children, axis, 0, 0.0), content, config, children)

def after_children(check: Result<&2, &2, Error, Unit>, content: G.Rect, config: Config, children: +List<Child>) -> Result<&2, &2, Error, Layout>:
  match check:
    case Fail{error}:
      Fail{error}
    case Done{u}:
      solve(content, config, children)

def checked_config(ok: Bool, container: G.Rect, +config: Config, +children: +List<Child>) -> Result<&2, &2, Error, Layout>:
  match ok:
    case False{}:
      Fail{InvalidConfig{}}
    case True{}:
      Config{a, p, g, j, s} = config
      after_children(check_children(children), G.inset(container, p), config, children)

def checked_container(ok: Bool, container: G.Rect, +config: Config, children: +List<Child>) -> Result<&2, &2, Error, Layout>:
  match ok:
    case False{}:
      Fail{InvalidContainer{}}
    case True{}:
      Config{a, p, g, j, s} = config
      checked_config(G.valid_insets(p) && G.valid_length(g), container, config, children)

def layout(+container: G.Rect, config: Config, children: +List<Child>) -> Result<&2, &2, Error, Layout>:
  checked_container(G.valid_rect(container), container, config, children)

def find(ps: +List<Placement>, +wanted: U32) -> Maybe<&2, G.Rect>:
  match ps:
    case Nil{}:
      None{}
    case Con{Placement{id, r}, rest}:
      Bool.pick(Maybe<&2, G.Rect>, U32.is_eq(id, wanted), Some{r}, find(rest, wanted))
