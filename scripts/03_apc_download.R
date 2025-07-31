

# ---
# uses the admitted patient care dataset
# .xls / .xlsx files instead of .zip files
# ---


# url scraping ---

# base and publication urls
base_url <- "https://digital.nhs.uk"
pub_url <- paste0(
  base_url, 
  "/data-and-information/publications/statistical/hospital-admitted-patient-care-activity"
  )
main_page <- read_html(pub_url)

# extracts dated snapshot links
links <- main_page %>%
  html_elements("a") %>%
  html_attr("href") %>%
  unique()

date_pattern <- "/data-and-information/publications/statistical/hospital-admitted-patient-care-activity/.+[0-9]{2,4}-[0-9]{2}"
dated_links <- links[
  !is.na(links) & 
    str_detect(links, date_pattern)
  ]

url_endings <- basename(dated_links)

# for consistency in snapshot dates
extract_snapshot <- function(text) {
  match <- str_extract(text, "\\b[12][0-9]{3}-[0-9]{2}\\b")
  return(ifelse(
    is.na(match), 
    NA, 
    match
    ))
}

snapshot_dates <- sapply(url_endings, extract_snapshot)

# filters out any invalid entries
 valid_entries <- which(!is.na(snapshot_dates))
 dated_links <- dated_links[valid_entries]
 snapshot_dates <- snapshot_dates[valid_entries]

# constructs full urls
publication_urls <- paste0(
  base_url, 
  dated_links
  )
names(publication_urls) <- snapshot_dates

# log to track downloaded files
file_log <- data.frame(
  snapshot_date = character(),
  file_path = character(),
  stringsAsFactors = FALSE
)

for (snapshot_date in snapshot_dates) {
  message(
    "Processing snapshot: ", 
    snapshot_date
    )
  snapshot_url <- publication_urls[[snapshot_date]]

  snapshot_page <- tryCatch(
    read_html(snapshot_url), 
    error = function(e) {
    message(
      "  error: could not read snapshot page"
      )
    return(NULL)
  })
  if (is.null(snapshot_page)) next

  # downloading files ---  
  
  file_links <- snapshot_page %>%
    html_elements("a") %>%
    html_attr("href") %>%
    str_subset("\\.xls[x]?$") %>%
    str_subset("resp") 

  if (length(file_links) == 0) {
    message(
      "  error: no relevant .xls/.xlsx files found for this snapshot"
      )
    next
  }

  for (link in file_links) {
    file_url <- ifelse(
      str_starts(link, "http"), 
      link, 
      paste0(base_url, link)
      )
    file_name <- basename(file_url)
    download_dir <- file.path(
      tempdir(), 
      paste0("apc_snapshot_", snapshot_date)
      )
    dir_create(download_dir)
    file_path <- file.path(download_dir, file_name)

    message("  - Downloaded file: ", file_name)

    tryCatch({
      GET(
        file_url, 
        write_disk(file_path, overwrite = TRUE), 
        timeout(60)
        )
    }, error = function(e) {
      message(" error: failed to download file")
      next
    })
  }
    
    # records file in log
    file_log <- bind_rows(file_log, data.frame(
      snapshot_date = snapshot_date,
      file_path = file_path,
      stringsAsFactors = FALSE
    ))
  }
