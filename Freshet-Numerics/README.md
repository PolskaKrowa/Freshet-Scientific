# Freshet-Numerics

The numerical foundation for arithmetic-heavy Freshet programs. The initial
API focuses on contiguous `f64` buffers, row-major dense operations and a
workspace-based conjugate-gradient solver.

## Public module

```freshet
import freshet_numerics;
```

### Functions

| Function | Contract |
|---|---|
| `dot_f64(a, b)` | Deterministic dot product; rejects mismatched lengths |
| `norm2_f64(a)` | Euclidean 2-norm |
| `axpy_f64(alpha, x, y)` | `y[i] = alpha*x[i] + y[i]` |
| `matvec_f64(n, A, x, y)` | Row-major square matrix-vector product |
| `matmul_f64(m, k, n, A, B, C)` | Row-major dense matrix product `C = A*B` |
| `conjugate_gradient_f64(...)` | Solve `A*x=b` for symmetric positive-definite `A` |

The `Span<f64>` arguments are views. Inputs must remain alive for the duration
of each call. Output spans must have the required capacity. `axpy_f64` permits
exact `x`/`y` aliasing; partial overlap is not supported. Matrix outputs must
not overlap their inputs. Conjugate gradient requires three `n`-element
workspace spans (`residual`, `direction`, `product`) in addition to `x`; `x` and all three workspaces must be pairwise disjoint and must not overlap
`A` or `b` (the read-only `A` and `b` inputs may overlap). All solver inputs
must be finite, and `A` must be symmetric positive-definite.

### Example

```freshet
import freshet_numerics;

fn main() {
    let a: [f64; 3] = [1.0, 2.0, 3.0];
    let b: [f64; 3] = [4.0, 5.0, 6.0];
    let result: Result<f64, NumericsError> =
        freshet_numerics::dot_f64(span(a), span(b));
    match (result) {
        Ok(value) => { print_f64(value, 1); println(); }
        Err(error) => { print("invalid vector dimensions"); println(); }
    }
}
```

## Numerical notes

- Dot products use `@reproducible` reductions for bitwise thread-count
  independence on the same binary.
- `matvec_f64` and `matmul_f64` partition output rows/elements so parallel
  workers write disjoint locations.
- Conjugate gradient assumes a symmetric positive-definite matrix. A
  non-positive `pᵀAp` is reported as `NotPositiveDefinite`. Reaching the
  iteration limit returns a report with `converged = false`.
- No sparse matrices, preconditioners, BLAS ABI or GPU backend are included yet.

## Build and test

```sh
penstock build .
penstock test tests/test_numerics.fsht -Isrc
```
