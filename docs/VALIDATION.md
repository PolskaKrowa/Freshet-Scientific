# Validation record — Freshet-Scientific 0.2.1

This file distinguishes checks actually performed in the packaging
environment from tests that remain the responsibility of a user's Penstock
installation. A source-level or independent reference check is not presented
as a Penstock compiler pass.

## Compiler validation performed for 0.2.1

0.2.1 was validated against a real reference compiler build: the current
Penstock development tree (`fsht-03:03`, `0.1.0-INDEV`) built from source and
run against the official LLVM 23.1.4 SDK that Penstock's own bootstrap
downloads and SHA-256 verifies. All results below come from executed
commands, not static analysis.

- `penstock test` on all four suites, from each project directory:
  - Freshet-Numerics: **16/16 tests passed**.
  - Freshet-Fluid: **12/12 tests passed**.
  - Freshet-Data: **19/19 tests passed**.
  - Freshet-Mechanics: **16/16 tests passed** (`-Isrc -I../Freshet-Numerics/src`).
- `penstock build .` for all four projects produced the static-library
  targets `libfreshet_numerics.a`, `libfreshet_fluid.a`, `libfreshet_data.a`
  and `libfreshet_mechanics.a` (plus the auto-generated C headers for
  library targets).
- Every example was compiled and executed:
  `dot` (35.00), `sparse_pcg` (converged, x = 1, 2, 3),
  `binary_transform` (processed blocks end-to-end), `stream_stats`,
  `passive_scalar` (256 cells), `bar_and_beam`, and the 500-step Re=100
  `lid_driven_cavity` with divergence checkpoints and both centreline
  profiles.
- The 0.2.0 sources had never been compiled; executing the reference
  compiler surfaced and drove every 0.2.1 fix (see the changelog): the
  dotted `MechanicsError.X` variant spelling, cross-module trait-impl
  visibility, the floating-point min/max parfor reduction link failure,
  the projection solver's undamped odd-even mode, the double-close heap
  abort in the Data tests, the reserved-keyword `step` identifier and the
  main-body generic-instantiation crash in the sparse PCG example.

## Known reference-compiler limitations observed (not worked around in code beyond the above)

These are Penstock-side behaviours recorded so future releases can drop the
corresponding workarounds when the compiler changes; none of them require
changes to Freshet-lang or Penstock from this repository:

- Floating-point `reduction(min:…)`/`reduction(max:…)` parfor lowering emits
  `llvm.fmin`/`llvm.fmax`, which LLVM 20-23 do not provide; the affected
  kernels use serial deterministic maxima for now.
- A `fn main()` that directly instantiates a trait-generic function crashes
  the current compiler; generic calls are issued from ordinary functions.
- Trait impls are resolved from the module owning the generic function, so
  matrix-free operator types must be visible from `freshet_numerics`.
- `borrowed mut` aggregate parameters do not write back; handle closes are
  exactly-once by construction.

## Checks performed in the package environment (retained from 0.2.0)

- Static scan of all `.fsht` files: balanced delimiters, module declarations,
  no `match`/`if` used as expressions, mutable bindings for writable
  aliases derived from `Span<T>.ptr`.
- `sh -n tools/test-all.sh`.
- Parsed all four `penstock.toml` files with a TOML parser and checked that
  each declares a static-library target and source entry.
- Independent reference calculations for the scaled 2-norm at large and
  small magnitudes, Welford/Chan merge agreement, a small SPD PCG system,
  the periodic MAC `D(G(p))` identity, a manufactured Dirichlet pressure
  recovery, closed-wall scalar mass conservation, and the eigenvalue
  analysis that pinned the projection's undamped odd-even mode (maximal
  non-gauge eigenvalue 1.0 of the unrelaxed iteration matrix).

## Not performed here

- Performance benchmarks, parallel-scaling measurements and
  `@reproducible` throughput comparisons (unchanged from 0.2.0 policy).
- Cross-target matrix runs (the `--target` surface) — validation used the
  host `x86_64-pc-linux-gnu` target only.

Re-run the compiler validation with:

```sh
PENSTOCK=penstock ./tools/test-all.sh
cmake -S . -B build -DPENSTOCK_EXECUTABLE="$(command -v penstock)"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

The lid-driven cavity example is a 32×32, Re=100 transient run that emits
centreline profiles. It is not yet quantitatively verified against a
published Ghia steady-state reference curve. The Mechanics FEM
implementation is a 1D axial-bar foundation, not a general 2D/3D
finite-element solver.
