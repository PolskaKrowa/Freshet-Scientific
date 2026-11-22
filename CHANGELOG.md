# Changelog

## 0.2.0 — 2026-11-22

### Compiler diagnostic follow-up
- Corrected the `BinaryChunkTransformF64` trait and implementation receiver syntax to match the established Penstock trait form (by-value `Self` parameter); this removes the parser-error cascade in Freshet-Data.
- Kept record-batch column access pointer-typed end-to-end: typed `Span<T>` views are built from the existing payload pointer and sliced without pointer/integer conversions or payload copies.
- Replaced the struct-returning pressure-boundary helper with pure scalar helpers, avoiding the unsupported struct-literal path in Penstock's `@pure` checker while preserving the MAC pressure stencil coefficients.
- Gave overlapping Mechanics error variants distinct `Mechanics`-prefixed names, allowing Numerics to retain Penstock-compatible context-resolved variants when both libraries are imported; added a mixed-import regression test.

### Freshet-Numerics
- Added explicit finite-input/result checks and rejected non-finite CG tolerances.
- Replaced `sqrt(dot(x,x))` with a scaled sum-of-squares 2-norm.
- Added CSR validation/SpMV, COO-to-CSR assembly, a static-dispatch linear-operator trait, Jacobi preconditioning, PCG and BiCGStab.
- Added reusable fill/scale/sum/max/AXPY primitives and blocked dense matrix multiplication.

### Freshet-Data
- Added Welford statistics, Chan merge, covariance/correlation accumulators and histograms; zero-variance correlation is explicitly marked undefined.
- Added fixed-width binary block I/O for f64/f32/i64/u64 with explicit byte order, partial-element detection and caller-owned scratch buffers; added a static-dispatch reusable chunk-transform pipeline.
- Added typed zero-copy column accessors for validated record batches and a reusable binary read-transform-write pipeline.
- Kept `scan_f64_lines` bounded-memory and made the reader close on EOF and every early-return path.

### Freshet-Fluid
- Replaced the collocated projection path with a MAC-grid projection: cell-centred pressure and staggered face velocities.
- The pressure stencil is built from the same discrete face gradient and cell divergence used for velocity correction.
- Added pressure-equation residual reporting, initial/final divergence reporting, explicit pressure/velocity boundary kinds, periodic conservative scalar transport, closed-wall no-flux scalar transport and Heun RK2.
- Added 3D MAC face counts/divergence, non-trivial projection tests, periodic operator and Dirichlet manufactured-pressure recovery tests, closed-wall scalar-mass conservation coverage, and a Re=100 lid-driven cavity example that reports centreline profiles (not yet validated against an external Ghia reference).

### Freshet-Mechanics
- Added the separate Mechanics library with all seven SI base dimensions, checked dimension exponents, stable 2D/3D vector norms and truss geometry, isotropic material models, statics, beam formulae, 2D/3D truss element stiffness, scaled principal/von-Mises stress evaluation and a 1D bar FEM assembly/CG path.
- Fixed FEM assembly to preserve caller-applied nodal loads rather than clearing the load vector. Added matrix sizing, geometry and intermediate-result validation.

- Added Mechanics to the top-level CMake aggregate target and test runner; the default `freshet_scientific` build now includes all four libraries.
- Tightened generated-result finite checks and operator/preconditioner return-count validation, CSR Jacobi reciprocal checks, public material-value validation, Fluid boundary-data handling and binary I/O edge cases; added binary-transform, text-scan and sparse-PCG regression coverage.
- Expanded all three original library test suites and added Mechanics regression cases.
- No changes were made to Freshet-lang or Penstock.

**Validation note:** static audits and project/build metadata checks are performed in the package environment. Actual Penstock compilation and test execution must be run with the target Penstock toolchain; no compiler pass is claimed unless the corresponding test command is executed.

## 0.1.3 — 2026-11-22

- Marked every raw pointer alias used as a writable output (`y_ptr`,
  `c_ptr`, `x_ptr`, `residual_ptr`, `direction_ptr`, `output_ptr`,
  `pressure_ptr`, `scratch_ptr`, `u_ptr`, and `v_ptr`) as a mutable
  binding with `let mut`.
- This follows Penstock's pointer mutability rule: writes through a raw
  pointer require a mutable, owned, or mutable-borrow binding. The
  language's own pointer optimisation regression uses `let mut` pointer
  aliases for this purpose.
- No kernel algorithms or parallel scheduling were changed.

Compilation and test execution still require the user's Penstock toolchain;
this environment does not contain the `penstock` executable.

## 0.1.2 — 2026-11-22

- Reworked all writable `parfor` kernels to capture explicit `*f64` output
  pointers. Penstock's race checker permits disjoint indexed stores through
  pointer-typed captures; it rejects writes rooted at a captured `Span<T>`.
- Changed dense matrix multiplication and 2D CFD stencil traversals to
  row-parallel, contiguous-column loops. This removes per-cell integer
  division/modulo and the corresponding F0402 performance warnings.
- Added a vendored copy of Penstock's Apache-2.0 `io` module to
  `Freshet-Data/src`, so standalone project builds resolve `import io;` even
  when the compiler's standard-library modules are not installed under
  `share/penstock/modules`.
- Updated project version metadata and documented the vendored module.

The changes address the diagnostics in the 22 November 2026 build log. Actual
Penstock compilation and test execution still need to be run with the user's
installed compiler; this environment does not contain the `penstock` binary.

## 0.1.1 — 2026-11-22

- Replaced match-as-expression constructs with statement-form matching.
- Removed imports of the unavailable `math` module in favour of compiler-known
  math intrinsics.

## 0.1.0 — 2026-11-22

- Initial three-library scientific computing foundation.
