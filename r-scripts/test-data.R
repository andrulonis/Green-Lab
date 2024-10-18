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


# QQ-plot

par(mfrow = c(4, 3))
all_qqplots <- list()
counter <- 1
for (result in 4:7) {
  for (job in seq_along(job_types)) {
    data_mode1 <- df_total[[colnames(df_total)[result]]][df_total$JobType == job_types[job] &
                                                           df_total$Mode == modes[1]]
    
    data_mode2 <- df_total[[colnames(df_total)[result]]][df_total$JobType == job_types[job] &
                                                           df_total$Mode == modes[2]]
    
    qqplot(
      data_mode1,
      data_mode2,
      main = paste("QQ-Plot of", colnames(df_total)[result], "\nfor", job_types[job]),
      xlab = "Sequential",
      ylab = "Parallel"
    )
    
    # TODO: Check how to plot all diagrams on one page and save it
    # png(
    #   paste(
    #     dirname(rstudioapi::getSourceEditorContext()$path),
    #     "/out/plots/qq-plot-",
    #     colnames(df_total)[result],
    #     "-",
    #     job_types[job],
    #     ".png",
    #     sep = ""
    #   ),
    #   width = 1200,
    #   height = 800
    # )
    
    
    
    all_qqplots <- append(all_qqplots, qq_plot)
    # 
    # dev.off()
    counter <- counter + 1
  }
}

par(mfrow = c(1, 1))

# Shapiro-Wilk
counter <- 1
filePath = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/shapiro_results.txt",
  sep = ""
)
for (job in seq_along(job_types)) {
  for (mode in seq_along(modes)) {
    data_job_mode <- df_total$AvgCPU[df_total$JobType == job_types[job] &
                                       df_total$Mode == modes[mode]]
    shapiro_test <- shapiro.test(data_job_mode)
    
    cat(paste(job_types[job], "job with", modes[mode], "execution:\n"))
    cat(paste(job_types[job], "job with", modes[mode], "execution:\n"), file = filePath, append = TRUE)
    
    print(shapiro_test)
    cat(capture.output(shapiro_test), file = filePath, append = TRUE)
    
    # TODO: Save that in the dataframe
    if (shapiro_test$p.value < 0.05){
      cat(">>> No normal distribution\n\n")
      cat(">>> No normal distribution\n\n", file = filePath, append = TRUE)
    }
    else {
      cat(">>> Normal distribution\n\n")
      cat(">>> Normal distribution\n\n", file = filePath, append = TRUE)
    }
    counter <- counter + 1
  }
  cat("______________________________________\n\n", file = filePath, append = TRUE)
}
