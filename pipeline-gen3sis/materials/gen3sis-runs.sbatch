#!/bin/sh

#SBATCH -A ecode
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dolsonem@msu.edu
#SBATCH --job-name=gen3sis_hstrat
#SBATCH --time=0-3:59
#SBATCH --mem-per-cpu=4G 
#SBATCH --array 1-120

cd /mnt/scratch/dolsonem/hstrat-evolutionary-inference/pipline-gen3sis/materials

CURR_TREAT=plain
if [ ${SLURM_ARRAY_TASK_ID} -gt 30 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 61 ];
then
    CURR_TREAT=ecology;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 60 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 91 ];
then
    CURR_TREAT=spatial_ecology;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 90 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 121 ];
then
    CURR_TREAT=spatial_plain;
fi

RNG_SEED=${SLURM_ARRAY_TASK_ID} TREATMENT=${CURR_TREAT} ./run_simulation.sh