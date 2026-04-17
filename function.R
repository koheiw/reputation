source("settings.R")
require(stringi)
require(lubridate)

get_years <- function() {
  return(2025:2025)
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