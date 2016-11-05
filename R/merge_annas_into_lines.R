# Merge Anna's data into the lines data
# This code takes in the the national data of lines and routes produced by malcolm
# and the scenario data produced by anna
# it joins them together asuming that anna has the right data
# is then save out the result overwriting the original l_nat file

library(dplyr)
l_nat_orig <- readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
data_to_keep = data.frame(l_nat_orig@data["id"])
l_nat = l_nat_orig
l_nat@data = l_nat_orig@data[c("id", "is_two_way", "dist")]

# Add new lines
rf <- readRDS("../pct-bigdata/rf_nat.Rds")
rq <- readRDS("../pct-bigdata/rq_nat.Rds")
f = "C://Users/georl/Dropbox/PCT/xx-PCTAreaLines_TEMP/161103_PCTarealines_csv.zip"
unzip(zipfile = f)
l_anna = readr::read_csv("161103_PCTarealines_csv/pct_lines.csv")
l_anna$id <- paste(l_anna$msoa1, l_anna$msoa2)
l_nat_merged <- left_join(l_nat@data, l_anna)
l_nat_orig@data = l_nat_merged

not_in_annas_data <- l_nat_merged[is.na(l_nat_merged$ebike_siw), ] # need to ask Anna why...
in_annas_not_in_nat <- left_join(l_anna_eng, l_nat@data, by = c("id" = "id"))
in_annas_not_in_nat <- in_annas_not_in_nat[is.na(in_annas_not_in_nat$is_two_way), ] # empty, we have it all
to_drop <- !is.na(l_nat_merged$ebike_siw) # rows not in Anna's
l_nat <- l_nat[to_drop, ]
l_nat@data <- l_nat_merged[to_drop, ]
rf@data <- rf[to_drop, ]
rq@data <- rq[to_drop, ]

# save output
saveRDS(l_nat_orig, file.path("..", "pct-bigdata", "l_nat.Rds"))
write.csv(not_in_annas_data, file = "../pct-bigdata/not_in_annas_data.csv")
