# Roadmap

## 0.3.0 — multigrid, GMRES, sparse global analysis and the FDO format

Implemented in this release (developed against an independent Python
reference of every algorithm; see `docs/VALIDATION.md` for the revalidation
plan with the reference compiler):

- Numerics: validated matrix representations (`dense_matrix_validate_f64`,
  `dense_matrix_is_symmetric_f64`, `csr_merge_duplicates_f64`,
  `csr_is_symmetric_f64`) and the restarted, right-preconditioned
  `preconditioned_gmres_f64` with `IdentityPreconditionerF64`.
- Fluid: geometric multigrid (cell-centred 2:1 hierarchy, boundary-blind
  piecewise-constant prolongation and block-average restriction with the
  exact R·A·P = 2·A₂h rediscretisation identity), the standalone multigrid
  projection, Jacobi- and multigrid-preconditioned CG pressure projections
  and parallel coarse-grid correction kernels.
- Mechanics: sparse global structural analysis (global truss assembly in
  2D/3D, sparse Dirichlet elimination, sparse PCG solve, support reactions,
  element post-processing and equilibrium checks).
- Data: the FDO (Freshet-Data Optimised) file format with magic identifier,
  version, byte-order marker, dimensions, column schema and units, offsets,
  sizes, Adler-32 checksums, binary payloads and optional run-length
  compression with raw fallback.

Still open from the 0.3 plan: benchmark datasets and throughput/bandwidth
reporting for the new kernels, property-based/differential test harnesses,
and CI that records the exact compiler configuration.

## 0.2.1 — first reference-compiler validation

The complete 0.2.0 surface was compiled, linked and executed against the
reference Penstock compiler with its LLVM 23 backend for the first time:
all four test suites pass (16/12/19/16), all four static-library targets
build and every example runs. The fixes this surfaced — the weighted Jacobi
projection sweep, the serial floating-point maxima, the cross-module
operator visibility, the exactly-once close contract and the source-surface
corrections — are listed in the changelog; the corresponding Penstock-side
limitations are recorded in `docs/VALIDATION.md` so the workarounds can be
retired when the compiler moves.

## 0.2.0 — correctness and breadth foundations

Implemented in this release:

- Finite-value validation, scaled `f64` norms, Welford/Chan statistics,
  covariance/correlation and explicit solver breakdown checks.
- COO-to-CSR assembly, CSR validation/SpMV, matrix-free operator dispatch,
  Jacobi preconditioning, CG/PCG, BiCGStab and blocked dense multiplication.
- Fixed-width binary block I/O, typed zero-copy record-batch column views,
  reusable bounded-memory transforms and a streaming text adapter with
  deterministic reader close.
- MAC-grid 2D pressure projection, residual/divergence reports, boundary
  descriptors, conservative periodic and closed-wall scalar transport, Heun RK2,
  3D MAC divergence, non-trivial and manufactured projection tests, cavity
  centreline-profile example.
- Separate Freshet-Mechanics library with all seven SI dimensions, engineering
  vectors, material properties, statics, beam reference formulae, truss
  elements, stress invariants and 1D axial-bar FEM assembly/solve.

## Subsequent development

### Numerics

- Restarted Krylov comparisons (GMRES(m) sensitivity) and ILU/IC
  preconditioning on merged CSR structures, block CSR, sparse assembly
  utilities and mixed precision.
- Factorisations and preconditioner comparisons tied to real application
  matrices.

### Data

- Parallel FDO encode/decode, dictionary/filter codecs beyond run-length,
  richer catalogue metadata, filtered column projection and general transform
  callbacks. Quantiles and approximate sketches may follow exact statistics.

### Fluid

- Boundary-condition verification against analytical/reference flows,
  conservative momentum fluxes and higher-order reconstruction. The current
  Re=100 cavity run is a transient profile-producing demonstration, not yet
  validated against a published steady-state reference dataset.
- 3D pressure projection (including the 3D multigrid hierarchy), variable-density
  and thermal/energy models, then turbulence closures and more advanced meshes.

### Mechanics

- Beam/frame finite elements in the global assembly, distributed loads,
  validation against analytical/reference cases beyond trusses, and sparse
  factorisation-based solvers.
- More constitutive behaviour only after verification and test cases exist.

GPU/accelerator execution, distributed-memory decomposition, adaptive meshes,
nonlinear structural mechanics and multiphysics coupling remain longer-term
work. Roadmap items are proposals until their code and tests land.
