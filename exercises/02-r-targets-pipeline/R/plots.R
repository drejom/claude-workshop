# R/plots.R
# Volcano plot: Male (Testes) vs Female (Ovary), label top 15 DE genes

# Build and save a volcano plot from a limma topTable data frame.
# Columns expected: gene_id, logFC, adj.P.Val, AveExpr
# Saves a PNG to `out_path` and returns the path (for targets format = "file").
plot_volcano <- function(results, out_path, top_n = 15,
                         fdr_cut = 0.05, lfc_cut = 1) {

  # Significance categories
  plot_data <- results |>
    dplyr::mutate(
      sig = dplyr::case_when(
        adj.P.Val < fdr_cut & logFC >  lfc_cut ~ "Up in Male",
        adj.P.Val < fdr_cut & logFC < -lfc_cut ~ "Up in Female",
        adj.P.Val < fdr_cut                    ~ "FDR < 0.05",
        .default = "NS"
      ),
      sig = factor(sig, levels = c("Up in Male", "Up in Female", "FDR < 0.05", "NS")),
      neg_log10_fdr = -log10(adj.P.Val)
    )

  # Top genes to label (smallest adj.P.Val; break ties by |logFC|)
  label_data <- plot_data |>
    dplyr::arrange(adj.P.Val, dplyr::desc(abs(logFC))) |>
    dplyr::slice_head(n = top_n)

  sig_colours <- c(
    "Up in Male"   = "#d62728",
    "Up in Female" = "#1f77b4",
    "FDR < 0.05"   = "#9467bd",
    "NS"           = "grey70"
  )

  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = logFC, y = neg_log10_fdr, colour = sig)
  ) +
    ggplot2::geom_point(size = 0.8, alpha = 0.6) +
    ggplot2::geom_vline(xintercept = c(-lfc_cut, lfc_cut),
                        linetype = "dashed", colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_hline(yintercept = -log10(fdr_cut),
                        linetype = "dashed", colour = "grey40", linewidth = 0.4) +
    ggrepel::geom_text_repel(
      data        = label_data,
      ggplot2::aes(label = gene_id),
      size        = 2.8,
      max.overlaps = 40,
      segment.size = 0.3,
      segment.colour = "grey50",
      box.padding  = 0.4,
      show.legend  = FALSE,
      seed         = 42
    ) +
    ggplot2::scale_colour_manual(values = sig_colours, name = NULL) +
    ggplot2::labs(
      title    = "Differential expression: Male (Testes) vs Female (Ovary)",
      subtitle = sprintf(
        "Midday control, Anolis carolinensis  |  FDR < %.2f, |logFC| > %g  |  top %d labelled",
        fdr_cut, lfc_cut, top_n
      ),
      x = expression(log[2]~fold~change~(Male/Female)),
      y = expression(-log[10]~FDR)
    ) +
    ggplot2::theme_bw(base_size = 11) +
    ggplot2::theme(
      legend.position  = "top",
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.subtitle    = ggplot2::element_text(colour = "grey40", size = 9)
    )

  ggplot2::ggsave(
    filename = out_path,
    plot     = p,
    width    = 8,
    height   = 6,
    dpi      = 300
  )

  out_path
}
