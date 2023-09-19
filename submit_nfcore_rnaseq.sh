#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
#SBATCH --mem=24GB
#SBATCH --partition=short
#SBATCH --job-name=submit_nfcore_rnaseq

mkdir -p ./results/nfcore;
nextflow run nf-core/rnaseq -profile mamba -c ./nextflow.config --min_trimmed_reads 100000 --minAssignedFrags 1 --multiqc_title nfcore_rnaseq --save_reference --input results/samples_filtered_for_nfcore.csv --fasta /n/groups/kwon/data1/databases/human/ensembl_110_grch38/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz --gtf /n/groups/kwon/data1/databases/human/ensembl_110_grch38/Homo_sapiens.GRCh38.110.chr.gtf.gz --outdir ./results/nfcore -resume
