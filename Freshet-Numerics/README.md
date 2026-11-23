# Freshet-Numerics

Numerical primitives and linear solvers for arithmetic-heavy Freshet programs.
The current implementation is `f64`-centred and keeps matrices, vectors and
solver workspaces in caller-owned spans.

## Public module

```freshet
import freshet_numerics;
```

## Vector and dense kernels

| Function | Contract |
|---|---|
| `fill_f64(output, value)` | Fill an output span |
| `scale_f64(alpha, input, output)` | `output = alpha * input` |
| `sum_f64(input)` | Reproducible parallel sum |
| `max_f64(input)` | Deterministic serial maximum |
| `dot_f64(a, b)` | Reproducible dot product |
| `norm2_f64(values)` | Scaled sum-of-squares Euclidean norm |
| `axpy_f64(alpha, x, y)` | In-place `y = alpha*x + y` |
| `matvec_f64(n, A, x, y)` | Row-major dense square matrix-vector product |
| `matmul_f64(m,k,n,A,B,C)` | Dense row-major product |
| `blocked_matmul_f64(...)` | Caller-selected tiled dense product |
| `dense_matrix_validate_f64(A)` | Validate a `DenseMatrixF64` view (shape + finiteness) |
| `dense_matrix_is_symmetric_f64(A)` | Exact mirrored-entry symmetry of a square dense view |

The norm avoids squaring raw magnitudes and therefore handles many vectors
whose direct sum of squares would overflow or underflow. A norm whose true
result is itself outside the `f64` range is reported as `NonFiniteResult`.

`max_f64` and the other floating-point maxima in this repository are
computed by serial deterministic loops: the reference compiler currently
lowers floating-point min/max parfor reductions to LLVM intrinsics that do
not exist in LLVM 20-23, so those kernels stay serial until its backend
matrix is corrected. Integer reductions and `reduction(+:…)` remain
parallel.

## Sparse matrices and solvers

`CSRMatrixF64` is a non-owning CSR view containing `rows`, `cols`, `nnz`, row
offsets, column indices and values. `csr_validate` checks structural and index
invariants; `csr_matvec_f64` applies it. `coo_to_csr_f64` assembles caller
provided COO entries into caller-owned CSR output arrays and workspace.
Duplicate entries are retained and contribute additively during SpMV; entries
are not sorted or coalesced by the conversion routine. `csr_merge_duplicates_f64`
canonicalises a CSR matrix afterwards: within each row the stored entries are
insertion-sorted by column index and duplicates are summed, producing the single
entry per (row, column) representation that preconditioners and future
incomplete factorisations expect; it returns the merged nonzero count.
`csr_is_symmetric_f64` checks numerical symmetry directly on
duplicate-carrying matrices (cost O(nnz * row length); an inspection kernel,
not a hot path), matching `dense_matrix_is_symmetric_f64` on the dense side.

The static-dispatch `LinearOperatorF64` trait represents `y = A*x`. Dense
and CSR types implement it, and `DiagonalOperatorF64` ships as the
provided matrix-free diagonal operator. Note that Penstock's current
generic-instantiation visibility rules resolve trait impls from the module
that owns the generic solver, so operator types must be declared in (or be
visible from) `freshet_numerics`; `ShortOperatorF64` and
`OverflowOperatorF64` also ship with the library as intentionally
contract-violating fixtures for the solver validation tests and must not be
used as real operators. `PreconditionerF64` provides the corresponding
preconditioner interface.

Implemented iterative solvers:

- `conjugate_gradient_operator_f64` and dense compatibility wrapper
  `conjugate_gradient_f64` for symmetric positive-definite operators.
- `preconditioned_conjugate_gradient_f64` for SPD operators with a suitable
  positive preconditioner.
- `bicgstab_f64` for general nonsymmetric operators.
- `preconditioned_gmres_f64`: restarted GMRES(m) with modified Gram-Schmidt
  Arnoldi and Givens rotations for general (possibly nonsymmetric) operators,
  right-preconditioned through any `PreconditionerF64`. The residual norm in
  the returned report is recomputed from `b - A x` rather than trusted from
  the least squares estimate. The workspaces (Krylov basis, Hessenberg
  coefficients, rotations, triangular-solve coefficients and update vector)
  are caller-owned; see the function documentation for the exact lengths.
- `IdentityPreconditionerF64` (z = r) makes plain GMRES the identity-
  preconditioned case without a second solver variant.
- `diagonal_inverse_f64` and `csr_inverse_diagonal_f64` for Jacobi inverse
  diagonals; `JacobiPreconditionerF64` applies one to a residual.

Sparse direct factorisation, incomplete-factorisation preconditioners,
block sparse formats and distributed sparse assembly are not implemented in
this release.

## Numerical and memory contracts

- Non-finite inputs are reported as `NonFiniteInput`; non-finite computed
  outputs/intermediates are reported as `NonFiniteResult`.
- CG/PCG require finite non-negative tolerances and SPD-compatible operators.
  A non-positive `pᵀAp` is `NotPositiveDefinite`; breakdowns are explicit.
- Iteration limits are reported through `converged = false`, not silently
  treated as success.
- GMRES reports lucky breakdown of the Arnoldi process as convergence of the
  current restart cycle (the Krylov space already contains the exact
  solution); a zero Givens denominator or non-finite coefficient is reported
  as `SolverBreakdown`/`NonFiniteResult`.
- Matrix/vector/workspace spans must have the documented lengths and should
  not overlap unless explicitly supported. `axpy_f64` supports exact `x`/`y`
  aliasing; partial overlap is not supported.
- Solvers do not allocate their Krylov workspaces. The caller supplies and
  owns them, making memory use explicit and reusable.

## Example

See [`examples/sparse_pcg.fsht`](examples/sparse_pcg.fsht) for COO assembly,
CSR conversion and Jacobi-preconditioned CG, and
[`examples/gmres_solver.fsht`](examples/gmres_solver.fsht) for restarted
GMRES on a small nonsymmetric system.

## Build and test

```sh
penstock build .
penstock test tests/test_numerics.fsht -Isrc
```
