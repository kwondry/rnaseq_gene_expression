#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
#SBATCH --mem=16GB
#SBATCH --partition=short
#SBATCH --job-name=submit_kraken

mkdir -p ./slurm

snakemake --use-conda --conda-prefix=~/snakemake_conda_prefix --cluster-config cluster.yaml \
  --cluster "sbatch --output=slurm/{rulename}.{jobid} -p {cluster.partition} -N {cluster.nodes} -n {cluster.cores} --mem={cluster.mem} --time={cluster.time}" \
  --jobname {rulename}.{jobid} --jobs 500 --keep-going --rerun-incomplete
