library(lubridate)
library(dplyr)
library(tidyr)
library(readr)
library(rlang)

missingness_tables <- function(data, snapshot_col = "snapshot_date",
                                        prac_id_col = "PRAC_CODE",
                                        output_dir = NULL) {

  data[[snapshot_col]] <- dmy(data[[snapshot_col]])
  data$year <- year(data[[snapshot_col]])
  
  nonempty_data <- data #[, colSums(!is.na(data)) > 0]
  
  # long format, percentage of variable missing per year
  missingness_long <- nonempty_data %>%
    pivot_longer(cols = -c(!!sym(snapshot_col), year, !!sym(prac_id_col)),
                 names_to = "Variable", values_to = "value") %>%
    group_by(year, variable) %>%
    summarise(pct_missing = mean(is.na(value)) * 100, .groups = "drop")
  
  # wide format
  missingness_table <- missingness_long %>%
    mutate(year = as.numeric(year)) %>%
    pivot_wider(names_from = year, values_from = pct_missing,
                values_fill = list(pct_missing = NA)) %>%
    arrange(variable)
  
  # any fully missing values
  fully_missing <- missingness_table %>%
    filter(if_any(where(is.numeric), ~ .x == 100))
  
  # csvs
  if (!is.null(output_dir)) {
    dir.create(output_dir, showWarnings = FALSE)
    write_csv(missingness_table, file.path(output_dir, "missingness_table.csv"))
    write_csv(fully_missing, file.path(output_dir, "fully_missing_variables.csv"))
