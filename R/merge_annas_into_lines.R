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
# check they're the same
n = 100001 # try many values
plot(rf[n,]); plot(rq[n,], add = TRUE) # yes, good
rf_geo_id = stplanr::line2df(rf)


f = "C://Users/georl/Dropbox/PCT/xx-PCTAreaLines_TEMP/161103_PCTarealines_csv.zip"
unzip(zipfile = f)
l_anna = readr::read_csv("161103_PCTarealines_csv/pct_lines.csv")
l_anna$id <- paste(l_anna$msoa1, l_anna$msoa2)
l_nat_merged <- left_join(l_nat@data, l_anna)
l_nat@data = l_nat_merged

# test compatibility of l_nat new with old data
cor(l_nat$all, l_nat_orig$all, use = "complete.obs") # 1 = perfect fit
cor(l_nat$govtarget_slc, l_nat_orig$govtarget_slc, use = "complete.obs") # 0.9982
cor(l_nat$dutch_slc, l_nat_orig$dutch_slc, use = "complete.obs") # 0.9944
summary(l_nat@data) # 12 nas in all vars - remove them
l_nat = l_nat[!is.na(l_nat$all),]
saveRDS(l_nat, "../pct-bigdata/lines_oneway_shapes_updated.Rds")

# Merge regional data
fz = "../pct-bigdata/ukmsoas-scenarios.Rds"
ukmsoas = readRDS(fz)
z_anna = readr::read_csv("161103_PCTarealines_csv/pct_area.csv")
z_cols_keep = names(ukmsoas)[!names(ukmsoas) %in% names(z_anna)]
ukmsoas@data = ukmsoas@data[z_cols_keep][1:2]
ukmsoas@data = dplyr::rename(ukmsoas@data,
                             home_msoa = geo_code
                             )
ukmsoas@data = dplyr::inner_join(ukmsoas@data, z_anna)
ukmsoas@data = dplyr::rename(ukmsoas@data,
                                            geo_code = home_msoa,
                                            geo_label = home_msoa_name
)

names(ukmsoas)
saveRDS(ukmsoas, fz)
