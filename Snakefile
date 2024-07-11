import pandas as pd

#reads in samples
raw_samplesheet = pd.read_csv("input/sample_sheet.csv").to_dict(orient="records")
fastq_map = {rec["sample"]:{"forward_fastq":rec["fastq_1"], "reverse_fastq":rec["fastq_2"]} for rec in raw_samplesheet}

#checking if reads are single or paired
def check_paired_fastq(records):
    for record in records:
        if pd.isna(record['fastq_2']):
            return "single"
    return "paired"

read_type = check_paired_fastq(raw_samplesheet)


ALL_SAMPLES = list(fastq_map.keys())
print("These are your samples: \n", ALL_SAMPLES)

def get_fastqs_for_kraken(wildcards):
    if read_type == "single":
        return {"db":"/n/groups/kwon/data1/databases/kraken_db", "forward_fastq":fastq_map[wildcards.sample]["forward_fastq"], "reverse_fastq": list()}
    if read_type == "paired":
        return {"db":"/n/groups/kwon/data1/databases/kraken_db", "forward_fastq":fastq_map[wildcards.sample]["forward_fastq"], "reverse_fastq":fastq_map[wildcards.sample]["reverse_fastq"]}

rule target:
    input:
        expand("results/kraken/{sample}.txt", sample = ALL_SAMPLES),
        kraken_stats = "results/percent_human_by_sample.csv"

rule kraken:
    input:
        unpack(get_fastqs_for_kraken)
    output:
        report = "results/kraken/{sample}.txt"
    conda:
        "envs/kraken.yaml"
    threads:
        8
    params:
        type_param = "single"
    shell:
        """
        if [ "{params.type_param}" == "single" ]; then

        kraken2 --db {input.db} --gzip-compressed --threads {threads} \
        {input.forward_fastq}  --memory-mapping --report {output.report}

        else

        kraken2 --db {input.db} --gzip-compressed --threads {threads} \
        --paired {input.forward_fastq} {input.reverse_fastq}  --memory-mapping --report {output.report}

        fi
        """


rule parse_kraken_make_nfcore_samplesheet:
    input:
        expand("results/kraken/{sample}.txt", sample = ALL_SAMPLES)
    output:
        samplesheet = "results/samples_filtered_for_nfcore.csv",
        bad_samples = "results/badsamples_from_kraken.csv",
        kraken_stats = "results/percent_human_by_sample.csv"
    conda:
        "envs/tidyverse.yaml"
    params:
        min_human_reads = 100000
    script:
        "scripts/parse_kraken_make_nfcore_samplesheet.R"