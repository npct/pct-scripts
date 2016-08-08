source("set-up.R")
l = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
l = l[l$dist > 0,]

# subset lines for cambridge (temporary - comment out for generating all routes)
z = readRDS("../pct-data/cambridgeshire/z.Rds")
l = l[z,]
plot(l)

rf = line2route(l = l, route_fun = "route_cyclestreet", plan = "fastest")
rq = line2route(l = l, route_fun = "route_cyclestreet", plan = "quietest")
# summary(rf$length)

rf$id = l$id
rq$id = l$id

saveRDS(rf, "../pct-bigdata/rf_cam.Rds")
saveRDS(rq, "../pct-bigdata/rq_cam.Rds")
