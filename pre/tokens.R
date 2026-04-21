source("function.R")
require(quanteda)

country <- c("id")
for (u in country) {
  year <- get_years()
  dates <- get_date_range(paste0(min(year), "-01-01"), paste0(max(year), "-12-31"), unit = "month", size = 1)
  for (date in dates) {
    
    from <- date[1]
    to <- date[2]
    
    dir.create(paste0(DIR_DATA, "/tokens/", u), FALSE, TRUE)
    f <- paste0(DIR_DATA, "/corpus/" , u, "/corpus_", from, "_", to, ".rds")
    g <- paste0(DIR_DATA, "/tokens/", u, "/tokens_", from, "_", to, ".rds")
    if (!file.exists(f) || file.exists(g)) {
      cat("Skip", u, format(from), format(to), "\n")
      next
    } else {
      cat("Tokenize", u, format(from), format(to), "\n")
    }
    corp <- readRDS(f)
    
    corp <- corp |>
      corpus_reshape("sentences")
    
    # # remove credit
    # corp[] <- stri_replace_last_regex(corp[], "(Copyright|\\(c\\)|\\u00A9)\\s?\\d{4}.*$", " ") 
    # # remove horizontal lines
    # corp[] <- stri_replace_all_regex(corp[], "[\\u2025\\u2026]+", " ") 
    # # remove HTML special character
    # corp[] <- stri_replace_all_regex(corp[], "&[a-z]+?;", " ") # &amp; &quot;
    # # remove caption
    # corp[] <- stri_replace_all_regex(corp[], "\\[caption .*?\\].*?\\[\\/caption\\]", " ")
    # 
    toks <- tokens(corp, split_hyphens = TRUE, normalize = TRUE,
                   concatenator = " ")
    # 
    # # measure noise
    # s <- ntoken(tokens_select(toks, stopwords("en")))
    # toks$noise <- ave(s == 0, docid(toks), FUN = mean) # prop. of non-syntactical sentences
    # cat(sprintf("Save %d documents (%.2f%% noise)\n", sum(toks$noise < 0.5), mean(toks$noise > 0.5) * 100))
	
    saveRDS(toks, g)
  }
}

