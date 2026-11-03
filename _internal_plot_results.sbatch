#!/bin/bash
#SBATCH --job-name=PlottingResults         # create a short name for your job
#SBATCH --output=./../slurmout/plot_outputs/%A__%N/out.log      # stdout file
#SBATCH --error=./../slurmout/plot_outputs/%A__%N/err.log       # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=24       # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --partition=serc
#SBATCH --constraint="GPU_MEM:48GB|GPU_MEM:80GB|GPU_MEM:40GB"
#SBATCH --gres=gpu:1             # number of gpus per node
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G is default)
#SBATCH --time=10:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-user=aashrayc@stanford.edu
#SBATCH --mail-type=START,END,FAIL

set -euo pipefail

module reset
module load gcc/14.2.0
source "/oak/stanford/groups/cyaolai/JasperChen/VirtualEnv/DIFFICE_gpu_env/bin/activate"
module restore compute_stress

unset JAX_PLATFORMS
unset JAX_PLATFORM_NAME


echo "HOSTNAME=$(hostname)"
echo "PWD=$(pwd)"
echo "PYTHON=$(which python)"

echo "Analyzing folder: $1"

foldername=$(basename "$1")
echo "Data Product: $foldername"

diff_dir="/oak/stanford/groups/cyaolai/AashrayChegu/DIFFICE_DIFFS"

cd /oak/stanford/groups/cyaolai/AashrayChegu/compute_metrics

# echo "Starting Zarr Export"
# python3 regular_grid_evaluation.py     --folder $1

# if [ "$#" -eq 2 ]; then
#     echo "Generating Comparisons"
#     python3 generate_comparisons.py    --folder $1 --config $analysis_config
# fi

# echo "Mean Residuals"
# python3 get_mean_residual.py           --folder $1 --save-location /oak/stanford/groups/cyaolai/AashrayChegu/compute_metrics/residual_csvs/

# echo "Making PowerPoints"
# python3 make_pptx.py                   --folder $1

cd /oak/stanford/groups/cyaolai/AashrayChegu/evaluate_inversions

echo "Building Zarrs"
python3 1_build_zarr.py         --folder $1

echo "Building Plots"
python3 2_viz_zarrs.py          --folder $1

echo "Mean Residuals"
python3 7_get_mean_residuals.py --folder $1

if [ "$#" -neq 2 ]; then
    exit 0
fi

cp $2/* $1 

if [ -e "$1/fields_over_time.toml" ]; then

    echo "Plot Fields Over Time"
    python3 3_fields_over_time.py --folder $1

fi

if [ -e "$1/diff.toml" ]; then
       
    echo "Diffing the Zarrs"
    python3 4_diff_zarrs.py --folder $1

    echo "Visualizing the Diffed Zarrs"
    python3 5_viz_diff_zarrs.py --folder "$diff_dir/$foldername"

fi

if [ -e "$1/comparisons.toml" ]; then
       
    echo "Cross Comparison Plots"
    python3 6_cross_comparison_plots.py --folder "$diff_dir/$foldername"

fi