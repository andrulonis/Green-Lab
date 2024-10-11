library("tidyverse")
setwd(paste(dirname(rstudioapi::getSourceEditorContext()$path), "/results-data",sep = ""))
options(digits = 22)

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
    if (!is.null(data[[seq_run, rep]]) && nrow(data[[seq_run, rep]]) > 0) {
      data_rq3[[seq_run, rep]] <- data[[seq_run, rep]][order(data[[seq_run, rep]][, "Time"]), ]
    }
  }
}

total_energy = matrix(NA, 6 * 10, nrow = 6, ncol = 10)
execution_time = matrix(NA, 6 * 10, nrow = 6, ncol = 10)
avg_mem = matrix(NA, 6 * 10, nrow = 6, ncol = 10)
avg_cpu = matrix(NA, 6 * 10, nrow = 6, ncol = 10)

cpu_columns <- grep("^CPU_USAGE_", colnames(data[[1,1]]))

for (run in 1:nrow(data)) {
  for (rep in 1:ncol(data)) {
      total_energy[[run,rep]] = max(data[[run,rep]][,"PACKAGE_ENERGY..J."]) - min(data[[run,rep]][,"PACKAGE_ENERGY..J."])
      execution_time[[run,rep]] = max(data[[run,rep]][,"Time"]) - min(data[[run,rep]][,"Time"])
      avg_mem[[run,rep]] = mean(data[[run,rep]][,"USED_MEMORY"])
      avg_cpu[[run,rep]] = mean(data[[run,rep]][,cpu_columns])
  }
}

cpu_mean_usage = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)
energy_usage = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)

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
      cpu_mean_usage[[run,rep]] = as.list(cpu_means)
      energy_usage[[run,rep]] = as.list(data_rq3[[run,rep]][,"PACKAGE_ENERGY..J."])
  }
}
