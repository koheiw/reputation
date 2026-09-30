source("settings.R")
require(stringi)
require(lubridate)

lang <- c("persian" = "fa",
  "arabic"  = "ar",
  "english" = "en",
  "central kurdish" = "ku",
  "turkish" = "tr",
  "urdu" = "ur")

get_years <- function() {
  return(2024:2026)
}

get_languages <- function(source = "factiva") {
  return("en")
}

write_log <- function(status, message = "", file = "test.log", reset = FALSE, stdout = TRUE) {
  file <- paste0(DIR_LOG, "/" , file)
  ex <- filelock::lock(file)
  cat(format(Sys.time()), status, message, "\n", file = file, append = !reset)
  if (stdout)
    cat(format(Sys.time()), status, message, "\n")
  filelock::unlock(ex)
}

get_date_range <- function(from, to, size = 1, unit = c('year', 'month', 'week', 'day')) {
  
  unit <- match.arg(unit)
  
  from <- as.Date(from)
  to <- as.Date(to)
  date <- seq.Date(from, to, by = 1)
  if (unit == 'day') {
    index <- format(date, "%Y%m%d")
  } else if (unit == 'week') {
    index <- format(date, '%Y%U')
  } else if (unit == 'month') {
    index <- format(date, '%Y%m')
  } else if (unit == 'year') {
    index <- format(date, '%Y')
  }
  
  index <- as.integer(factor(index))
  dates <- lapply(split(date, ceiling(index / size)), range)
  names(dates) <- NULL
  return(dates)
}

get_date_window <- function(from, to, size = 12) {
  r <- get_date_range(from, to, size = 1, unit = "month")
  lis <- lapply(seq_along(r), function(x) r[seq(x, min(length(r), x + size - 1))])
  lis <- lis[lengths(lis) == size]
  lis <- lapply(lis, function(x) c(x[[1]][1], x[[length(x)]][2]))
  return(lis)
}

get_language <- function(country) {
  c("ph" = "en", 
    "my" = "ms", 
    "id" = "id",
    "vn" = "vi",
    "us" = "en",
    "cn" = "zh")[country]
}

load_tokens <- function(from, to, country = "gb", dir = "tokens", sample = 1.0, segment = TRUE) {
  
  dates <- get_date_range("1977-01-01", "2050-12-31", unit = "month", size = 1) 
  lang <- get_language(country)
  conc <- ifelse(lang %in% c("zh", "ja"), "", " ")
  toks <- as.tokens_xptr(as.tokens(list(), concatenator = conc))
  for (date in dates) {
    if (from <= date[2] && date[1] <= to) {
      f <- paste0(DIR_DATA, "/", dir, "/", country, "/tokens_", date[1], "_", date[2] ,".rds")
      if (file.exists(f)) {
        message(sprintf("Load tokens %s from %s to %s in %s", country, date[1], date[2], dir))
      } else {
        message(sprintf("Cannot not load tokens %s from %s to %s in %s", country, date[1], date[2], dir))
        next
      }
      tmp <- as.tokens_xptr(readRDS(f))
      if (sample < 1.0) {
        set.seed(1234)
        id <- levels(docid(tmp))
        tmp <- tokens_subset(tmp, docid_ %in% sample(id, length(id) * sample))
      } 
      toks <- c(toks, tmp)
    }
  }
  if (segment)
    toks <- tokens_segment(toks, c(".", "?", "!"), valuetype = "fixed",
                           extract_pattern = FALSE, pattern_position = "after")
  
  return(toks)
}

print_log <- function(status, ...) {
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), status, ..., "\n")
}