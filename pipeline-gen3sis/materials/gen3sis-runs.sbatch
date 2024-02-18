#!/bin/sh

#SBATCH -A ecode
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dolsonem@msu.edu
#SBATCH --job-name=gen3sis_hstrat
#SBATCH --time=0-3:59
#SBATCH --mem-per-cpu=4G 

cd /mnt/scratch/dolsonem/hstrat-evolutionary-inference/pipeline-gen3sis/materials

CURR_TREAT=plain
for i in {1..30}
do
    RNG_SEED=${i} TREATMENT=${CURR_TREAT} ./run_simulation.sh
done

CURR_TREAT=ecology;
for i in {1..30}
do
    RNG_SEED=${i} TREATMENT=${CURR_TREAT} ./run_simulation.sh
done

CURR_TREAT=spatial_ecology;
for i in {1..30}
do
    RNG_SEED=${i} TREATMENT=${CURR_TREAT} ./run_simulation.sh
done

CURR_TREAT=spatial_plain;
for i in {1..30}
do
    RNG_SEED=${i} TREATMENT=${CURR_TREAT} ./run_simulation.sh
done

