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
  correction. It reports the pressure-equation residual and maximum initial
  and final divergence separately.
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
non-zero velocity field. The example
[`examples/lid_driven_cavity.fsht`](examples/lid_driven_cavity.fsht) advances a
32×32, Reynolds-number-100 transient cavity for 500 explicit steps and prints
divergence checkpoints plus the two centreline velocity profiles. It is a
repeatable demonstration/benchmark input, not yet a verified Ghia steady-state
benchmark: no external reference curve or quantitative Ghia acceptance
tolerance is bundled.

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
Cartesian. 3D MAC face counts and divergence are available, but 3D pressure
projection/time integration is not. Turbulence, compressible flow, heat and
species transport, variable-density flow, non-orthogonal grids, adaptive mesh
refinement and GPU execution are not implemented.

## Build and test

```sh
penstock build .
penstock test tests/test_fluid.fsht -Isrc
```
