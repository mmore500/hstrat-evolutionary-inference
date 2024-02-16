#!/bin/bash

set -e
set -u

cd "$(dirname "$0")"

source ./IMAGE_URI.sh

echo "Running Avida with treatment ${TREATMENT} and seed ${RNG_SEED}"

WORK_DIR=data/treatment=${TREATMENT}+seed=${RNG_SEED}
echo "WORK_DIR ${WORK_DIR}"
mkdir -p "${WORK_DIR}" || :

cd "${WORK_DIR}"
rm -rf *
cp -r ../../configs-common configs-common
cp -r ../../configs-treatment configs-treatment

export SINGULARITYENV_RNG_SEED="${RNG_SEED}"
export SINGULARITYENV_TREATMENT="${TREATMENT}"

singularity exec --cleanenv "${IMAGE_URI}" find .
singularity run --cleanenv "${IMAGE_URI}" -c "configs-treatment/${TREATMENT}.cfg" -s "${RNG_SEED}"
