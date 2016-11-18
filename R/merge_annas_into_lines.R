# Merge Anna's data into the lines data
# This code takes in the the national data of lines and routes produced by malcolm
# and the scenario data produced by anna
# it joins them together asuming that anna has the right data
# is then save out the result overwriting the original l_nat file

library(dplyr)
path_to_routes <- "D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/ToNatBuild/"
l_nat <- readRDS(file.path(path_to_routes, "lines_allonefile.Rds"))
l_nat@data = l_nat@data[c("id", "is_two_way", "dist")]

# Add new lines

rf <- readRDS(file.path(path_to_routes, "rf_allonefile_withIDandANNA.Rds"))
rq <- readRDS(file.path(path_to_routes, "rq_allonefile_withIDandANNA_rf.Rds"))
# check they're the same
n = 76576 # try many values
plot(rf[n,]); plot(rq[n,], add = TRUE); plot(l_nat[n,], add = TRUE)# yes, good

path_to_dropbox <- "C://Users/georl/Dropbox"
f = file.path(path_to_dropbox, "PCT/xx-PCTAreaLines_TEMP/161103_PCTarealines_csv.zip")
unzip(zipfile = f)
l_anna = readr::read_csv("161103_PCTarealines_csv/pct_lines.csv")
l_anna$id <- paste(pmin(l_anna$msoa1, l_anna$msoa2), pmax(l_anna$msoa1, l_anna$msoa2))
l_nat$id <- paste(pmin(l_nat$msoa1, l_nat$msoa2), pmax(l_nat$msoa1, l_nat$msoa2))
l_nat_merged <- left_join(l_nat@data, l_anna, by = "id")
l_nat@data = l_nat_merged

# Remove flows without scenario data
l_nat <- l_nat[!is.na(l_nat@data$govtarget_slc),]
rf <- rf[!is.na(l_nat@data$govtarget_slc),]
rq <- rq[!is.na(l_nat@data$govtarget_slc),]

l_nat@data = dplyr::rename(l_nat@data,
                            all = all.y,
                            msoa1 = msoa1.y,
                            msoa2 = msoa2.y,
                            light_rail = light_rail.y,
                            train = train.y,
                            bus = bus.y,
                            taxi = taxi.y,
                            motorbike = motorbike.y,
                            car_driver = car_driver.y,
                            car_passenger = car_passenger.y,
                            bicycle = bicycle.y,
                            foot = foot.y,
                            other = other.y
)

remove_cols <- function(df, col_regex){
  df[,!grepl(col_regex, names(df))]
}
l_nat@data <- remove_cols(l_nat@data, "\\.x") # remove the dupped columns

saveRDS(l_nat,"../pct-bigdata/msoa/l_nat.Rds")
saveRDS(rf,"../pct-bigdata/msoa/rf_nat.Rds")
saveRDS(rq,"../pct-bigdata/msoa/rq_nat.Rds")
