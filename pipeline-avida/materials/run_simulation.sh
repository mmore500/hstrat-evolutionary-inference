#!/bin/bash

set -e
set -u

cd "$(dirname "$0")"


echo "Running Avida with treatment ${TREATMENT} and seed ${RNG_SEED}"

WORK_DIR=data/treatment=${TREATMENT}+seed=${RNG_SEED}
echo "WORK_DIR ${WORK_DIR}"
mkdir -p "${WORK_DIR}" || :

cd "${WORK_DIR}"
rm -rf *
ln -s ../../configs-common configs-common
ln -s ../../configs-treatment configs-treatment

singularity run docker://ghcr.io/emilydolson/avida-empirical@sha256:0b663e3531a1046329db0039369c65a72e8d2901ddd89ca951f933fd7464abd4 -c configs-treatment/"${TREATMENT}.cfg" -s "${RNG_SEED}"
