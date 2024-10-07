#!/bin/bash
#SBATCH --job-name=${job_name}
#SBATCH --output=${shared_dir}/out/${job_name}.out
#SBATCH --error=${shared_dir}/out/${job_name}.err
#SBATCH --cpus-per-task=${cpus_per_task}
#SBATCH --ntasks=$ntasks
#SBATCH --time=00:00:05
#SBATCH --nodelist=$node

cd ${working_dir}

# Load the haddock3 virtual environment
source ${haddock3_venv_dir}/bin/activate

# Copy the haddock3 example to the working directory
cp -r ${shared_dir}/jobs/${cfg_dir} ${working_dir}

cd ${working_dir}/${cfg_dir}

# Run the haddock3 workflow
srun --output=${shared_dir}/out/${job_name}-%t.out haddock3 ${cfg_file}

# Cleanup
rm -rf ${working_dir}/${cfg_dir}

