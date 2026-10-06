import Base

type Size is Data:
  Size{width: F32, height: F32}

type Rect is Data:
  Rect{x: F32, y: F32, width: F32, height: F32}

type Insets is Data:
  Insets{left: F32, top: F32, right: F32, bottom: F32}

# Bounded logical coordinates reject NaN/infinity without bit reinterpretation.
def valid_coord(+v: F32) -> Bool:
  (v >= F32.neg(1000000.0) : F32) && (v <= 1000000.0 : F32)

def valid_length(+v: F32) -> Bool:
  (v >= 0.0 : F32) && (v <= 1000000.0 : F32)

def valid_size(s: Size) -> Bool:
  Size{w, h} = s
  valid_length(w) && valid_length(h)

def valid_rect(r: Rect) -> Bool:
  Rect{+x, +y, +w, +h} = r
  valid_coord(x) && valid_coord(y) && valid_length(w) && valid_length(h) && valid_coord((x + w : F32)) && valid_coord((y + h : F32))

def valid_insets(i: Insets) -> Bool:
  Insets{l, t, r, b} = i
  valid_length(l) && valid_length(t) && valid_length(r) && valid_length(b)

def contains(r: Rect, +px: F32, +py: F32) -> Bool:
  Rect{+x, +y, w, h} = r
  (px >= x : F32) && (py >= y : F32) && (px < x + w : F32) && (py < y + h : F32)

def equal(a: Rect, b: Rect) -> Bool:
  Rect{x, y, w, h} = a
  Rect{u, v, s, t} = b
  F32.is_eq(x, u) && F32.is_eq(y, v) && F32.is_eq(w, s) && F32.is_eq(h, t)

def inset(r: Rect, p: Insets) -> Rect:
  Rect{x, y, +w, +h} = r
  Insets{+l, +t, rr, b} = p
  Rect{(x + F32.min(l, w) : F32), (y + F32.min(t, h) : F32), F32.max(0.0, (w - l - rr : F32)), F32.max(0.0, (h - t - b : F32))}
