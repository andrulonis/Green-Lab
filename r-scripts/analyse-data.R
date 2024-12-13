library("tidyverse")

setwd(paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/results-data",
  sep = ""
))
options(digits = 22)

# Load data from csv files

data = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)
data_rq3 = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)

for (file in list.files(getwd())) {
  file_nums = as.numeric(unlist(regmatches(file, gregexpr("[0-9]+", file))))
  row = file_nums[1] + 1
  col = file_nums[2] + 1
  
  csv_data = as.matrix(read.csv(file, stringsAsFactors = TRUE))
  
  if (is.null(data[[row, col]])) {
    data[[row, col]] = csv_data
  } else {
    data[[row, col]] = rbind(data[[row, col]], csv_data)
  }
  if (is.null(data_rq3[[row, col]]) && row %% 2 == 0) {
    data_rq3[[row, col]] = csv_data
  }
}

for (seq_run in seq(from = 1, to = 5, by = 2)) {
  for (rep in 1:ncol(data)) {
    if (!is.null(data[[seq_run, rep]]) &&
        nrow(data[[seq_run, rep]]) > 0) {
      data_rq3[[seq_run, rep]] <- data[[seq_run, rep]][order(data[[seq_run, rep]][, "Time"]), ]
    }
  }
}

# Calculate necessary values for RQ1 and RQ2

# total_energy will be populated later with the help of data for RQ3.
# This is due to the problem with the wraparound of the power value reported by the machine.
total_energy = matrix(NA, 6 * 10, nrow = 6, ncol = 10)
RAM_total_energy = matrix(NA, 6 * 10, nrow = 6, ncol = 10)

execution_time = matrix(NA, 6 * 10, nrow = 6, ncol = 10)
avg_mem = matrix(NA, 6 * 10, nrow = 6, ncol = 10)
avg_cpu = matrix(NA, 6 * 10, nrow = 6, ncol = 10)

cpu_columns <- grep("^CPU_USAGE_", colnames(data[[1, 1]]))

for (run in 1:nrow(data)) {
  for (rep in 1:ncol(data)) {
    execution_time[[run, rep]] = max(data[[run, rep]][, "Time"]) - min(data[[run, rep]][, "Time"])
    avg_mem[[run, rep]] = mean(data[[run, rep]][, "USED_MEMORY"])
    avg_cpu[[run, rep]] = mean(data[[run, rep]][, cpu_columns])
  }
}

# Calculate necessary values for RQ3

cpu_mean_usage = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)
energy_usage = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)
RAM_energy_usage = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)

for (run in 1:nrow(data)) {
  for (rep in 1:ncol(data)) {
    num_rows = nrow(data_rq3[[run, rep]])
    
    if (is.null(num_rows)) {
      next
    }
    
    cpu_means = numeric(num_rows)
    
    for (row_id in 1:num_rows) {
      cpu_means[row_id] = mean(data_rq3[[run, rep]][row_id, cpu_columns])
    }
    cpu_mean_usage[[run, rep]] = as.list(cpu_means[-1])
    energy_values = diff(data_rq3[[run, rep]][, "PACKAGE_ENERGY..J."])
    energy_values[energy_values < 0] = energy_values[energy_values < 0] + 262144
    energy_values[energy_values > 100] = mean(energy_values[energy_values >= 0 &
                                                              energy_values <= 100])
    energy_usage[[run, rep]] = as.list(energy_values)
    
    RAM_energy_values = diff(data_rq3[[run, rep]][, "DRAM_ENERGY..J."])
    RAM_energy_values[RAM_energy_values < 0] = RAM_energy_values[RAM_energy_values < 0] + 262144
    RAM_energy_values[RAM_energy_values > 100] = mean(RAM_energy_values[RAM_energy_values >= 0 &
                                                                          RAM_energy_values <= 100])
    RAM_energy_usage[[run, rep]] = as.list(RAM_energy_values)
  }
}

# Get the energy usage from the power consumption:
for (run in 1:nrow(data)) {
  for (rep in 1:ncol(data)) {
    total_energy[[run, rep]] = sum(unlist(energy_usage[[run, rep]]))
    RAM_total_energy[[run,rep]] = sum(unlist(RAM_energy_usage[[run,rep]]))
  }
}

