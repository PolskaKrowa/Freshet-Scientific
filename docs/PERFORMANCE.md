# Performance policy

The project is designed for performance, but it does not label code “highly
optimised” merely because it uses `parfor` or is compiled at `-O3`.

## Kernel rules

- Use contiguous `Span<T>` inputs and outputs in hot paths.
- Keep allocation, file I/O and container growth outside parallel regions.
- Give each parallel iteration a unique output location.
- Prefer row-major layouts for the initial dense matrix kernels.
- Keep workspaces caller-owned and reusable.
- Use `@reproducible` for reductions whose result must not depend on worker
  count; measure the throughput cost against the non-reproducible variant
  before adding an alternative.
- Do not enable `@fastmath` by default. Any relaxed-FP path must have an
  explicit API or function annotation, a stated error tolerance and a test.

## Benchmark requirements

A performance change should include:

1. A correctness test against a simple reference implementation.
2. A benchmark with input sizes large enough to leave timer and dispatch
   overhead behind.
3. Compiler version, standard version, CPU model, core count, thread settings,
   optimisation flags and input dimensions.
4. Warm-up and repeated measurements, reporting median and spread rather than
   the single best run.
5. A checksum or residual check so faster wrong answers are rejected.

This release establishes representative correctness workloads across all four
sub-libraries, but does not yet publish performance benchmark results. The
performance harness and measurement baselines are scheduled for the next
release; no throughput or scaling claim is made by this release.
