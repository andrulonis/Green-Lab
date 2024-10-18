library("car")

# Load data from analyse-data.R

load(file.path(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "out",
  "df_total.RData"
))

job_types <- c("docking-protein-DNA",
               "docking-protein-protein",
               "cyclise-peptide")
modes <- c("sequential", "parallel")
metrics <- c("AvgCPU", "AvgMem", "ExecTime", "TotalEnergy")
metrics_labels <- c("CPU utilisation (%)", "Memory usage (GiB)", "Execution time (s)", "Energy usage (kJ)")
df_total$AvgMem = df_total$AvgMem / 2^30
df_total$ExecTime = df_total$ExecTime / 10^3
df_total$TotalEnergy = df_total$TotalEnergy / 10^3

# QQ-plot

png(
    file.path(
      dirname(rstudioapi::getSourceEditorContext()$path),
      "out", "plots", "qqplots.png"
    ),
    width=1600,
    height=1200
)
par(mfrow=c(4,6), oma=c(1, 3, 5, 0), mar=c(1.75, 1.75, 1.75, 1.75))


for (metric in metrics) {
  for (job in job_types) {
    for (mode in modes) {
      data <- df_total[[metric]][df_total$JobType == job & df_total$Mode == mode]

      qqPlot(
        data,
        ylab = "",
        main = NULL
      )
    }
  }
}

title("QQ-plots of metrics per run", outer = TRUE, line = 3, cex.main = 2)

for (row in seq_along(metrics_labels)) {
  mtext(metrics_labels[length(metrics_labels) + 1 - row], side = 2, line = 1, outer = TRUE, at = 0.130  + 0.25 * (row - 1), font = 2, cex = 1)
}
for (row in seq_along(job_types)) {
  mtext(job_types[row], side = 3, line = 1, outer = TRUE, at = 0.175 + (row - 1) * 0.33, font = 2, cex = 1)
}

for (mode in seq(1, 6, 2)) {
  mtext(modes[1], side = 3, line = -1, outer = TRUE, at = 0.08 + 0.1675 * (mode - 1), font = 2, cex = 1)
  mtext(modes[2], side = 3, line = -1, outer = TRUE, at = 0.25 + 0.1675 * (mode - 1), font = 2, cex = 1)
}


dev.off()

# Shapiro-Wilk

shapiro_results <- data.frame(
  Metric = character(),
  JobType = character(),
  Mode = character(),
  PValue = numeric(),
  IsNormal = logical()
)

filePath = file.path(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "out",
  "shapiro_results.txt"
)
file.remove(filePath)
for (metric in metrics) {
  for (job in job_types) {
    for (mode in modes) {
      data <- df_total[[metric]][df_total$JobType == job & df_total$Mode == mode]
      shapiro_test <- shapiro.test(data)

      # Append results to the data frame
      shapiro_results <- rbind(shapiro_results, data.frame(
        Metric = metric,
        JobType = job,
        Mode = mode,
        PValue = shapiro_test$p.value,
        IsNormal = shapiro_test$p.value < 0.05
      ))
  
      # Write to file
      cat(sprintf("%s of %s job with %s execution:\n", metric, job, mode), file = filePath, append = TRUE)
      cat(sprintf("Shapiro-Wilk normality test gave p-value = %.8f ", shapiro_test$p.value), file = filePath, append = TRUE)
      cat(sprintf(
        ">>> %s\n\n", 
        ifelse(shapiro_results$Distribution[nrow(shapiro_results)], "Normal", "Not normal")
      ), file = filePath, append = TRUE)
    }
  }
}
