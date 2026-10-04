# use Probabilistic LSS with while keeping unigrams
source("function.R")
library(quanteda)
library(wordvector)
library(AWE)

dir_sub <- "awe"

year <- get_years()
dates <- get_date_window(paste0(min(year), "-01-01"), paste0(max(year), "-12-31"), size = 12)
#dates <- list(as.Date(c("2025-09-01", "2026-08-31")))
dates <- list(as.Date(c("2025-09-01", "2026-08-31")),
              as.Date(c("2024-09-01", "2025-08-31")))
for (date in dates) {
  
  from <- date[1]
  to <- date[2]
  
  
  d <- paste0(DIR_RESULT, "/", dir_sub , "/", from, "_", to)
  # if (dir.exists(d)) {
  #   print_log("Skip", format(from), format(to))
  #   next
  # } else {
    print_log("Fit", format(from), format(to))
  #}
  
  load_tokens(from, to, "ph") |>
    tokens_select("^\\p{Latin}+$", valuetype = "regex") |>
    prep_data(data_anchors_topics$en, lang = "en_ph", dir = d, dim = 150)

  load_tokens(from, to, "id") |>
    tokens_select("^\\p{Latin}+$", valuetype = "regex") |>
    prep_data(data_anchors_topics$id, lang = "id_id", dir = d, dim = 150)

  load_tokens(from, to, "my") |>
    tokens_select("^\\p{Latin}+$", valuetype = "regex") |>
    prep_data(data_anchors_topics$ms, lang = "ms_my", dir = d, dim = 150)

  load_tokens(from, to, "vn") |>
    tokens_select("^\\p{Latin}+$", valuetype = "regex") |>
    prep_data(data_anchors_topics$vi, lang = "vi_vn", dir = d, dim = 150)

  load_tokens(from, to, "cn") |>
    tokens_select("^\\p{Han}+$", valuetype = "regex") |>
    prep_data(data_anchors_topics$zh_cn, lang = "zh_cn", dir = d, dim = 150)
  
  train_models(c("en_ph", "id_id", "ms_my", "vi_vn", "zh_cn"), dir = d, dim = 150)
  
}
