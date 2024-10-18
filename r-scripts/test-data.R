library("car")

# Load data from analyse-data.R

load(paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/df_total.RData",
  sep = ""
))

job_types <- c("docking-protein-DNA",
               "docking-protein-protein",
               "cyclise-peptide")
modes <- c("sequential", "parallel")
metrics <- c("AvgCPU", "AvgMem", "ExecTime", "TotalEnergy")

# QQ-plot

png(
    paste(
      dirname(rstudioapi::getSourceEditorContext()$path),
      "/out/plots/qqplots.png",
      sep = ""
    ),
    width=1600,
    height=1200
)
par(mfrow=c(4,6))

for (metric in metrics) {
  for (job in job_types) {
    for (mode in modes) {
      data <- df_total[[metric]][df_total$JobType == job & df_total$Mode == mode]
      qqPlot(
        data,
        main = paste("QQ-Plot of", metric, "\nfor", job, "\n", mode),
        ylab = colnames(df_total)[result]
      )
    }
  }
}

dev.off()

# Shapiro-Wilk
filePath = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/shapiro_results.txt",
  sep = ""
)
for (job in job_types) {
  for (mode in modes) {
    
    data_job_mode <- df_total$AvgCPU[df_total$JobType == job & df_total$Mode == mode]
    shapiro_test <- shapiro.test(data_job_mode)
    
    cat(paste(job, "job with", mode, "execution:\n"))
    cat(paste(job, "job with", mode, "execution:\n"), file = filePath, append = TRUE)
    
    print(shapiro_test)
    cat(capture.output(shapiro_test), file = filePath, append = TRUE)
    
    # TODO: Save that in the data frame
    if (shapiro_test$p.value < 0.05){
      cat(">>> No normal distribution\n\n")
      cat(">>> No normal distribution\n\n", file = filePath, append = TRUE)
    }
    else {
      cat(">>> Normal distribution\n\n")
      cat(">>> Normal distribution\n\n", file = filePath, append = TRUE)
    }
  }
  cat("______________________________________\n\n", file = filePath, append = TRUE)
}
