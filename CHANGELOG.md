# Changelog

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
