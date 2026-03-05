# R/download.R
# Functions to download raw counts and metadata from GEO

# Download the supplementary count matrix for a GEO accession.
# Returns the local path to the downloaded .csv.gz file (for format = "file").
download_counts <- function(gse_id, basedir = "data") {
  dest_dir <- file.path(basedir, gse_id)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  GEOquery::getGEOSuppFiles(
    GEO        = gse_id,
    makeDirectory = FALSE,   # we manage the directory ourselves
    baseDir    = dest_dir,
    fetch_files = TRUE
  )

  # Return path to the specific file we need
  target_file <- file.path(dest_dir, paste0(gse_id, "_GA_raw_counts_FINAL.csv.gz"))

  if (!file.exists(target_file)) {
    # List what was actually downloaded to help diagnose
    downloaded <- list.files(dest_dir, full.names = TRUE)
    stop(
      "Expected file not found: ", target_file,
      "\nFiles in ", dest_dir, ":\n  ",
      paste(downloaded, collapse = "\n  ")
    )
  }

  target_file
}

# Load the raw count matrix from the downloaded .csv.gz.
# Columns 1-5 are genomic annotation (Chr, Start, End, Strand, Length) — skip them.
# Returns a plain integer matrix with gene IDs as rownames.
load_counts <- function(count_file) {
  raw <- utils::read.csv(
    count_file,
    row.names   = 1,
    check.names = FALSE
  )

  # Columns 1-4 are annotation after row.names consumed col 1 (Geneid)
  # Remaining annotation cols: Chr, Start, End, Strand, Length (indices 1-5 pre row.names)
  # After row.names = 1, the first 5 cols in raw are annotation
  annotation_cols <- 1:5
  count_data <- raw[, -annotation_cols]

  as.matrix(count_data)
}

# Download GEO series metadata and return the pData data frame.
# getGEO() returns a named list of ExpressionSets; we take the first element.
fetch_pdata <- function(gse_id) {
  geo_list <- GEOquery::getGEO(
    GEO         = gse_id,
    GSEMatrix   = TRUE,
    getGPL      = FALSE
  )

  gse <- geo_list[[1]]
  pdata <- Biobase::pData(gse)
  pdata
}
