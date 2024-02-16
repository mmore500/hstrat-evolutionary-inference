#!/bin/bash

set -e
set -u

cd "$(dirname "$0")"

source ./IMAGE_URI.sh
./ensure_assets.sh

if [ ! -d "landscapes" ]; then
    echo "landscapes directory not found, creating it"
    echo "this may take a minute!"
   ./make_landscapes.sh
fi

echo "RNG_SEED ${RNG_SEED}"
echo "TREATMENT ${TREATMENT}"

singularity run "${IMAGE_URI} Rscript run_simulation.R

singularity run "${IMAGE_URI} alifedata-phyloinformatics-convert toalifedata \
    --input-file "data/treatment=${TREATMENT}+seed=${RNG_SEED}/${TREATMENT}/phy.nex" \
    --input-schema nexus \
    --output-file "data/treatment=${TREATMENT}+seed=${RNG_SEED}/${TREATMENT}/phy.csv"
