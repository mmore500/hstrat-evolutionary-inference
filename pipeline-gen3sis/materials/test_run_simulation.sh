#!/bin/bash

cd "$(dirname "$0")" || exit 1

for TREATMENT in \
    "ecology" \
    "plain" \
    "spatial_ecology" \
    "spatial_plain" \
; do
for RNG_SEED in 1; do
export TREATMENT=${TREATMENT}
export RNG_SEED=${RNG_SEED}

timeout 3s ./run_simulation.sh &> /dev/null
status="$?"
if (( status == 124 )); then
    echo "TREATMENT=${TREATMENT} RNG_SEED=${RNG_SEED} OK"
else
    echo "TREATMENT=${TREATMENT} RNG_SEED=${RNG_SEED} FAIL"
    exit 1
fi
done
done
