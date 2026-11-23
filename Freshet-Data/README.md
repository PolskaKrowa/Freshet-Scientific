# Freshet-Data

Bounded-memory, column-oriented data processing for large Freshet workloads.
The design favours caller-owned chunk buffers and composable numerical
accumulators over loading a whole dataset into memory.

## Public module

```freshet
import freshet_data;
```

## Statistics and transforms

- `statistics_f64` uses Welford's online update for count, mean, population
  variance, standard deviation, minimum and maximum.
- `statistics_merge_f64` combines non-empty chunk summaries using the Chan
  formula. Merge independent chunks in ascending chunk-index order when
  reproducible combination order matters.
- `CovarianceAccumulatorF64` supports online paired updates, Chan-style merge,
  and final population covariance, variances and correlation. The result marks
  correlation as undefined when either input variance is zero.
- `histogram_f64` tallies in-range values and values below/above a closed range.
- `affine_transform_f64` and `copy_f64` operate on caller-owned spans.
- The numerical entry points reject non-finite inputs and report non-finite
  intermediate/output values.

## Fixed-width binary I/O

`BinaryFile` reads and writes raw fixed-width blocks for `f64`, `f32`, `i64`
and `u64`. The caller chooses `Native`, `LittleEndian` or `BigEndian`. Writers
receive a caller-owned scratch span so byte swapping never mutates the input
buffer and no temporary allocation is required per call. Scratch and input
spans must not overlap. Reads return the
number of complete elements and report `TruncatedBlock` if the file ends in a
partial element. `binary_close` closes a handle **exactly once** — a
`borrowed mut` close cannot invalidate other copies of the handle struct
(fsht-03:02 aggregate borrows do not write back), so a second close of the
same handle is undefined. Pair every open with a single deferred close and
call `binary_flush` when data must be visible before the defer fires.

`process_binary_f64_chunks<T: BinaryChunkTransformF64>` provides a generic,
statically-dispatched bounded-memory reader → reusable input buffer →
decode/validate → parallel transform/numerical kernel → reusable output and
write-scratch buffers → writer path. A caller can implement the trait for a
custom chunk processor without a function-pointer dispatch or per-chunk
allocation. `AffineTransformF64` and `transform_binary_f64_file` provide the
built-in affine convenience path. Input and output paths must be distinct (the
pipeline rejects identical path strings).

## Columnar record batches

`ColumnSchema` describes one fixed-width column (`F64`, `F32`, `I64` or `U64`)
and its byte offset in a caller-owned payload. `RecordBatchView` validates
column bounds, alignment and non-overlap; typed accessors return borrowed,
zero-copy spans. The payload and schema spans must outlive every returned
column view. The byte payload must be backed by memory aligned for the widest
column type. Typed accessors reinterpret the payload's existing pointer using
pointer-to-pointer casts and return span slices; they do not copy or reconstruct
addresses through integer casts. The caller owns the payload and must keep it
alive and correctly aligned for the lifetime of every returned column view.

This is a columnar view/descriptor foundation, not yet an owning dataset
catalogue, compression layer or query planner.

## Text streaming

`scan_f64_lines` remains a reference/convenience adapter for one finite `f64`
per line. It uses Penstock's buffered `Reader`, updates Welford state online,
and closes the reader on EOF and every early error path. It currently creates
an owned `String` per line; use fixed-width binary blocks for throughput-
critical ingestion.

`src/io.fsht` is a vendored copy of Penstock's Apache-2.0 fsht-03:01 `io`
module so standalone project builds can resolve `import io;` when the compiler
installation does not ship its module directory. Its `Reader` and `IoError`
ABI is the Penstock standard-library ABI. See `../THIRD_PARTY_NOTICES.md`.

## Build and test

```sh
penstock build .
penstock test tests/test_data.fsht -Isrc
```
