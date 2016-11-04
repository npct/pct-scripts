# Merge Anna's data into the lines data
# This code takes in the the national data of lines and routes produced by malcolm
# and the scenario data produced by anna
# it joins them together asuming that anna has the right data
# is then save out the result overwriting the original l_nat file

require(dplyr)
l_nat <- readRDS(file.path("..", "pct-bigdata", "l_nat_noScens.Rds")) # without scinario data
rf <- readRDS(file.path("..", "pct-bigdata", "rf_nat.Rds"))
rq <- readRDS(file.path("..", "pct-bigdata", "rq_nat.Rds"))
l_anna = read.csv(file = "D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/xx-PCTAreaLines_TEMP/161103_PCTarealines_csv/pct_lines.csv")


l_anna_eng <- l_anna[grepl("E\\d{8}", l_anna$msoa1) & grepl("E\\d{8}", l_anna$msoa2),]
l_anna_eng$id <- paste(l_anna_eng$msoa1, l_anna_eng$msoa2)
duplicated_idx = names(l_nat) %in% names(l_anna_eng)

id <- paste(l_nat$msoa1, l_nat$msoa2)
l_nat@data <- l_nat@data[!duplicated_idx]
l_nat$id <- id

l_nat_merged <- left_join(l_nat@data, l_anna_eng, by = c("id" = "id"))

not_in_annas_data <- l_nat_merged[is.na(l_nat_merged$ebike_siw), ] # need to ask Anna why...

in_annas_not_in_nat <- left_join(l_anna_eng, l_nat@data, by = c("id" = "id"))
in_annas_not_in_nat <- in_annas_not_in_nat[is.na(in_annas_not_in_nat$is_two_way), ] # empty, we have it all

to_drop <- !is.na(l_nat_merged$ebike_siw) # rows not in Anna's
l_nat <- l_nat[to_drop, ]
l_nat@data <- l_nat_merged[to_drop, ]
rf@data <- rf[to_drop, ]
rq@data <- rq[to_drop, ]

saveRDS(l_nat, file.path("..", "pct-bigdata", "l_nat.Rds"))
write.csv(not_in_annas_data, file = "../pct-bigdata/not_in_annas_data.csv")
