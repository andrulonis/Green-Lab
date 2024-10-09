library("tidyverse")
setwd(paste(dirname(rstudioapi::getSourceEditorContext()$path), "/results-data",sep = ""))
options(digits = 22)

data = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)
results_rq3 = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)

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
  if (is.null(results_rq3[[row, col]]) && row %% 2 == 0) {
    results_rq3[[row, col]] = csv_data
  }
}

for (seq_run in seq(from = 1, to = 5, by = 2)) {
  for (rep in 1:ncol(data)) {
    if (!is.null(data[[seq_run, rep]]) && nrow(data[[seq_run, rep]]) > 0) {
      data[[seq_run, rep]] <- data[[seq_run, rep]][order(data[[seq_run, rep]][, "Time"]), ]
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

for (run in 1:nrow(data)) {
  for (rep in 1:ncol(data)) {
    if (run %% 2 != 0) {
      for (row in data[[run,rep]]) {
        #TODO: FIX THOSE MEANS
        results_rq3[[run,rep]][[1]] = results_rq3[[run,rep]][[1]] + mean(row[cpu_columns])
        results_rq3[[run,rep]][[2]] = results_rq3[[run,rep]][[2]] + row["PACKAGE_ENERGY..J."]
      }
    } else {
      results_rq3[[run,rep]] = list(results_rq3[[run,rep]][,mean(cpu_columns)], results_rq3[[run,rep]][,"PACKAGE_ENERGY..J."])
    }
    #for (energy in length(results_rq3[[run,rep]][2]:2)) {
    #  results_rq3[[run,rep]][[2]][[energy]] = results_rq3[[run,rep]][[2]][[energy]] - results_rq3[[run,rep]][[2]][[energy-1]]
    #}
  }
}
