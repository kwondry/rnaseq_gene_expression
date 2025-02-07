import pandas as pd
import os
import logging
import math

# split sample sheet with >1000 samples into batches
path_to_sample_sheet = "input/ben_samplesheet_smartseq_20250110.csv"

def split_sample_sheet(path, verbose=False):
    # logging config
    #logger = logging.getLogger() 
    #if logger.hasHandlers():
    #    logger.handlers.clear()
    #if verbose:
    #    logging.basicConfig(level=logging.DEBUG)
    #else:
    #    logging.basicConfig(level=logging.INFO)
    
    # check if sample sheet has been split already
    if os.path.isdir("./input/sample_sheet_batches/"):
        print("Sample sheet has already been separated into batches")
    else:
        # load sample sheet
        sample_sheet = pd.read_csv(path)
        # Calculate the number of batches and batch size
        num_batches = math.ceil(sample_sheet.shape[0] / 1000)
        batch_size = math.ceil(sample_sheet.shape[0] / num_batches)
        # Sort by the 'sample' column
        sample_sheet = sample_sheet.sort_values(by='sample')
        # Create a row number (starting at 1 for consistency with R)
        sample_sheet['row_number'] = range(1, len(sample_sheet) + 1)
        # Calculate potentially_wrong_batch
        sample_sheet['potentially_wrong_batch'] = 1 + (sample_sheet['row_number'] / batch_size).apply(math.floor)
        # Group by sample and assign the 'batch' as the first potentially_wrong_batch for that sample
        sample_sheet['batch'] = sample_sheet.groupby('sample')['potentially_wrong_batch'].transform('first')
        # (Optional) If you don't need the intermediate columns anymore, you can drop them:
        sample_sheet = sample_sheet.drop(columns=['row_number', 'potentially_wrong_batch'])        
        # output CSV files for each batch
        os.makedirs("./input/sample_sheet_batches/")
        for batch_number, group_df in sample_sheet.groupby('batch'):
            path_to_sample_sheet_batch = f"./input/sample_sheet_batches/sample_sheet_batch{batch_number}.csv"
            group_df.drop("batch", axis=1).to_csv(path_to_sample_sheet_batch)
        #logger.debug(sample_sheet.groupby('batch').size())




split_sample_sheet(path_to_sample_sheet, verbose=False)

ALL_BATCHES = glob_wildcards("input/sample_sheet_batches/sample_sheet_{batch_num}.csv").batch_num

rule target:
    input:
        # expand("results/{batch_num}/multiqc/star_salmon/nfcore_rnaseq_{batch_num}_multiqc_report.html", batch_num=ALL_BATCHES)
        "results/combined_salmon.merged.gene_counts.tsv"

rule test:
    input:
        test_done = "test_results/multiqc/star_salmon/nfcore_rnaseq_test_multiqc_report.html"

def get_samples_for_batch(batch_num):
    raw_sample_sheet = pd.read_csv(f"input/sample_sheet_batches/sample_sheet_{batch_num}.csv")
    return raw_sample_sheet["sample"].tolist()

def get_fastqs_for_kraken(wildcards):
    raw_sample_sheet = pd.read_csv(path_to_sample_sheet).to_dict(orient="records")
    fastq_map = {rec["sample"]:{"forward_fastq":rec["fastq_1"], "reverse_fastq":rec["fastq_2"]} for rec in raw_sample_sheet}
    return {"db":"/n/scratch/users/j/jos6417/kraken_db", "forward_fastq":fastq_map[wildcards.sample]["forward_fastq"]}


rule kraken:
    input:
        unpack(get_fastqs_for_kraken)
    output:
        report = "results/{batch_num}/kraken/{sample}.txt"
    conda:
        "envs/kraken.yaml"
    resources:
        cpus_per_task=8, 
        mem_mb=32000,
        runtime="8h",
        partition="short"
    shell:
        """
        kraken2 --db {input.db} --gzip-compressed --threads {threads} \
         {input.forward_fastq}  --memory-mapping --report {output.report}
        """

def get_kraken_results(wildcards):
    print(["results/{{batch_num}}/kraken/{}.txt".format(s) for s in get_samples_for_batch(wildcards.batch_num)])
    return ["results/{{batch_num}}/kraken/{}.txt".format(s) for s in get_samples_for_batch(wildcards.batch_num)]

