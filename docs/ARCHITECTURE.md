# Architecture

## Layer boundary

Freshet-Scientific is a consumer of the Freshet language, not an extension of
it. The Freshet-lang introduction (chapter 00) explicitly places scientific
libraries in Layer 2 and requires that they be expressible without compiler
changes. This project therefore avoids compiler intrinsics, language patches
and changes to the standard `fsh` modules.

## API shape

The first release uses one public Freshet module per sub-library:

- `freshet_numerics`
- `freshet_fluid`
- `freshet_data`

This is intentionally straightforward while the API is being established.
Private helpers remain ordinary private declarations. As the surface grows,
modules can be split by concern without changing the public module names.

## Memory and ownership

Computational kernels operate on `Span<T>` views. The caller owns the backing
array or `Vec<T>` and controls its lifetime. The library does not allocate
large temporary arrays in its inner loops. Solvers that need workspace accept
that workspace explicitly, making peak memory visible and allowing reuse.

The supported parallel pattern is the one prescribed by the Freshet standard:
read immutable input spans, partition independent output indices, and use an
explicit reduction for scalar accumulators. No vector is resized or appended
to inside a `parfor` region.

## Numerical behaviour

Strict floating-point semantics are retained by default. Reductions for which
thread-count-independent results matter use `@reproducible`. Algorithms state
their mathematical assumptions and report invalid dimensions, breakdown and
iteration limits through result types.

## Build model

Every sub-library is a standalone Penstock project with a `static-lib` target.
The source module remains the canonical Freshet interface. The generated
archive is a compiler build artefact; a stable C ABI and installable package
metadata are intentionally deferred until the exported ABI is frozen.
