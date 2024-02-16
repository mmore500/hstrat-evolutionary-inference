#!/bin/bash

set -u

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

# pull singularity image
singularity exec docker://ghcr.io/mmore500/gen3sis@sha256:ec5c901d454e6cbee7e02f5675006ddd38c8c4c94a33027d963779216c9c7b80 true

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