rule parse_kraken_make_nfcore_samplesheet:
    input:
        kraken_results = get_kraken_results,
        raw_sample_sheet = "input/sample_sheet_batches/sample_sheet_{batch_num}.csv"
    output:
        samplesheet = "results/{batch_num}/samples_filtered_for_nfcore.csv",
        kraken_stats = "results/{batch_num}/percent_human_by_sample.csv"
    conda:
        "envs/tidyverse.yaml"
    params:
        min_human_reads = 100000
    resources:
        cpus_per_task=4,
        mem_mb=16000,
        runtime="8h",
        partition="short"
    script:
        "scripts/parse_kraken_make_nfcore_samplesheet.R"

rule rnaseq_pipeline:
    input:
        input = "results/{batch_num}/samples_filtered_for_nfcore.csv",
        fasta = "/n/groups/kwon/data1/databases/human/ensembl_110_grch38/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz",
        gtf = "/n/groups/kwon/data1/databases/human/ensembl_110_grch38/Homo_sapiens.GRCh38.110.chr.gtf.gz"
    output:
        gene_counts = "results/{batch_num}/star_salmon/salmon.merged.gene_counts.tsv",
        gene_tpm = "results/{batch_num}/star_salmon/salmon.merged.gene_tpm.tsv",
        avg_transcript_lengths = "results/{batch_num}/star_salmon/salmon.merged.gene_counts_length_scaled.tsv"
    params:
        pipeline = "nf-core/rnaseq",
        revision = "3.12.0",
        profile = ["mamba"],
        aligner = "star_salmon",
        save_reference = False,
        min_trimmed_reads = 100000,
        save_align_intermeds = False,
        skip_deseq2_qc = True,
        skip_rseqc = True,
        skip_bigwig = True,
        skip_stringtie = True,
        skip_preseq = True,
        salmon_index = "/n/groups/kwon/data1/databases/rnaseq_index/index/salmon",
        multiqc_title = "nfcore_rnaseq_{batch_num}",
        extra = "-c rnaseq.config -w temp/work_{batch_num} -resume",
        outdir = lambda wildcards, output: output.gene_counts.split("/star_salmon/")[0] + "/"
    # resources:
    #     active_nextflow = 1   # only runs one batch at a time
    handover: True
    wrapper:
        "v5.0.0/utils/nextflow"


rule combining_batches:
    input:
        gene_counts = expand("results/{batch_num}/star_salmon/salmon.merged.gene_counts.tsv", batch_num = ALL_BATCHES),
        gene_tpm = expand("results/{batch_num}/star_salmon/salmon.merged.gene_tpm.tsv", batch_num = ALL_BATCHES),
        avg_transcript_lengths = expand("results/{batch_num}/star_salmon/salmon.merged.gene_counts_length_scaled.tsv", batch_num = ALL_BATCHES),
    output:
        combined_gene_counts = "results/combined_salmon.merged.gene_counts.tsv",
        combined_gene_tpm = "results/combined_salmon.merged.gene_tpm.tsv",
        combined_avg_transcript_lengths = "results/combined_salmon.merged.gene_counts_length_scaled.tsv"
    conda:
        "envs/tidyverse.yaml"
    resources:
        cpus_per_task=2, 
        mem_mb=64000,
        runtime="8h",
        partition="short"
    script:
        "scripts/combining_batches.R"

rule rnaseq_pipeline_test:
    output:
        "test_results/multiqc/star_salmon/nfcore_rnaseq_test_multiqc_report.html",
    params:
        pipeline = "nf-core/rnaseq",
        revision = "3.12.0",
        profile = ["test", "mamba"],
        aligner = "star_salmon",
        save_reference = False,
        min_trimmed_reads = 1,
        save_align_intermeds = False,
        skip_deseq2_qc = True,
        skip_rseqc = True,
        skip_bigwig = True,
        skip_stringtie = True,
        skip_preseq = True,
        multiqc_title = "nfcore_rnaseq_test",
        extra = "-w temp/work -resume",
        outdir = lambda wildcards, output: str(Path(output[0]).parents[-2])
    handover: True
    wrapper:
        "v5.0.0/utils/nextflow"
