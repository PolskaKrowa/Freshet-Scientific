# Freshet-Data

Bounded-memory data-processing primitives for large Freshet workloads.

## Public module

```freshet
import freshet_data;
```

### Initial capabilities

- `validate_column_f64` checks a contiguous column span.
- `statistics_f64` computes count, mean, population variance, minimum and
  maximum using deterministic parallel reductions. Column inputs must contain finite values.
- `affine_transform_f64` and `copy_f64` process contiguous spans in parallel.
- `chunk_count`, `chunk_offset` and `chunk_length` provide overflow-checked
  planning for fixed-size out-of-core blocks.
- `scan_f64_lines` streams a text file containing one floating-point value per
  line. Invalid, NaN and infinite records are rejected. It keeps only the current line and Welford accumulator in memory.

## Large-data usage model

For enormous datasets, the preferred architecture is:

1. Open a buffered reader or storage adapter.
2. Reuse a fixed-size caller-owned buffer.
3. Read one block at a time.
4. Decode/validate the block into contiguous typed spans.
5. Run `freshet_data` kernels over those spans.
6. Write the result and reuse the workspace for the next block.

The library's chunk helpers are intentionally storage-agnostic. A future
release will add binary/columnar decoders and compression adapters. The
one-value-per-line reader is a reference ingest path, not a binary throughput
claim.

## Build and test

```sh
penstock build .
penstock test tests/test_data.fsht -Isrc
```


### Streaming module resolution

`src/io.fsht` is a vendored copy of Penstock's Apache-2.0 fsht-03:01 `io`
module. This keeps `penstock build` self-contained when a Penstock installation
does not include `share/penstock/modules/io.fsht`. The `Reader`, `Writer` and
`IoError` types and their runtime ABI remain those defined by Penstock. See
`../THIRD_PARTY_NOTICES.md`.
