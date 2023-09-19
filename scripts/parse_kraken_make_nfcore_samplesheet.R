library(tidyverse)

all_kraken_results <- map_dfr(
    snakemake@input[["kraken_results"]],
    ~ read_tsv(.x, col_names = c("pct", "n_clade", "n_taxon", "tax_level", "tax_id", "tax_name") %>% mutate(report_path = .x))
) %>%
    mutate(sample = str_replace(report_path, "results/kraken/", "") %>% str_replace("\\.txt", ""))

raw_sample_sheet <- read_csv(snakemake@input[["raw_sample_sheet"]])

raw_sample_sheet %>%
    semi_join(
        all_kraken_results %>% filter(tax_name == "Homo sapiens", n_taxon >= snakemake@params[["min_human_reads"]])
    ) %>%
    write_csv(snakemake@output[["samplesheet"]])

raw_sample_sheet %>%
    anti_join(
        all_kraken_results %>% filter(tax_name == "Homo sapiens", n_taxon >= snakemake@params[["min_human_reads"]])
    ) %>%
    write_csv(snakemake@output[["bad_samples"]])

all_kraken_results %>% write_csv(snakemake@output[["kraken_stats"]])
