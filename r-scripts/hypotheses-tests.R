library(effsize)
# Load the library needed for Cliff Delta and Cohen's D

library("car")
# Load data from analyse-data.R

load(paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/df_total.RData",
  sep = ""
))

printAndSafe <- function(x, filePath) {
  cat(x)
  cat(x, file = filePath, append = TRUE)
}

par(mfrow=c(6, 10), mar=c(1, 1, 1, 1))

for (i in seq(1, 60)) {
  y <- df_total$EnergyPerS[i]
  x <- df_total$AvgCPUPerS[i]
  plot(unlist(x), unlist(y))
}

df_total$PearsonCoeff = NA

for (row in 1:nrow(df_total)) {
  y <- unlist(df_total$EnergyPerS[row])
  x <- unlist(df_total$AvgCPUPerS[row])
  df_total$PearsonCoeff[row] = cor(as.numeric(x), as.numeric(y), method = "pearson")
}

job_types <- c("docking-protein-DNA",
               "docking-protein-protein",
               "cyclise-peptide")
modes <- c("sequential", "parallel")
metrics <- c("AvgCPU", "AvgMem", "ExecTime", "TotalEnergy", "PearsonCoeff")
metrics_labels <- c("CPU utilisation (%)", "Memory usage (GiB)", "Execution time (s)", "Energy usage (kJ)", "Pearson Coefficient")
df_total$AvgMem = df_total$AvgMem / 2^30
df_total$ExecTime = df_total$ExecTime / 10^3
df_total$TotalEnergy = df_total$TotalEnergy / 10^3

# QQ-plot for all metrics

png(
  file.path(
    dirname(rstudioapi::getSourceEditorContext()$path),
    "out", "plots", "qqplots.png"
  ),
  width=1600,
  height=1200
)
par(mfrow=c(5,6), oma=c(1, 3, 5, 0), mar=c(1.75, 1.75, 1.75, 1.75))


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
  mtext(metrics_labels[length(metrics_labels) + 1 - row], side = 2, line = 1, outer = TRUE, at = 0.130  + 0.2 * (row - 1), font = 2, cex = 1)
}
for (row in seq_along(job_types)) {
  mtext(job_types[row], side = 3, line = 1, outer = TRUE, at = 0.175 + (row - 1) * 0.33, font = 2, cex = 1)
}

for (mode in seq(1, 6, 2)) {
  mtext(modes[1], side = 3, line = -1, outer = TRUE, at = 0.08 + 0.1675 * (mode - 1), font = 2, cex = 1)
  mtext(modes[2], side = 3, line = -1, outer = TRUE, at = 0.25 + 0.1675 * (mode - 1), font = 2, cex = 1)
}


dev.off()

# Shapiro test for all metrics

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
        IsNormal = shapiro_test$p.value >= 0.05
      ))
      
      # Write to file
      cat(sprintf("%s of %s job with %s execution:\n", metric, job, mode), file = filePath, append = TRUE)
      cat(sprintf("Shapiro-Wilk normality test gave p-value = %.8f ", shapiro_test$p.value), file = filePath, append = TRUE)
      cat(sprintf( ">>> %s\n\n", ifelse(shapiro_results$IsNormal[nrow(shapiro_results)], "Normal", "Not normal")), file = filePath, append = TRUE)
    }
  }
}


filePath = file.path(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "out",
  "hypotheses-tests.txt"
)
file.remove(filePath)
# Mann-Whitney test for RQ1 and RQ2, t-test for RQ3
counter = 1
for (row in seq(1, nrow(df_total), by = 20)) {
  printAndSafe(sprintf("AvgCPU p-value for example %s: %.10f",counter,wilcox.test(df_total$AvgCPU[row:(row+9)],df_total$AvgCPU[(row+10):(row+19)])$p.value), filePath)
  printAndSafe(sprintf("\nAvgMem p-value for example %s: %.10f",counter,wilcox.test(df_total$AvgMem[row:(row+9)],df_total$AvgMem[(row+10):(row+19)])$p.value), filePath)
  printAndSafe(sprintf("\nExecTime p-value for example %s: %.10f",counter,wilcox.test(df_total$ExecTime[row:(row+9)],df_total$ExecTime[(row+10):(row+19)])$p.value), filePath)
  printAndSafe(sprintf("\nTotalEnergy p-value for example %s: %.10f",counter,wilcox.test(df_total$TotalEnergy[row:(row+9)],df_total$TotalEnergy[(row+10):(row+19)])$p.value), filePath)
  printAndSafe(sprintf("\nPearsonCoeff p-value for example %s: %.10f",counter,t.test(df_total$PearsonCoeff[row:(row+9)],df_total$PearsonCoeff[(row+10):(row+19)])$p.value), filePath)

  printAndSafe("\n\n", filePath)
  cliff_avgcpu = cliff.delta(df_total$AvgCPU[row:(row+9)],df_total$AvgCPU[(row+10):(row+19)])
  cliff_avgmem = cliff.delta(df_total$AvgMem[row:(row+9)],df_total$AvgMem[(row+10):(row+19)])
  cliff_exectime = cliff.delta(df_total$ExecTime[row:(row+9)],df_total$ExecTime[(row+10):(row+19)])
  cliff_totenergy = cliff.delta(df_total$TotalEnergy[row:(row+9)],df_total$TotalEnergy[(row+10):(row+19)])
  cohen_pearson = cohen.d(df_total$PearsonCoeff[row:(row+9)],df_total$PearsonCoeff[(row+10):(row+19)])
  printAndSafe(sprintf("\nAvgCPU Cliff's Delta for example %s: estimate= %s, confidence level= %s",counter,cliff_avgcpu$estimate, cliff_avgcpu$conf.int), filePath)
  printAndSafe(sprintf("\nAvgMem Cliff's Delta for example %s: estimate= %s, confidence level= %s",counter,cliff_avgmem$estimate, cliff_avgmem$conf.int), filePath)
  printAndSafe(sprintf("\nExecTime Cliff's Delta for example %s: estimate= %s, confidence level= %s",counter,cliff_exectime$estimate, cliff_exectime$conf.int), filePath)
  printAndSafe(sprintf("\nTotalEnergy Cliff's Delta for example %s: estimate= %s, confidence level= %s",counter,cliff_totenergy$estimate, cliff_totenergy$conf.int), filePath)
  printAndSafe(sprintf("\nPearsonCoeff Cohen's D for example %s: estimate= %s, confidence level= %s",counter,cohen_pearson$estimate, cohen_pearson$conf.int), filePath)
  counter = counter + 1
}
