# Freshet-Fluid

A Freshet-native foundation for parallel computational fluid dynamics on
uniform 2D Cartesian grids.

## Initial capabilities

- Grid-size validation with overflow checking.
- Central-difference velocity divergence and scalar Laplacian operators.
- A conservative first-order upwind advection term plus explicit diffusion for
  a passive scalar.
- A CFL/diffusion-based timestep recommendation.
- A constant-density pressure Poisson solve using Jacobi iteration, followed
  by a velocity projection step.

## Public module

```freshet
import freshet_fluid;
```

The APIs take caller-owned `Span<f64>` fields. Fields are cell-centred and
stored row-major, with `index = j*nx + i`. All field spans must contain exactly
`nx*ny` values. The first and last rows/columns are treated as fixed boundary
cells by the initial operators.

### Pressure projection

`project_incompressible_2d` takes velocity, pressure, pressure-scratch and
divergence spans. The pressure solve uses Dirichlet-zero pressure values on the
outer boundary and Jacobi updates on interior cells. This is a simple baseline,
not a universal boundary-condition model. The report exposes iteration count,
maximum update and convergence status; callers must check `converged`.

### Passive scalar transport

`transport_scalar_upwind_2d` advances a cell-centred passive scalar using
first-order upwind face fluxes and an explicit Laplacian diffusion term. The
caller is responsible for choosing a timestep no larger than the result from
`stable_timestep_2d` (or another validated stability criterion).

## Important limitations

This is not yet a complete CFD application framework. It does not implement
compressible equations, energy/species coupling, turbulence closures, immersed
boundaries, mesh refinement, non-orthogonal meshes or GPU execution. The simple
boundary treatment must be checked against the physical problem before use.

## Build and test

```sh
penstock build .
penstock test tests/test_fluid.fsht -Isrc
```
