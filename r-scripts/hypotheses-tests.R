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
  
  printAndSafe(
    paste(
      "\n\n>>> Null hypothesis is",
      exec_result && mem_result && cpu_result
    ),
    filePath
  )
}

# Hypothesis 3

# TODO: Calculate all Pearson corr. coeffs., average them, compare them
# Could be useful library: https://personality-project.org/r/psych/help/r.test.html

df_total$PearsonCoeff = NA

for (row in 1:nrow(df_total)) {
  df_total$PearsonCoeff[row] = cor(as.numeric(unlist(df_total$AvgCPUPerS[row])),as.numeric(unlist(df_total$EnergyPerS[row])), method = "pearson")
}

print(as.numeric(unlist(df_total$Run))[as.numeric(unlist(df_total$EnergyPerS))>1000])

plot(as.numeric(unlist(df_total$AvgCPUPerS)), as.numeric(unlist(df_total$EnergyPerS)))
    