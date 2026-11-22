# Freshet-Scientific

**Scientific, engineering and high-throughput data libraries for the Freshet programming language.**

Freshet-Scientific implements the separate Layer 2 described by the
[Freshet language standard](https://github.com/PolskaKrowa/Freshet-lang).
It remains independent of Freshet-lang and Penstock: the public algorithms
are written in Freshet and use the ratified `fsht-03:03` language/runtime
surface and its documented math intrinsics, without language extensions or
compiler source modifications.

## Libraries in 0.2.0

| Library | Responsibility | Included foundations |
|---|---|---|
| **Freshet-Numerics** | Arithmetic and linear algebra | Stable scaled 2-norm, checked finite-value kernels, dense and blocked matrix products, COO-to-CSR assembly, CSR SpMV, matrix-free `LinearOperatorF64`, Jacobi preconditioning, CG/PCG and BiCGStab |
| **Freshet-Data** | Bounded-memory and columnar data processing | Welford/Chan statistics, mergeable covariance accumulators, histograms, fixed-width binary block I/O (`f64`, `f32`, `i64`, `u64`), explicit byte order, zero-copy record-batch column views and reusable chunk transforms |
| **Freshet-Fluid** | Structured-grid incompressible CFD | Consistent 2D MAC-grid pressure projection, pressure residual and divergence reports, boundary-condition types, conservative periodic and closed-wall scalar fluxes, Heun RK2, 3D MAC divergence and a lid-driven cavity profile example |
| **Freshet-Mechanics** | Engineering and structural mechanics | SI dimensional quantities, 2D/3D vectors, isotropic materials, statics, beam formulae, 2D/3D truss element stiffness, stress invariants and a 1D axial-bar FEM assembly/solve path |

This is a substantial **0.2.0 research foundation**, not a declaration that
every numerical model is validated for safety-critical design or production
CFD. Solver convergence, conditioning, boundary-condition suitability and
model assumptions remain application responsibilities. Advanced 3D flow,
nonlinear/large-deformation mechanics, high-order FEM, GPU execution and
parallel/distributed I/O remain future work.

## Design principles

1. **Freshet first; no compiler fork.** Library code is `.fsht` and must remain
   expressible without changes to Freshet-lang or Penstock.
2. **Caller-owned workspaces.** Dense/sparse solvers and data transforms accept
   `Span<T>` buffers. Allocation and I/O stay outside hot parallel regions.
3. **Explicit numerical contracts.** Non-finite inputs/results, dimension
   errors, invalid sparse structures and solver breakdowns are reported.
   Strict IEEE-style floating-point semantics remain the default.
4. **Parallel writes are disjoint.** `parfor` kernels write distinct output
   indices. Reproducible reductions are used where determinism matters.
5. **Bounded-memory data flow.** Binary readers, transformation buffers and
   writers are reused per chunk; column accessors return borrowed spans into a
   caller-owned record-batch payload.
6. **Discretisations must agree.** The MAC pressure operator is the discrete
   divergence of the same face-gradient used for velocity correction. The
   periodic manufactured-operator test pins this identity.
7. **Measure and verify.** Performance claims require benchmarks; physical
   models require residual, conservation and manufactured/reference tests.

## Requirements

- Penstock implementing Freshet `fsht-03:03` (the tested reference is the
  current Penstock development compiler).
- CMake 3.16 or later for the convenience build and CTest wiring.
- Freshet-Data's fixed-width binary adapter uses the C stdio ABI (`#link c`);
  it currently targets hosted platforms providing the standard C library.

## Build

Build the libraries directly:

```sh
penstock build Freshet-Numerics
penstock build Freshet-Data
penstock build Freshet-Fluid
penstock build Freshet-Mechanics
```

Or use the top-level CMake targets:

```sh
cmake -S . -B build
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

CMake invokes the installed Penstock executable; it does not bootstrap, patch,
or modify Penstock. Set `PENSTOCK_EXECUTABLE` if it is not on `PATH`:

```sh
cmake -S . -B build -DPENSTOCK_EXECUTABLE=/opt/penstock/bin/penstock
```

Run the test projects without CMake:

```sh
PENSTOCK=penstock ./tools/test-all.sh
```

## Examples

- `Freshet-Numerics/examples/sparse_pcg.fsht` assembles a COO matrix, converts
  it to CSR and solves it with Jacobi-preconditioned CG.
- `Freshet-Data/examples/binary_transform.fsht` streams fixed-width little-
  endian `f64` blocks through reusable input/output/work buffers.
- `Freshet-Fluid/examples/lid_driven_cavity.fsht` advances a 2D MAC-grid cavity
  and prints divergence checkpoints plus centreline velocity profiles. The run is a transient demonstration, not yet a Ghia steady-state reference benchmark.
- `Freshet-Mechanics/examples/bar_and_beam.fsht` evaluates a simply supported
  beam formula; the test suite also assembles and solves a 1D bar FEM system.

## Key contracts and limitations

### Numerics

- The public scalar kernels currently specialise in `f64` (binary I/O also
  supports `f32`, `i64` and `u64`).
- CSR uses caller-owned row offsets, column indices and values. COO-to-CSR
  assembly retains input order within each row; duplicate entries are legal
  and sum naturally during SpMV. It does not sort columns or merge duplicates
  during assembly.
- `LinearOperatorF64` uses static dispatch and caller-owned output spans. CG
  requires an SPD operator; PCG additionally requires a suitable positive
  preconditioner. BiCGStab is provided for nonsymmetric operators.
- Solver workspaces must not alias each other or the input/output spans unless
  a function explicitly documents alias support. `axpy_f64` permits exact
  `x`/`y` aliasing; arbitrary partial overlap is not supported.

### Data

- Statistics use population variance. Welford updates and Chan merges support
  independently processed chunks; combine chunks in increasing chunk-index
  order when deterministic results are required. Covariance results flag
  correlation as undefined when either variance is zero.
- Binary file functions process raw fixed-width values. The caller selects
  `Native`, `LittleEndian` or `BigEndian` and supplies non-overlapping reusable scratch for
  endian-converting writes. A partial trailing element is reported as
  `TruncatedBlock`.
- Record-batch payloads are non-owning, column-oriented byte buffers. Column
  offsets must be aligned to their element width, columns may not overlap, and
  the payload must outlive all returned column spans.
- `process_binary_f64_chunks<T: BinaryChunkTransformF64>` provides the
  reusable reader/chunk/decode/validate/parallel-transform/write path with
  static dispatch and caller-owned workspaces. `scan_f64_lines` remains a
  convenience/reference adapter; high-throughput ingestion should use binary
  blocks.

### Fluid

- The pressure projection is 2D, constant-density and uniform Cartesian. It
  stores pressure at cell centres and velocity on staggered faces. Its report
  distinguishes the pressure-equation residual from the initial/final maximum
  divergence; callers must check `converged` and the reported final divergence.
- `Wall` implies homogeneous pressure Neumann data; `Inflow` and `Neumann` use
  the supplied outward pressure derivative; `Dirichlet` and `Outflow` use
  prescribed pressure values; `Periodic` wraps.
  The velocity boundary helper prescribes wall tangential speed (including a
  moving lid). Verify these conventions against the physical problem.
- A 3D MAC divergence/face-count foundation is present, but the 3D pressure
  projection and 3D time integrator are not yet implemented.

### Mechanics

- Quantities store SI values plus integer exponents for all seven SI base
  dimensions: length, mass, time, electric current, thermodynamic temperature,
  amount of substance and luminous intensity. Addition/subtraction require matching dimensions;
  multiplication/division combine checked exponents.
- Beam functions implement specific Euler–Bernoulli closed-form cases, not a
  general beam element library. Truss routines provide linear two-node element
  stiffness/axial-force calculations; the first FEM solve path is a 1D axial
  bar with dense SPD CG.
- Material and stress functions use linear isotropic assumptions. No claim is
  made for plasticity, contact, buckling, fatigue or nonlinear constitutive
  behaviour.

## Repository layout

```text
Freshet-Scientific/
├── Freshet-Numerics/   # dense/sparse kernels and Krylov solvers
├── Freshet-Data/       # binary blocks, record batches and statistics
├── Freshet-Fluid/      # MAC-grid CFD foundations and cavity example
├── Freshet-Mechanics/  # SI units and structural mechanics
├── docs/               # architecture, performance policy and roadmap
├── tools/              # multi-project test runner
└── CMakeLists.txt
```

## Upstream relationship

- [Freshet-lang](https://github.com/PolskaKrowa/Freshet-lang) specifies
  `fsht-03:03` and the language/runtime primitives.
- [Penstock](https://github.com/PolskaKrowa/Penstock) is the reference compiler.
- [`docs/VALIDATION.md`](docs/VALIDATION.md) records which static/reference checks were run and which Penstock tests still require the target toolchain.
- This repository implements Layer 2 scientific and engineering libraries.
  It is separate by design and does not require modifications to either
  upstream project.

## Licence

Apache-2.0. See [`LICENSE`](LICENSE).
