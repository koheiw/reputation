source("function.R")
library(mongolite)
library(quanteda)
library(stringi)
library(jsonlite)

con <- mongo("newsdata", db = "reputation", url = URL_MONGO)

sources <- list(
  "ph" = c("inquirer",  # Philippine Daily Inquirer (liberal)
           "mb"),       # Manila Bulletin (pro-government)
  "id" = c("mediaindonesia", # Media Indonasia
           "republikain")    # Republika
)

country <- c("id")
for (u in country) {
  year <- get_years()
  dates <- get_date_range(paste0(min(year), "-01-01"), paste0(max(year), "-12-31"), unit = "month", size = 1)
  for (date in dates) {
    
    from <- date[1]
    to <- date[2]
    
    dir.create(paste0(DIR_DATA, "/corpus/", u), FALSE, TRUE)
    f <- paste0(DIR_DATA, "/corpus/", u, "/corpus_", from, "_", to, ".rds")
    if (file.exists(f)) {
      cat("Skip", u, format(from), format(to), "\n")
      next
    } else {
      cat("Export", u, format(from), format(to), "\n")
    }
    
    # TODO: remove credit, remove lists
    tmp <- con$find(sprintf('{"pubDate": {"$gte": {"$date": "%sT00:00:00Z"}, 
                                          "$lte": {"$date": "%sT23:59:59Z"}}, 
                              "source_id": {"$in": %s}}', 
                            from, to, toJSON(sources[[u]])), 
                    fields = '{"_id": 0, "id" : 1, "source_id": 1, "link": 1, 
                               "content": 1, "pubDate": 1, "title": 1}')
    
    if (!nrow(tmp)) {
      cat("No documents", u, format(from), format(to), "\n")
      next
    }
    
    tmp$content[is.na(tmp$content)] <- ""
    tmp$title[is.na(tmp$title)] <- ""

    tmp$date <- as.Date(tmp$pubDate)
    tmp$country <- rep(u, nrow(tmp))
    tmp <- tmp[order(tmp$date),]
    
    tmp$doc_id <- stri_trans_tolower(paste0(tmp[["source_id"]], "_", tmp[["id"]]))
    tmp[c("id", "pubDate")] <- NULL
    corp <- corpus(tmp, text_field = "content")
    
    saveRDS(corp, f)
  }
}

con$disconnect()
