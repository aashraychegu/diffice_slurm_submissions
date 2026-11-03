#!/bin/bash
squeue -u aashrayc --format="%.18i %.9P %.75j %.8u %.10T %.10M %.10l %.6D %R" | grep $1 | awk '{print $1}' | tr '\n' ' '