# Contributing

1. Keep the language/compiler dependency at the public `fsht-03:03` surface
   unless a later ratified standard is deliberately adopted.
2. Add tests with every algorithm or API change. Prefer small deterministic
   cases and include edge cases (empty input, mismatched dimensions, singular
   or non-convergent systems).
3. State assumptions: layout, units, boundary conditions, aliasing, convergence
   criteria and floating-point mode.
4. Do not allocate or resize containers inside `parfor` kernels.
5. Add a benchmark only with a correctness check and enough metadata to repeat
   the measurement.
6. Do not claim hardware acceleration, scalability or production readiness
   without measurements on the named hardware and compiler build.

Run `PENSTOCK=penstock ./tools/test-all.sh` before submitting a change.
