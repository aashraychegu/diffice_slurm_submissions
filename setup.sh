alias queue="squeue -u aashrayc --format='%.18i %.9P %.75j %.8u %.10T %.10M %.10l %.6D %R'"
cancel () { scancel $(queue | awk '/DIFFICE/ {print $1}'); }
export -f cancel