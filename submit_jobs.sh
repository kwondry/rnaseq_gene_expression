#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=72:00:00
#SBATCH --mem=16GB
#SBATCH --partition=medium
#SBATCH --job-name=submit_jobs

mkdir -p ./slurm

snakemake  --executor slurm --default-resources slurm_partition=short --resources active_nextflow=1 --configfile config.yaml --use-conda --jobname {rulename}.{jobid} --jobs 500 --keep-going --rerun-incomplete
