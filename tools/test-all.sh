#!/usr/bin/env sh
set -eu

PENSTOCK_BIN="${PENSTOCK:-penstock}"
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

run_test() {
  name="$1"
  project="$2"
  source="$3"
  printf '\n== %s ==\n' "$name"
  (cd "$ROOT/$project" && "$PENSTOCK_BIN" test "$ROOT/$project/$source" "-I$ROOT/$project/src")
}

run_test "Freshet-Numerics" "Freshet-Numerics" "tests/test_numerics.fsht"
run_test "Freshet-Fluid" "Freshet-Fluid" "tests/test_fluid.fsht"
run_test "Freshet-Data" "Freshet-Data" "tests/test_data.fsht"
