#!/bin/bash

cd "$(dirname "$0")"

source snippets/setup_instrumentation.sh

RUNMODE="${1}"
echo "RUNMODE ${RUNMODE}"

REVISION="$(git rev-parse --short HEAD)"
echo "REVISION ${REVISION}"

BATCH="date=2024-03-25+time=20-16-32+revision=9e45feb+uuid=bec266fa-7cf7-42a6-a6d9-e7dc0f4d7292"
echo "BATCH ${BATCH}"


STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=4+what=compute_phylometrics/"
echo "STAGE_PATH ${STAGE_PATH}"

BATCH_PATH="${STAGE_PATH}/batches/${BATCH}/"
echo "BATCH_PATH ${BATCH_PATH}"

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
all_phylogeny_files="$( \
  find "${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=1+what=descend_template_phylogenies/latest/"* -type f  -path "*a=collapsed-phylogeny+*" -name "*+ext=.csv.gz" \
) $( \
  find "${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=2+what=reconstruct_phylogenies/latest/"* -type f  -path "*a=reconstructed-tree+*" -name "*+ext=.csv.gz" \
)"

num_phylogeny_files="$(echo ${all_phylogeny_files} | wc -w)"
echo "num_phylogeny_files ${num_phylogeny_files}"

waitforjobs() {
    while test $(jobs -p | wc -w) -ge "$1"; do echo "x"; sleep 1; done
}

process_file() {
  local target_phylogeny_file="$1"
  local BATCH_PATH="$2"

  python3 - << PYSCRIPT_EOF
import logging
from keyname import keyname as kn

phylometrics_filename = kn.pack({
  **kn.unpack(kn.rejoin("${target_phylogeny_file}")),
  **{
    "a" : "phylometrics",
    "a_" : kn.unpack(kn.rejoin("${target_phylogeny_file}"))["a"],
    "ext" : ".csv",
  },
})
phylometrics_path = kn.chop(
  "${BATCH_PATH}/"
  f"{phylometrics_filename}",
  mkdir=True,
  logger=logging,
)
print(phylometrics_path)
PYSCRIPT_EOF
}

test_file() {
  local target_phylogeny_file="$1"
  local BATCH_PATH="$2"

  if ! [ -f "$(process_file "${target_phylogeny_file}" "${BATCH_PATH}")" ]; then
    echo "hit!! ${target_phylogeny_file}"
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
target_phylogeny_files: ${target_phylogeny_file}
J2_HEREDOC_EOF
  sbatch "${SBATCH_SCRIPT_PATH}"
  else
    printf "."
  fi

}

# second sed strips leftover empty line at end
echo ${all_phylogeny_files} \
| tr '\n' ' ' \
| xargs -n 100  \
| while read target_phylogeny_files \
; do
  for target_phylogeny_file in ${target_phylogeny_files}; do
    test_file "${target_phylogeny_file}" "${BATCH_PATH}"
  done &
  waitforjobs 50
done

echo "$(ls -1 "${SBATCH_SCRIPT_DIRECTORY_PATH}" | wc -l) slurm scripts created"
