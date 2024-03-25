#!/bin/bash

SCRIPT_PATH="$(realpath "$0")"
echo "SCRIPT_PATH ${SCRIPT_PATH}"

cd "$(dirname "$0")"

source ../pipeline/snippets/setup_instrumentation.sh

RUNMODE="${1}"
echo "RUNMODE ${RUNMODE}"

REVISION="$(git rev-parse --short HEAD)"
echo "REVISION ${REVISION}"

BATCH="date=$(date +%Y-%m-%d)+time=$(date +%H-%M-%S)+revision=${REVISION}+uuid=$(uuidgen)"
echo "BATCH ${BATCH}"

source ../pipeline/snippets/setup_production_dependencies.sh

PREV_STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=1+what=make_reconstructions_avida/"
echo "PREV_STAGE_PATH ${PREV_STAGE_PATH}"

STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=2+what=compute_phylometrics_avida/"
echo "STAGE_PATH ${STAGE_PATH}"

BATCH_PATH="${STAGE_PATH}/batches/${BATCH}/"
echo "BATCH_PATH ${BATCH_PATH}"

for try in {0..9}; do
  mkdir -p "${BATCH_PATH}/data" && break
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
import multiprocessing.pool as mpp

# https://stackoverflow.com/a/65854996
def istarmap(self, func, iterable, chunksize=1):
    """starmap-version of imap"""
    self._check_running()
    if chunksize < 1:
        raise ValueError(
            "Chunksize must be 1+, not {0:n}".format(
                chunksize))

    task_batches = mpp.Pool._get_tasks(func, iterable, chunksize)
    result = mpp.IMapIterator(self)
    self._taskqueue.put(
        (
            self._guarded_task_generation(result._job,
                                          mpp.starmapstar,
                                          task_batches),
            result._set_length
        ))
    return (item for chunk in result for item in chunk)

mpp.Pool.istarmap = istarmap


import functools
import gc
import glob
import gzip
import io
import itertools as it
import logging
import multiprocessing
import os
import random
import shutil
import sys
import tempfile
import uuid

from hstrat import _auxiliary_lib as hstrat_aux
from hstrat import hstrat
from keyname import keyname as kn
import numpy as np
import pandas as pd
from phylotrackpy import systematics
from retry import retry
from tqdm import tqdm


logging.basicConfig(
    format="\n%(asctime)s %(levelname)-8s %(message)s\n",
    level=logging.INFO,
    datefmt=">>> %Y-%m-%d %H:%M:%S",
)

globbed_true_phylogeny_paths = [
    *glob.glob(
        "${PREV_STAGE_PATH}/latest/data/**/phylogeny-snapshot-*.csv",
        recursive=True,
    )
]
logging.info(f"""{
  len(globbed_true_phylogeny_paths)
} phylogeny paths were globbed""")
logging.info(f"""first globbed true phylogeny path is {
  globbed_true_phylogeny_paths[0]
}""")

globbed_reconstructed_phylogeny_paths = [
    *glob.glob(
        "${PREV_STAGE_PATH}/latest/*treatment*/a=reconstructed-tree+*.csv.gz",
        recursive=True,
    )
]
logging.info(f"""{
  len(globbed_reconstructed_phylogeny_paths)
} phylogeny paths were globbed""")
logging.info(f"""first globbed reconstructed phylogeny path is {
  globbed_reconstructed_phylogeny_paths[0]
}""")

open_retry = retry(
  tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
)(open)

