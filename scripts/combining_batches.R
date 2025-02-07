library(tidyverse)

combinine_gene_tables <- function(dir, table_type, out) {
    gene_counts <- list.files(dir, recursive = TRUE, pattern = "\\.tsv$", full.names = TRUE) %>%
    as_tibble() %>%
    filter(str_detect(value, table_type)) %>%
    pull(value) %>%
    map(read_tsv) %>%
    reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
    write_tsv(out)
}
snakemake@input[['gene_counts']] %>%
    map(read_tsv) %>%
    reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
    write_tsv(snakemake@output[['combined_gene_counts']])

snakemake@input[['gene_tpm']] %>%
    map(read_tsv) %>%
    reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
    write_tsv(snakemake@output[['combined_gene_tpm']])
    
snakemake@input[['avg_transcript_lengths']] %>%
    map(read_tsv) %>%
    reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
    write_tsv(snakemake@output[['combined_avg_transcript_lengths']])
    
snakemake@input[['gene_counts_library_scaled']] %>%
    map(read_tsv) %>%
    reduce(~ full_join(.x, .y, by = c("gene_id", "gene_name"))) %>%
    write_tsv(snakemake@output[['combined_gene_counts_library_scaled']])
    
    
# combinine_gene_tables(str_extract(snakemake@input[['gene_counts']], "^.*results")[1], "salmon.merged.gene_counts.tsv", snakemake@output[['combined_gene_counts']])
# combinine_gene_tables(str_extract(snakemake@input[['gene_tpm']], "^.*results")[1], "salmon.merged.gene_tpm.tsv", snakemake@output[['combined_gene_tpm']])
# combinine_gene_tables(str_extract(snakemake@input[['avg_transcript_lengths']], "^.*results")[1], "salmon.merged.gene_counts_length_scaled.tsv", snakemake@output[['combined_avg_transcript_lengths']])
# combinine_gene_tables(str_extract(snakemake@input[['gene_counts_library_scaled']], "^.*results")[1], "salmon.merged.gene_counts_scaled.tsv", snakemake@output[['combined_gene_counts_library_scaled']])
