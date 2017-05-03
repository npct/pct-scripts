# Renaming/updating data for pct-shiny

library(dplyr)

# load original data for lines
uklines_old <- readRDS("../pct-bigdata/msoa/l_nat.Rds")
names(uklines_old)
uklines_new <- readr::read_csv(file.choose())#"../pct-bigdata/pct_area.csv")
uklines_new$id <- paste(uklines_new$msoa1, uklines_new$msoa2)

names(uklines_new)

uklines = uklines_old[uklines_old$id %in% uklines_new$id,]

# # check they are the same - nope!
# plot(uklines$all, uklines_new$all)

col_missing_in_new <- !names(uklines_old) %in% names(uklines_new)[names(uklines_new) != "id"]
uklines_new <- left_join(uklines@data[col_missing_in_new], uklines_new, by= "id")

plot(uklines$all, uklines_new$all) # now they fit!
uklines@data <- uklines_new

names(uklines)
head(uklines)

saveRDS(uklines, "../pct-bigdata/msoa/l_nat_nearmkt.Rds")