def analyze_one(a: str, phylogeny_path: str) -> pd.DataFrame:
  syst = systematics.Systematics(lambda x: x)  # arg: fun_taxon

  @retry(
    tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
  )
  def get_max_origin_time():
    # fillna for synthetic common root
    return pd.read_csv(phylogeny_path)["origin_time"].fillna(0).max()
  max_origin_time = get_max_origin_time()
  logging.info(
    f"extracted max origin time {max_origin_time} from source phylogeny"
  )

  @retry(
    tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
  )
  def do_load_from_file():
    df = pd.read_csv(phylogeny_path)
    df = hstrat_aux.alifestd_collapse_unifurcations(df, mutate=True)
    df["destruction_time"] = df["destruction_time"].fillna(max_origin_time)
    deunifurcated_path = f"/tmp/{uuid.uuid4()}.csv"
    df.to_csv(deunifurcated_path, index=False)
    syst.load_from_file(
      deunifurcated_path,
      "id",  # info_col
      True,  # assume_leaves_extant
    )

  do_load_from_file()
  logging.info("deserialized systematics from source phylogeny")

  phylometrics = dict()

  # can't calculate diversity without org counts
  # logging.info("calculating 'diversity'")
  # phylometrics["diversity"] = syst.calc_diversity()

  logging.info("calculating 'colless_like_index'")
  phylometrics["colless_like_index"] = syst.colless_like_index()

  logging.info("calculating 'average_depth'")
  phylometrics["average_depth"] = syst.get_ave_depth()

  logging.info("calculating 'average_origin_time'")
  phylometrics["average_origin_time"] = syst.get_average_origin_time(False)

  logging.info("calculating 'average_origin_time_normalized'")
  phylometrics["average_origin_time_normalized"] = (
    syst.get_average_origin_time(True)
  )

  logging.info("calculating 'max_depth'")
  phylometrics["max_depth"] = syst.get_max_depth()

  logging.info("calculating 'mean_pairwise_distance'")
  phylometrics["mean_pairwise_distance"] = syst.get_mean_pairwise_distance(False)

  logging.info("calculating 'mean_pairwise_distance_branch_only'")
  phylometrics["mean_pairwise_distance_branch_only"] = (
    syst.get_mean_pairwise_distance(True)
  )

  logging.info("calculating 'num_active'")
  phylometrics["num_active"] = syst.get_num_active()

  logging.info("calculating 'num_ancestors'")
  phylometrics["num_ancestors"] = syst.get_num_ancestors()

  logging.info("calculating 'num_outside'")
  phylometrics["num_outside"] = syst.get_num_outside()

  logging.info("calculating 'num_roots'")
  phylometrics["num_roots"] = syst.get_num_roots()

  logging.info("calculating 'num_taxa'")
  phylometrics["num_taxa"] = syst.get_num_taxa()

  logging.info("calculating 'phylogenetic_diversity'")
  phylometrics["phylogenetic_diversity"] = syst.get_phylogenetic_diversity()

  logging.info("calculating 'sum_pairwise_distance'")
  phylometrics["sum_pairwise_distance"] = syst.get_sum_pairwise_distance(False)

  logging.info("calculating 'sum_pairwise_distance_branch_only'")
  phylometrics["sum_pairwise_distance_branch_only"] = syst.get_sum_pairwise_distance(True)

  logging.info("calculating 'total_orgs'")
  phylometrics["total_orgs"] = syst.get_total_orgs()

  logging.info("calculating 'tree_size'")
  phylometrics["tree_size"] = syst.get_tree_size()

  logging.info("calculating 'sum_distance'")
  phylometrics["sum_distance"] = syst.get_sum_distance()

  logging.info("calculating 'variance_pairwise_distance'")
  phylometrics["variance_pairwise_distance"] = (
    syst.get_variance_pairwise_distance(False)
  )

  logging.info("calculating 'variance_pairwise_distance_branch_only'")
  phylometrics["variance_pairwise_distance_branch_only"] = (
    syst.get_variance_pairwise_distance(True)
  )

  logging.info("calculating 'mrca_depth'")
  phylometrics["mrca_depth"] = syst.mrca_depth()

  logging.info("calculating 'sackin_index'")
  phylometrics["sackin_index"] = syst.sackin_index()

  logging.info("calculating mean_evolutionary_distinctiveness")
  phylometrics[
    "mean_evolutionary_distinctiveness"
  ] = syst.get_mean_evolutionary_distinctiveness(
    max_origin_time,
  )

  logging.info("calculating sum_evolutionary_distinctiveness")
  phylometrics[
    "sum_evolutionary_distinctiveness"
  ] = syst.get_sum_evolutionary_distinctiveness(
    max_origin_time,
  )

  logging.info("calculating variance_evolutionary_distinctiveness")
  phylometrics[
    "variance_evolutionary_distinctiveness"
  ] = syst.get_variance_evolutionary_distinctiveness(
    max_origin_time,
  )


  logging.info("phylometric calculations complete")


  phylometrics_records = [
    {
      "a": a,
      "epoch": 0,
      "mut_distn": "default",
      **kn.unpack(kn.rejoin(
        phylogeny_path.replace("/phylogeny", "+phylogeny"),
      )),
      **phylometrics,
    }
  ]
  logging.info("phylometrics_records")
  logging.info(str(phylometrics_records))

  phylometrics_df = pd.DataFrame.from_records(phylometrics_records)
  logging.info("phylometrics_df")
  logging.info(str(phylometrics_df))
  return phylometrics_df



cpu_count = multiprocessing.cpu_count()
logging.info(f"cpu_count {cpu_count}")
with multiprocessing.Pool(processes=cpu_count) as pool:
  args = [
    *(
      ("collapsed-phylogeny", path)
      for path in globbed_true_phylogeny_paths
    ),
    *(
      ("reconstructed-phylogeny", path)
      for path in globbed_reconstructed_phylogeny_paths
    ),
  ]
  dfs = [*tqdm(
    pool.istarmap(analyze_one, args),
    total=len(args),
  )]

collated_phylometrics_df = pd.concat(dfs, ignore_index=True)

logging.info(
    "collated phylometrics dataframe constructed "
    f"with {len(collated_phylometrics_df)} rows"
)
collated_phylometrics_path = (
    "${BATCH_PATH}/a=collated-phylometrics+ext=.csv"
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
          # true phylogeny paths don't have provlogs
          globbed_reconstructed_phylogeny_paths,
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

def do_save():
  with open_retry(collated_provlog_path, "a+") as provlog_file:
    provlog_file.write(
f"""-
a: {collated_provlog_path}
batch: ${BATCH}
date: $(date --iso-8601=seconds)
hostname: $(hostname)
revision: ${REVISION}
runmode: ${RUNMODE}
user: $(whoami)
uuid: $(uuidgen)
slurm_job_id: ${SLURM_JOB_ID-none}
stage: 2
stage 2 batch path: $(readlink -f "${BATCH_PATH}")
stage 1 batch path: $(readlink -f "${PREV_STAGE_PATH}/latest")
""",
    )
do_save()

logging.info("PYSCRIPT complete")

HEREDOC
)

pwd

python3 -c "${PYSCRIPT}"

echo "fin ${0}"
