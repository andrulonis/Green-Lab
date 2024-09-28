#!/bin/bash
#SBATCH --job-name=${job_name}
#SBATCH --output=${job_name}.out
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
haddock3 ${cfg_file} &
haddock3 ${cfg_file} &
haddock3 ${cfg_file} &
haddock3 ${cfg_file} &
wait

# Cleanup
rm -rf ${working_dir}/${cfg_dir}

# Copy the output to the shared directory
cp ${out_file} ${shared_dir}/out
