# R/save_outputs.R
# Write final outputs to disk; return file paths for targets format = "file"

save_de_csv <- function(results, out_path) {
  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(results, file = out_path, row.names = FALSE)
  out_path
}
