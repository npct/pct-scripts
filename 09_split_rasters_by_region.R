# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
rasterOptions(datatype = "INT2U", maxmemory = 1e10)
# Anna Q: should this line also exist at start of 08?? [not sure what INT2U does where...]

# SET INPUT PARAMETERS + LOAD INPUT DATASETS
purpose <- "commute"
geography <- "lsoa"  
raster_scenarios <- c("bicycle", "govtarget", "gendereq", "dutch", "ebike")

# LOAD REGIONS, AND TRANSFORM TO EASTING/NORTHING SO THAT CAN BUFFER 1KM
pct_regions <- geojson_read(file.path(path_inputs, "02_intermediate/01_geographies/pct_regions_highres.geojson"), what = "sp")
regions <- spTransform(pct_regions, proj_27700)

# TEST RASTERS
r <- raster("census-all.tif")
bbmini <- extent(r)[c(1, 1, 3, 3)] + c(10000, 20000, 10000, 20000)
rmini <- crop(r, bbmini)
mapview::mapview(rmini) # check the data makes sense
rmini <- crop(r, extent(regions[2,]) + c(-1e3, 1e3, -1e3, 1e3))
mapview::mapview(rmini) +
  mapview::mapview(regions[2,])
writeRaster(rmini, filename = "region1.tiff")

# run for all regions and scenarios
i <- 1
s <- raster_scenarios[1]
dir.create("regional-rasters")
setwd("regional-rasters/")
for(s in raster_scenarios[2:5]) {
  
  r <- raster(paste0("../regional-rasters-old/", s, "-all.tif"))
  
  for(i in 1:nrow(regions)) {
    
    dir.create(as.character(regions$region_name[i]))
    rmini <- crop(r, extent(regions[i,]) + c(-1e3, 1e3, -1e3, 1e3))
    raster_name <- paste0(as.character(regions$region_name[i]), "/", s, ".tif")
    if(grepl(raster_name, "ducht")) {
      raster_name <- gsub(pattern = "ducht", "dutch")
    }
    writeRaster(rmini, raster_name)
  }
}
setwd("..")
