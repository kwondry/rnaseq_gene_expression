library(tidyverse)

all_kraken_results <- map_dfr(
    snakemake@input[["kraken_results"]],
    ~ read_tsv(.x, col_names = c("pct", "n_clade", "n_taxon", "tax_level", "tax_id", "tax_name")) %>% mutate(report_path = .x)) %>%
    mutate(sample = str_replace(report_path, "^.*?/kraken/", "") %>% str_replace("\\.txt", ""))

raw_sample_sheet <- read_csv(snakemake@input[["raw_sample_sheet"]])

raw_sample_sheet %>%
    semi_join(
        all_kraken_results %>% filter(tax_name == "Homo sapiens", n_taxon >= snakemake@params[["min_human_reads"]])
    ) %>%
    mutate_all(~ifelse(is.na(.), "", .)) %>%
    write_csv(snakemake@output[["samplesheet"]])

all_kraken_results %>% write_csv(snakemake@output[["kraken_stats"]])
