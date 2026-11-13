ls "/oak/stanford/groups/cyaolai/AashrayChegu/slurmout/run_all_configs/$1*"
read -p "Select The Run Name:" runname
tail -n 100 "../slurmout/run_all_configs/$runname/out.log"

