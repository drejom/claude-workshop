# Install all dependencies for the GSE291397 targets pipeline
# Run this once before executing tar_make()

# CRAN packages
install.packages(c(
  "targets",
  "tarchetypes",
  "dplyr",
  "tibble",
  "ggplot2",
  "ggrepel"
))

# Bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

BiocManager::install(c(
  "GEOquery",
  "limma",
  "edgeR",
  "Biobase"
))
