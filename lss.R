source("function.R")
library(quanteda)
library(wordvector)
library(GMTM)
library(AWE)

dir_sub <- "lss"

year <- get_years()
year <- 2025:2026
dates <- get_date_window(paste0(min(year), "-01-01"), paste0(max(year), "-12-31"), size = 1)
for (date in dates) {
  
  from <- date[1]
  to <- date[2]
  
  
  f <- paste0(DIR_RESULT, "/", dir_sub , "/data_", from, "_", to)
  dir.create(file.path(DIR_RESULT, dir_sub), FALSE, TRUE)
  # if (dir.exists(f)) {
  #   print_log("Skip", format(from), format(to))
  #   next
  # } else {
    print_log("Fit", format(from), format(to))
  #}
  
  #e <- paste0(DIR_RESULT, "/awe/", from, "_", to)
  d <- paste0(DIR_RESULT, "/awe/2025-09-01_2026-08-31")
  
  wov_ph <- readRDS(file.path(d, "word2vec_en_ph_k150.rds"))
  dov_ph <- load_tokens(from, to, "ph") |>
      as.textmodel_doc2vec(wov_ph)
  
  wov_id <- readRDS(file.path(d, "word2vec_id_id_k150.rds"))
  dov_id <- load_tokens(from, to, "id") |>
    as.textmodel_doc2vec(wov_id)
  
  wov_my <- readRDS(file.path(d, "word2vec_ms_my_k150.rds"))
  dov_my <- load_tokens(from, to, "my") |>
    as.textmodel_doc2vec(wov_my)
  
  wov_vn <- readRDS(file.path(d, "word2vec_vi_vn_k150.rds"))
  dov_vn <- load_tokens(from, to, "vn") |>
    as.textmodel_doc2vec(wov_vn)
  
  wov_cn <- readRDS(file.path(d, "word2vec_zh_cn_k150.rds"))
  dov_cn <- load_tokens(from, to, "cn") |>
    as.textmodel_doc2vec(wov_cn)
  
  dfmt_ph <- dfm(load_tokens(from, to, "ph"))
  dfmt_id <- dfm(load_tokens(from, to, "id"))
  dfmt_my <- dfm(load_tokens(from, to, "my"))
  dfmt_vn <- dfm(load_tokens(from, to, "vn"))
  dfmt_cn <- dfm(load_tokens(from, to, "cn"))
  
  wov <- rbind(wov_ph, wov_id, wov_my, wov_vn, wov_cn)
  dict <- dictionary(file = "../dilemma2/dictionary_en.yml")
  lss <- LSX::as.textmodel_lss(wov, dict$seedwords$threat$threat, spatial = TRUE)
  
  dfmt <- rbind(dfmt_ph, dfmt_id, dfmt_my, dfmt_vn, dfmt_cn)
  dat <- data.frame(docvars(dfmt),
                    lss = predict(lss, dfmt, rescale = FALSE))

  saveRDS(lss, paste0(DIR_RESULT, "/", dir_sub , "/lss_", from, "_", to))
  saveRDS(dat, f)

}
