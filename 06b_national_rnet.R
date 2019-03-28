

# setup -------------------------------------------------------------------

memfree <- as.numeric(system("awk '/MemFree/ {print $2}' /proc/meminfo", intern=TRUE))
memfree / 1e6
packageVersion("stplanr") # should be 0.2.8
library(sf)
library(stplanr)
scenarios = c("bicycle", "govtarget_slc", "govnearmkt_slc", "gendereq_slc", 
             "dutch_slc", "ebike_slc")

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
summary(rf_all$ebike_slc == 0) # only 120 with 0 score in data
summary(rf_all) # looks good:
# id               bicycle         govtarget_slc      govnearmkt_slc      gendereq_slc        dutch_slc      
# Length:2007710     Min.   :  0.0000   Min.   :  0.0000   Min.   :  0.0000   Min.   :  0.0000   Min.   :  0.000  
# Class :character   1st Qu.:  0.0000   1st Qu.:  0.0000   1st Qu.:  0.0000   1st Qu.:  0.0000   1st Qu.:  1.000  
# Mode  :character   Median :  0.0000   Median :  0.0000   Median :  0.0000   Median :  0.0000   Median :  1.000  
# Mean   :  0.3142   Mean   :  0.6321   Mean   :  0.6325   Mean   :  0.4939   Mean   :  1.996  
# 3rd Qu.:  0.0000   3rd Qu.:  1.0000   3rd Qu.:  1.0000   3rd Qu.:  0.0000   3rd Qu.:  2.000  
# Max.   :255.0000   Max.   :269.0000   Max.   :295.0000   Max.   :298.0000   Max.   :349.000  
# ebike_slc                geometry      
# Min.   :  0.000   LINESTRING   :2007710  
# 1st Qu.:  1.000   epsg:4326    :      0  
# Median :  1.000   +proj=long...:      0  
# Mean   :  2.641                          
# 3rd Qu.:  2.000                          
# Max.   :361.000
# saveRDS(rf_all, "../pct-largefiles/rf_all.Rds")

# read-in cleaned file
rf_all = readRDS("../pct-largefiles/rf_all.Rds")

# tests -------------------------------------------------------------------

library(sf)
library(stplanr)
scenarios = c("bicycle", "govtarget_slc", "govnearmkt_slc", "gendereq_slc", 
              "dutch_slc")

od_test = readr::read_csv("https://github.com/npct/pct-outputs-regional-notR/raw/master/commute/lsoa/isle-of-wight/z_attributes.csv")
# od_test = readRDS("../pct-outputs-regional-R/commute/lsoa/isle-of-wight/l.Rds")
summary({sel_isle = rf_all$id %in% od_test$id}) # 110 not in there out of 1698, ~5%
nrow(rf_isle) / nrow(rf_all) * 100 # less than 0.1% of data - should take 1000 time longer than test to run...
rf_isle = rf_all[sel_isle, ]
# rf_isle = sf::st_as_sf(readRDS("../pct-outputs-regional-R/commute/lsoa/isle-of-wight/rf.Rds"))
# for tests:
download.file("https://github.com/npct/pct-scripts/releases/download/0.0.1/rf_isle.Rds", "rf_isle.Rds", mode = "wb")
download.file("https://github.com/npct/pct-outputs-regional-R/raw/master/commute/lsoa/isle-of-wight/rf.Rds", "rf_isle.Rds", mode = "wb")
rf_isle = sf::st_as_sf(readRDS("rf_isle.Rds"))
# plot(rf_isle[1:9, ])
# plot(rf_isle) # takes a while...
# saveRDS(rf_isle, "rf_isle.Rds")

# fails
rnet_isle = overline2(rf_isle, attrib = scenarios)
# works

rnet_isle = overline2(rf_isle, attrib = "bicycle")
rnet_isle = overline2(rf_isle, attrib = "ebike_slc")

# works but takes longer (18 vs 8 seconds)
system.time({
  rnet_isle = overline2(rf_isle, attrib = "bicycle", ncores = 4)
})

# fails
system.time({
  rnet_isle = overline2(rf_isle, attrib = scenarios, ncores = 4)
})

