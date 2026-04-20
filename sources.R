source("settings.R")
library(jsonlite)

file <- list.files("sources", pattern = ".json", full.names = TRUE)
names(file) <- stri_match_first_regex(file, "/(.*)\\.json")[,2]

lis <- lapply(file, function(f) {
  col <- c("id", "name", "url", "icon", "priority", "description", "category",  
           "language", "country", "total_article", "last_fetch")
  tmp <- read_json(f, simplifyVector = TRUE)[col]
  tmp[] <- sapply(tmp, function(x) {
    if (is.list(x)) {
      sapply(x, paste0, collapse = ", ")
    } else {
      x
    }
  })
  return(tmp)
})

readODS::write_ods(lis, "sources/data_sources.ods")

