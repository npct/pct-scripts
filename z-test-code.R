rnet_orig = readRDS("school/lsoa/rq_shape.Rds")
rnet = rnet_orig[1:999, ]
plot(rnet)
library(tmap)
ttm()
tm_shape(rnet) +
  tm_lines()

od_raster_attributes = readr::read_csv("school/lsoa/od_raster_attributes.csv")
rnet_joined = dplyr::left_join(rnet@data, od_raster_attributes)
summary(rnet_joined)
rnet@data = rnet_joined

tm_shape(rnet) +
  tm_lines("govtarget_slc", palette = "RdYlBu")
