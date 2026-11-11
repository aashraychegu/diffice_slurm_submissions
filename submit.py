from pathlib import Path
from argparse import ArgumentParser
import subprocess
from tqdm import tqdm
import yaml
from datetime import datetime
import jinja2

parser = ArgumentParser(prog = "submit_inversions.py", description = "Submit DIFFICE Inversions", epilog = "")
parser.add_argument("--product"  , default = None        , help = "Product name to run inversions on. [REQUIRED to properly run]")
parser.add_argument("--product-dir", default = "/oak/stanford/groups/cyaolai/AashrayChegu/data-product/product/", help = "The directory where your data product is located")

parser.add_argument("--runtime_h" , default = 8, type = int, help = "How many hours should the script run for")
parser.add_argument("--gpu_constraint"   , nargs = "+", default = ["40", "80", "48"], help = "VRAM requirements on the GPUs")
parser.add_argument("--mock"     , action = "store_true" , default = False, help = "Do a Mock Submission")

parser.add_argument("--configs-dirs-location", default = "/oak/stanford/groups/cyaolai/AashrayChegu/evaluate_inversions/configs/", help = "The directory where your metrics configuration file is located")
parser.add_argument("--configs-dir", default = None, help = "The comparison config to use. Defaults to `None`, which does nothing")

parser.add_argument("--history-dir", default = "./history", help = "The directory for logs")
parser.add_argument("--template-path", default = "./_internal_diffice_slurm_script_template.jinja2", help = "The path to the template")


args = parser.parse_args()

product = args.product
runtime_h = args.runtime_h
gpu_constraint = args.gpu_constraint
mock = args.mock
configs_dir = args.configs_dir

product_dir = Path(args.product_dir).resolve().absolute()
configs_dirs_location = Path(args.configs_dirs_location).resolve().absolute()
submit_history_dir = Path(args.history_dir).resolve().absolute()
template_path = Path(args.template_path).resolve().absolute()
mock_value = "11111110"

all_data_product_config_files = []
print("Data Product Config Files:")
print("-"*100)
for file in product_dir.glob("*/"):
    print(f"~> {file.stem}")
    all_data_product_config_files.append(file.stem)
print("="*100)

all_configs_file_dirs = []
print("\nConfiguration File Directories:")
print("-"*100)
for file in configs_dirs_location.iterdir():
    print(f"-> {file.stem}")
    all_configs_file_dirs.append(file.stem)
print("="*100)

if args.product is None:
    parser.print_help()
    exit()

if product not in all_data_product_config_files:
    print(f"[ERROR] Invalid product: {product}")
    exit()

if configs_dir is not None and configs_dir not in all_configs_file_dirs:
    print(f"[ERROR] Invalid config_dir: {configs_dir}")
    exit()

def get_str_datetime():
    return datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

start_time = get_str_datetime()

history_dir = submit_history_dir / f"{start_time} {product}"
history_dir.mkdir(exist_ok = True)
log_file_path = (history_dir / f"{product}.log").resolve().absolute()
log_file_path.touch()
log_file = log_file_path.open("w")
submit_script = (history_dir / f"{product}.sbatch").resolve().absolute()

environment = jinja2.Environment(loader = jinja2.FileSystemLoader(template_path.parent))
template = environment.get_template(template_path.name)

content = template.render(time = f"{runtime_h}:00:00", constraint = "|".join([f"GPU_MEM:{i}GB" for i in gpu_constraint]))
submit_script.write_text(content)

print(f"Using Submission Script: {submit_script}")
config_files = list((product_dir / product).glob("*.yaml"))


job_ids = []
output_dir = ""
for config_file in (pbar := tqdm(config_files)):
    config = yaml.safe_load(config_file.read_text())
    if not mock:
        output = subprocess.run(["sbatch", "--parsable", submit_script.as_posix(), config_file.as_posix()], capture_output = True)
        job_id = output.stdout.strip().decode()
        subprocess.run(["scontrol", "update", f"JobId={job_id}", f"JobName=DIFFICE:{config["name"]}"])
    else:
        job_id = mock_value
    job_ids.append(job_id)
    message = f"Submitted {job_id} successfully at {get_str_datetime()}"
    pbar.set_description(f"{message:<75}")
    log_file.write(f"{message}\n")
    output_dir = Path(config["artifacts"]["output_dir"]).resolve().absolute().parent.as_posix()
print("Output Dir:",output_dir)

slug = ["sbatch", "--parsable", "-d", f"afterany:{":".join(job_ids)}" ,"_internal_plot_results.sbatch", output_dir]

if configs_dir is not None:
    slug.append((configs_dirs_location / configs_dir).as_posix())

if not mock:
    output = subprocess.run(slug, capture_output = True)
    job_id = output.stdout.strip().decode()
    subprocess.run(["scontrol", "update", f"JobId={job_id}", f"JobName=Plotting-DIFFICE:{product}"])
    job_ids.append(job_id)
else:
    print(f"mocking with slug: {" ".join(slug)}")
    job_id = mock_value


message = f"Submitted Plotting Job: {job_id} successfully at {get_str_datetime()}"
print("\n",message,"\n")
log_file.write(f"{message}\n")
log_file.write(f"\n{" ".join(job_ids)}")
subprocess.run(["squeue", "-u", "aashrayc", r'--format="%.18i %.9P %.120j %.8u %.10T %.10M %.10l %.6D %R"'])
print(f"Finished Submitting {product}")
log_file.close()



