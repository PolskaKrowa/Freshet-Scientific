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

## 0.3.0 additions

The 0.3.0 kernels follow the same rules; two additional notes:

- The multigrid transfer kernels (block-average restriction,
  piecewise-constant prolongation and the accumulated coarse-grid
  correction) are `parfor` kernels whose iterations write distinct cells and
  index only existing neighbours, so they perform no per-cell division or
  modulo (the F0402 pattern avoided since 0.1.2). The V-cycle itself walks
  levels with an explicit descent/ascent loop over the caller-owned level
  workspace; no level metadata is stored beyond sizes recoverable by exact
  doubling.
- The FDO writer intentionally encodes every run-length column twice (once
  to size and checksum the directory entry, once to emit the payload) rather
  than caching encoded bytes, keeping the encoding workspace at
  16 * row_count bytes instead of the total stored size. The FDO reader
  validates and checksums the stored payload before decoding. Neither path
  is performance-benchmarked yet; the correctness workloads above are the
  basis for future throughput claims.
