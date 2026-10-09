# Changelog

All notable changes to Tessra are recorded here. Tessra follows
[semantic versioning](https://semver.org) in its 0.x form: while the API is
experimental, a minor version (0.2.0) may change it in breaking ways and a
patch version (0.1.1) only fixes. Tessra is built from source together with its
sibling AMAGE libraries; the set of versions tested together is listed in
[eco-build's releases](https://github.com/amage-si/eco-build/tree/main/releases).

## [0.1.0] - 2026-10-09

First tagged release, tested with Bend 2.0.35 on Linux (X11/XWayland) as part
of AMAGE Eco 0.1.0.

### Included

- Row and column layout with padding, gaps, justification, cross-axis
  alignment, preferred sizes and min/max constraints.
- Explicit overflow reporting, typed validation errors and edge-exclusive hit
  testing.
- The shared geometry (`Size`, `Rect`, `Insets`) of the ecosystem.
- 20 native checks.

[0.1.0]: https://github.com/amage-si/tessra/releases/tag/v0.1.0
