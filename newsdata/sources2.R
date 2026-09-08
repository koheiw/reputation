source("settings.R")
library(jsonlite)
library(stringi)

file <- list.files("newsdata/sources2", pattern = "\\.json", full.names = TRUE)
names(file) <- stri_match_first_regex(file, "([a-z]+)_([0-9]+)\\.json")[,2]

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
  tmp$priority <- as.numeric(tmp$priority)
  tmp$total_article <- as.integer(tmp$total_article)
  tmp <- tmp[order(tmp$priority),]
  return(tmp)
})

lis2 <- lapply(split(lis, names(lis)), function(x) {
  tmp <- do.call(rbind, x)
  tmp <- tmp[!duplicated(tmp$id),]
  tmp <- tmp[order(tmp$total_article, decreasing = TRUE),]
  rownames(tmp) <- NULL
  return(tmp)
})

readODS::write_ods(lis2, file.path(DIR_DATA, paste0("data_sources2_", Sys.Date(), ".ods")))

