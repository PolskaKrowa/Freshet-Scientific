# Freshet-Scientific

**Scientific and high-performance computing libraries for the Freshet language.**

Freshet-Scientific is the Layer 2 scientific software ecosystem described by the
[Freshet language standard](https://github.com/PolskaKrowa/Freshet-lang). It is
kept separate from the language and Penstock compiler: numerical algorithms,
physics models and data-processing facilities belong here and must not require
compiler changes.

The initial distribution contains three independently buildable sub-libraries:

| Sub-library | Purpose | Initial implementation |
|---|---|---|
| **Freshet-Numerics** | Arithmetic-heavy kernels, dense linear algebra and iterative solvers | Contiguous `Span<f64>` kernels, deterministic reductions, matrix-vector/matrix-matrix products and conjugate gradient |
| **Freshet-Fluid** | Parallel computational fluid dynamics | 2D structured-grid operators, explicit passive-scalar transport, timestep estimation and a constant-density pressure-projection step |
| **Freshet-Data** | High-throughput processing of large datasets | Zero-copy span operations, parallel statistics, bounded chunk planning and a streaming one-value-per-line reader |

This is a deliberately small **0.1.3 foundation**, not a claim that the three
libraries are already production-complete. In particular, the initial fluid
solver is a structured-grid research baseline, not a complete turbulence,
compressible-flow, multiphase or adaptive-mesh package. The data library supplies
bounded-memory primitives rather than a database or a distributed storage engine.

## Design principles

1. **Freshet first.** Public algorithms are implemented in `.fsht` and use the
   language's types, ownership model, modules and `parfor` execution model.
2. **No compiler fork.** The code targets the ratified `fsht-03:03` standard and
   the Penstock reference compiler. It does not add compiler intrinsics or alter
   Freshet-lang.
3. **Contiguous memory.** Hot kernels accept `Span<T>` and make data layout and
   aliasing visible. Callers own storage and can reuse workspaces across calls.
4. **Parallel writes are disjoint.** Parallel kernels write distinct output
   indices. Reductions use `@reproducible` where repeatable floating-point
   results matter.
5. **Strict floating point by default.** The standard's strict IEEE-style
   semantics remain the default. Any future fast-math kernels must be opt-in,
   benchmarked and documented with their numerical trade-offs.
6. **Bounded memory.** Large-data APIs process caller-selected chunks or stream
   records instead of materialising an entire input file in memory.
7. **Measure before tuning.** Optimisation claims require correctness checks,
   representative benchmarks and recorded target/toolchain details.

## Requirements

- Penstock **0.1.0-INDEV** or a later compiler implementing `fsht-03:03`.
- CMake 3.16 or later (optional; the compiler's project manifests work without
  CMake).
- A supported Penstock/LLVM toolchain. Consult the Penstock installation guide
  for the current backend requirements.

## Build

Build each sub-library directly with Penstock:

```sh
penstock build Freshet-Numerics
penstock build Freshet-Fluid
penstock build Freshet-Data
```

Each directory contains a `penstock.toml` static-library project manifest. The
resulting archives are written beside their manifests. The source modules are
also suitable for direct inclusion in a Freshet program using `import` and
`-I` module search paths; see the examples below. Freshet-Data carries the
Penstock `io` module in its source directory, so that adapter does not depend
on a separately installed `share/penstock/modules/io.fsht` file. Its provenance
and licence are recorded in `THIRD_PARTY_NOTICES.md`.

Or use the top-level CMake convenience targets:

```sh
cmake -S . -B build
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

CMake invokes the installed `penstock` executable; it does not bootstrap or
modify Penstock itself. Set `PENSTOCK_EXECUTABLE` when the compiler is not on
`PATH`:

```sh
cmake -S . -B build -DPENSTOCK_EXECUTABLE=/opt/penstock/bin/penstock
```

Run the test suites without CMake:

```sh
PENSTOCK=penstock ./tools/test-all.sh
```

## Use a sub-library from Freshet

The source modules are the primary language-level interface. For example:

```freshet
import freshet_numerics;

fn main() {
    let a: [f64; 4] = [1.0, 2.0, 3.0, 4.0];
    let b: [f64; 4] = [4.0, 3.0, 2.0, 1.0];
    let result: Result<f64, NumericsError> =
        freshet_numerics::dot_f64(span(a), span(b));
    match (result) {
        Ok(value) => { print_f64(value, 1); println(); }
        Err(error) => { print("dimension mismatch"); println(); }
    }
}
```

Compile with the relevant source directory on the module path, for example:

```sh
penstock -I./Freshet-Numerics/src app.fsht -o app
```

See each sub-library's README and `examples/` directory for more complete
usage. The initial APIs deliberately use caller-owned `Span<T>` buffers for
hot kernels. This avoids hidden allocation in parallel regions and lets an
application select its own allocator and memory lifetime.

## Current scope and limitations

- Numerical kernels currently specialise on `f64`; generic scalar and mixed
  precision APIs are future work.
- Dense matrix operations use row-major storage. Sparse, banded, distributed
  and GPU backends are not yet implemented.
- The conjugate-gradient solver assumes a symmetric positive-definite operator.
  It reports breakdown/non-convergence rather than silently claiming success.
- Fluid routines use a 2D uniform Cartesian grid and constant density. Boundary
  treatment is intentionally simple and must be validated for each application.
- `Freshet-Data::scan_f64_lines` is a convenient text ingest path (one floating
  point value per line), not the high-throughput binary ingestion path. The
  core chunk/span APIs are the intended basis for efficient binary and
  columnar readers.
- The project has not yet been benchmarked end-to-end on the target compiler in
  this environment. No throughput or scalability figures are claimed.

## Repository layout

```text
Freshet-Scientific/
├── Freshet-Numerics/   # dense numerical kernels and iterative methods
├── Freshet-Fluid/      # structured-grid CFD foundations
├── Freshet-Data/       # streaming, chunking and dataset kernels
├── docs/               # architecture, performance policy and roadmap
├── tools/              # test helpers
├── CMakeLists.txt
├── THIRD_PARTY_NOTICES.md
└── README.md
```

## Relationship to the upstream projects

- [Freshet-lang](https://github.com/PolskaKrowa/Freshet-lang) defines the
  language and standard-library contract (`fsht-03:03`).
- [Penstock](https://github.com/PolskaKrowa/Penstock) is the reference compiler.
- This repository implements the separate Layer 2 scientific-library layer;
  it should be consumable by any conforming Freshet compiler.

## Licence

Apache-2.0. See [`LICENSE`](LICENSE).
