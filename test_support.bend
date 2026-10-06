import Base

def expect(ok: Bool, name: String) -> IO(Unit):
  match ok:
    case False{}:
      IO.die(Unit, 1, "FAIL: " ++ name)
    case True{}:
      IO.print("PASS: " ++ name)
