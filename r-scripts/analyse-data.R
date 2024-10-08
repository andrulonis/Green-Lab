library("tidyverse")
setwd(paste(dirname(rstudioapi::getSourceEditorContext()$path), "/results-data",sep = ""))

data = matrix(vector("list", 6 * 10), nrow = 6, ncol = 10)

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
}

results = matrix(vector("list", 6 * 10), 6 * 10, nrow = 6, ncol = 10)
cpu_columns <- grep("^CPU_USAGE_", colnames(data[[1,1]]))

for (run in 1:nrow(data)) {
  for (rep in 1:ncol(data)) {
    results[[run,rep]] = list(
      total_energy = max(data[[run,rep]][,"PACKAGE_ENERGY..J."]) - min(data[[run,rep]][,"PACKAGE_ENERGY..J."]),
      execution_time = max(data[[run,rep]][,"Time"]) - min(data[[run,rep]][,"Time"]),
      avg_mem = mean(data[[run,rep]][,"USED_MEMORY"]),
      avg_cpu = mean(data[[run,rep]][,cpu_columns])
    )
  }
}
