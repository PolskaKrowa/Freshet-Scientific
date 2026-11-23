# Validation record — Freshet-Scientific 0.3.0

This file distinguishes checks actually performed in the packaging
environment from tests that remain the responsibility of a user's Penstock
installation. A source-level or independent reference check is not presented
as a Penstock compiler pass.

## Independent reference validation performed for 0.3.0 (package environment)

Every 0.3.0 algorithm was implemented and exercised first as an independent
Python reference of the identical formulation, and the shipped Freshet code
plus its test constants were written against the reference's measurements:

- **Multigrid:** dense-matrix two-grid analysis of the cell-centred pair
  (piecewise-constant prolongation P, block-average restriction R = Pᵀ/4)
  verified the rediscretisation identity R·A·P = 2·A₂h exactly (including
  Dirichlet/Neumann closure rows and periodic wrap), the adjoint identity
  ⟨P e, r⟩ = 4 ⟨e, R r⟩ to machine precision on wrapped and clamped grids, and
  a two-grid spectral radius of ≈0.16 with the natural rediscretised coarse
  operator (rediscretisation without the constant pair diverges, radius ≈2.5 —
  the reason the shipped pair is what it is). V-cycle convergence measured on
  the shipped test problems: 6×6 Dirichlet manufactured pressure converges in
  15 cycles to 1e-10 (max error 3.5e-13), 8×8 periodic manufactured in 11
  cycles (1.6e-13), 16×16 periodic (three levels) in 14 cycles, and an 8×8
  wall/lid case in 12 cycles to 1e-8. The weighted-Jacobi baseline for the
  same Dirichlet problem needs 428 sweeps.
- **Pressure PCG:** on the 8×8 one-dimensional manufactured Dirichlet
  problem, Jacobi-PCG converges in 16 iterations and multigrid-PCG in 9
  (both to 1e-10, pressure error ≤ 2.8e-14) — the shipped comparison test's
  margins. The operator's sign convention (A is the negative Laplacian, CG
  runs on L = -A) was verified by eigen-decomposition of the constrained
  systems.
- **GMRES:** the restarted reference (modified Gram-Schmidt + Givens, right
  preconditioning) reproduces the 2×2 nonsymmetric solution (0.1, 0.6),
  converges in 22 inner steps with Jacobi and identity preconditioning on an
  8×8 nonsymmetric system, and in 28 outer steps with restart = 1 — matching
  the shipped tolerances. Lucky-breakdown and sign-cancellation behaviour
  was checked against direct dense solves.
- **Sparse global analysis:** the determinate three-bar triangle (pin,
  roller, 1000 N apex load) matches statics exactly (inclined compression
  1118.033989 N, base tension 1000 N, reactions (0, 500) N) and the
  Castigliano apex settlement to 1e-18 relative; the 3D three-bar support
  matches compression 2√3·P/9 and the unit-load settlement to 1e-15. The
  mechanism-deficient two-bar variant (m+r < 2j) that motivated the
  three-bar design was identified by eigen-analysis in the reference.
- **FDO format:** a byte-level reference implementation of the layout
  (32-byte header with magic/version/byte-order/Adler-32, 80-byte directory
  entries, raw and run-length payloads) round-trips both byte orders, sizes
  the shipped test file at exactly 448 bytes, compresses the run column to
  16 bytes, exercises the raw fallback, and detects single-byte payload
  corruption through the checksum. Adler-32 was checked against published
  vectors (`"a" → 6422626`, `"abc" → 38600999`).

The static checks of the package environment were re-run over all changed
sources (see below). No Penstock compilation pass is claimed for 0.3.0 in
this environment; the commands for revalidation with the reference
toolchain are at the end of this file.

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

## Checks performed in the package environment (retained and extended for 0.3.0)

- Static scan of all `.fsht` files: balanced delimiters, module declarations,
  no `match`/`if` used as expressions, mutable bindings for writable
  aliases derived from `Span<T>.ptr`, statement-form enum-variant matching,
  no bitwise/shift operators, no `fn main()` generic instantiation, and no
  floating-point `reduction(min:/max:)` clauses. New 0.3.0 sources were
  additionally restricted to constructs demonstrated by the 0.2.1-validated
  corpus (span slicing, pointer-to-pointer casts, `str_to_cstr`, `defer`,
  `malloc`/`free`, checked arithmetic).
- `sh -n tools/test-all.sh`.
- Parsed all four `penstock.toml` files with a TOML parser and checked that
  each declares a static-library target and source entry (Freshet-Data now
  lists two compilation roots: `freshet_data.fsht` and `fdo_format.fsht`).
- Independent reference calculations for the scaled 2-norm at large and
  small magnitudes, Welford/Chan merge agreement, a small SPD PCG system,
  the periodic MAC `D(G(p))` identity, a manufactured Dirichlet pressure
  recovery, closed-wall scalar mass conservation, and the eigenvalue
  analysis that pinned the projection's undamped odd-even mode (maximal
  non-gauge eigenvalue 1.0 of the unrelaxed iteration matrix), plus the
  0.3.0 reference set listed above.

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

The 0.3.0 additions must be revalidated with the same commands: the expected
suite counts after revalidation are Numerics 22/22, Fluid 20/20, Data 24/24
and Mechanics 19/19, plus the four new examples (`gmres_solver`,
`multigrid_projection`, `global_truss`, `fdo_roundtrip`).

The lid-driven cavity example is a 32×32, Re=100 transient run that emits
centreline profiles. It is not yet quantitatively verified against a
published Ghia steady-state reference curve. The Mechanics FEM
implementation keeps a 1D axial-bar dense foundation; the sparse global path
is a linear truss foundation, not a general 2D/3D finite-element solver.
