# Load data from analyse-data.R

load(paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/df_total.RData",
  sep = ""
))

load(paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/avg_cpu_all.RData",
  sep = ""
))

load(paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/avg_power_all.RData",
  sep = ""
))

# Plot the power and CPU usage means over all repetitions

png(
  file.path(
    dirname(rstudioapi::getSourceEditorContext()$path),
    "out", "plots", "all-avg-plots.png"
  ),
  width=800,
  height=600
)

par(mfrow = c(2, 3))
par(mar=c(5, 4, 4, 6) + 0.1)
for (list in seq_along(avg_power_all)) {
  par(new=FALSE)
  
  plot(
    avg_power_all[[list]],
    type = "l",
    col = "blue",
    lwd = 1,
    xlab = "",
    ylab = "",
    axes=FALSE,
    main = names(avg_power_all)[list]
  )
  box()
  mtext("power usage (W)",side=2,col="black",line=2.5) 
  axis(2, ylim=c(0,80), col="blue",col.axis="blue",las=1)
  
  par(new=TRUE)
  plot(
    avg_cpu_all[[list]],
    type = "l",
    col = "orange",
    lwd = 1,
    axes=FALSE,
    xlab="",
    ylab=""
  )
  axis(4, col="orange",col.axis="orange",las=1)
  mtext("CPU usage (%)",side=4,col="black",line=2.5) 
  
  axis(1)
  mtext("Time (seconds)",side=1,col="black",line=2.5) 
}

dev.off()


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
