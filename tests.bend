import Base
import ./main.bend as L
import ./geometry.bend as G
import ./test_support.bend as A

def child(id: U32, w: F32, h: F32) -> L.Child:
  L.Child{id, G.Size{w, h}, L.unconstrained()}

def config(axis: L.Axis, justify: L.Justify, align: L.Align) -> L.Config:
  L.Config{axis, G.Insets{10.0, 10.0, 10.0, 10.0}, 8.0, justify, align}

def at_rect(found: Maybe<&2, G.Rect>, expected: G.Rect) -> Bool:
  match found:
    case None{}:
      False{}
    case Some{r}:
      G.equal(r, expected)

def at(result: Result<&2, &2, L.Error, L.Layout>, id: U32, expected: G.Rect) -> Bool:
  match result:
    case Fail{e}:
      False{}
    case Done{L.Layout{content, children, overflow}}:
      at_rect(L.find(children, id), expected)

def overflow(result: Result<&2, &2, L.Error, L.Layout>) -> Bool:
  match result:
    case Fail{e}:
      False{}
    case Done{L.Layout{c, p, yes}}:
      yes

def invalid(result: Result<&2, &2, L.Error, L.Layout>) -> Bool:
  Result.is_fail(&2, &2, L.Error, L.Layout, result)

def empty(result: Result<&2, &2, L.Error, L.Layout>) -> Bool:
  match result:
    case Done{L.Layout{c, Nil{}, False{}}}:
      True{}
    case _:
      False{}

def row() -> Result<&2, &2, L.Error, L.Layout>:
  L.layout(G.Rect{0.0, 0.0, 200.0, 100.0}, config(L.Row{}, L.Leading{}, L.Center{}), [child(1, 40.0, 20.0), child(2, 60.0, 30.0)])

def column() -> Result<&2, &2, L.Error, L.Layout>:
  L.layout(G.Rect{0.0, 0.0, 160.0, 200.0}, config(L.Column{}, L.Middle{}, L.Center{}), [child(1, 40.0, 20.0), child(2, 60.0, 30.0)])

def main() -> IO(Unit):
  do IO<Unit>:
    A.expect(at(row(), 1, G.Rect{10.0, 40.0, 40.0, 20.0}), "row padding and cross center")
    A.expect(at(row(), 2, G.Rect{58.0, 35.0, 60.0, 30.0}), "row spacing")
    A.expect(Bool.not(overflow(row())), "row fits")
    A.expect(at(column(), 1, G.Rect{60.0, 71.0, 40.0, 20.0}), "column main center")
    A.expect(at(column(), 2, G.Rect{50.0, 99.0, 60.0, 30.0}), "column gap")
    A.expect(at(L.layout(G.Rect{0.0, 0.0, 200.0, 100.0}, config(L.Row{}, L.Trailing{}, L.End{}), [child(1, 40.0, 20.0)]), 1, G.Rect{150.0, 70.0, 40.0, 20.0}), "trailing and end")
    A.expect(at(L.layout(G.Rect{0.0, 0.0, 200.0, 100.0}, config(L.Row{}, L.Between{}, L.Start{}), [child(1, 40.0, 20.0), child(2, 60.0, 20.0)]), 2, G.Rect{130.0, 10.0, 60.0, 20.0}), "space between")
    A.expect(at(L.layout(G.Rect{0.0, 0.0, 200.0, 100.0}, config(L.Row{}, L.Leading{}, L.Stretch{}), [L.Child{1, G.Size{1.0, 200.0}, L.Constraints{G.Size{20.0, 10.0}, G.Size{80.0, 40.0}}}]), 1, G.Rect{10.0, 10.0, 20.0, 40.0}), "min max and bounded stretch")
    A.expect(overflow(L.layout(G.Rect{0.0, 0.0, 40.0, 20.0}, config(L.Row{}, L.Leading{}, L.Start{}), [child(1, 60.0, 20.0)])), "overflow is explicit without negative size")
    A.expect(empty(L.layout(G.Rect{0.0, 0.0, 0.0, 0.0}, config(L.Row{}, L.Between{}, L.Stretch{}), Nil{})), "empty zero viewport and oversized padding")
    A.expect(at(L.layout(G.Rect{0.0, 0.0, 300.0, 100.0}, config(L.Row{}, L.Trailing{}, L.Start{}), [child(1, 40.0, 20.0)]), 1, G.Rect{250.0, 10.0, 40.0, 20.0}), "relayout at changed viewport")
    A.expect(invalid(L.layout(G.Rect{0.0, 0.0, F32.neg(1.0), 20.0}, config(L.Row{}, L.Leading{}, L.Start{}), Nil{})), "negative container rejected")
    A.expect(invalid(L.layout(G.Rect{0.0, 0.0, 10.0, 20.0}, L.Config{L.Row{}, G.Insets{0.0, 0.0, 0.0, 0.0}, F32.neg(1.0), L.Leading{}, L.Start{}}, Nil{})), "negative spacing rejected")
    A.expect(invalid(L.layout(G.Rect{0.0, 0.0, 10.0, 20.0}, config(L.Row{}, L.Leading{}, L.Start{}), [L.Child{9, G.Size{1.0, 1.0}, L.Constraints{G.Size{20.0, 0.0}, G.Size{10.0, 10.0}}}])), "contradictory constraints rejected")
    A.expect(invalid(L.layout(G.Rect{0.0, 0.0, 10.0, 20.0}, config(L.Row{}, L.Leading{}, L.Start{}), [child(1, F32.neg(1.0), 1.0)])), "invalid preferred size rejected")
    A.expect(Bool.not(G.valid_length(F32.div(0.0, 0.0))), "NaN rejected")
    A.expect(Bool.not(G.valid_length(F32.div(1.0, 0.0))), "infinity rejected")
    A.expect(G.contains(G.Rect{F32.neg(10.0), 0.0, 20.0, 10.0}, 0.0, 0.0), "negative origin supported")
    A.expect(Bool.not(G.contains(G.Rect{0.0, 0.0, 20.0, 10.0}, 20.0, 5.0)), "right edge exclusive")
    A.expect(Bool.not(G.contains(G.Rect{0.0, 0.0, 20.0, 10.0}, 5.0, 10.0)), "bottom edge exclusive")
    IO.print("Tessra: 20 tests passed")
