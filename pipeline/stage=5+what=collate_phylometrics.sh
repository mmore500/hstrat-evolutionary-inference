#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
echo "SCRIPT_PATH ${SCRIPT_PATH}"

cd "$(dirname "$0")"

source snippets/setup_instrumentation.sh

RUNMODE="${1}"
echo "RUNMODE ${RUNMODE}"

REVISION="$(git rev-parse --short HEAD)"
echo "REVISION ${REVISION}"

BATCH="date=$(date +%Y-%m-%d)+time=$(date +%H-%M-%S)+revision=${REVISION}+uuid=$(uuidgen)"
echo "BATCH ${BATCH}"

source snippets/setup_production_dependencies.sh

PREV_STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=4+what=compute_phylometrics/"
echo "PREV_STAGE_PATH ${PREV_STAGE_PATH}"

STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=5+what=collate_phylometrics/"
echo "STAGE_PATH ${STAGE_PATH}"

BATCH_PATH="${STAGE_PATH}/batches/${BATCH}/"
echo "BATCH_PATH ${BATCH_PATH}"

for try in {0..9}; do
  mkdir -p "${BATCH_PATH}" && break
  echo "mkdir -p ${BATCH_PATH} failed (try ${try})"
  SLEEP_DURATION="$((RANDOM % 10 + 1))"
  echo "sleeping ${SLEEP_DURATION} then retrying"
  sleep "${SLEEP_DURATION}"
done

for try in {0..9}; do
  ln -srfT "${BATCH_PATH}" "${STAGE_PATH}/latest" && break
  echo "ln -srfT ${BATCH_PATH} ${STAGE_PATH}/latest failed (try ${try})"
  echo "removing ${STAGE_PATH}/latest"
  rm -rf "${STAGE_PATH}/latest"
  SLEEP_DURATION="$((RANDOM % 10 + 1))"
  echo "sleeping ${SLEEP_DURATION} then retrying"
  sleep "${SLEEP_DURATION}"
done

PYSCRIPT=$(cat << HEREDOC
import glob
import logging
import multiprocessing
import os

import pandas as pd
from retry import retry
from tqdm import tqdm


logging.basicConfig(
    format="\n%(asctime)s %(levelname)-8s %(message)s\n",
    level=logging.INFO,
    datefmt=">>> %Y-%m-%d %H:%M:%S",
)

globbed_phylometrics_paths = [
    *glob.glob(
        "${PREV_STAGE_PATH}/latest/a=phylometrics*/**/*+ext=.csv",
        recursive=True,
    )
]
logging.info(f"""{
  len(globbed_phylometrics_paths)
} phylometrics paths were globbed""")
logging.info(f"""first globbed phylometrics path is {
  globbed_phylometrics_paths[0]
}""")

read_csv_with_retry = retry(
    tries=10,
    delay=1,
    max_delay=10,
    backoff=2,
    jitter=(0, 4),
    logger=logging,
)(
  # wrap is workaround for retry compatibility
  lambda *args, **kwargs: pd.read_csv(*args, **kwargs)
)

collated_phylometrics_df = pd.concat(
    (
        read_csv_with_retry(phylometrics_path)
        for phylometrics_path in tqdm(
          globbed_phylometrics_paths,
          desc="phylometrics_paths",
          mininterval=10,
        )
    ),
    ignore_index=True,
    join="outer",
)
logging.info(
    "collated phylometrics dataframe constructed "
    f"with {len(collated_phylometrics_df)} rows"
)
collated_phylometrics_path = (
    "${STAGE_PATH}/latest/a=collated-phylometrics+ext=.csv"
)

retry(
    tries=10,
    delay=1,
    max_delay=10,
    backoff=2,
    jitter=(0, 4),
    logger=logging,
)(
  # wrap is workaround for retry compatibility
  lambda path, index: collated_phylometrics_df.to_csv(path, index=index)
)(collated_phylometrics_path, index=False)

logging.info(f"collated phylometrics written to {collated_phylometrics_path}")

collated_provlog_path = collated_phylometrics_path + ".provlog.yaml"

# adapted from https://stackoverflow.com/a/74214157
def read_file_bytes(path: str, size: int = -1) -> bytes:
    fd = os.open(path, os.O_RDONLY)
    try:
        if size == -1:
            size = os.fstat(fd).st_size
        return os.read(fd, size)
    finally:
        os.close(fd)

@retry(
    tries=10,
    delay=1,
    max_delay=10,
    backoff=2,
    jitter=(0, 4),
    logger=logging,
)
def do_collate_provlogs():
  with multiprocessing.Pool(processes=None) as pool:
    contents = [*pool.imap(
      read_file_bytes,
      (
        f"{phylometrics_path}.provlog.yaml"
        for phylometrics_path in tqdm(
          globbed_phylometrics_paths,
          desc="provlog_files",
          mininterval=10,
        )
      ),
    )]
  logging.info("contents read in from provlogs")

  with open(collated_provlog_path, "wb") as f_out:
    f_out.writelines(
      tqdm(
        contents,
        desc="provlog_contents",
        mininterval=10,
      ),
    )
do_collate_provlogs()

logging.info(f"collated provlog written to {collated_provlog_path}")

logging.info("PYSCRIPT complete")

HEREDOC
)

pwd

python3 -c "${PYSCRIPT}"

PROVLOG_PATH="${STAGE_PATH}/latest/a=collated-phylometrics+ext=.csv.provlog.yaml"
echo "PROVLOG_PATH ${PROVLOG_PATH}"

cat << HEREDOC >> "${PROVLOG_PATH}"
-
  a: ${PROVLOG_PATH}
  batch: ${BATCH}
  date: $(date --iso-8601=seconds)
  hostname: $(hostname)
  revision: ${REVISION}
  runmode: ${RUNMODE}
  user: $(whoami)
  uuid: $(uuidgen)
  slurm_job_id: ${SLURM_JOB_ID-none}
  stage: 5
  stage 4 batch path: $(readlink -f "${PREV_STAGE_PATH}")
  stage 5 batch path: $(readlink -f "${BATCH_PATH}")
  script path: ${SCRIPT_PATH}
HEREDOC

echo "appended new entry to ${PROVLOG_PATH}"

gzip "${PROVLOG_PATH}"

echo "gzipped ${PROVLOG_PATH}"

echo "fin ${0}"
