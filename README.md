# RNA-Seq Gene Expression Workflow

This Snakemake workflow performs RNA-Seq analysis, including quality control, alignment, quantification, and differential gene expression.

The main steps are:
1. splitting your samples into batches
2. running `kraken` on each sample, and only keeping samples that have 100,000 human reads
3. runs the `nfcore rnaseq` pipeline on each batch
4. combines the outputs of each batch into one output file

## Workflow Structure

The project aims to follow the recommended Snakemake workflow structure. The current structure is:

```
.
├── config/
│   ├── config.yaml
│   └── sample_sheet_schema.yaml
├── workflow/
│   └── Snakefile  (Main Snakemake file - currently located in the project root)
|   ├── envs/
|   ├── scripts/
│   └── sample_sheet_schema.yaml
├── input/
│   └── ... (samplesheet can go here)
├── results/
│   └── ... (output files from the workflow)
├── submit_jobs.sh (submit this to run the workflow after dryrun)
└── README.md
```

## Configuration

The main configuration for the workflow is in `config/config.yaml`.

### `config.yaml` Schema:

```yaml
sample_sheet_path: "path/to/your/samples.csv" # Path to the input sample sheet
sample_sheet_batch_size: 1000 # Optional: Number of samples per batch. Batching occurs if total samples > 2 * this value.
kraken_db_path: "/path/to/your/kraken_db"  # Path to the Kraken2 database
```


## Kraken Database

The workflow includes a rule to automatically download and prepare the Kraken2 standard database if it's not found at the path specified by `kraken_db_path` in the `config.yaml`. 


### Input Sample Sheet (`sample_sheet_path`)

The input sample sheet is a CSV file that provides information about each sample to be processed.

**Schema (`config/sample_sheet_schema.yaml`):**

```yaml
properties:
  sample:
    type: string
    description: "Unique identifier for the sample."
  fastq_1:
    type: string
    description: "Path to the forward FASTQ file (R1)."
  fastq_2:
    type: string
    description: "Path to the reverse FASTQ file (R2). Optional, leave empty for single-end data."
required:
  - sample
  - fastq_1
```

**Example `samples.csv`:**

```csv
sample,fastq_1,fastq_2,strandedness
SampleA,/path/to/SampleA_R1.fastq.gz,/path/to/SampleA_R2.fastq.gz,unstranded
SampleB,/path/to/SampleB_R1.fastq.gz,/path/to/SampleB_R2.fastq.gz,unstranded
SampleC,/path/to/SampleC_R1.fastq.gz,,unstranded
```

For the `strandedness` column, refer to the details of your library prep. Are reads in the `forward` orientation relative to the gene, or `reverse`? Or could they be either (`unstranded`)? If you are unsure you can set to `auto`, but this will fail for very contanminated, low quality libraries and results in extra execution time.  

## Usage

To run the workflow:

1.  **Activate Conda Environment (if necessary):**
    Ensure you have Conda installed and any base environments for Snakemake activated.

2.  **Update Configuration:**
    Modify `config/config.yaml` with your specific paths and settings.
    Ensure your sample sheet (e.g., `input/samples.csv`) matches the schema and its path is correctly set in `config.yaml`.

3.  **Execute Snakemake:**
    Navigate to the root directory of the workflow and run Snakemake. You will need to specify the location of the config file.


    For a dry run (to see what tasks would be executed):
    ```bash
    snakemake -n --cores 1 --use-conda
    ```

    To run on the cluster, submit the `submit_jobs.sh` to the queue.

    ```bash
    sbatch submit.jobs.sh
    ```
