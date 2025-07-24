library(rvest)      # web scraping
library(httr)       # http requests
library(stringr)    # string operations
library(lubridate)  # date formatting
library(readr)      # reads csvs faster
library(fs)         # for file path
library(dplyr)      # for data

# main url
base_url <- "https://digital.nhs.uk"
pub_url <- paste0(base_url, "/data-and-information/publications/statistical/general-and-personal-medical-services")
main_page <- read_html(pub_url)

# extracts all dated links
links <- main_page %>%
  html_elements("a") %>%
  html_attr("href") %>%
  unique()

date_pattern <- "^/data-and-information/publications/statistical/general-and-personal-medical-services/[0-9]{1,2}-[a-z]+-[0-9]{4}$"
dated_links <- links[!is.na(links) & str_detect(links, date_pattern)]
snapshot_dates <- basename(dated_links)

formatted_dates <- sapply(snapshot_dates, function(date_str) {
  parsed <- dmy(str_replace_all(date_str, "-", " "))
  if (is.na(parsed)) return(NA)
  format(parsed, "%d/%m/%Y")
})

publication_urls <- paste0(base_url, dated_links)
names(publication_urls) <- formatted_dates

# initialise empty dataframe
master_gp_data <- data.frame()
# stores dimensions of each file
gp_data_shape <- list()

# loop over all snapshot dates
for (target_date in names(publication_urls)) {
  message("Processing snapshot: ", target_date)
  
  snapshot_url <- publication_urls[[target_date]]
  snapshot_page <- tryCatch(read_html(snapshot_url), error = function(e) {
    message(" error: failed to read snapshot page")
    return(NULL)
  })
  if (is.null(snapshot_page)) next
  
  # finds relevant .zip file
  zip_links <- snapshot_page %>%
    html_elements("a") %>%
    html_attr("href") %>%
    str_subset("\\.zip$") %>%
    str_subset("(?i)GPW.*PracticeCSV.*") #case insensitive
  
  if (length(zip_links) == 0) { 
    message(" error: .zip file not found")
    next
  }
  
  # date info
  snapshot_date_obj <- dmy(target_date)
  target_year <- year(snapshot_date_obj)
  target_month_num <- format(snapshot_date_obj, "%m")
  target_month_name <- tolower(format(snapshot_date_obj, "%B"))
  keyword <- if (snapshot_date_obj < ymd("2023-01-30")) "general" else "detailed"
  
  gp_data <- NULL
  
  # checks all matched .zip files
  for (zip_link in zip_links) {
    zip_url <- ifelse(startsWith(zip_link, "http"), zip_link, paste0(base_url, zip_link))
    zip_filename <- basename(zip_url)
    
    download_dir <- file.path(tempdir(), paste0("gp_snapshot_", gsub("/", "-", target_date)))
    dir_create(download_dir)
    zip_path <- file.path(download_dir, zip_filename)
    
  # downloads the zip file
    tryCatch({
      download.file(zip_url, zip_path, mode = "wb", quiet = TRUE)
      unzip(zip_path, exdir = download_dir)
    }, error = function(e) {
      message(" error: download or unzip failed")
      next
    })
    
  # finds correct csv file
    csv_files <- dir(download_dir, pattern = "\\.csv$", full.names = TRUE)
    selected_csv <- csv_files[
      grepl(keyword, tolower(csv_files)) &
        grepl(target_year, csv_files) &
        (grepl(paste0("[-_]", target_month_num, "[-_]"), csv_files) |
           grepl(target_month_name, tolower(csv_files)))
    ]
    
  # reads csv file 
    if (length(selected_csv) >= 1) {
      matched_csv <- selected_csv[1]
      gp_data <- tryCatch({
        read_csv(matched_csv, show_col_types = FALSE, col_types = cols(.default = col_character()))
      }, error = function(e) {
        message(" error: failed to read csv")
        NULL
      })
      if (!is.null(gp_data)) break
    }
  }
  
  # skips date if relevant csv file not in any .zip
  if (is.null(gp_data)) {
    message(" error: no matching csv in any .zip file for this date.")
    next
  }
  
  # master dataset
  gp_data$snapshot_date <- target_date
  master_gp_data <- bind_rows(master_gp_data, gp_data)
  gp_data_shape[[target_date]] <- c(nrow(gp_data), ncol(gp_data))
 }

 # summary of dimensions
 summary <- data.frame(
  date = names(gp_data_shape),
  rows = sapply(gp_data_shape, `[`, 1),
  cols = sapply(gp_data_shape, `[`, 2)
 )

print(summary)
glimpse(master_gp_data)
