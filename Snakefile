import pandas as pd
raw_samplesheet = pd.read_csv("input/sample_sheet.csv").to_dict(orient="records")

fastq_map = {rec["sample"]:{"forward_fastq":rec["fastq_1"], "reverse_fastq":rec["fastq_2"]} for rec in raw_samplesheet}

ALL_SAMPLES = list(fastq_map.keys())

def get_fastqs_for_kraken(wildcards):
    return {"db":"/n/scratch3/users/j/je112/kraken_db", "forward_fastq":fastq_map[wildcards.sample]["forward_fastq"], "reverse_fastq":fastq_map[wildcards.sample]["reverse_fastq"]}

rule target:
    input:
        expand("results/kraken/{sample}.txt", sample = ALL_SAMPLES)

rule kraken:
    input:
        unpack(get_fastqs_for_kraken)
    output:
        report = "results/kraken/{sample}.txt"
    conda:
        "envs/kraken.yaml"
    threads:
        8
    shell:
        """
        kraken2 --db {input.db} --gzip-compressed --threads {threads} \
        --paired {input.forward_fastq}  {input.reverse_fastq}  --memory-mapping --report {output.report}
        """

rule parse_kraken_make_nfcore_samplesheet:
    input:
        expand("results/kraken/{sample}.txt", sample = ALL_SAMPLES)
    output:
        samplesheet = "results/samples_filtered_for_nfcore.csv",
        kraken_stats = "results/percent_human_by_sample.csv"
    conda:
        "envs/tidyverse.yaml"
    params:
        min_human_reads = 100000
    script:
        "scripts/parse_kraken_make_nfcore_samplesheet.R"