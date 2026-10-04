source("function.R")
library(quanteda)
library(wordvector)
library(GMTM)
library(AWE)

dir_sub <- "gmtm"

get_terms <- function(x, words = NULL) {
  prob <- probability(x)
  if (!is.null(words)) 
    prob <- prob[words,,drop = FALSE]
  term <- apply(prob, 2, function(x) rownames(prob)[order(x, decreasing = TRUE)])
  colnames(term) <- x$label
  head(term, 10)
}

get_topics <- function(x, data, words = NULL) {
  prob <- probability(x)
  if (!is.null(words)) 
    prob <- prob[words,,drop = FALSE]
  temp <- dfm_match(data, rownames(prob))
  factor(x$label[max.col(temp %*% prob)], levels = x$label)
}

year <- get_years()
dates <- get_date_window(paste0(min(year), "-01-01"), paste0(max(year), "-12-31"), size = 1)
dates <- list(as.Date(c("2026-08-01", "2026-08-31")))
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
  
  #e <- paste0(DIR_RESULT, "/awe/", from, "_", to)
  e <- paste0(DIR_RESULT, "/awe/2025-09-01_2026-08-31")
  
  wov_ph <- readRDS(file.path(e, "word2vec_en_ph_k150.rds"))
  dov_ph <- load_tokens(from, to, "ph") |>
      as.textmodel_doc2vec(wov_ph)
  
  wov_id <- readRDS(file.path(e, "word2vec_id_id_k150.rds"))
  dov_id <- load_tokens(from, to, "id") |>
    as.textmodel_doc2vec(wov_id)
  
  wov_my <- readRDS(file.path(e, "word2vec_ms_my_k150.rds"))
  dov_my <- load_tokens(from, to, "my") |>
    as.textmodel_doc2vec(wov_my)
  
  wov_vn <- readRDS(file.path(e, "word2vec_vi_vn_k150.rds"))
  dov_vn <- load_tokens(from, to, "vn") |>
    as.textmodel_doc2vec(wov_vn)
  
  wov_cn <- readRDS(file.path(e, "word2vec_zh_cn_k150.rds"))
  dov_cn <- load_tokens(from, to, "cn") |>
    as.textmodel_doc2vec(wov_cn)
  
  
  dfmt_ph <- dfm(load_tokens(from, to, "ph"))
  dfmt_id <- dfm(load_tokens(from, to, "id"))
  dfmt_my <- dfm(load_tokens(from, to, "my"))
  dfmt_vn <- dfm(load_tokens(from, to, "vn"))
  dfmt_cn <- dfm(load_tokens(from, to, "cn"))
  
  wov <- rbind(wov_ph, wov_id, wov_my, wov_vn, wov_cn)
  gmm <- textmodel_gmm(wov$values$word, k = 50, verbose = TRUE)
  
  gmm$terms <- list(
    ph = get_terms(gmm, names(wov_ph$frequency)),
    id = get_terms(gmm, names(wov_id$frequency)),
    my = get_terms(gmm, names(wov_my$frequency)),
    vn = get_terms(gmm, names(wov_vn$frequency)),
    cn = get_terms(gmm, names(wov_cn$frequency))
  )
  
  term <- sapply(gmm$terms, function(x) apply(x, 2, paste, collapse = ", "))
  readODS::write_ods(as.data.frame.matrix(term), row_names = TRUE,
                     path = file.path(DIR_RESULT, "/awe/data_terms.ods"))
  
  dfmt <- rbind(dfmt_ph, dfmt_id, dfmt_my, dfmt_vn, dfmt_cn)
  dat <- data.frame(docvars(dfmt),
                    topic = get_topics(gmm, dfmt))
  
  dict <- dictionary(file = "../dilemma2/dictionary_en.yml")
  lss <- LSX::as.textmodel_lss(wov, dict$seedwords$threat$threat, spatial = TRUE)
  dat$lss <- predict(lss, dfmt)
  
  (tb <- table(dat$topic, dat$country))
  proportions(tb, 2)
  
  save(dat, lss, gmm, file = file.path(DIR_RESULT, "/awe/gmm-lss.rda"))
  
  stop()

}
