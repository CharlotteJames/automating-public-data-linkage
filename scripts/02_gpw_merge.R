master_gp_data <- data.frame()
gp_data_shape <- list()

# merges in order listed in file_log
for (i in seq_len(nrow(file_log))) {
  snapshot_date <- file_log$snapshot_date[i]
  csv_file <- file_log$file_path[i]
  
  message(
    "Appending CSV: (", snapshot_date, ") - ", 
    basename(csv_file)
    )
  
  gp_data <- tryCatch({
    read_csv(
      csv_file, 
      show_col_types = FALSE, 
      col_types = cols(.default = col_character())
      )
  }, error = function(e) {
    message(
      "  error reading CSV: ", 
      csv_file
      )
    return(NULL)
  })
  
  if (!is.null(gp_data)) {
  gp_data$snapshot_date <- snapshot_date
    master_gp_data <- bind_rows(
      master_gp_data, 
      gp_data
      )
    gp_data_shape[[snapshot_date]] <- c(
      nrow(gp_data), 
      ncol(gp_data)
      )
  }
}

# summary of rows and columns per snapshot
summary <- data.frame(
  date = names(gp_data_shape),
  rows = sapply(gp_data_shape, `[`, 1),
  cols = sapply(gp_data_shape, `[`, 2)
)
