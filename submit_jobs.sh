#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10-00:00:00
#SBATCH --mem=32GB
#SBATCH --partition=priority
#SBATCH --job-name=submit_jobs


snakemake  --executor slurm --default-resources slurm_partition=short --groups kraken=kraken_group --group-components kraken_group=6 --resources active_nextflow=2 --use-conda --jobname {rulename}.{jobid} --jobs 2000 --keep-going --rerun-incomplete
