# Roadmap

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

## 0.3 — validation and performance evidence

- Run the complete test suites on the supported Penstock/compiler versions and
  add CI that records the exact compiler and target configuration.
- Add benchmark datasets for dense/CSR SpMV, Krylov solvers, binary ingestion,
  fluid timesteps and Mechanics assembly/solve. Report throughput, bandwidth,
  memory footprint and convergence/residual alongside wall time.
- Add property-based and differential tests for CSR structure, solver
  convergence, endian I/O, boundary fluxes, dimensional algebra and FEM
  equilibrium.
- Consider GMRES, incomplete-factorisation preconditioners and sparse FEM
  assembly after CSR and operator APIs have benchmark coverage.

## Subsequent development

### Numerics

- GMRES and restarted Krylov methods, ILU/IC preconditioning, block CSR,
  sparse assembly utilities and mixed precision.
- Factorisations and preconditioner comparisons tied to real application
  matrices.

### Data

- Compression and checksummed block formats, richer schema/catalogue metadata,
  filtered column projection, parallel decode/encode and general transform
  callbacks. Quantiles and approximate sketches may follow exact statistics.

### Fluid

- Boundary-condition verification against analytical/reference flows,
  conservative momentum fluxes and higher-order reconstruction. The current
  Re=100 cavity run is a transient profile-producing demonstration, not yet
  validated against a published steady-state reference dataset.
- 3D pressure projection, variable-density and thermal/energy models, then
  turbulence closures and more advanced meshes.

### Mechanics

- Sparse FEM assembly/solution, 2D/3D truss model assembly, frame/beam finite
  elements and validation against analytical/reference cases.
- More constitutive behaviour only after verification and test cases exist.

GPU/accelerator execution, distributed-memory decomposition, adaptive meshes,
nonlinear structural mechanics and multiphysics coupling remain longer-term
work. Roadmap items are proposals until their code and tests land.
