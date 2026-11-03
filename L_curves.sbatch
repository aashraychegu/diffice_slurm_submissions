#!/bin/bash
#SBATCH --job-name=L_curve           # create a short name for your job
#SBATCH --output=/oak/stanford/groups/cyaolai/AashrayChegu/slurm/slurmout/l_curves__n_eq_1/%A__%N/out.log      # stdout file
#SBATCH --error=/oak/stanford/groups/cyaolai/AashrayChegu/slurm/slurmout/l_curves__n_eq_1/%A__%N/err.log       # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=32        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --partition=serc
#SBATCH --mem=128G         # memory per cpu-core (4G is default)
#SBATCH --time=120:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-user=aashrayc@stanford.edu

set -euo pipefail

cd /oak/stanford/groups/cyaolai/AashrayChegu/ISSM-Adjoint
matlab -nodisplay -nosplash -nodesktop -batch L_curves
