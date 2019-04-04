# Aim: build regional rnets

test_region = "avon"

f = paste0("../pct-outputs-regional-R/school/lsoa/", test_region, "/rnet.Rds")
rnet_example = readRDS(f)
summary(rnet_example)
plot(rnet_example, lwd = rnet_example$dutch_slc / mean(rnet_example$dutch_slc))
n = names(rnet_example)
s = object.size(rnet_example) # save size for future reference

# Todo: move this into rnet generation script
rnet_orig = sf::read_sf("schools_overlined.gpkg") # original schools layer
rnet = sf::st_transform(rnet_orig, 4326)
rnet = cbind(local_id = 1:nrow(rnet), rnet)
names(rnet) %in% n # names are the same
summary(rnet$bicycle[rnet$bicycle > 0 & rnet$bicycle <= 2])
rnet$bicycle[rnet$bicycle > 0 & rnet$bicycle <= 2] = NA
rnet$govtarget_slc[is.na(rnet$bicycle) & rnet$govtarget_slc <= 2] = NA
rnet$dutch_slc[is.na(rnet$bicycle) & rnet$dutch_slc <= 2] = NA

summary(rnet$bicycle)
summary(rnet$govtarget_slc)
summary(rnet$dutch_slc)
# sf::st_write(rnet, "schools_rnet.gpkg")

rnet_small = rnet[rnet$dutch_slc >= 10, ] # removes around 15%
summary(rnet_small$bicycle)
nrow(rnet_small) / nrow(rnet)

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


# SET INPUT PARAMETERS
purpose = "school"
geography = "lsoa" 

k = which(r$region_name == "london")
for(k in 1:nrow(r)) {
    rmini = rnet[r[k,], ]
    r_spatial = as(rmini, "Spatial")
    rmini_spatial = r_spatial[r_spatial$dutch_slc > 10, ]
    s_new = object.size(rmini_spatial) 
    s_new / 1e6 
    if(s_new > 50000000) {
      print("reducing rnet size")
      rmini_spatial = rmini_spatial[rmini_spatial$dutch_slc >= 100, ] 
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
    
    saveRDS(r_spatial, file.path("../pct-outputs-regional-R/", purpose, geography, paste0(as.character(r$region_name[k]), "/rnet_full.Rds"))) 
    
    geojsonio::geojson_write(r_spatial, file = file.path("../pct-outputs-regional-notR/", purpose, geography, paste0(as.character(r$region_name[k]), "/rnet_full.geojson"))) 
    
    message(paste0("Region ", k, " saved at ", Sys.time()))
}

# post-processing tests ---------------------------------------------------

# test values
region_to_test = "london" # pick any region
test_rnet = readRDS(paste0("../pct-outputs-regional-R/school/lsoa/", region_to_test, "/rnet_full.Rds"))
summary(test_rnet)

test_rnet = readRDS(paste0("../pct-outputs-regional-R/school/lsoa/", region_to_test, "/rnet.Rds"))
summary(test_rnet)

test_rnet = sf::read_sf(paste0("../pct-outputs-regional-notR/school/lsoa/", region_to_test, "/rnet.geojson"))
summary(test_rnet)


u = paste0("https://github.com/npct/pct-outputs-regional-R/raw/master/school/lsoa/", region_to_test, "/rnet.Rds")
download.file(u, "rnet.Rds")
test_rnet = readRDS("rnet.Rds")
summary(test_rnet$bicycle)
summary(test_rnet$bicycle == 1)
summary(test_rnet$bicycle == 2)
summary(test_rnet$bicycle == 3)

# test national rnet
region_to_test = "london" # pick any region
u = paste0("https://github.com/npct/pct-lsoa-vis/releases/download/0.0.1/schools_rnet.gpkg")
download.file(u, "rnet.gpkg")
test_rnet = sf::st_read("rnet.gpkg")
summary(test_rnet$bicycle)
summary(test_rnet$bicycle == 1)
summary(test_rnet$bicycle == 2)
summary(test_rnet$bicycle == 3)


