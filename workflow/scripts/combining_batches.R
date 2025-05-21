library(tidyverse)

# Gene Counts
if (length(snakemake@input[['gene_counts']]) == 1) {
    file.copy(snakemake@input[['gene_counts']][[1]], snakemake@output[['combined_gene_counts']])
} else {
    snakemake@input[['gene_counts']] %>%
        map(read_tsv) %>%
        reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
        write_tsv(snakemake@output[['combined_gene_counts']])
}

# Gene TPM
if (length(snakemake@input[['gene_tpm']]) == 1) {
    file.copy(snakemake@input[['gene_tpm']][[1]], snakemake@output[['combined_gene_tpm']])
} else {
    snakemake@input[['gene_tpm']] %>%
        map(read_tsv) %>%
        reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
        write_tsv(snakemake@output[['combined_gene_tpm']])
}

# Average Transcript Lengths
if (length(snakemake@input[['counts_length_scaled']]) == 1) {
    file.copy(snakemake@input[['counts_length_scaled']][[1]], snakemake@output[['combined_counts_length_scaled']])
} else {
    snakemake@input[['counts_length_scaled']] %>%
        map(read_tsv) %>%
        reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
        write_tsv(snakemake@output[['combined_counts_length_scaled']])
}


