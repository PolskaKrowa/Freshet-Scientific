# Validation record — Freshet-Scientific 0.2.0

This file distinguishes checks actually performed in the package environment
from tests that require the user's Penstock installation. A source-level or
independent reference check is not presented as a Penstock compiler pass.

## Checks performed

- Static scan of all 25 `.fsht` files: balanced delimiters, source-module
declarations, no `match`/`if` used as expressions, and mutable bindings for
writable aliases derived from `Span<T>.ptr`.
- `sh -n tools/test-all.sh`.
- Parsed all four `penstock.toml` files with Python's TOML parser and checked
  that each declares a static-library target and source entry.
- Configured top-level CMake with a placeholder executable solely to inspect
  generated build metadata. The `freshet_numerics`, `freshet_fluid`,
  `freshet_data`, `freshet_mechanics` and aggregate `freshet_scientific`
  targets were registered; CTest listed the four library test suites. This
  does **not** build a library.
- Independent reference calculations checked the scaled 2-norm at large and
  small magnitudes, Welford/Chan merge agreement, a small SPD PCG system, the
  periodic MAC `D(G(p))` identity, a manufactured Dirichlet pressure recovery,
  and closed-wall scalar mass conservation. These calculations check the
  mathematical formulations, not the compiled Freshet source.

## Not performed here

The `penstock` executable is not installed in this environment. Therefore the
following have **not** been run for 0.2.0:

- `penstock build` for any of the four projects;
- the four `.fsht` test suites through `penstock test`;
- actual static archive linking or execution of the examples;
- performance benchmarks or parallel-scaling measurements.

Run the complete compiler validation with:

```sh
PENSTOCK=penstock ./tools/test-all.sh
cmake -S . -B build -DPENSTOCK_EXECUTABLE="$(command -v penstock)"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

The lid-driven cavity example is a 32×32, Re=100 transient run that emits
centreline profiles. It is not yet quantitatively verified against a published
Ghia steady-state reference curve. The Mechanics FEM implementation is a 1D
axial-bar foundation, not a general 2D/3D finite-element solver.
