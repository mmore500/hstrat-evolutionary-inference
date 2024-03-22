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

# use collapsed phylogenies instead of reconstructed phylogenies
# 'find "${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=0+what=generate_template_phylogenies/latest/epoch=0000"{0,2,7}/treatment=*/ -type f  -path "*a=perfect-phylogeny+*" -name "*+ext=.csv.gz"' \
all_phylogeny_files="$( \
  find "${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=1+what=descend_template_phylogenies/latest/"* -type f  -path "*a=collapsed-phylogeny+*" -name "*+ext=.csv.gz" \
) $( \
  find "${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=2+what=reconstruct_phylogenies/latest/"* -type f  -path "*a=reconstructed-tree+*" -name "*+ext=.csv.gz" \
) $( \
  find "${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=3+what=consolidate_template_phylogenies/latest/"* -type f  -path "*a=consolidated-phylogeny+*" -name "*+ext=.csv.gz" \
)"

num_phylogeny_files="$(echo ${all_phylogeny_files} | wc -w)"
echo "num_phylogeny_files ${num_phylogeny_files}"

num_batches="$(((${num_phylogeny_files} + 249) / 250))"
echo "num_batches ${num_batches}"

# second sed strips leftover empty line at end
echo ${all_phylogeny_files} \
| tr '\n' ' ' \
| sed -E 's/(\S+\s+){1,250}/&\n/g' \
| sed '/^$/d'  \
| while read target_phylogeny_files \
; do
  SBATCH_SCRIPT_PATH="${SBATCH_SCRIPT_DIRECTORY_PATH}/$(uuidgen).slurm.sh"
  echo "SBATCH_SCRIPT_PATH ${SBATCH_SCRIPT_PATH}"
  j2 --format=yaml -o "${SBATCH_SCRIPT_PATH}" "stage=4+what=compute_phylometrics/compute_phylometrics.slurm.sh.jinja" << J2_HEREDOC_EOF
batch: ${BATCH}
revision: ${REVISION}
runmode: ${RUNMODE}
setup_instrumentation: |
${SETUP_INSTRUMENTATION_SNIPPET}
setup_production_dependencies: |
${SETUP_PRODUCTION_DEPENDENCIES_SNIPPET}
target_phylogeny_files: ${target_phylogeny_files}
J2_HEREDOC_EOF
chmod +x "${SBATCH_SCRIPT_PATH}"
done \
  | tqdm \
    --desc "instantiate slurm scripts" \
    --total "${num_batches}"

echo "$(ls -1 "${SBATCH_SCRIPT_DIRECTORY_PATH}" | wc -l) slurm scripts created"
find "${SBATCH_SCRIPT_DIRECTORY_PATH}" -type f | python3 -m qspool
