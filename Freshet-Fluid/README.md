# Freshet-Fluid

A Freshet-native foundation for structured-grid incompressible CFD. The
current projection is a uniform Cartesian 2D MAC-grid method: pressure is
cell-centred, horizontal velocity is stored on vertical faces, and vertical
velocity is stored on horizontal faces.

## Public module

```freshet
import freshet_fluid;
```

## Discrete operators and projection

- `mac_divergence_2d` computes cell divergence from face velocities.
- `mac_gradient_periodic_2d` computes face pressure gradients.
- `mac_laplacian_periodic_2d` is the corresponding periodic composition
  `D(G(p))`.
- `project_incompressible_mac_2d` solves the pressure Poisson equation using
  the same face-gradient and cell-divergence convention used by the velocity
  correction, with a weighted (under-relaxed) Jacobi sweep (omega = 0.8): the
  plain iteration's odd-even mode is an undamped eigenvalue -1 mode on
  periodic and homogeneous-Neumann grids, which would stall the residual for
  general velocity fields. It reports the pressure-equation residual and
  maximum initial and final divergence separately; the residual merge and
  the norm helpers are serial deterministic maxima (see the Freshet-Numerics
  README's floating-point min/max reduction note).
- `mac_pressure_operator_apply_2d` exposes the pressure operator itself
  (`A*p = neighbour_sum - diagonal*p + source`, the negative discrete
  Laplacian) and `mac_pressure_diagonal_2d` its diagonal; these are the
  shared kernels of the residual reports, the multigrid sweeps and the
  conjugate-gradient projections.
- `project_incompressible_mac_multigrid_2d` solves the same pressure Poisson
  equation with geometric multigrid: a cell-centred 2:1 hierarchy whose
  transfer pair is the boundary-blind piecewise-constant prolongation P and
  the block-average restriction R = Pᵀ/4 (for which the rediscretised 2h
  operator satisfies R·A·P = 2·A₂h exactly, including boundary rows). Each
  V-cycle pre-smooths, restricts the defect, solves the coarse levels by
  heavier smoothing, prolongates the coarse correction in parallel and
  post-smooths; `mac_multigrid_level_count_2d` and
  `mac_multigrid_workspace_requirement_2d` report the hierarchy depth and
  workspace length, `mac_pressure_v_cycle_2d` is the reusable cycle and
  `mac_restrict_full_weighting_2d`/`mac_prolongate_constant_2d` are the
  standalone transfer kernels (the adjoint identity ⟨P e, r⟩ = 4⟨e, R r⟩
  is regression-tested).
- `project_incompressible_mac_pcg_2d` solves the pressure Poisson equation
  with preconditioned conjugate gradient on L = -A (which is symmetric
  positive definite whenever the boundary set contains a pressure
  Dirichlet/outflow side; otherwise `InvalidBoundarySet` is reported and the
  Jacobi or multigrid projections should be used, as their iteration does
  not require definiteness). `PressureJacobi` preconditions with the pressure
  diagonal and `PressureMultigrid` with one V-cycle per application
  (multigrid as a preconditioner for CG). The convergence test uses the
  Euclidean residual norm; the report's `pressure_residual` is the same
  A-form max-norm the other projections report. Parallel coarse-grid
  correction: restriction and prolongation are `parfor` kernels whose
  iterations write distinct cells and read only the other level's values.
- `mac_apply_velocity_boundaries_2d` supports explicit `Dirichlet`, `Neumann`,
  `Periodic`, `Wall`, `Inflow` and `Outflow` kinds. The descriptor separates
  normal/tangential velocity data from pressure value/gradient data.
- `mac_momentum_predictor_2d` and `cavity_step_2d` provide an explicit 2D
  first-order upwind momentum predictor followed by projection.

The tests include the discrete manufactured identity `D(G(p)) = L(p)`, a
manufactured pressure-recovery projection, projection of a non-trivial
periodic velocity field and a lid-driven cavity step. A further manufactured one-dimensional
Dirichlet-pressure test checks recovery against a known pressure field, while
the non-trivial periodic test checks divergence reduction from an initially
non-zero velocity field. The multigrid tests add the transfer-adjoint
identity, Dirichlet/periodic manufactured-pressure recovery through the
multigrid projection, a wall-bounded divergence-reduction case, and a
same-problem comparison in which the multigrid-preconditioned CG needs fewer
iterations than the Jacobi-preconditioned CG. The examples
[`examples/lid_driven_cavity.fsht`](examples/lid_driven_cavity.fsht) and
[`examples/multigrid_projection.fsht`](examples/multigrid_projection.fsht)
advance a 32×32, Reynolds-number-100 transient cavity for 500 explicit steps
and project a wall-bounded flow with the multigrid solver, respectively. The
cavity run is a repeatable demonstration/benchmark input, not yet a verified
Ghia steady-state benchmark: no external reference curve or quantitative Ghia
acceptance tolerance is bundled.

## Transport and time integration

The scalar transport functions include first-order upwind transport, a
periodic conservative shared-face flux form, and Heun RK2 wrappers. The
periodic flux form makes the domain-summed flux telescope, subject to floating
point round-off. The non-periodic `transport_scalar_upwind_2d` path currently
uses fixed boundary cells with zero normal advective and diffusive flux at
their interfaces; its regression test checks total scalar-mass conservation.
This is a closed-domain baseline rather than a general prescribed-inflow scalar
boundary implementation. Timestep helpers include advection and
explicit-diffusion rate contributions; callers remain responsible for choosing
a physically appropriate stable step.

## Boundary conventions and limitations

Pressure boundary handling in the 2D projection currently uses prescribed
pressure values for `Dirichlet`/`Outflow`, prescribed outward pressure
gradients for `Neumann`/`Inflow`, homogeneous normal pressure gradient for
`Wall`, and wraparound for `Periodic`. Velocity handling sets wall-normal
velocity to zero, supports prescribed normal velocity for `Dirichlet` and
`Inflow`, extrapolates `Neumann`/`Outflow`, and matches periodic face values.
Wall tangential velocity supports a moving lid. These are explicit baseline
conventions, not an all-purpose boundary-condition library; validate them for
the governing equations and geometry in use.

The projection and momentum predictor are 2D, constant-density and uniform
Cartesian. The multigrid hierarchy coarsens by exactly 2:1 in both
dimensions, so every level keeps at least three cells per dimension: grids
whose dimensions are not both even stop at a single level (plain smoothing),
and level/sweep/relaxation parameters are validated (`InvalidGrid`/
`InvalidRelaxation`). 3D MAC face counts and divergence are available, but 3D
pressure projection/time integration is not. Turbulence, compressible flow,
heat and species transport, variable-density flow, non-orthogonal grids,
adaptive mesh refinement and GPU execution are not implemented.

## Build and test

```sh
penstock build .
penstock test tests/test_fluid.fsht -Isrc
```
