# Boxplot, jitter, and violin plot

for (result in 4:7) {
  plot_total <- ggplot(df_total, aes(x = interaction(JobType, Mode), y = .data[[colnames(df_total)[result]]])) +
    geom_violin(trim = FALSE) +
    geom_boxplot(alpha = 0.5, fill = "white") +
    geom_jitter(size = 0.25, colour = "red") +
    facet_wrap(~ JobType + Mode, scales = "free") +
    scale_y_continuous(
      labels = function(x)
        format(x, digits = 4, scientific = TRUE)
    ) +
    labs(
      title = paste(colnames(df_total)[result], "per Job and Mode"),
      x = "JobType and Mode",
      y = colnames(df_total)[result]
    ) +
    theme(axis.text.x = element_blank())
  print(plot_total)
  ggsave(
    paste(
      dirname(rstudioapi::getSourceEditorContext()$path),
      "/out/plots/total-plot-",
      colnames(df_total)[result],
      ".png",
      sep = ""
    ),
    plot = plot_total,
    width = 6,
    height = 4
  )
}
