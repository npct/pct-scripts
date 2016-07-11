# Aim: check the data produced by pct-load
source("set-up.R")
# check national lines data
# after downloading latest data from github, e.g. with download-data.R
fname = "../pct-bigdata/rf.Rds"
fname = "../pct-bigdata/rq.Rds"
r = readRDS(fname)

# Which lengths are crazy long?
sel = r$length > 100 | is.na(r$length)
summary(sel)
plot(r[sel,])
summary(r$length[sel])

# What about the units for hilliness?
summary(r$av_incline)

# Fix the lengths (out be 3 orders of magnitude)
r$length[sel] = r$length[sel] / 1000

# save the result
# saveRDS(r, fname)

# Check distance data for straight lines
fname = "../pct-bigdata/pct_lines_oneway_shapes.Rds"
r = readRDS(fname)
# Which lengths are crazy long?
sel = r$dist > 100 | is.na(r$dist)
summary(sel)
plot(r[sel,])
summary(r$length[sel])

# checks per region
pct_data <- file.path("..", "pct-data")
regions <- readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
la_all <- regions$Region <- as.character(regions$Region)
i = 1
offending_region = NULL
for(i in 1:length(la_all)){
  region_shape = regions[i,]
  region_name = region_shape$Region
  
  zones = readRDS(paste0("../pct-data/", region_name, "/z.Rds"))
  rq = readRDS(paste0("../pct-data/", region_name, "/rq.Rds"))
  if(max(rq$length, na.rm = T) > 100){
    print(region_name)
    offending_region = c(offending_region, region_name)
  }
}
