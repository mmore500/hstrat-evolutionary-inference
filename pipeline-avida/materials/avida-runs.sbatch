#!/bin/sh

#SBATCH -A ecode
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dolsonem@msu.edu
#SBATCH --job-name=avida_hstrat
#SBATCH --time=0-12:00
#SBATCH --mem-per-cpu=4G
#SBATCH --array 1-300

cd /mnt/scratch/dolsonem/hstrat-evolutionary-inference/pipline-avida/materials

CURR_TREAT=plain
if [ ${SLURM_ARRAY_TASK_ID} -gt 30 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 61 ];
then
    CURR_TREAT=ecology_rich;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 60 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 91 ];
then
    CURR_TREAT=ecology_some;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 90 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 121 ];
then
    CURR_TREAT=ecology_weak;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 120 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 151 ];
then
    CURR_TREAT=selection_strong;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 150 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 181 ];
then
    CURR_TREAT=selection_weak;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 180 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 211 ];
then
    CURR_TREAT=spatial_ecology_rich;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 210 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 241 ];
then
    CURR_TREAT=spatial_ecology_some;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 240 ] && [ ${SLURM_ARRAY_TASK_ID} -lt 271 ];
then
    CURR_TREAT=spatial_ecology_weak;
fi

if [ ${SLURM_ARRAY_TASK_ID} -gt 270 ];
then
    CURR_TREAT=spatial_plain;
fi


RNG_SEED=${SLURM_ARRAY_TASK_ID} TREATMENT=${CURR_TREAT} ./run_simulation.sh
