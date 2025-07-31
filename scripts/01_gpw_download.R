# ---
# uses the general practice workforce dataset
# the 07/2022 page contains two.zip files with historical data
# assigns snapshot date to .csv files for dates prior to 07/2022
# ---


# url scraping ---

# base and publication urls
base_url <- "https://digital.nhs.uk"
pub_url <- paste0(
  base_url, 
  "/data-and-information/publications/statistical/general-and-personal-medical-services"
  )
main_page <- read_html(pub_url)

# extracts dated snapshot links
links <- main_page %>%
  html_elements("a") %>%
  html_attr("href") %>%
  unique()

date_pattern <- "^/data-and-information/publications/statistical/general-and-personal-medical-services/[0-9]{1,2}-[a-z]+-[0-9]{4}$"
dated_links <- links[
  !is.na(links) & 
    str_detect(links, date_pattern)
  ]
snapshot_dates <- basename(dated_links)

formatted_dates <- sapply(
  snapshot_dates, 
  function(date_str) {
  parsed <- dmy(str_replace_all(date_str, "-", " "))
  if (is.na(parsed)) return(NA)
  format(parsed, "%d/%m/%Y")
  }
  )

publication_urls <- paste0(
  base_url, 
  dated_links
  )
names(publication_urls) <- formatted_dates

# initialise
file_log <- data.frame(snapshot_date = character(), 
                           file_path = character(), 
                           stringsAsFactors = FALSE
                           )

skip_dates <- character(0)

# loops through each snapshot date
# if any date is repeated from the 07/2022 snapshot, skips

for (target_date in names(publication_urls)) {
  if (target_date %in% skip_dates && target_date != "31/07/2022") 
    next
  message(
    "Processing snapshot: ", 
    target_date
    )
  
  snapshot_url <- publication_urls[[target_date]]
  snapshot_page <- tryCatch(
    read_html(snapshot_url), 
    error = function(e) {
    message(
      "  error: failed to read snapshot page"
      )
    return(NULL)
  }
  )
  if (is.null(snapshot_page)) 
    next
  
  # finds relevant zip links
  
  zip_links <- snapshot_page %>%
    html_elements("a") %>%
    html_attr("href") %>%
    str_subset("\\.zip$") %>%
    str_subset("(?i)GPW.*Practice.*")
  
  if (length(zip_links) == 0) {
    message(
      "  error: .zip file not found"
      )
    next
  }
  
  snapshot_date_obj <- dmy(target_date)
  keyword <- if (snapshot_date_obj < ymd("2023-01-30")) 
    "general" else "detailed"
  
  # downloading files ---
  
  # 07/2022 case
  
  if (target_date == "31/07/2022") {
    all_csvs <- list()
    
    for (zip_link in zip_links) {
      zip_url <- ifelse(
        startsWith(zip_link, "http"), 
        zip_link, paste0(
          base_url, 
          zip_link
          )
        )
      zip_filename <- basename(zip_url)
      
      download_dir <- file.path(
        tempdir(), paste0(
          "gp_snapshot_", 
          gsub("/", "-", target_date)
          )
        )
      dir_create(download_dir)
      zip_path <- file.path(download_dir, zip_filename)
      
      tryCatch({
        download.file(
          zip_url, 
          zip_path, 
          mode = "wb", 
          quiet = TRUE
          )
        unzip(
          zip_path, 
          exdir = download_dir
          )
      }, error = function(e) {
        message(
          "  error: download or unzip failed"
          )
        next
      })
      
      csv_files <- dir(
        download_dir, 
        pattern = "\\.csv$", 
        full.names = TRUE
        )
      selected_csv <- csv_files[
        grepl(keyword, 
              tolower(csv_files)
              ) &
          !grepl("definition|metadata", 
                 tolower(csv_files)
                 )
        ]
      
      for (csv_path in selected_csv) {
        file_lower <- tolower(basename(csv_path))
        month_str <- str_extract(
          file_lower, 
          paste(tolower(month.name), 
                collapse = "|"
                ))
        
        year_str <- str_extract(
          file_lower, 
          "\\b20[1-9][0-9]\\b"
          )
        
        if (!is.na(month_str) && !is.na(year_str)) {
          parsed <- suppressWarnings(dmy(paste(
            "01", 
            month_str, 
            year_str)
            ))
          if (!is.na(parsed)) {
            snapshot <- format(ceiling_date(parsed, "month") - days(1),
                               "%d/%m/%Y"
                               )
            
            all_csvs[[snapshot]] <- csv_path
          }}}}
    
    # orders csv files
    ordered_snapshots <- names(all_csvs)[order(dmy(
      names(all_csvs)), 
      decreasing = TRUE
      )]

  for (snapshot in ordered_snapshots) {
  csv_file <- all_csvs[[snapshot]]
  message(
    "  - Extracted CSV: (", snapshot, ") - ", 
    basename(csv_file)
    )
  file_log <- rbind(
    file_log, data.frame(
      snapshot_date = snapshot, 
      file_path = csv_file, 
      stringsAsFactors = FALSE
    ))
  }
    
    skip_dates <- c(skip_dates, names(all_csvs))
    next
  }
  
 # for all other snapshot dates ---
  
 all_csvs_for_date <- list() 
 
  for (zip_link in zip_links) {
    zip_url <- ifelse(
      startsWith(zip_link, "http"), 
      zip_link, 
      paste0(
        base_url, 
        zip_link
        ))
    
    zip_filename <- basename(zip_url)
    
    download_dir <- file.path(
      tempdir(), paste0(
        "gp_snapshot_", 
        gsub("/", "-", target_date)
        ))
    
    dir_create(download_dir)
    zip_path <- file.path(download_dir, zip_filename)
    
    tryCatch({
      download.file(
        zip_url, 
        zip_path, 
        mode = "wb", 
        quiet = TRUE
        )
      unzip(
        zip_path, 
        exdir = download_dir
        )
    }, error = function(e) {
      message(
        "  error: download or unzip failed"
        )
      next
    })
    
    csv_files <- dir(
      download_dir, 
      pattern = "\\.csv$", 
      full.names = TRUE
      )
    selected_csvs <- csv_files[
      grepl(keyword, tolower(csv_files)) &
        grepl(year(snapshot_date_obj), csv_files) &
        (grepl(paste0(
          "[-_]", 
          format(snapshot_date_obj, 
                 "%m"
                 ), 
          "[-_]"
          ), 
          csv_files) |
         grepl(format(snapshot_date_obj, "%B"), 
               tolower(csv_files)
               )) &
        !grepl("definition|metadata", 
               tolower(csv_files)
               )
    ]
  
if (length(selected_csvs) > 0) {
  for (csv_path in selected_csvs) {
    message(
      "  - Extracted CSV: ", 
      basename(csv_path)
      )
    all_csvs_for_date <- c(all_csvs_for_date, csv_path)
    file_log <- rbind(file_log, data.frame(
      snapshot_date = target_date, 
      file_path = csv_path, 
      stringsAsFactors = FALSE
      ))
  }}
  }
 }
