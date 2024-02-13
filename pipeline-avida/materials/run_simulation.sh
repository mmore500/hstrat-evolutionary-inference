#!/bin/bash

set -e

cd "$(dirname "$0")"


echo "Running Avida with treatment ${TREATMENT} and seed ${RNG_SEED}"

WORK_DIR=data/treatment=${TREATMENT}+seed=${SEED}
echo "WORK_DIR ${WORK_DIR}"
mkdir -p "${WORK_DIR}" || :

cd "${WORK_DIR}"
rm -rf *
ln -s ../../configs-common configs-common
ln -s ../../configs-treatment configs-treatment

singularity run docker://ghcr.io/emilydolson/avida-empirical@sha256:9d4d03034e3e6a573e316d2fcbc338f3d656c4c54bda6cc9a51c412487a8918f -c configs-treatment/"${TREATMENT}.cfg" -s "${RNG_SEED}"
