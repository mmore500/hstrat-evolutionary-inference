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

PYSCRIPT=$(cat << 'HEREDOC'
from pylib import specify_template_phylogeny_generation_replicates

replicates_df = specify_template_phylogeny_generation_replicates()

for idx, row in replicates_df.iterrows():
  payload_dict = row.to_dict()
  payload_dict["index"] = idx
  payload_str = str(payload_dict).replace("\n", " ")
  print(payload_str)

HEREDOC
)

pwd

echo "$(python3 -c "${PYSCRIPT}")"

SETUP_INSTRUMENTATION_SNIPPET="$(
  cat snippets/setup_instrumentation.sh | sed 's/^/  /'
)"
SETUP_PRODUCTION_DEPENDENCIES_SNIPPET="$(
  cat snippets/setup_production_dependencies.sh | sed 's/^/  /'
)"

SBATCH_SCRIPT_DIRECTORY_PATH="$(mktemp -d)"
echo "SBATCH_SCRIPT_DIRECTORY_PATH ${SBATCH_SCRIPT_DIRECTORY_PATH}"

NUM_JOBS=$(python3 -c "${PYSCRIPT}" | wc -l)
echo "NUM_JOBS ${NUM_JOBS}"

# adapted from https://superuser.com/a/284226
while IFS= read -r PAYLOAD; do
  SBATCH_SCRIPT_PATH="${SBATCH_SCRIPT_DIRECTORY_PATH}/$(uuidgen).slurm.sh"
  echo "SBATCH_SCRIPT_PATH ${SBATCH_SCRIPT_PATH}"
  j2 --format=yaml -o "${SBATCH_SCRIPT_PATH}" "stage=0+what=generate_template_phylogenies/generate_template_phylogeny.slurm.sh.jinja" << J2_HEREDOC_EOF
batch: ${BATCH}
config_dict_str: |-
  ${PAYLOAD}
revision: ${REVISION}
runmode: ${RUNMODE}
setup_instrumentation: |
${SETUP_INSTRUMENTATION_SNIPPET}
setup_production_dependencies: |
${SETUP_PRODUCTION_DEPENDENCIES_SNIPPET}
J2_HEREDOC_EOF
chmod +x "${SBATCH_SCRIPT_PATH}"

done \
  <<< "$(python3 -c "${PYSCRIPT}")" \
  | tqdm \
    --desc "instantiate slurm scripts" \
    --total "${NUM_JOBS}"

find "${SBATCH_SCRIPT_DIRECTORY_PATH}" -type f | python3 -m qspool
