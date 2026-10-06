import Base
import ../main.bend as L
import ../geometry.bend as G

# A toolbar row: two buttons and a title, spread with Between and centered
# vertically. Sizes are fixed; Tessra reports overflow instead of shrinking.
def toolbar() -> +List<L.Child>:
  [L.Child{1, G.Size{48.0, 32.0}, L.unconstrained()},
    L.Child{2, G.Size{120.0, 24.0}, L.unconstrained()},
    L.Child{3, G.Size{48.0, 32.0}, L.unconstrained()}]

def config() -> L.Config:
  L.Config{L.Row{}, G.Insets{8.0, 8.0, 8.0, 8.0}, 8.0, L.Between{}, L.Center{}}

def show_rect(r: G.Rect) -> String:
  G.Rect{x, y, w, h} = r
  "x=" ++ F32.show(x) ++ " y=" ++ F32.show(y) ++ " w=" ++ F32.show(w) ++ " h=" ++ F32.show(h)

def show_overflow(overflow: Bool) -> String:
  match overflow:
    case True{}: "overflow"
    case False{}: "fits"

def print_places(ps: +List<L.Placement>) -> IO(Unit):
  match ps:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{L.Placement{id, r}, rest}:
      do IO<Unit>:
        IO.print("  child " ++ U32.show(id) ++ ": " ++ show_rect(r))
        print_places(rest)

def report(title: String, result: Result<&2, &2, L.Error, L.Layout>) -> IO(Unit):
  match result:
    case Fail{e}:
      IO.die(Unit, 1, title ++ ": layout rejected")
    case Done{L.Layout{content, children, overflow}}:
      do IO<Unit>:
        IO.print(title ++ " (" ++ show_overflow(overflow) ++ ")")
        print_places(children)

def main() -> IO(Unit):
  do IO<Unit>:
    report("360x48 viewport", L.layout(G.Rect{0.0, 0.0, 360.0, 48.0}, config(), toolbar()))
    report("200x48 viewport", L.layout(G.Rect{0.0, 0.0, 200.0, 48.0}, config(), toolbar()))
