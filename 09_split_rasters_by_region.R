# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
rasterOptions(datatype = "INT2U", maxmemory = 1e10)

# SET INPUT PARAMETERS
purpose <- "commute"
geography <- "lsoa"  
scenarios <- c("bicycle", "govtarget", "govnearmkt", "gendereq", "dutch", "ebike")


# LOAD REGIONS, AND TRANSFORM TO EASTING/NORTHING PROJECTION SO THAT CAN BUFFER 1KM
pct_regions <- geojson_read(file.path(path_inputs, "02_intermediate/01_geographies/pct_regions_highres.geojson"), what = "sp")
regions <- spTransform(pct_regions, proj_27700)


# TEST IF RASTERS ARE LOADING AND DISPLAYING CORRECTLY
# r <- raster(file.path(path_outputs_national, purpose, geography, "ras_bicycle_all.tif"))
# bbmini <- extent(r)[c(1, 1, 3, 3)] + c(10000, 20000, 10000, 20000)
# rmini <- crop(r, bbmini)
# mapview::mapview(rmini) # check the data makes sense
# rmini <- crop(r, extent(regions[2,]) + c(-1e3, 1e3, -1e3, 1e3))
# mapview::mapview(rmini) +  mapview::mapview(regions[2,])


# RUN RASTERS FOR ALL REGIONS AND SCENARIOS
for(s in scenarios[1:5]) {
  message(paste0("Splitting rasters for ", s, " scenario at ",Sys.time()))
  r <- raster(file.path(path_outputs_national, purpose, geography, paste0("ras_", s, "_all.tif")))

  for(k in 1:length(regions)) {
    rmini <- crop(r, extent(regions[k,]) + c(-1e3, 1e3, -1e3, 1e3))
    writeRaster(rmini, file.path(path_outputs_regional_notR, purpose, geography, paste0(as.character(regions$region_name[k]), "/ras_", s, ".tif")), overwrite=TRUE) 
    message(paste0("Region ", k, " saved at ",Sys.time()))
  }
}