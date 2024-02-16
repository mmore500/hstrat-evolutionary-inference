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
ln -s ../../configs-common configs-common
ln -s ../../configs-treatment configs-treatment

singularity run "${IMAGE_URI}" -c "configs-treatment/${TREATMENT}.cfg" -s "${RNG_SEED}"
