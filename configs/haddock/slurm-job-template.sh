#!/bin/bash
#SBATCH --job-name=${job_name}
#SBATCH --output=${shared_dir}/out/${job_name}.out
#SBATCH --error=${shared_dir}/out/${job_name}.err
#SBATCH --time=03:00:00
#SBATCH --nodelist=$node
#SBATCH --ntasks=$ntasks
#SBATCH --cpus-per-task=${cpus_per_task}

cd ${working_dir}

# Load the haddock3 virtual environment
source ${haddock3_venv_dir}/bin/activate

# Copy the haddock3 example to the working directory
cp -r ${shared_dir}/jobs/${cfg_dir} ${working_dir}

cd ${working_dir}/${cfg_dir}

# Create N copies of the config, which each have a unique run directory, to avoid interference
for ((i = 1 ; i <= ${total_tasks} ; i++)); do
    RUN_DIR="${job_name}-$i" NCORES=${cpus_per_task} envsubst < ${cfg_file} > ${job_name}-$i.cfg
done

# Run the haddock3 workflows, i is the index of the task (1 to total_tasks) being executed
for ((i = 1 ; i <= ${total_tasks} ; i++)); do
    srun --exclusive --ntasks=1 --output=${shared_dir}/out/${job_name}-$i.out bash -c "haddock3 ${job_name}-$i.cfg" &
done
wait

# Cleanup
rm -rf ${working_dir}/${cfg_dir}
