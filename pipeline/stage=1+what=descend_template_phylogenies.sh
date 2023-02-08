#!/bin/bash

cd "$(dirname "$0")"

source snippets/setup_instrumentation.sh

RUNMODE="${1}"
echo "RUNMODE ${RUNMODE}"

REVISION="$(git rev-parse --short HEAD)"
echo "REVISION ${REVISION}"

BATCH="date=$(date +%Y-%m-%d)+time=$(date +%H-%M-%S)+revision=${REVISION}+uuid=$(uuidgen)"
echo "BATCH ${BATCH}"

source snippets/setup_production_dependencies.sh

SETUP_INSTRUMENTATION_SNIPPET="$(
  cat snippets/setup_instrumentation.sh | sed 's/^/  /'
)"
SETUP_PRODUCTION_DEPENDENCIES_SNIPPET="$(
  cat snippets/setup_production_dependencies.sh | sed 's/^/  /'
)"

SBATCH_SCRIPT_DIRECTORY_PATH="$(mktemp -d)"
echo "SBATCH_SCRIPT_DIRECTORY_PATH ${SBATCH_SCRIPT_DIRECTORY_PATH}"

NUM_TREATMENTS="$(python3 -c "from pylib import specify_template_phylogeny_generation_replicates; print(len(specify_template_phylogeny_generation_replicates()['treatment'].unique()))")"
echo "NUM_TREATMENTS ${NUM_TREATMENTS}"

# adapted from https://superuser.com/a/284226
for ((target_treatment=0; target_treatment < NUM_TREATMENTS; ++target_treatment)); do
# excluding '${MAX_COMMON_EPOCH}'
for target_epoch in "epoch=00000" "epoch=00002" "epoch=00007"; do
for recency_proportional_resolution in 3 10 30 100; do
SBATCH_SCRIPT_PATH="${SBATCH_SCRIPT_DIRECTORY_PATH}/$(uuidgen).slurm.sh"
echo "recency_proportional_resolution ${recency_proportional_resolution}"
echo "target_treatment ${target_treatment}"
echo "target_epoch ${target_epoch}"
echo "SBATCH_SCRIPT_PATH ${SBATCH_SCRIPT_PATH}"
j2 --format=yaml -o "${SBATCH_SCRIPT_PATH}" "stage=1+what=descend_template_phylogenies/descend_template_phylogeny.slurm.sh.jinja" << J2_HEREDOC_EOF
batch: ${BATCH}
recency_proportional_resolution: ${recency_proportional_resolution}
revision: ${REVISION}
runmode: ${RUNMODE}
setup_instrumentation: |
${SETUP_INSTRUMENTATION_SNIPPET}
setup_production_dependencies: |
${SETUP_PRODUCTION_DEPENDENCIES_SNIPPET}
target_epoch: ${target_epoch}
target_treatment: ${target_treatment}
J2_HEREDOC_EOF
chmod +x "${SBATCH_SCRIPT_PATH}"
done
done
done

find "${SBATCH_SCRIPT_DIRECTORY_PATH}" -type f | python3 -m qspool
