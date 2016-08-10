# Aim: identify and fix missing routes
source("set-up.R")
l = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
l = l[l$dist > 0,]
rq = readRDS("../pct-bigdata/rq_nat.Rds")
rf = readRDS("../pct-bigdata/rf_1_to_50_missing_39.Rds")

nrow(rf) / nrow(l) # 98% there

# test ids match, especially for the final routes
ids_sample = sample(l$id[1:nrow(l)], size = 200)
ids_notouch = NULL
for(i in ids_sample){
  plot(l[l$id == i,])
  plot(rf[rf$id == i,], add = T)
  touches = gIntersects(l[l$id == i,], rf[rf$id == i,])
  if(!touches) j = c(j)
}

l_missing = l[!l$id %in% rf$id,]
plot(l_missing)
plot(rf, add = T, col = "red")

regions = geojson_read("../pct-bigdata/regions.geojson")
library(mapview)
mapview()