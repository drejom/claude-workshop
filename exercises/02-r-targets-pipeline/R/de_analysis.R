# R/de_analysis.R
# limma-voom differential expression: Female (Ovary) vs Male (Testes)

# Build a filtered, TMM-normalised DGEList.
# Genes failing edgeR::filterByExpr() (default: ~10 counts in the smallest group)
# are dropped before normalisation.
make_dge <- function(counts, metadata) {
  # sex as factor with Female as reference (so positive logFC = higher in Male)
  sex <- factor(metadata$sex, levels = c("Female", "Male"))

  dge <- edgeR::DGEList(
    counts = counts,
    group  = sex,
    samples = metadata
  )

  # Filter low-count genes using the group structure
  design_filter <- stats::model.matrix(~ sex)
  keep <- edgeR::filterByExpr(dge, design = design_filter)
  dge  <- dge[keep, , keep.lib.sizes = FALSE]

  message(sprintf(
    "filterByExpr: kept %d / %d genes",
    sum(keep), length(keep)
  ))

  # TMM normalisation
  dge <- edgeR::calcNormFactors(dge, method = "TMM")

  dge
}

# Apply voom transformation, fit linear model, and compute empirical Bayes
# moderated statistics.  Comparison: Male (Testes) vs Female (Ovary).
fit_voom <- function(dge, metadata) {
  set.seed(42)

  sex    <- factor(metadata[colnames(dge), "sex"], levels = c("Female", "Male"))
  design <- stats::model.matrix(~ sex)
  colnames(design) <- c("Intercept", "Male_vs_Female")

  # voom with quality weights is more robust for unequal library sizes
  v <- limma::voomWithQualityWeights(dge, design = design, plot = FALSE)

  fit  <- limma::lmFit(v, design)
  fit  <- limma::eBayes(fit, robust = TRUE)

  fit
}

# Extract a tidy results table for the Male_vs_Female contrast.
# Returns all genes, sorted by adjusted p-value.
get_results <- function(fit) {
  tt <- limma::topTable(
    fit,
    coef   = "Male_vs_Female",
    number = Inf,
    sort.by = "P",
    adjust.method = "BH"
  )

  # topTable rownames are gene IDs; promote to column
  tt <- tibble::rownames_to_column(tt, var = "gene_id")

  tt
}
