# Aim: build regional rnets

rnet_example = readRDS("../pct-outputs-regional-R/school/lsoa/bedfordshire/rnet.Rds")
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

r = sf::read_sf("../pct-shiny/regions_www/pct_regions_highres.geojson")

# test for one region
r1 = r[r$region_name == "bedfordshire", ]
rnet1 = rnet[r1, ]
rnet_new1 = as(rnet1, "Spatial")
summary(rnet_new1)
plot(rnet_new1, lwd = rnet_new1$dutch_slc / mean(rnet_new1$dutch_slc))
s / object.size(rnet_new1) # 30% times bigger for bedfordshire

# SET INPUT PARAMETERS
purpose <- "school"
geography <- "lsoa" 

k = which(r$region_name == "avon")
for(k in 1:nrow(r)) {
    rmini <- rnet[r[k,], ]
    rmini = as(rmini, "Spatial")
    rmini
    saveRDS(rmini, file.path("../pct-outputs-regional-R/", purpose, geography, paste0(as.character(r$region_name[k]), "/rnet.Rds"))) 
    message(paste0("Region ", k, " saved at ",Sys.time()))
}


