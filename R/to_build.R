# Aim: get the dates modified for each region
# that will help decide which to rebuild
source("set-up.R")
library(lubridate)
regions = readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
regions = as.character(regions$Region)
i = 1
start_date = as_date("2016-08-15")
file_date = file.mtime(paste0("../pct-data/", regions[i], "/rnet.Rds"))
start_date < as_date(file_date)
region_dates = data_frame(name = regions, date = as.Date(NA), to_rebuild = NA)
for(i in 1:length(regions)){
  region_dates$date[i] = file.mtime(paste0("../pct-data/", regions[i], "/rnet.Rds"))
  region_dates$to_rebuild[i] = start_date > as_date(region_dates$date[i])
}
write_csv(region_dates, "to_rebuild.csv")

to_rebuild_updated = read_csv("to_rebuild_updated.csv")
to_rebuild_updated$date = region_dates$date
to_rebuild_updated$recently_built = start_date <= as_date(region_dates$date)
to_rebuild_updated$name[!to_rebuild_updated$recently_built]
to_rebuild_updated$to_rebuild[recently_built] = 0

write_csv(to_rebuild_updated, "to_rebuild_updated.csv")
