# Contributing to Tessra

Use Bend 2.0.35 for the current baseline. Read `bend guide` before editing Bend
and keep project text in English. Library implementation belongs in Bend; the
official runtime and operating system remain external dependencies.

## Validation

From the repository root:

```sh
export BEND_NO_TELEMETRY=1
mkdir -p build
bend main.bend --check-only
bend tests.bend -o build/tests
./build/tests --threads 2 --gpu off
bend examples/toolbar.bend -o build/toolbar
./build/toolbar --threads 2 --gpu off
```

The tests need no display. `geometry.bend` and `test_support.bend` are shared:
when you change them, also build and run the suites of
[Kairo](https://github.com/amage-si/kairo) and
[Mokko](https://github.com/amage-si/mokko) cloned beside this directory.

Build one target at a time. The native Bend runtime reserves substantial virtual
address space; a virtual-memory limit is not a resident-memory limit. Preserve
crash evidence and investigate before repeating a failed compiler invocation.

## Changes

Keep the API small and the numeric domain explicit. Add a focused regression
check when behavior changes, update [docs/api.md](docs/api.md), and report what
was actually validated. A layout claim about performance needs a measurement.

Use English commit messages that explain the result. Do not commit `build/`,
generated C, logs, crash dumps, credentials, or machine-specific paths. Do not
publish BendHub packages or create releases as a side effect of validation.

Compatibility work follows concrete Linux progress. New layout modes need
explicit implementations and their own checks before being advertised as
supported.
