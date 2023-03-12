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

PREV_STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=6+what=audit_reconstruction_quality/"
echo "PREV_STAGE_PATH ${PREV_STAGE_PATH}"

STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=7+what=collate_reconstruction_audits/"
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
import logging
import glob

import pandas as pd
from retry import retry
from tqdm import tqdm


logging.basicConfig(
    format="\n%(asctime)s %(levelname)-8s %(message)s\n",
    level=logging.INFO,
    datefmt=">>> %Y-%m-%d %H:%M:%S",
)

globbed_audit_paths = [
    *glob.glob(
        "${PREV_STAGE_PATH}/latest/a=reconstruction-audit*/**/*+ext=.csv",
        recursive=True,
    )
]
logging.info(f"""{
  len(globbed_audit_paths)
} audit paths were globbed""")
logging.info(f"""first globbed audit path is {
  globbed_audit_paths[0]
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

collated_audit_df = pd.concat(
    (
        read_csv_with_retry(audit_path)
        for audit_path in tqdm(
          globbed_audit_paths,
          desc="audit_paths",
          mininterval=10,
        )
    ),
    ignore_index=True,
    join="outer",
)
logging.info(
    "collated audit dataframe constructed "
    f"with {len(collated_audit_df)} rows"
)
collated_audit_path = (
    "${STAGE_PATH}/latest/a=collated-reconstruction-audits+ext=.csv"
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
  lambda path, index: collated_audit_df.to_csv(path, index=index)
)(collated_audit_path, index=False)

logging.info(f"collated audit written to {collated_audit_path}")

collated_provlog_path = collated_audit_path + ".provlog.yaml"

@retry(
    tries=10,
    delay=1,
    max_delay=10,
    backoff=2,
    jitter=(0, 4),
    logger=logging,
)
def do_collate_provlogs():
  with open(collated_provlog_path, "wb") as f_out:
      for audit_path in tqdm(
        globbed_audit_paths,
        desc="audit_paths",
        mininterval=10,
      ):
        provlog_path = audit_path + ".provlog.yaml"
        with open(provlog_path, "rb") as f_in:
            f_out.write(f_in.read())
do_collate_provlogs()

logging.info(f"collated provlog written to {collated_provlog_path}")

HEREDOC
)

pwd

python3 -c "${PYSCRIPT}"

echo "fin ${0}"
