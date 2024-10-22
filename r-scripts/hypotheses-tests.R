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

printAndSafe <- function(x, filePath) {
  cat(x)
  cat(x, file = filePath, append = TRUE)
}

msToMins <- function(ms) {
  return(ms / 60000)
}

bToGb <- function(bytes) {
  return(bytes / 1073741824)
}

# Hypothesis 1

filePath = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/hypo_1_results.txt",
  sep = ""
)

printAndSafe("Hypothesis 1", filePath)
for (job in seq_along(job_types)) {
  energy_seq <- df_total$TotalEnergy[df_total$JobType == job_types[job] &
                                       df_total$Mode == modes[1]]
  energy_para <- df_total$TotalEnergy[df_total$JobType == job_types[job] &
                                        df_total$Mode == modes[2]]
  
  printAndSafe(paste("\n\nAverage energy usage for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", mean(energy_seq), "J"), filePath)
  printAndSafe(paste("\nParallel:", mean(energy_para), "J"), filePath)
  
  # TODO: Check for normality and do either t-test or 
  t_test <- t.test(energy_seq,
                   energy_para,
                   paired = TRUE,)
  
  printAndSafe(capture.output(t_test), filePath)
}


# Hypothesis 2

filePath = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/hypo_2_results.txt",
  sep = ""
)

printAndSafe("Hypothesis 2\n", filePath)
for (job in seq_along(job_types)) {
  exec_time_seq <- df_total$ExecTime[df_total$JobType == job_types[job] &
                                           df_total$Mode == modes[1]]
  exec_time_para <- df_total$ExecTime[df_total$JobType == job_types[job] &
                                            df_total$Mode == modes[2]]
  
  MEM_seq <- df_total$AvgMem[df_total$JobType == job_types[job] &
                                        df_total$Mode == modes[1]]
  MEM_para <- df_total$AvgMem[df_total$JobType == job_types[job] &
                                         df_total$Mode == modes[2]]
  
  CPU_seq <- df_total$AvgCPU[df_total$JobType == job_types[job] &
                                        df_total$Mode == modes[1]]
  CPU_para <- df_total$AvgCPU[df_total$JobType == job_types[job] &
                                         df_total$Mode == modes[2]]
  
  
  printAndSafe(paste("\n\nAverage execution time for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", msToMins(mean(exec_time_seq)), "minutes"), filePath)
  printAndSafe(paste("\nParallel:", msToMins(mean(exec_time_para)), "minutes"), filePath)

  # TODO: Check normality and do either t-test or Wilcoxon
  
  printAndSafe(paste("\n\nAverage memory usage for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", bToGb(mean(MEM_seq)), "GB"), filePath)
  printAndSafe(paste("\nParallel:", bToGb(mean(MEM_para)), "GB"), filePath)
  
  # TODO: Check normality and do either t-test or Wilcoxon

  
  printAndSafe(paste("\n\nAverage CPU usage for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", mean(CPU_seq), "%"), filePath)
  printAndSafe(paste("\nParallel:", mean(CPU_seq), "%"), filePath)

  # TODO: Check normality and do either t-test or Wilcoxon
  
  # printAndSafe(
  #   paste(
  #     "\n\n>>> Null hypothesis is",
  #     exec_result && mem_result && cpu_result
  #   ),
  #   filePath
  # )
}

# Hypothesis 3

# Could be useful library: https://personality-project.org/r/psych/help/r.test.html
par(mfrow=c(6, 10), mar=c(1, 1, 1, 1))

for (i in seq(1, 60)) {
  y <- unlist(df_total$EnergyPerS[i])
  x <- unlist(df_total$AvgCPUPerS[i])
  x <- x[y < 1000]
  y <- y[y < 1000]
  plot(x, y)
}

df_total$PearsonCoeff = NA

for (row in 1:nrow(df_total)) {
  df_total$PearsonCoeff[row] = cor(as.numeric(unlist(df_total$AvgCPUPerS[row])),as.numeric(unlist(df_total$EnergyPerS[row])), method = "pearson")
}

job_types <- c("docking-protein-DNA",
               "docking-protein-protein",
               "cyclise-peptide")
modes <- c("sequential", "parallel")
metrics <- c("PearsonCoeff")
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
par(mfrow=c(4,4), oma=c(1, 3, 5, 0), mar=c(1.75, 1.75, 1.75, 1.75))


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

dev.off()

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
  "shapiro_results_rq3.txt"
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


# T-test

for (row in seq(1, nrow(df_total), by = 20)) {
  print(t.test(df_total$PearsonCoeff[row:(row+9)],df_total$PearsonCoeff[(row+10):(row+19)],)$p.value)
}
