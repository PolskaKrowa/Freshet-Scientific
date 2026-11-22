# Roadmap

## 0.1.x — foundations (this starter)

- Establish the Layer 2 repository and independent build/test projects.
- Add `f64` vector/matrix kernels and a workspace-based conjugate-gradient
  solver.
- Add 2D structured-grid operators, passive-scalar transport and a constant-
  density pressure projection baseline.
- Add span/chunk operations, summary statistics and bounded-memory text ingest.

## 0.2 — correctness and measurement

- Compile every project with the current Penstock reference compiler in CI.
- Add property, conservation, manufactured-solution and convergence tests.
- Add reproducible benchmark cases and memory-bandwidth measurements.
- Define stable error, workspace and ABI conventions across sub-libraries.

## 0.3 — numerical breadth

- Generic scalar and mixed-precision APIs where the Freshet type system makes
  them practical.
- LU/QR factorizations, preconditioned Krylov methods and sparse CSR matrices.
- Higher-order finite-volume reconstruction, selectable boundary conditions,
  compressible-flow foundations and validated equation-of-state interfaces.
- Columnar binary data readers, checksums, typed schemas and compression adapters.

## Later

- SIMD and architecture-specialised kernels only where Penstock-generated code
  and benchmarks justify them.
- Distributed-memory decomposition and accelerator backends behind explicit
  execution interfaces.
- Mesh refinement, multiphysics coupling and advanced turbulence models.
- Out-of-core and distributed dataset execution with deterministic semantics.

The roadmap is aspirational. Each item requires a design, tests and benchmark
before it is described as implemented.
