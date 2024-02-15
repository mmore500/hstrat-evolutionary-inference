#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "be sure landscapes/ is available!"
echo "hint: run ./make_landscapes.sh"

echo "RNG_SEED ${RNG_SEED}"
echo "TREATMENT ${TREATMENT}"

git clone https://github.com/project-gen3sis/Simulations.git || :
(cd Simulations; git checkout 8ce6b88a6cd388f4cb4d963bb807ef91633385c6)

singularity run docker://ghcr.io/mmore500/gen3sis@sha256:ec5c901d454e6cbee7e02f5675006ddd38c8c4c94a33027d963779216c9c7b80 Rscript run_simulation.R

singularity run docker://ghcr.io/mmore500/gen3sis@sha256:ec5c901d454e6cbee7e02f5675006ddd38c8c4c94a33027d963779216c9c7b80 alifedata-phyloinformatics-convert toalifedata \
    --input-file "data/treatment=${TREATMENT}+seed=${RNG_SEED}/${TREATMENT}/phy.nex" \
    --input-schema nexus \
    --output-file "data/treatment=${TREATMENT}+seed=${RNG_SEED}/${TREATMENT}/phy.csv"
