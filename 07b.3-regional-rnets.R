# Aim: build regional rnets

test_region = "london"

f = paste0("../pct-outputs-regional-R/school/lsoa/", test_region, "/rnet.Rds")
rnet_example = readRDS(f)
summary(rnet_example)
plot(rnet_example, lwd = rnet_example$dutch_slc / mean(rnet_example$dutch_slc))
n = names(rnet_example)
s = object.size(rnet_example) # save size for future reference

u = "https://github.com/mem48/pct-raster-tests/releases/download/1.0.1/schools_overlined.gpkg"
download.file(url = u, destfile = "schools_overlined.gpkg")
rnet_large = sf::read_sf("schools_overlined.gpkg")
rnet = sf::st_transform(rnet_large, 4326)
rnet = cbind(local_id = 1:nrow(rnet), rnet)
names(rnet) %in% n # names are the same
rnet = rnet[rnet$dutch_slc >= 10, ] # removes around 15%
nrow(rnet) / nrow(rnet_large)
summary(rnet$bicycle[rnet$bicycle > 0 & rnet$bicycle <= 2])
rnet$bicycle[rnet$bicycle > 0 & rnet$bicycle <= 2] = NA
summary(rnet$bicycle)
# sf::st_write(rnet, "schools_rnet.gpkg")

r = sf::read_sf("../pct-shiny/regions_www/pct_regions_highres.geojson")

# test for one region
r1 = r[r$region_name == test_region, ]
rnet1 = rnet[r1, ]
rnet_new1 = as(rnet1, "Spatial")
summary(rnet_new1)
plot(rnet_new1, lwd = rnet_new1$dutch_slc / mean(rnet_new1$dutch_slc))
s_new = object.size(rnet_new1) 
s / s_new # 30% times bigger for bedfordshire
s_new / 1e6 # 130 MB for London...
summary(rnet_new1$dutch_slc)
hist(rnet_new1$dutch_slc)
rnet_new2 = rnet_new1[rnet_new1$dutch_slc >= 50, ] 



# SET INPUT PARAMETERS
purpose <- "school"
geography <- "lsoa" 

k = which(r$region_name == "london")
for(k in 1:nrow(r)) {
    rmini <- rnet[r[k,], ]
    rmini_spatial = as(rmini, "Spatial")
    s_new = object.size(rmini_spatial) 
    s_new / 1e6 
    if(s_new > 50000000) {
      print("reducing rnet size")
      rmini_spatial = rmini_spatial[rmini_spatial$dutch_slc >= 50, ] 
    } 
    # else if(s_new > 70000000) {
    #   print("reducing rnet size")
    #   rmini = rmini[rmini$dutch_slc >= 70, ] 
    # } else if(s_new > 50000000) {
    #   print("reducing rnet size")
    #   rmini = rmini[rmini$dutch_slc >= 40, ] 
    # } else if(s_new > 30000000) {
    #   print("reducing rnet size")
    #   rmini = rmini[rmini$dutch_slc >= 20, ] 
    # } 
    saveRDS(rmini_spatial, file.path("../pct-outputs-regional-R/", purpose, geography, paste0(as.character(r$region_name[k]), "/rnet.Rds"))) 
    geojsonio::geojson_write(rmini, file = file.path("../pct-outputs-regional-notR/", purpose, geography, paste0(as.character(r$region_name[k]), "/rnet.geojson"))) 
    message(paste0("Region ", k, " saved at ", Sys.time()))
}


