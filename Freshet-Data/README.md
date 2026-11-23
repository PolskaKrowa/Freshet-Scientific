# Freshet-Data

Bounded-memory, column-oriented data processing for large Freshet workloads.
The design favours caller-owned chunk buffers and composable numerical
accumulators over loading a whole dataset into memory.

## Public modules

```freshet
import freshet_data;
import fdo_format; // FDO (Freshet-Data Optimised) file format
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
catalogue or query planner.

## FDO (Freshet-Data Optimised) file format

`fdo_format` writes and reads a self-describing, checksummed, optionally
compressed container for validated record-batch payloads:

- **Magic identifier and version:** the first four bytes are the literal
  `FDO1`; byte 4 is the format version (1). A foreign or truncated stream is
  rejected with `InvalidFormat` before anything else is trusted.
- **Byte order:** byte 5 is the file byte-order marker (`L` or `B`); every
  multi-byte field of the header, directory and payloads uses that order.
  Serialisation and assembly use division/modulo and multiplication only
  (no bit-shift or bitwise operators).
- **Dimensions:** the header stores the row and column counts; the
  directory stores each column's element count (equal to the row count in
  v1).
- **Column schema:** every 80-byte directory entry carries a NUL-padded
  printable-ASCII name (max 15 characters) and unit field, a data type code
  (`f64`, `f32`, `i64` or `u64`), the element count, the payload offset, the
  stored size, the compression flag and the payload checksum. Reading is
  strict: the caller declares the expected type, name and unit, and
  mismatches report `InvalidSchema` rather than coercing.
- **Offsets and sizes:** payload offsets are absolute from the file start,
  begin after the directory and are validated against it; stored sizes are
  bounded by the 16-per-row sanity limit.
- **Checksums:** the header carries an Adler-32 (`fdo_adler32`, exported)
  over its first 24 bytes and every payload carries one over its stored
  bytes; mismatches report `ChecksumMismatch`. Adler-32 detects every
  single-byte change; it is not a cryptographic digest.
- **Binary payloads:** each column's elements are stored in the file byte
  order; `fdo_read_column` returns host-order bytes sized for the record
  batch accessors, so round-tripped payloads re-enter the zero-copy views
  directly.
- **Optional compression:** `FdoRunLength` stores `(run count, element)`
  pairs per column (runs detected by exact element byte comparison); a
  column whose encoding would not shrink falls back to raw storage and the
  directory records the actual flag. `FdoRaw` stores plain elements.

`fdo_write` takes the caller payload plus three reusable u64 workspaces
`(sizes, checksums, compress_flags)` and one byte workspace of at least
`16 * row_count`; it returns the total file size. `fdo_open_read`/
`fdo_close` follow the exactly-once close contract of `BinaryFile`.
`fdo_read_column` seeks and checksums the stored payload before decoding
and `fdo_verify_file` validates the whole file without materialising a
payload. The format is a container: value-level finiteness is the caller's
job, exactly like record batches.

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

## Example

See [`examples/binary_transform.fsht`](examples/binary_transform.fsht) for
the reusable binary transform pipeline and
[`examples/fdo_roundtrip.fsht`](examples/fdo_roundtrip.fsht) for a complete
FDO write/verify/read round trip with compression.

## Build and test

`fdo_format.fsht` is a second compilation root of the static library (the
project's `penstock.toml` lists both `src/freshet_data.fsht` and
`src/fdo_format.fsht`), so the archive exports both modules without a
circular module import.

```sh
penstock build .
penstock test tests/test_data.fsht -Isrc
```
