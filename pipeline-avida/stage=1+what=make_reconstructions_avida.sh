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

STAGE_PATH="${HOME}/scratch/data/hstrat-evolutionary-inference/runmode=${RUNMODE}/stage=1+what=make_reconstructions_avida/"
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

for try in {0..9}; do
wget "https://osf.io/x5a2d/download" -O "${BATCH_PATH}/data.tar.gz" && break
echo "wget failed (try ${try})"
SLEEP_DURATION="$((RANDOM % 10 + 1))"
echo "sleeping ${SLEEP_DURATION} then retrying"
sleep "${SLEEP_DURATION}"
done

for try in {0..9}; do
tar -C "${BATCH_PATH}/data" -xvf "${BATCH_PATH}/data.tar.gz" && break
echo "untar failed (try ${try})"
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
import itertools as it
import logging
import multiprocessing
import os
import random

from hstrat import _auxiliary_lib as hstrat_aux
from hstrat import hstrat
from keyname import keyname as kn
import numpy as np
import pandas as pd
from retry import retry
from tqdm import tqdm


logging.basicConfig(
    format="\n%(asctime)s %(levelname)-8s %(message)s\n",
    level=logging.INFO,
    datefmt=">>> %Y-%m-%d %H:%M:%S",
)

globbed_phylogeny_paths = [
    *glob.glob(
        "${BATCH_PATH}/data/**/phylogeny-snapshot-*.csv",
        recursive=True,
    )
]
logging.info(f"""{
  len(globbed_phylogeny_paths)
} phylogeny paths were globbed""")
logging.info(f"""first globbed phylogeny path is {
  globbed_phylogeny_paths[0]
}""")

open_retry = retry(
  tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
)(open)

def reconstruct_one(
  template_path: str, recency_proportional_resolution: int
) -> None:
  template_df = retry(
    tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
  )(
    pd.read_csv
  )(template_path)
  template_df = hstrat_aux.alifestd_to_working_format(template_df)
  assert hstrat_aux.alifestd_validate(template_df)
  assert hstrat_aux.alifestd_has_contiguous_ids(template_df)
  assert hstrat_aux.alifestd_is_topologically_sorted(template_df)

  collapsed_df = hstrat_aux.alifestd_collapse_unifurcations(
    template_df,
    mutate=True,
  )
  collapsed_df = hstrat_aux.alifestd_to_working_format(collapsed_df)

  attrs = kn.unpack(kn.rejoin(template_path.replace(
    "/phylogeny", "+phylogeny",
  )))
  hstrat_aux.seed_random( random.Random(
    f"{ attrs['seed'] } "
    f"{ recency_proportional_resolution } "
  ).randrange(2**32) )

  seed_column = hstrat.HereditaryStratigraphicColumn(
    hstrat.recency_proportional_resolution_algo.Policy(
      int(recency_proportional_resolution)
    ),
    stratum_differentia_bit_width=8,
  )
  extant_population = hstrat.descend_template_phylogeny_alifestd(
    collapsed_df,
    seed_column,
  )

  reconstruction_postprocesses = ("naive",)
  tree_ensemble = hstrat.build_tree_trie_ensemble(
      extant_population,
      trie_postprocessors=[
          # naive
          hstrat.CompoundTriePostprocessor(
              postprocessors=[
                  hstrat.AssignOriginTimeNaiveTriePostprocessor(),
                  hstrat.AssignDestructionTimeYoungestPlusOneTriePostprocessor(),
              ],
          ),
      ],
  )
  logging.info(f"tree_ensemble has size {len(tree_ensemble)}")

  reconstruction_dfs = [*map(
      functools.partial(
          hstrat_aux.alifestd_assign_root_ancestor_token,
          root_ancestor_token="None",
      ),
      tree_ensemble,
  )]
  logging.info(f"reconstruction_dfs has size {len(reconstruction_dfs)}")

  # check data validity
  for postprocess, reconstruction_df in zip(
    reconstruction_postprocesses, reconstruction_dfs
  ):
    assert hstrat_aux.alifestd_validate(reconstruction_df), postprocess

  reconstruction_filenames = [*map(
    lambda postprocess: kn.pack({
      **kn.unpack(kn.rejoin(
        template_path.replace("/phylogeny", "+phylogeny"),
      )),
      **{
        "a" : "reconstructed-tree",
        "trie-postprocess" : postprocess,
        "subsampling-fraction" : 1,
        "resolution" : recency_proportional_resolution,
        "ext" : ".csv.gz",
      },
    }),
    reconstruction_postprocesses,
  )]
  logging.info(f"""reconstruction_filenames has size {
    len(reconstruction_filenames)
  }""")

  def setup_reconstruction_paths():
    return [
      kn.chop(
        f"${BATCH_PATH}/"
        f"""epoch={
            0
        }+resolution={
          recency_proportional_resolution
        }+subsampling_fraction={
          1
        }+seed={
          attrs['seed']
        }+treatment={
          kn.unpack(kn.rejoin(
            template_path.replace("/phylogeny", "+phylogeny"),
          ))["treatment"]
        }/"""
        f"{reconstruction_filename}",
        mkdir=True,
        logger=logging,
      )
      for reconstruction_filename in reconstruction_filenames
    ]
  reconstruction_paths = retry(
    tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
  )(setup_reconstruction_paths)()
  logging.info(f"""reconstruction_paths has size {
    len(reconstruction_paths)
  }""")

  for reconstruction_path, reconstruction_df in zip(
    reconstruction_paths, reconstruction_dfs
  ):
    retry(
      tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
    )(reconstruction_df.to_csv)(reconstruction_path, index=False)
    logging.info(f"wrote reconstructed tree to {reconstruction_path}")

    provlog_path = f"{reconstruction_path}.provlog.yaml"
    @retry(
      tries=10, delay=1, max_delay=10, backoff=2, jitter=(0, 4), logger=logging,
    )
    def do_save():
      with open_retry(provlog_path, "a+") as provlog_file:
        provlog_file.write(
  f"""-
    a: {provlog_path}
    batch: ${BATCH}
    date: $(date --iso-8601=seconds)
    hostname: $(hostname)
    revision: ${REVISION}
    runmode: ${RUNMODE}
    user: $(whoami)
    uuid: $(uuidgen)
    slurm_job_id: ${SLURM_JOB_ID-none}
    stage: 1
    stage 1 batch path: $(readlink -f "${BATCH_PATH}")
    template_path: {template_path}
  """,
        )
    do_save()

cpu_count = multiprocessing.cpu_count()
logging.info(f"cpu_count {cpu_count}")
with multiprocessing.Pool(processes=cpu_count) as pool:
    args = [*it.product(globbed_phylogeny_paths, [3, 10, 33, 100])]
    [*tqdm(
      pool.istarmap(reconstruct_one, args),
      total=len(args),
    )]

logging.info("PYSCRIPT complete")

HEREDOC
)

pwd

python3 -c "${PYSCRIPT}"

echo "fin ${0}"
