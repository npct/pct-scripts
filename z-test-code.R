rf_orig = readRDS("school/lsoa/rf_shape.Rds")
od_raster_attributes = readr::read_csv("school/lsoa/od_raster_attributes.csv")
rf_orig_joined = dplyr::left_join(rf_orig@data, od_raster_attributes)
rf_orig@data = rf_orig_joined
summary(rf_orig)

rf = rf_orig[1:999, ]
plot(rf)
library(tmap)
ttm()
tm_shape(rf) +
  tm_lines()

tm_shape(rf) +
  tm_lines("govtarget_slc", palette = "RdYlBu")
