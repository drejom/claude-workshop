# R/filter.R
# Filter pData to Midday control Ovary/Testes samples and match to count columns

# Extract the library name from a GEO description string.
# pData description entries look like: "Library name: 33TA"
# Returns just the library name token (e.g. "33TA").
parse_library_name <- function(description) {
  # Match "Library name: <token>" — handle leading/trailing whitespace
  m <- regmatches(description, regexpr("Library name:\\s*(\\S+)", description, perl = TRUE))
  if (length(m) == 0 || nchar(m) == 0) return(NA_character_)
  sub("Library name:\\s*", "", m, perl = TRUE)
}

# Filter pData to the 8 samples needed (Midday control, Ovary + Testes, 4 reps each)
# and match each sample to a column name in the count matrix.
#
# Returns a list with:
#   $counts   — integer matrix, columns in the same order as $metadata rows
#   $metadata — data frame with columns: sample, tissue, sex, library
filter_gonads <- function(counts, pdata) {

  # --- 1. Identify characteristic columns ---------------------------------
  # GEO::getGEO() parses characteristics into columns named "tissue:ch1",
  # "Sex:ch1", "treatment:ch1", etc.  We match by keyword against the full
  # column name (case-insensitive).
  # Prefer parsed characteristic columns (name ends in ":ch1") over
  # protocol/freetext columns (e.g. "treatment_protocol_ch1").
  find_col <- function(keywords) {
    all_cols  <- colnames(pdata)
    matched   <- all_cols[Reduce(`|`, lapply(
      keywords,
      function(k) grepl(k, all_cols, ignore.case = TRUE)
    ))]
    if (length(matched) == 0) stop(
      "Could not find column matching: ", paste(keywords, collapse = ", "),
      "\nAvailable columns:\n  ", paste(all_cols, collapse = "\n  ")
    )
    # Prefer columns ending with ":ch1" (parsed GEO characteristics)
    parsed <- matched[grepl(":ch1$", matched)]
    if (length(parsed) > 0) parsed[1] else matched[1]
  }

  tissue_col    <- find_col(c("tissue"))
  treatment_col <- find_col(c("treatment"))

  # --- 2. Normalise values for robust matching ----------------------------
  tissue_vals    <- tolower(trimws(pdata[[tissue_col]]))
  treatment_vals <- tolower(trimws(pdata[[treatment_col]]))

  # Treatment column holds "Midday", "Midnight", "ALAN" — "Midday" is the control
  # --- 3. Filter rows ------------------------------------------------------
  keep <- tissue_vals %in% c("ovary", "testes") &
          grepl("midday", treatment_vals, fixed = TRUE)

  meta_filt <- pdata[keep, , drop = FALSE]

  if (nrow(meta_filt) == 0) {
    stop(
      "No samples passed the filter.\n",
      "Tissue values seen:     ", paste(unique(tissue_vals),    collapse = ", "), "\n",
      "Treatment values seen:  ", paste(unique(treatment_vals), collapse = ", ")
    )
  }

  # Expect exactly 4 Ovary + 4 Testes = 8 samples
  n_ovary  <- sum(tolower(trimws(meta_filt[[tissue_col]])) == "ovary")
  n_testes <- sum(tolower(trimws(meta_filt[[tissue_col]])) == "testes")

  if (n_ovary != 4 || n_testes != 4) {
    warning(sprintf(
      "Expected 4 Ovary and 4 Testes samples; found %d Ovary and %d Testes.",
      n_ovary, n_testes
    ))
  }

  # --- 4. Extract library names from the description field ----------------
  library_names <- vapply(meta_filt$description, parse_library_name, character(1))
  unmatched <- is.na(library_names)
  if (any(unmatched)) {
    stop(
      "Could not parse library name from description for ",
      sum(unmatched), " sample(s).\n",
      "Example description: ", head(meta_filt$description[unmatched], 1)
    )
  }

  # --- 5. Match library names to count matrix columns ---------------------
  missing_libs <- setdiff(library_names, colnames(counts))
  if (length(missing_libs) > 0) {
    stop(
      "Library names not found as count matrix columns: ",
      paste(missing_libs, collapse = ", "),
      "\nFirst 10 count columns: ",
      paste(head(colnames(counts), 10), collapse = ", ")
    )
  }

  counts_filt <- counts[, library_names, drop = FALSE]

  # --- 6. Build tidy metadata data frame ----------------------------------
  tissue_raw <- trimws(meta_filt[[tissue_col]])
  # Harmonise sex: GEO has "Female" for Ovary, "male" (lowercase) for Testes
  sex <- dplyr::case_when(
    tolower(tissue_raw) == "ovary"  ~ "Female",
    tolower(tissue_raw) == "testes" ~ "Male",
    .default = NA_character_
  )

  metadata <- data.frame(
    sample  = rownames(meta_filt),
    library = library_names,
    tissue  = tissue_raw,
    sex     = sex,
    row.names = library_names,
    stringsAsFactors = FALSE
  )

  # Order both objects so Ovary samples come first (Female = reference level later)
  ord <- order(metadata$sex, decreasing = FALSE)   # Female before Male alphabetically
  metadata    <- metadata[ord, , drop = FALSE]
  counts_filt <- counts_filt[, ord, drop = FALSE]

  list(counts = counts_filt, metadata = metadata)
}
