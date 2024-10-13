job_types <- c("docking-protein-DNA",
               "docking-protein-protein",
               "cyclise-peptide")
modes <- c("sequential", "parallel")

printAndSafe <- function(x, filePath) {
  cat(x)
  cat(x, file = filePath, append = TRUE)
}

msToMinutes <- function(ms) {
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
  avg_energy_seq <- mean(df_total$TotalEnergy[df_total$JobType == job_types[job] &
                                                df_total$Mode == modes[1]])
  avg_energy_para <- mean(df_total$TotalEnergy[df_total$JobType == job_types[job] &
                                                 df_total$Mode == modes[2]])
  
  printAndSafe(paste("\n\nAverage energy usage for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", avg_energy_seq, "J"), filePath)
  printAndSafe(paste("\nParallel:", avg_energy_para, "J"), filePath)
  printAndSafe(paste("\nDifference:", max(avg_energy_seq, avg_energy_para) - min(avg_energy_seq, avg_energy_para), "J"), filePath)
  result <- (max(avg_energy_seq, avg_energy_para) - min(avg_energy_seq, avg_energy_para)) < 50
  printAndSafe(paste("\n\n>>> Null hypothesis is", result), filePath)
}


# Hypothesis 2

filePath = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/hypo_2_results.txt",
  sep = ""
)

printAndSafe("Hypothesis 2\n", filePath)
for (job in seq_along(job_types)) {
  avg_exec_seq <- mean(df_total$ExecTime[df_total$JobType == job_types[job] &
                                                df_total$Mode == modes[1]])
  avg_exec_para <- mean(df_total$ExecTime[df_total$JobType == job_types[job] &
                                                 df_total$Mode == modes[2]])
  
  avg_MEM_seq <- mean(df_total$AvgMem[df_total$JobType == job_types[job] &
                                        df_total$Mode == modes[1]])
  avg_MEM_para <- mean(df_total$AvgMem[df_total$JobType == job_types[job] &
                                         df_total$Mode == modes[2]])
  
  avg_CPU_seq <- mean(df_total$AvgCPU[df_total$JobType == job_types[job] &
                                           df_total$Mode == modes[1]])
  avg_CPU_para <- mean(df_total$AvgCPU[df_total$JobType == job_types[job] &
                                            df_total$Mode == modes[2]])
  
  
  printAndSafe(paste("\n\nAverage execution time for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", msToMinutes(avg_exec_seq), "minutes"), filePath)
  printAndSafe(paste("\nParallel:", msToMinutes(avg_exec_para), "minutes"), filePath)
  printAndSafe(paste("\nDifference:", msToMinutes(max(avg_exec_seq, avg_exec_para) - min(avg_exec_seq, avg_exec_para)), "minutes"), filePath)
  exec_result <- (max(avg_exec_seq, avg_exec_para) - min(avg_exec_seq, avg_exec_para)) < 1
  
  printAndSafe(paste("\n\nAverage memory usage for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", bToGb(avg_MEM_seq), "GB"), filePath)
  printAndSafe(paste("\nParallel:", bToGb(avg_MEM_para), "GB"), filePath)
  printAndSafe(paste("\nDifference:", bToGb(max(avg_MEM_seq, avg_MEM_para) - min(avg_MEM_seq, avg_MEM_para)), "GB"), filePath)
  mem_result <- (max(avg_MEM_seq, avg_MEM_para) - min(avg_MEM_seq, avg_MEM_para)) < 1
  
  printAndSafe(paste("\n\nAverage CPU usage for", job_types[job]), filePath)
  printAndSafe(paste("\nSequential:", avg_CPU_seq, "%"), filePath)
  printAndSafe(paste("\nParallel:", avg_CPU_para, "%"), filePath)
  printAndSafe(paste("\nDifference:", max(avg_CPU_seq, avg_CPU_para) - min(avg_CPU_seq, avg_CPU_para), "%"), filePath)
  cpu_result <- (max(avg_CPU_seq, avg_CPU_para) - min(avg_CPU_seq, avg_CPU_para)) < 5
  
  printAndSafe(paste("\n\n>>> Null hypothesis is", exec_result && mem_result && cpu_result), filePath)
}

# Hypothesis 3

