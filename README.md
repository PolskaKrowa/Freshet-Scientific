<div align=center>
   <img width="612" height="408" alt="freshet-scientific_logo" src="https://github.com/user-attachments/assets/59620e8a-4336-45f9-b2fa-5406f9d5ad62" />
</div>

# Freshet-Scientific

**Scientific, engineering and high-throughput data libraries for the Freshet programming language.**

Freshet-Scientific implements the separate Layer 2 described by the
[Freshet language standard](https://github.com/PolskaKrowa/Freshet-lang).
It remains independent of Freshet-lang and Penstock: the public algorithms
are written in Freshet and use the ratified `fsht-03:03` language/runtime
surface and its documented math intrinsics, without language extensions or
compiler source modifications.

## Libraries in 0.3.0

| Library | Responsibility | Included foundations |
|---|---|---|
| **Freshet-Numerics** | Arithmetic and linear algebra | Stable scaled 2-norm, checked finite-value kernels, dense and blocked matrix products, validated dense matrix views with symmetry checks, COO-to-CSR assembly, canonical CSR duplicate merge and symmetry checks, CSR SpMV, matrix-free `LinearOperatorF64` (with the shipped `DiagonalOperatorF64`), Jacobi and identity preconditioning, CG/PCG, BiCGStab and restarted GMRES(m) |
| **Freshet-Data** | Bounded-memory and columnar data processing | Welford/Chan statistics, mergeable covariance accumulators, histograms, fixed-width binary block I/O (`f64`, `f32`, `i64`, `u64`), explicit byte order, zero-copy record-batch column views, reusable chunk transforms, and the checksummed, optionally run-length-compressed **FDO** columnar file format with magic, version, byte-order marker, dimensions, column schema, units, offsets, sizes and Adler-32 checksums |
| **Freshet-Fluid** | Structured-grid incompressible CFD | Consistent 2D MAC-grid pressure projection, the pressure operator and diagonal as public kernels, geometric multigrid (boundary-blind piecewise-constant prolongation and block-average restriction, parallel coarse-grid correction), multigrid and Jacobi/`PressureMultigrid`-preconditioned CG pressure projections, pressure residual and divergence reports, boundary-condition types, conservative periodic and closed-wall scalar fluxes, Heun RK2, 3D MAC divergence and a lid-driven cavity profile example |
| **Freshet-Mechanics** | Engineering and structural mechanics | SI dimensional quantities, 2D/3D vectors, isotropic materials, statics, beam formulae, 2D/3D truss element stiffness, stress invariants, a 1D axial-bar FEM assembly/solve path, and sparse global structural analysis: global truss COO assembly (2D/3D), sparse Dirichlet elimination, sparse PCG solve, support reactions, element post-processing and equilibrium checks |

This is a substantial **0.3.0 research foundation** — extending the first
release validated end-to-end against the reference Penstock compiler — not a
declaration that every numerical model is validated for safety-critical design
or production CFD. Solver convergence, conditioning, boundary-condition
suitability and model assumptions remain application responsibilities.
Advanced 3D flow, nonlinear/large-deformation mechanics, high-order FEM, GPU
execution and parallel/distributed I/O remain future work. The 0.3.0 sources
were developed against an independent Python reference of every new
algorithm and the package environment's static checks; revalidation with the
reference compiler is documented in `docs/VALIDATION.md`.

## Design principles

1. **Freshet first; no compiler fork.** Library code is `.fsht` and must remain
   expressible without changes to Freshet-lang or Penstock.
2. **Caller-owned workspaces.** Dense/sparse solvers, multigrid levels, FDO
   encoding and data transforms accept `Span<T>` buffers. Allocation and I/O
   stay outside hot parallel regions.
3. **Explicit numerical contracts.** Non-finite inputs/results, dimension
   errors, invalid sparse structures, singular elimination rows, foreign file
   formats, checksum mismatches and solver breakdowns are reported.
   Strict IEEE-style floating-point semantics remain the default.
4. **Parallel writes are disjoint.** `parfor` kernels write distinct output
   indices. Reproducible reductions are used where determinism matters.
5. **Bounded-memory data flow.** Binary readers, transformation buffers,
   multigrid level buffers and writers are reused per chunk; column
   accessors return borrowed spans into a caller-owned record-batch payload.
6. **Discretisations must agree.** The MAC pressure operator is the discrete
   divergence of the same face-gradient used for velocity correction. The
   periodic manufactured-operator test pins this identity, and the multigrid
   transfer kernels are pinned by the adjoint identity `<P e, r> = 4 <e, R r>`.
7. **Measure and verify.** Performance claims require benchmarks; physical
   models require residual, conservation and manufactured/reference tests.

## Requirements

- Penstock implementing Freshet `fsht-03:03` (the tested reference is the
  current Penstock development compiler).
- CMake 3.16 or later for the convenience build and CTest wiring.
- Freshet-Data's fixed-width binary adapter and the FDO format use the C
  stdio ABI (`#link c`); they currently target hosted platforms providing
  the standard C library.

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
  it to CSR and solves it with Jacobi-preconditioned CG;
  `gmres_solver.fsht` solves a small nonsymmetric system with restarted
  GMRES.
- `Freshet-Data/examples/binary_transform.fsht` streams fixed-width little-
  endian `f64` blocks through reusable input/output/work buffers;
  `fdo_roundtrip.fsht` writes, verifies and reads back a compressed,
  checksummed FDO columnar file.
- `Freshet-Fluid/examples/lid_driven_cavity.fsht` advances a 2D MAC-grid cavity
  and prints divergence checkpoints plus centreline velocity profiles (a
  transient demonstration, not yet a Ghia steady-state reference benchmark);
  `multigrid_projection.fsht` projects a wall-bounded flow with the geometric
  multigrid pressure solver.
- `Freshet-Mechanics/examples/bar_and_beam.fsht` evaluates a simply supported
  beam formula; `global_truss.fsht` runs the complete sparse pipeline (global
  assembly, CSR conversion, sparse constraints, sparse PCG solve, support
  reactions, element post-processing and equilibrium check) on a determinate
  three-bar truss.

## Key contracts and limitations

### Numerics

- The public scalar kernels currently specialise in `f64` (binary I/O and
  FDO columns also support `f32`, `i64` and `u64`).
- CSR uses caller-owned row offsets, column indices and values. COO-to-CSR
  assembly retains input order within each row; duplicate entries are legal
  and sum naturally during SpMV and CSR CG. `csr_merge_duplicates_f64`
  canonicalises rows (sorted columns, summed duplicates) when a single entry
  per (row, column) is required; `csr_is_symmetric_f64` and
  `dense_matrix_is_symmetric_f64` are exact-equality inspection kernels.
- `LinearOperatorF64` uses static dispatch and caller-owned output spans. CG
  requires an SPD operator; PCG additionally requires a suitable positive
  preconditioner. BiCGStab and GMRES are provided for nonsymmetric
  operators; GMRES is right-preconditioned through `PreconditionerF64`
  (`IdentityPreconditionerF64` for the plain case). Under the current
  Penstock visibility rules, operator types must be visible from the
  `freshet_numerics` module (the shipped dense, CSR, diagonal and fixture
  operators are); see the Freshet-Numerics README. Floating-point min/max
  kernels are serial deterministic maxima until the reference compiler's
  reduction lowering links against LLVM 20-23.
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
- The FDO format is a container: it verifies structure, offsets and checksums,
  but value-level finiteness is the caller's responsibility, exactly like
  record batches. Reading is strict — the expected type/name/unit must match
  the directory. Adler-32 checksums detect single-byte corruption; they are
  not cryptographic. Run-length compression falls back to raw storage when it
  would not shrink a column.
- `process_binary_f64_chunks<T: BinaryChunkTransformF64>` provides the
  reusable reader/chunk/decode/validate/parallel-transform/write path with
  static dispatch and caller-owned workspaces. `scan_f64_lines` remains a
  convenience/reference adapter; high-throughput ingestion should use binary
  blocks or FDO files.

### Fluid

- The pressure projection is 2D, constant-density and uniform Cartesian. It
  stores pressure at cell centres and velocity on staggered faces. Its report
  distinguishes the pressure-equation residual from the initial/final maximum
  divergence; callers must check `converged` and the reported final divergence.
- `Wall` implies homogeneous pressure Neumann data; `Inflow` and `Neumann` use
  the supplied outward pressure derivative; `Dirichlet` and `Outflow` use
  prescribed pressure values; `Periodic` wraps. The velocity boundary helper
  prescribes wall tangential speed (including a moving lid). Verify these
  conventions against the physical problem.
- The multigrid hierarchy coarsens by exactly 2:1 in both dimensions (every
  level keeps at least three cells per dimension); grids that are not even in
  both dimensions keep a single level. The multigrid and Jacobi projections
  accept the same boundary sets as the original projection; the PCG
  projection requires a pressure Dirichlet/outflow reference (SPD system) and
  reports `InvalidBoundarySet` otherwise. The multigrid coarse solve is an
  approximate (heavier smoothing) solve, not an exact one; the shipped tests
  measure the composite contraction.
- A 3D MAC divergence/face-count foundation is present, but the 3D pressure
  projection and 3D time integrator are not yet implemented.

### Mechanics

- Quantities store SI values plus integer exponents for all seven SI base
  dimensions: length, mass, time, electric current, thermodynamic
  temperature, amount of substance and luminous intensity. Addition/subtraction require matching dimensions;
  multiplication/division combine checked exponents.
- Beam functions implement specific Euler–Bernoulli closed-form cases, not a
  general beam element library. Truss routines provide linear two-node element
  stiffness/axial-force calculations; the 1D bar FEM path uses dense SPD CG
  and the new sparse global path covers linear truss models (nodal loads
  only). Sparse Dirichlet elimination turns constrained rows into identity
  equations through existing diagonals; stiffness-less constrained rows
  report `SingularSystem`. Sparse rows may keep explicit zeros where
  elimination cleared entries.
- Material and stress functions use linear isotropic assumptions. No claim
  is made for plasticity, contact, buckling, fatigue or nonlinear constitutive
  behaviour.

## Repository layout

```text
Freshet-Scientific/
├── Freshet-Numerics/   # dense/sparse kernels, Krylov solvers and GMRES
├── Freshet-Data/       # binary blocks, record batches, statistics and FDO
├── Freshet-Fluid/      # MAC-grid CFD, multigrid and PCG projections
├── Freshet-Mechanics/  # SI units, structural mechanics and sparse analysis
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
