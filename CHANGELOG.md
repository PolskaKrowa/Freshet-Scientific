# Changelog

## 0.2.1 — 2026-11-23

First release validated against the real Penstock reference compiler (a
current development build of `fsht-03:03` with its default LLVM 23 SDK).
The 0.2.0 sources had never been compiled; every change below was found by
running `penstock build` / `penstock test` and is confined to this repository
— no changes were made to Freshet-lang or Penstock.

### Compiler-diagnostic fixes (source surface)
- Removed the dotted enum-variant spelling `MechanicsError.X` used throughout
  Freshet-Mechanics; Penstock parses `A.B` as field access, so variants are
  written by their (already `Mechanics`-prefixed) bare context-resolved
  names, for example `Err(MechanicsDimensionMismatch)`. The mixed-import
  convention is unchanged: Mechanics variants keep the `Mechanics` prefix so
  they never collide with the concise `NumericsError` variants.
- Marked the cast-derived record-batch alias pointers in the Freshet-Data
  tests `let mut`: writes through non-owned immutable pointer bindings are
  rejected by Penstock's pointer-mutability rule (F0208).
- Renamed the loop variable `step` in the lid-driven cavity example
  (`step_index`): `step` is a reserved keyword and the example did not parse
  (F0102).
- Moved the trait-generic solver call in `examples/sparse_pcg.fsht` out of
  `fn main()` into a helper function: the current Penstock development
  compiler crashes when `fn main()` itself instantiates a trait-generic
  function, while the identical call from an ordinary function or an `@test`
  function compiles and runs correctly.

### Cross-module trait dispatch
- Moved the matrix-free operator fixtures out of the test module into
  Freshet-Numerics itself: `DiagonalOperatorF64` is now a documented public
  diagonal operator, and the two intentionally contract-violating fixtures
  (`ShortOperatorF64`, `OverflowOperatorF64`) ship with the library so the
  solver validation tests can exercise them. Penstock's current
  generic-instantiation visibility rules resolve trait impls from the module
  that owns the generic function, so operator types must be visible from
  `freshet_numerics`; the Numerics README now states this constraint instead
  of claiming arbitrary application modules can implement the trait.

### Numerical fixes
- The MAC pressure projection now uses a weighted (under-relaxed) Jacobi
  sweep with omega = 0.8. Plain Jacobi's odd-even "checkerboard" mode is an
  eigenvalue -1 mode of the periodic and homogeneous-Neumann 5-point operator
  on even grids, so the unweighted sweep never damps it and the pressure
  residual stalls at the checkerboard energy of the right-hand side for
  general velocity fields (the two previously failing projection tests
  exposed exactly this). The relaxed sweep keeps the exact discrete solution
  as its fixed point and preserves the disjoint parallel writes; all twelve
  Fluid tests now pass, including the previously stalling periodic and cavity
  projections.
- Replaced the five floating-point `[reduction(max:…)]` parfor kernels
  (`max_f64`, `stable_timestep_2d`, `mac_stable_timestep_2d`, the projection
  residual maximum and the internal `max_abs` helper) with serial
  deterministic maxima, and the projection residual pass with a serial pass.
  Penstock 0.1.0 lowers floating-point min/max parfor reductions to
  `llvm.fmin`/`llvm.fmax`, which do not exist in LLVM 20-23, so every such
  kernel failed to link with the reference backend. Integer reductions and
  `reduction(+:…)` are unaffected and remain parallel. The serial maxima are
  noted in the sources and can return to parfor when the reference compiler
  emits `llvm.maxnum`/`llvm.minimum` for the backend matrix.

### Memory-safety fix in Freshet-Data
- The binary I/O tests closed every handle explicitly *and* through `defer`,
  double-`fclose`-ing each `FILE*` and aborting glibc ("double free detected
  in tcache 2"). Tests now close each handle exactly once (deferred) and
  call `binary_flush` where data must be visible before the deferred close
  fires. `binary_close` documents the exactly-once contract: a
  `borrowed mut` close cannot invalidate the caller's copy of the handle
  struct (fsht-03:02 aggregate borrows do not write back), so a second close
  of the same handle is undefined.

### Test corrections
- The boundary-value regression in Freshet-Fluid now asserts the documented
  contract: a bottom Wall's tangential speed drives the bottom row of u
  faces (and the left Inflow's tangential value the first interior column of
  v); it previously asserted an interior u column that the operator does not
  and should not touch.

### Validation (see docs/VALIDATION.md)
- All four test suites were compiled and executed with the reference
  compiler and its LLVM 23 backend: Numerics 16/16, Fluid 12/12, Data 19/19,
  Mechanics 16/16. All four static-library targets build
  (`libfreshet_*.a`), and every example runs, including the 500-step Re=100
  lid-driven cavity. No changes were made to Freshet-lang or Penstock.

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
