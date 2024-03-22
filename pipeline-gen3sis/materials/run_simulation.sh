#!/bin/bash

set -e
set -u

cd "$(dirname "$0")"

source ./IMAGE_URI.sh
./ensure_assets.sh

if [ ! -d "landscapes" ]; then
    echo "[INFO] landscapes directory not found, creating it"
    echo "[INFO] this may take a minute!"
   ./make_landscapes.sh
fi

echo "RNG_SEED ${RNG_SEED}"
echo "TREATMENT ${TREATMENT}"

export SINGULARITYENV_RNG_SEED="${RNG_SEED}"
export SINGULARITYENV_TREATMENT="${TREATMENT}"

singularity run --cleanenv "${IMAGE_URI}" Rscript run_simulation.R

singularity run --cleanenv "${IMAGE_URI}" alifedata-phyloinformatics-convert toalifedata \
    --input-file "data/treatment=${TREATMENT}+seed=${RNG_SEED}/${TREATMENT}/phy.nex" \
    --input-schema nexus \
    --output-file "data/treatment=${TREATMENT}+seed=${RNG_SEED}/${TREATMENT}/phy.csv"
