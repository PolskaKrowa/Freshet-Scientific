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
| `sum_f64(input)` / `max_f64(input)` | Deterministic sum / maximum |
| `dot_f64(a, b)` | Reproducible dot product |
| `norm2_f64(values)` | Scaled sum-of-squares Euclidean norm |
| `axpy_f64(alpha, x, y)` | In-place `y = alpha*x + y` |
| `matvec_f64(n, A, x, y)` | Row-major dense square matrix-vector product |
| `matmul_f64(m,k,n,A,B,C)` | Dense row-major product |
| `blocked_matmul_f64(...)` | Caller-selected tiled dense product |

The norm avoids squaring raw magnitudes and therefore handles many vectors
whose direct sum of squares would overflow or underflow. A norm whose true
result is itself outside the `f64` range is reported as `NonFiniteResult`.

## Sparse matrices and solvers

`CSRMatrixF64` is a non-owning CSR view containing `rows`, `cols`, `nnz`, row
offsets, column indices and values. `csr_validate` checks structural and index
invariants; `csr_matvec_f64` applies it. `coo_to_csr_f64` assembles caller
provided COO entries into caller-owned CSR output arrays and workspace.
Duplicate entries are retained and contribute additively during SpMV; entries
are not sorted or coalesced by the conversion routine.

The static-dispatch `LinearOperatorF64` trait represents `y = A*x`. Dense and
CSR types implement it, and application-defined types can implement it for
matrix-free operations. `PreconditionerF64` provides the corresponding
preconditioner interface.

Implemented iterative solvers:

- `conjugate_gradient_operator_f64` and dense compatibility wrapper
  `conjugate_gradient_f64` for symmetric positive-definite operators.
- `preconditioned_conjugate_gradient_f64` for SPD operators with a suitable
  positive preconditioner.
- `bicgstab_f64` for general nonsymmetric operators.
- `diagonal_inverse_f64` and `csr_inverse_diagonal_f64` for Jacobi inverse
  diagonals; `JacobiPreconditionerF64` applies one to a residual.

GMRES, sparse direct factorisation, incomplete-factorisation preconditioners,
block sparse formats and distributed sparse assembly are not implemented in
this release.

## Numerical and memory contracts

- Non-finite inputs are reported as `NonFiniteInput`; non-finite computed
  outputs/intermediates are reported as `NonFiniteResult`.
- CG/PCG require finite non-negative tolerances and SPD-compatible operators.
  A non-positive `pᵀAp` is `NotPositiveDefinite`; breakdowns are explicit.
- Iteration limits are reported through `converged = false`, not silently
  treated as success.
- Matrix/vector/workspace spans must have the documented lengths and should
  not overlap unless explicitly supported. `axpy_f64` supports exact `x`/`y`
  aliasing; partial overlap is not supported.
- Solvers do not allocate their Krylov workspaces. The caller supplies and
  owns them, making memory use explicit and reusable.

## Example

See [`examples/sparse_pcg.fsht`](examples/sparse_pcg.fsht) for COO assembly,
CSR conversion and Jacobi-preconditioned CG.

## Build and test

```sh
penstock build .
penstock test tests/test_numerics.fsht -Isrc
```
