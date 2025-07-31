# cleaning before appending ---

# needs to be refined

clean_apc_data <- function(file_path, snapshot_date) {
  raw <- tryCatch(read_excel(
    file_path, 
    sheet = 1,
    .name_repair = 'unique_quiet',
    col_names = FALSE
    ), error = function(e) return(NULL))
  if (is.null(raw)) return(NULL)

  # finds header row based on date pattern
  old_dates <- snapshot_date <= "2006-07"
  pattern <- if (old_dates) {
    "of responsibility"
  } else {
    "of responsibility code and description"
  }
  
  header_row <- which(
    apply(raw, 1, \(r) any(grepl(
      pattern, 
      r, 
      ignore.case = TRUE
      )))
  )[1]

  if (is.na(header_row)) {
    message(
      "  header row not found in: ", 
      basename(file_path)
      )
    return(NULL)
  }

  # sets column names from header row
  col_names <- raw[header_row, ] %>% 
    unlist() %>% 
    as.character()
  col_names[is.na(col_names) | col_names == ""] <- paste0(
    "unnamed_", 
    seq_along(col_names)
    )
  col_names <- make.names(col_names, unique = TRUE)

  # subset everything from header row onwards
  data <- raw[(header_row):nrow(raw), , drop = FALSE]
  names(data) <- col_names

  data <- filter(data, !if_all(everything(), ~ is.na(.) | . == ""))
  data <- mutate(data, across(everything(), as.character))
  data$snapshot_date <- snapshot_date
  return(data)
}

# merge ---

apc_merged_data <- data.frame()
file_shapes <- list()

# merges in file_log order
for (i in seq_len(nrow(file_log))) {
  snapshot_date <- file_log$snapshot_date[i]
  file_path <- file_log$file_path[i]

  message(
    "Appending file: (",
    snapshot_date,
    ") - ", 
    basename(file_path)
    )
  
  apc_data <- clean_apc_data(file_path, snapshot_date)

  if (!is.null(apc_data)) {
    apc_merged_data <- bind_rows(apc_merged_data, apc_data)
    file_shapes[[snapshot_date]] <- c(
      nrow(apc_data), 
      ncol(apc_data)
      )
  } else {
    message(
      "  skipped file: empty or failed to read"
      )
  }
}

# dimensions
summary <- data.frame(
  date = names(file_shapes),
  rows = sapply(file_shapes, `[`, 1),
  cols = sapply(file_shapes, `[`, 2),
  stringsAsFactors = FALSE
)
