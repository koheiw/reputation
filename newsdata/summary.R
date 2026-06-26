source("function.R")
require(mongolite)
require(jsonlite)

con <- mongo("newsdata", db = "reputation", url = URL_MONGO)

tmp <- con$aggregate('[{"$addFields": {"year": {"$year": "$pubDate"}}},
                       {"$group": {"_id": {"source_id": "$source_id", "year": "$year"},
                                   "total": {"$sum": 1}}}]')
dat <- cbind(tmp[["_id"]], tmp[,"total", drop = FALSE])

saveRDS(dat, paste0(DIR_DATA, "/corpus/data_summary.rds"))

con$disconnect()
