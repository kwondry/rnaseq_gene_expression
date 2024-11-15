import pandas as pd

rule target:
    input:
        done = "results/multiqc/star_salmon/nfcore_rnaseq_multiqc_report.html"

rule test:
    input:
        test_done = "test_results/multiqc/star_salmon/nfcore_rnaseq_test_multiqc_report.html"

rule rnaseq_pipeline:
    input:
        input = "input/sample_sheet.csv",
        fasta = "/n/groups/kwon/data1/databases/human/ensembl_110_grch38/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz",
        gtf = "/n/groups/kwon/data1/databases/human/ensembl_110_grch38/Homo_sapiens.GRCh38.110.chr.gtf.gz"
    output:
        "results/multiqc/star_salmon/nfcore_rnaseq_multiqc_report.html"
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
        multiqc_title = "nfcore_rnaseq",
        extra = "-c rnaseq.config -w temp/work -resume",
        outdir = lambda wildcards, output: str(Path(output[0]).parents[-2])
    handover: True
    wrapper:
        "v5.0.0/utils/nextflow"

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


