# _targets.R
# targets pipeline: GSE291397 Anolis carolinensis RNA-seq
# Comparison: Male (Testes) vs Female (Ovary), Midday control, limma-voom
#
# Usage:
#   source("install.R")        # first time only
#   targets::tar_make()        # run the pipeline
#   targets::tar_visnetwork()  # visualise dependency graph

library(targets)

# Declare packages loaded in each target's R session
tar_option_set(
  packages = c(
    "dplyr",
    "tibble",
    "ggplot2",
    "ggrepel",
    "limma",
    "edgeR",
    "GEOquery",
    "Biobase"
  ),
  # Store targets cache in _targets/ (default); use rds format
  format = "rds"
)

# Source all helper functions
source("R/download.R")
source("R/filter.R")
source("R/de_analysis.R")
source("R/plots.R")
source("R/save_outputs.R")

# ---------------------------------------------------------------------------
# Pipeline definition
# ---------------------------------------------------------------------------
list(

  # 1. Download supplementary count matrix from GEO
  #    format = "file" means the target is invalidated when the file changes
  tar_target(
    count_file,
    download_counts("GSE291397", basedir = "data"),
    format = "file"
  ),

  # 2. Load count matrix (genes x libraries integer matrix)
  tar_target(
    counts_raw,
    load_counts(count_file)
  ),

  # 3. Download series metadata and extract pData
  tar_target(
    pdata,
    fetch_pdata("GSE291397")
  ),

  # 4. Filter to 8 samples (4 Ovary + 4 Testes, Midday control)
  #    and match library names to count columns
  #    Returns list(counts, metadata)
  tar_target(
    filtered,
    filter_gonads(counts_raw, pdata)
  ),

  # 5. Build filtered, TMM-normalised DGEList
  tar_target(
    dge,
    make_dge(filtered$counts, filtered$metadata)
  ),

  # 6. voom transformation + lmFit + eBayes
  tar_target(
    fit,
    fit_voom(dge, filtered$metadata)
  ),

  # 7. Extract topTable results for Male_vs_Female contrast
  tar_target(
    de_results,
    get_results(fit)
  ),

  # 8. Save results table as CSV
  tar_target(
    results_csv,
    save_de_csv(de_results, "results/de_results.csv"),
    format = "file"
  ),

  # 9. Save volcano plot as PNG
  tar_target(
    volcano_png,
    {
      dir.create("results", showWarnings = FALSE, recursive = TRUE)
      plot_volcano(de_results, "results/volcano_plot.png")
    },
    format = "file"
  )

)
