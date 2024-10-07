#!/bin/bash
#SBATCH --job-name=${job_name}
#SBATCH --output=${shared_dir}/out/${job_name}.out
#SBATCH --error=${shared_dir}/out/${job_name}.err
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --ntasks=$ntasks
#SBATCH --time=02:00:00
#SBATCH --nodelist=$node

cd ${working_dir}

# Load the haddock3 virtual environment
source ${haddock3_venv_dir}/bin/activate

# Copy the haddock3 example to the working directory
cp -r ${shared_dir}/jobs/${cfg_dir} ${working_dir}

cd ${working_dir}/${cfg_dir}

# Create N copies of the config, which each have a unique run directory, to avoid interference
for ((i = 0 ; i < $ntasks ; i++)); do
    RUN_DIR=run$i NCORES=${cpus_per_task} envsubst < ${cfg_file} > ${job_name}-$i.cfg
done

# Run the haddock3 workflow, %t is the index of the task (0 to N) being executed.
# $SLURM_PROCID is this same index, but of the actual worker job, after it has started,
# which is what allows us to get it inside the bash command.
srun --output=${shared_dir}/out/${job_name}-%t.out  bash -c 'haddock3 ${job_name}-$SLURM_PROCID.cfg'

# Cleanup
rm -rf ${working_dir}/${cfg_dir}
