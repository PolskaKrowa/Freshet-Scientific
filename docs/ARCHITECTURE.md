# Architecture

## Layer boundary

Freshet-Scientific is a consumer of Freshet, not an extension of the language.
The Freshet-lang introduction (chapter 00) places scientific libraries in
Layer 2 and requires that they be expressible without compiler changes. The
public implementations in this repository are `.fsht` and target the
ratified `fsht-03:03` language/runtime surface.

## Libraries and dependency direction

- **Freshet-Numerics** owns vector kernels, dense/sparse matrix views and
  validation, canonical CSR merging, iterative linear solvers (CG/PCG,
  BiCGStab, GMRES) and the operator/preconditioner traits.
- **Freshet-Data** owns fixed-width binary I/O, the FDO columnar file format,
  columnar batch descriptors, chunk transforms and mergeable statistics. It
  has no dependency on Numerics.
- **Freshet-Fluid** owns grid layouts, finite-volume operators, the MAC
  projection, the pressure operator/diagonal kernels, the geometric
  multigrid hierarchy and the multigrid/PCG pressure projections. It
  computes its own 2D pressure iterations; it has no dependency on Numerics.
- **Freshet-Mechanics** owns dimensional quantities and engineering models.
  Its dense FEM path uses Freshet-Numerics for SPD conjugate gradient, and
  the `structural` module drives the sparse global path through Numerics'
  COO→CSR assembly, CSR operator/preconditioner dispatch and sparse CG.

The dependency graph is intentionally acyclic:

```text
Freshet-Numerics      Freshet-Data      Freshet-Fluid
        ^
        |
Freshet-Mechanics
```

Each library has a separate `penstock.toml` and static-library target. Its
umbrella module is `freshet_numerics`, `freshet_data`, `freshet_fluid` or
`freshet_mechanics`; focused internal modules remain importable where
appropriate. `fdo_format` is a second compilation root of the Freshet-Data
project (listed in its `penstock.toml` src array) so the archive exports it
without `freshet_data` importing it back — the FDO module depends on
`freshet_data`'s `ColumnType`/`ByteOrder`/`DataError` types, so the import
direction stays one-way and acyclic.

## Memory and ownership

Computational kernels operate on caller-owned `Span<T>` views. The caller owns
the backing storage and controls its lifetime. Large temporary arrays are not
allocated in hot loops. Iterative solvers, GMRES Krylov/Hessenberg buffers,
multigrid level buffers, binary transforms, FEM routines and FDO encoding
workspaces accept explicit reusable spans. File handles are closed through
explicit close calls or `defer` on all return paths; `binary_close`,
`fdo_close` and the FDO writer's deferred raw-handle close all document the
exactly-once contract.

Parallel kernels read immutable spans and write to distinct output indices
through mutable pointer aliases accepted by Penstock's `parfor` checks.
Scalar reductions use explicit reduction clauses; reproducibility-sensitive
sums request `@reproducible`. Floating-point min/max kernels are currently
serial deterministic maxima because the reference compiler's min/max
reduction lowering does not link against the LLVM 20-23 backend matrix (see
`docs/VALIDATION.md`); integer min/max reductions and `reduction(+:…)` remain
parallel. The MAC pressure solve is a weighted Jacobi sweep whose relaxation
damps the otherwise undamped odd-even mode of periodic and homogeneous-Neumann
grids. The multigrid transfer kernels (block-average restriction,
piecewise-constant prolongation and the accumulated coarse correction) are
likewise `parfor` kernels whose iterations write distinct cells — the parallel
coarse-grid correction — with the adjoint identity `<P e, r> = 4 <e, R r>` as
the regression pin. The multigrid hierarchy walks levels with an explicit
descent/ascent loop rather than recursion, and the coarse solve is heavier
smoothing rather than an exact factorisation.

## Numerical behaviour

Strict floating-point semantics remain the default. Public algorithms
validate finite inputs and check computed results where overflow or invalid
intermediates can occur. Errors are returned through library-specific enums.
CG/PCG assumptions and solver reports are explicit; GMRES recomputes its
reported residual from `b - A x` rather than trusting the least squares
estimate, and the Fluid PCG runs on the positive operator L = -A with the
boundary-set requirement documented. Fluid pressure correction
uses a MAC layout and a pressure stencil derived from its discrete divergence
and gradient operators. Mechanics' dense FEM example is limited to 1D linear
axial bars; the sparse global path covers linear truss models with nodal
loads. FDO serialises integers with division/modulo and multiplication only
(no bit-shift or bitwise operators) and performs strict schema checks on
read.

## Build and validation

The top-level CMake project registers all four static-library projects and
CTest suites. Penstock itself is an external prerequisite: CMake neither
builds nor changes the compiler. The repository's tarball is source-only;
static archives are generated by the user's Penstock build.