# Combine data to be stored in one dataframe and save it
"
Run:  |    0    |   1   |   2   |   3   |   4   |   5   |
Job:  |   dpd   |  dpd  |  dpp  |  dpp  |  pc   |  pc   |
Mode: |   seq   |  para |  seq  |  para |  seq  | para  |
"

job_types <- c("docking-protein-DNA",
               "docking-protein-protein",
               "cyclise-peptide")
modes <- c("sequential", "parallel")

df_total <- data.frame(
  JobType = character(),
  Mode = character(),
  Run = numeric(),
  AvgCPU = numeric(),
  AvgMem = numeric(),
  ExecTime = numeric(),
  TotalEnergy = numeric(),
  AvgCPUPerS = I(list()),
  EnergyPerS = I(list()),
  stringsAsFactors = FALSE
)

counter <- 1
for (job in seq_along(job_types)) {
  for (mode in seq_along(modes)) {
    for (run in 1:ncol(avg_cpu)) {
      avg_cpu_usage <- unlist(cpu_mean_usage[counter, run])
      avg_energy_usage <- unlist(energy_usage[counter, run])
      avg_cpu_usage <- avg_cpu_usage[avg_energy_usage < 1000]
      avg_energy_usage <- avg_energy_usage[avg_energy_usage < 1000]
      
      entry <- data.frame(
        JobType = job_types[job],
        Mode = modes[mode],
        Run = run,
        AvgCPU = avg_cpu[counter, run],
        AvgMem = avg_mem[counter, run],
        ExecTime = execution_time[counter, run],
        TotalEnergy = total_energy[counter, run],
        AvgCPUPerS = I(list(avg_cpu_usage)),
        EnergyPerS = I(list(avg_energy_usage))
      )
      
      df_total <- rbind(df_total, entry)
    }
    counter <- counter + 1
  }
}

# Calculate the means of CPU usage and power consumption over all repetitions

avg_cpu_all <- list()

counter = 1
for (job in seq_along(job_types)) {
  for (mode in seq_along(modes)) {
    lengths = list()
    for (i in 1:10) {
      lengths[[i]] <- length(cpu_mean_usage[[counter, i]])
    }
    min_length <- min(unlist(lengths))
    formated <- cbind(as.numeric(cpu_mean_usage[[counter, 1]])[1:min_length])
    for (i in 2:10) {
      formated <- cbind(formated, as.numeric(cpu_mean_usage[[counter, i]])[1:min_length])
    }
    
    avg_cpu_all[[paste(job_types[job], modes[mode], sep = "_")]] <- rowMeans(formated)
    
    counter = counter + 1
    
  }
}

avg_power_all <- list()

counter = 1
for (job in seq_along(job_types)) {
  for (mode in seq_along(modes)) {
    lengths = list()
    for (i in 1:10) {
      lengths[[i]] <- length(energy_usage[[counter, i]])
    }
    min_length <- min(unlist(lengths))
    formated <- cbind(as.numeric(energy_usage[[counter, 1]])[1:min_length])
    for (i in 2:10) {
      formated <- cbind(formated, as.numeric(energy_usage[[counter, i]])[1:min_length])
    }
    
    avg_power_all[[paste(job_types[job], modes[mode], sep = "_")]] <- rowMeans(formated)
    
    counter = counter + 1
    
  }
}

# Save df for RQ1 and RQ2
save(df_total, file = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/df_total.RData",
  sep = ""
))

# Save dfs for RQ3
save(cpu_mean_usage,
     file = paste(
       dirname(rstudioapi::getSourceEditorContext()$path),
       "/out/cpu_mean_usage.RData",
       sep = ""
     ))

save(energy_usage, file = paste(
  dirname(rstudioapi::getSourceEditorContext()$path),
  "/out/energy_usage.RData",
  sep = ""
))

# Save dfs for plotting
save(avg_cpu_all,
     file = paste(
       dirname(rstudioapi::getSourceEditorContext()$path),
       "/out/avg_cpu_all.RData",
       sep = ""
     ))

save(avg_power_all,
     file = paste(
       dirname(rstudioapi::getSourceEditorContext()$path),
       "/out/avg_power_all.RData",
       sep = ""
     ))

total_energy_experiment = sum(total_energy) + sum(RAM_total_energy)
total_execution_time = sum(execution_time)/(1000*60*60)
