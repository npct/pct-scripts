

# setup -------------------------------------------------------------------

memfree <- as.numeric(system("awk '/MemFree/ {print $2}' /proc/meminfo", intern=TRUE))
memfree / 1e6
packageVersion("stplanr") # should be 0.2.8
library(sf)
library(stplanr)

# preparation -------------------------------------------------------------

# rf_all_sp = readRDS("../pct-largefiles/rf_shape.Rds")
# rf_all_sf = sf::st_as_sf(rf_all_sp)
# names(rf_all_sf) # id variable to join
# rf_all_data = readr::read_csv("../pct-largefiles/od_raster_attributes.csv")
# nrow(rf_all_sf) == nrow(rf_all_data) # not of equal number of rows, data has fewer...
# summary({sel_has_data = rf_all_sf$id %in% rf_all_data$id}) # all data rows have an id in the routes
# 
# rf_all_sub = rf_all_sf[sel_has_data, ]
# 
# summary(rf_all_sub$id == rf_all_data$id) # they are identical
# rf_all = sf::st_sf(rf_all_data, geometry = rf_all_sub$geometry)
# saveRDS(rf_all, "../pct-largefiles/rf_all.Rds")

# read-in cleaned file
rf_all = readRDS("../pct-largefiles/rf_all.Rds")


# tests -------------------------------------------------------------------

od_test = readRDS("../pct-outputs-regional-R/commute/lsoa/isle-of-wight/l.Rds")
summary({sel_isle = rf_all$id %in% od_test$id}) # 110 not in there out of 1698, ~5%
rf_isle = rf_all[sel_isle, ]
plot(rf_isle[1:9, ])
plot(rf_isle) # takes a while...

