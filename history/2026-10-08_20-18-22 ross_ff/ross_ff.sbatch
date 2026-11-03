#!/bin/bash
#SBATCH --job-name=DIFFICE_inversion         # create a short name for your job
#SBATCH --output=./../slurmout/run_all_configs/%A__%N/out.log      # stdout file
#SBATCH --error=./../slurmout/run_all_configs/%A__%N/err.log       # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=16       # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --partition=serc
#SBATCH --constraint="GPU_MEM:40GB|GPU_MEM:80GB|GPU_MEM:48GB"
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G is default)
#SBATCH --gres=gpu:1             # number of gpus per node
#SBATCH --time=12:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-user=aashrayc@stanford.edu
#SBATCH --mail-type=FAIL

set -euo pipefail

export JAX_COMPILATION_CACHE_DIR="${GROUP_HOME}/jax_cache"
export JAX_ENABLE_COMPILATION_CACHE=true

export JAX_PERSISTENT_CACHE_MIN_COMPILE_TIME_SECS=0
export JAX_PERSISTENT_CACHE_MIN_ENTRY_SIZE_BYTES=-1

export JAX_PERSISTENT_CACHE_ENABLE_XLA_CACHES=true

export JAX_COMPILATION_CACHE_INCLUDE_METADATA_IN_KEY=false

export JAX_EXPLAIN_CACHE_MISSES=false

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-4}"

SCRIPT_DIR="/oak/stanford/groups/cyaolai/JasperChen/Software/DIFFICE_jax/examples"

export XLA_FLAGS="--xla_dump_to=/oak/stanford/groups/cyaolai/AashrayChegu/cache/jax2 --xla_dump_hlo_as_text"

module reset
source "/oak/stanford/groups/cyaolai/JasperChen/VirtualEnv/DIFFICE_gpu_env/bin/activate"

unset JAX_PLATFORMS
unset JAX_PLATFORM_NAME


echo "HOSTNAME=$(hostname)"
echo "PWD=$(pwd)"
echo "PYTHON=$(which python)"

nvidia-smi

cd /oak/stanford/groups/cyaolai/AashrayChegu/data-product

echo "**Starting $1 (job name: $SLURM_JOB_NAME)"
python3 "${SCRIPT_DIR}/run_inversion.py" "$1"