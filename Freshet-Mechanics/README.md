# Freshet-Mechanics

Engineering and structural-mechanics functionality, intentionally separate
from Freshet-Numerics. Mechanics depends on Numerics for its initial dense SPD
FEM solve; the other domains are engineering-domain APIs.

## Public modules

The build/metadata entry module is `freshet_mechanics` (currently exports
`version()`). Import the focused public API modules explicitly; Freshet module
imports are not transitive re-exports:

```freshet
import mechanics_common;
import units;
import vectors;
import materials;
import statics;
import beams;
import trusses;
import stress;
import fem;
import structural; // sparse global structural analysis
import freshet_numerics; // FEM report/error types and solver API
```

The public modules are `mechanics_common`, `units`, `vectors`, `materials`,
`statics`, `beams`, `trusses`, `stress`, `fem` and `structural`.

Mechanics error variants use the `Mechanics` prefix (for example,
`Err(MechanicsDimensionMismatch)`) so they remain distinct from
the concise `NumericsError` variants. Numerics error construction and
pattern matching use the normal context-resolved variant names (for
example, `Err(NonFiniteResult)`). This allows both APIs to be imported
in one compilation unit without ambiguous variant lookup.

## Initial functionality

- **Units:** `QuantitySI` stores a value and integer exponents for all seven
  SI base dimensions: length, mass, time, electric current, thermodynamic
  temperature, amount of substance and luminous intensity. Addition and
  subtraction require exact dimensional agreement; multiplication/division
  combine exponents with checked integer arithmetic.
- **Vectors:** 2D/3D vector values, dot/cross products, scaled norms and
  normalisation with zero-vector rejection.
- **Materials:** validated isotropic material properties and derived shear
  and bulk moduli.
- **Statics:** force resultants and moments.
- **Beams:** Euler–Bernoulli reference formulae for a simply supported beam
  under uniform load and a cantilever under an end load.
- **Trusses:** linear two-node 2D/3D truss element stiffness matrices and 2D
  axial-force recovery.
- **Stress:** plane-stress and 3D von Mises invariants, 2D principal stresses
  and plane-stress elastic strain conversion.
- **FEM:** dense 1D axial-bar stiffness assembly, symmetric Dirichlet
  elimination and a conjugate-gradient solve for the resulting SPD system.
- **Structural (sparse global analysis):** `assemble_global_truss_2d`/`_3d`
  assemble complete truss models into global COO triplets over the
  displacement degrees of freedom (16/36 entries per element, duplicates
  legal); conversion through `coo_to_csr_f64` yields the sparse system.
  `apply_sparse_dirichlet_constraints_f64` performs the symmetric sparse
  Dirichlet elimination (prescribed values move to the right-hand side,
  constrained rows become identity equations through their existing
  diagonals; rows without stiffness report `SingularSystem`),
  `solve_sparse_system_pcg_f64` solves with Jacobi-preconditioned CG,
  `support_reactions_f64` computes reactions = K·u − f at constrained
  degrees of freedom, `element_axial_results_2d`/`_3d` provide element
  post-processing (axial force with tension positive, stress, strain and
  length) and `equilibrium_check_2d`/`_3d` report the free-dof residual
  norms together with the load-plus-reaction component sums and a scaled
  overall verdict.

## Assumptions and limits

The initial material model is linear isotropic elasticity. Beam functions are
closed-form reference cases, not general beam elements. Truss stiffness is
small-strain linear two-node theory. The FEM module currently assembles 1D
axial bars into dense matrices; the sparse global path covers linear truss
models only (no beam/frame elements in the global assembly, no distributed
loads beyond nodal forces, and no geometric nonlinearity). Sparse rows keep
explicit zeros where Dirichlet elimination cleared entries; SpMV and the CSR
Jacobi preconditioner accumulate duplicates correctly, and
`csr_merge_duplicates_f64` canonicalises the structure when a single entry
per (row, column) is preferred.
Plasticity, nonlinear material models, buckling, fatigue, contact, geometric
nonlinearity, shell/solid elements and higher-order elements are not included.
All quantities are SI; the dimensional descriptor checks algebraic
consistency but does not attach units to every primitive `f64` in every API.

## Example

See [`examples/bar_and_beam.fsht`](examples/bar_and_beam.fsht) for the
beam/formula path and [`examples/global_truss.fsht`](examples/global_truss.fsht)
for the complete sparse pipeline (assembly, CSR conversion, constraints,
sparse PCG solve, reactions, element post-processing and equilibrium check)
on a determinate three-bar triangle.

## Build and test

```sh
penstock build .
penstock test tests/test_mechanics.fsht -Isrc -I../Freshet-Numerics/src
```
