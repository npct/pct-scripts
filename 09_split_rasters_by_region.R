# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
rasterOptions(datatype = "INT2U", maxmemory = 1e10)
# Anna Q: should this line also exist at start of 08?? [not sure what INT2U does where...]

# SET INPUT PARAMETERS
purpose <- "commute"
geography <- "lsoa"  
scenarios <- c("bicycle", "govtarget", "gendereq", "dutch", "ebike")

if(!dir.exists(file.path(path_rasters_regional, purpose ))) { dir.create(file.path(path_rasters_regional, purpose)) }
if(!dir.exists(file.path(path_rasters_regional, purpose, geography ))) { dir.create(file.path(path_rasters_regional, purpose, geography)) }


# LOAD REGIONS, AND TRANSFORM TO EASTING/NORTHING PROJECTION SO THAT CAN BUFFER 1KM
pct_regions <- geojson_read(file.path(path_inputs, "02_intermediate/01_geographies/pct_regions_highres.geojson"), what = "sp")
regions <- spTransform(pct_regions, proj_27700)


# TEST IF RASTERS ARE LOADING AND DISPLAYING CORRECTLY
# r <- raster(file.path(path_rasters_national, purpose, geography, "bicycle_all.tif"))
# bbmini <- extent(r)[c(1, 1, 3, 3)] + c(10000, 20000, 10000, 20000)
# rmini <- crop(r, bbmini)
# mapview::mapview(rmini) # check the data makes sense
# rmini <- crop(r, extent(regions[2,]) + c(-1e3, 1e3, -1e3, 1e3))
# mapview::mapview(rmini) +  mapview::mapview(regions[2,])


# RUN RASTERS FOR ALL REGIONS AND SCENARIOS
# s <- scenarios[1]
# k <- 1
for(s in scenarios[1:5]) {
  message(paste0("Splitting rasters for ", s, " scenario at ",Sys.time()))
  r <- raster(file.path(path_rasters_national, purpose, geography, paste0(s, "_all.tif")))

  for(k in 1:length(regions)) {
    if(!dir.exists(file.path(path_rasters_regional, purpose, geography,as.character(regions$region_name[k])))) { dir.create(file.path(path_rasters_regional, purpose, geography, as.character(regions$region_name[k]))) }
    rmini <- crop(r, extent(regions[k,]) + c(-1e3, 1e3, -1e3, 1e3))
    writeRaster(rmini, file.path(path_rasters_regional, purpose, geography, paste0(as.character(regions$region_name[k]), "/", s, ".tif")), overwrite=TRUE) 
    message(paste0("Region ", k, " saved at ",Sys.time()))
  }
}