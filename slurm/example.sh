#!/bin/bash
#SBATCH --job-name=Antigen
#SBATCH --output=Antigen.out
#SBATCH --cpus-per-task=32
#SBATCH --time=01:00:00
#SBATCH --nodelist=gl6

cd /home/nameofteam/haddock3
source venv/bin/activate
cd examples/docking-antibody-antigen
haddock3 docking-antibody-antigen-CDR-NMR-CSP-full.cfg