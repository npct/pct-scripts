

# setup -------------------------------------------------------------------

max_nrow_net = 20000 # max size of rnet to show (from 2/3 of what worked for schools)
memfree = as.numeric(system("awk '/MemFree/ {print $2}' /proc/meminfo", intern=TRUE))
memfree / 1e6
packageVersion("stplanr") # should be > 0.2.8 
library(sf)
library(stplanr)
purpose = "school"
scenarios = c("bicycle", "govtarget_slc", "cambridge_slc", "dutch_slc") # commute
# scenarios = c("bicycle", "govtarget_slc", "govnearmkt_slc", "gendereq_slc", "dutch_slc", "ebike_slc") # commute
regions = sf::read_sf("../pct-inputs/02_intermediate/01_geographies/pct_regions_highres.geojson")

# preparation -------------------------------------------------------------

# for commute data:
# rf_all_sp = readRDS("../pct-largefiles/rf_shape.Rds")
# rf_all_sf = sf::st_as_sf(rf_all_sp)
# names(rf_all_sf) # id variable to join
# rf_all_data = readr::read_csv("../pct-largefiles/od_raster_attributes.csv")
# nrow(rf_all_sf) == nrow(rf_all_data) # not of equal number of rows, data has fewer...
# summary({sel_has_data = rf_all_sf$id %in% rf_all_data$id}) # all data rows have an id in the routes
# rf_all_sub = rf_all_sf[sel_has_data, ]
# summary(rf_all_sub$id == rf_all_data$id) # they are identical
# rf_all = sf::st_sf(rf_all_data, geometry = rf_all_sub$geometry)
# summary(rf_all$ebike_slc == 0) # only 120 with 0 score in data
# summary(rf_all) # looks good:
# id               bicycle         govtarget_slc      govnearmkt_slc      gendereq_slc        dutch_slc      
# Length:2007710     Min.   :  0.0000   Min.   :  0.0000   Min.   :  0.0000   Min.   :  0.0000   Min.   :  0.000  
# Class :character   1st Qu.:  0.0000   1st Qu.:  0.0000   1st Qu.:  0.0000   1st Qu.:  0.0000   1st Qu.:  1.000  
# Mode  :character   Median :  0.0000   Median :  0.0000   Median :  0.0000   Median :  0.0000   Median :  1.000  
# Mean   :  0.3142   Mean   :  0.6321   Mean   :  0.6325   Mean   :  0.4939   Mean   :  1.996  
# 3rd Qu.:  0.0000   3rd Qu.:  1.0000   3rd Qu.:  1.0000   3rd Qu.:  0.0000   3rd Qu.:  2.000  
# Max.   :255.0000   Max.   :269.0000   Max.   :295.0000   Max.   :298.0000   Max.   :349.000  
# ebike_slc                geometry      
# Min.   :  0.000   LINESTRING   :2007710  
# 1st Qu.:  1.000   epsg:4326    :      0  
# Median :  1.000   +proj=long...:      0  
# Mean   :  2.641                          
# 3rd Qu.:  2.000                          
# Max.   :361.000
# saveRDS(rf_all, "../pct-largefiles/rf_all.Rds", version = 2)
# read-in cleaned file
# rf_all = readRDS("../pct-largefiles/rf_all.Rds")
# l_all = readRDS("../pct-outputs-national/commute/lsoa/l_all.Rds")

# for school data
# rf_all_sp = readRDS("../pct-largefiles/go-cambridge/rf_shape.Rds")
# rf_all_sf = sf::st_as_sf(rf_all_sp)
# names(rf_all_sf)
# od_attributes = readr::read_csv("../pct-largefiles/go-cambridge/od_raster_attributes.csv")
# summary(od_attributes)
# nrow(od_attributes)
# nrow(rf_all_sf)
# rf_all = dplyr::inner_join(rf_all_sf, od_attributes)
# nrow(rf_all)
# plot(rf_all[1:999, ])
# rnet_all_test = overline2(rf_all[1:999, ], attrib = scenarios)
# plot(rnet_all_test)
# rnet_all = overline2(rf_all, attrib = scenarios)
# plot(rnet_all[1:999, ])
# rnet_all_sp = as(rnet_all, "Spatial")
# set low values to NA
# saveRDS(rnet_all_sp, "../pct-largefiles/go-cambridge/rnet_schools_national_with_go_cambridge_sp.Rds")

# preprocess rnet file
# rnet_all_sp = readRDS("../pct-largefiles/go-cambridge/rnet_schools_national_with_go_cambridge_sp.Rds")
# rnet_all_sp@data = cbind(local_id = 1:nrow(rnet_all_sp), rnet_all_sp@data)
# summary(rnet_all_sp$bicycle)
# rnet_all_sp@data$bicycle[rnet_all_sp@data$bicycle > 0 & rnet_all_sp@data$bicycle <= 2] = NA
# for (i in c("govtarget_slc", "cambridge_slc", "dutch_slc")) {
#   rnet_all_sp@data[[i]][is.na(rnet_all_sp@data$bicycle) &
#                           rnet_all_sp@data[[i]] <= 2] = NA
# }
# rnet_all_sp
# summary(as.factor(rnet_all_sp$bicycle))
# summary(as.factor(rnet_all_sp$govtarget_slc))
# saveRDS(rnet_all_sp, "../pct-outputs-national/school/lsoa/rnet_all.Rds", version = 2)
rnet_all_sp = readRDS("../pct-outputs-national/school/lsoa/rnet_all.Rds")


# subset: test for one region
plot(regions)
region_name_single = "isle-of-wight"
region_single = regions %>%
  dplyr::filter(region_name == region_name_single) %>% 
  st_transform(27700) %>% 
  st_buffer(dist = 3000) %>% 
  st_transform(4326) %>% 
  as("Spatial")
rnet_single = rnet_all_sp[region_single, ]
plot(rnet_single[rnet_single$dutch_slc > 100, ]) # works
mapview::mapview(rnet_single[1:1000, ]) # works
rnet_subset = rnet_single[tail(order(rnet_single$dutch_slc), max_nrow_net), ]
dutch_slc_min = round(min(rnet_subset$dutch_slc / 10, na.rm = TRUE)) * 10
rnet_to_serve = rnet_single[rnet_single$dutch_slc >= dutch_slc_min, ]
summary(rnet_to_serve$dutch_slc)
"../pct-outputs-regional-R/commute/lsoa/isle-of-wight/rnet.Rds"
"../pct-outputs-regional-R/school/lsoa/isle-of-wight/"
rnet_folder = paste0("../pct-outputs-regional-R/", purpose, "/lsoa/", region_name_single, "/")
saveRDS(rnet_to_serve, paste0(rnet_folder, "rnet.Rds"), version = 2)
saveRDS(rnet_single, paste0(rnet_folder, "rnet_full.Rds"), version = 2)
rnet_folder_geojson = paste0("../pct-outputs-regional-notR/", purpose, "/lsoa/", region_name_single, "/")
rnet_file_geojson = paste0(rnet_folder_geojson, "rnet_full.geojson")
file.remove(rnet_file_geojson)
sf::write_sf(sf::st_as_sf(rnet_single), rnet_file_geojson)

# now in a loop:

log_data = data.frame(
  region_name = regions$region_name,
  rnet_lsoa_shiny_dutch_slc_min = NA,
  rnet_lsoa_shiny_n_row = NA,
  rnet_lsoa_full_n_row = NA,
  build_start_time = NA,
  build_end_time = NA
)

all_region_names = regions$region_name
# for(i in 20:21){
for(i in seq_len(nrow(regions))) {
  log_data$build_start_time[i] = Sys.time()
  region_name_single = all_region_names[i]
  region_single = regions %>%
    dplyr::filter(region_name == region_name_single) %>% 
    st_transform(27700) %>% 
    st_buffer(dist = 1000) %>% 
    st_transform(4326) %>% 
    as("Spatial")
  rnet_single = rnet_all_sp[region_single, ]
  plot(rnet_single[rnet_single$dutch_slc > 500, ]) # works
  # mapview::mapview(rnet_single[1:1000, ]) # works
  rnet_subset = rnet_single[tail(order(rnet_single$dutch_slc), max_nrow_net), ]
  dutch_slc_min = round(min(rnet_subset$dutch_slc / 10, na.rm = TRUE)) * 10
  rnet_to_serve = rnet_single[rnet_single$dutch_slc >= dutch_slc_min, ]
  summary(rnet_to_serve$dutch_slc)
  rnet_folder = paste0("../pct-outputs-regional-R/", purpose, "/lsoa/", region_name_single, "/")
  saveRDS(rnet_to_serve, paste0(rnet_folder, "rnet.Rds"), version = 2)
  plot(rnet_to_serve)
  saveRDS(rnet_single, paste0(rnet_folder, "rnet_full.Rds"), version = 2)
  rnet_folder_geojson = paste0("../pct-outputs-regional-notR/", purpose, "/lsoa/", region_name_single, "/")
  rnet_file_geojson = paste0(rnet_folder_geojson, "rnet_full.geojson")
  file.remove(rnet_file_geojson)
  sf::write_sf(sf::st_as_sf(rnet_single), rnet_file_geojson)
  log_data$build_end_time[i] = Sys.time()
  log_data$rnet_lsoa_shiny_dutch_slc_min[i] = dutch_slc_min
  log_data$rnet_lsoa_shiny_n_row[i] = nrow(rnet_to_serve)
  log_data$rnet_lsoa_full_n_row[i] = nrow(rnet_single)
  message("Done for region ", region_name_single)
}

knitr::kable(log_data)
readr::write_csv(log_data, "school-regional-rnet-build-log-2019-07-22.log")

# tests -------------------------------------------------------------------

# od_test = readr::read_csv("https://github.com/npct/pct-outputs-regional-notR/raw/master/commute/lsoa/isle-of-wight/od_attributes.csv")
# od_test$id = paste(od_test$geo_code1, od_test$geo_code2)
# summary({sel_isle = rf_all$id %in% od_test$id}) # 110 not in there out of 1698, ~5%
# rf_isle = rf_all[sel_isle, ]
# nrow(rf_isle) / nrow(rf_all) * 100 # less than 3% of data - should take ~10 time longer than test to run...
# create_rnet_region = function(r = "isle-of-wight") {
rs = c("isle-of-wight", "avon") # for testing...
rs = regions$region_name
r = rs[1]
for(r in rs) {
  i = log_data$region_name == r
  message("Reading in data for ", r)
  log_data$build_start_time[i] = Sys.time()
  
  z = pct::get_pct_zones(region = r, purpose = purpose, geography = "lsoa")
  l_internal = l[regions, , op = st_within]
  
  rf_region = rf_all[rf_all$id %in% l$id, ]
  rf_intern = rf_all[rf_all$id %in% l_internal$id, ]
  rf_extern = rf_region[!rf_region$id %in% l_internal$id, ]
  
  message("Generating internal rnet")
  rnet_intern = overline2(rf_intern, attrib = scenarios)
  message("Generating external rnet")
  rnet_extern = overline2(rf_extern, attrib = scenarios)
  
  filename_intern = paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_intern_sf.Rds")
  filename_extern = paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_extern_sf.Rds")
  filename_full = paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_full.Rds")
  filename_rnet = paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet.Rds")
  
  saveRDS(rnet_intern, filename_intern, version = 2)
  saveRDS(rnet_extern, filename_extern, version = 2)
  
  message("Generating combined rnet")
  rnet_combined = rbind(rnet_intern, rnet_extern)
  rnet = overline2(rnet_combined, attrib = scenarios)
  # plot(rnet)
  
  saveRDS(rnet, paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_sf.Rds"), version = 2)
  rnet_full = cbind(local_id = 1:nrow(rnet), rnet)
  saveRDS(as(rnet_full, "Spatial"), filename_full, version = 2)
  
  rnet_subset = rnet_full[tail(order(rnet_full$dutch_slc), max_nrow_net), ]
  dutch_slc_min = round(min(rnet_subset$dutch_slc / 10)) * 10
  rnet = rnet_full[rnet_full$dutch_slc >= dutch_slc_min, ]
  plot(rnet[rnet$dutch_slc > 100, ]) # test it works
  saveRDS(as(rnet, "Spatial"), filename_rnet, version = 2)
  
  # add log data
  log_data$dutch_slc_min[i] = dutch_slc_min
  log_data$n_row[i] = nrow(rnet)
  
  message("Job done for ", r)
  log_data$build_end_time[i] = Sys.time()
  
}

# # check rnet
r = "south-yorkshire"
rnet = readRDS(paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_sf.Rds"))
rnet_old = readRDS(paste0("../pct-outputs-regional-R/commute/msoa/", r, "/rnet.Rds"))
names(rnet_old)
names(rnet)
plot(rnet["bicycle"])

# to test on shiny app for single region...
file.copy(paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet.Rds"),
          paste0("../pct-outputs-regional-R/commute/msoa/", r, "/rnet.Rds"), overwrite = TRUE)
# remotes::install_cran(c("shiny", "rgdal", "rgeos", "leaflet", "shinyjs"))
# shiny::runApp("../pct-shiny/regions_www/m/")

# build regional rnets ----------------------------------------------------

rs = regions$region_name
# rs = rs[grep(pattern = "isle|dors", x = rs)]
# build rasters -------------------------------------------------------
rnet_all = lapply(X = rs, function(r){
  r1 = readRDS(paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_full.Rds"))
  message("size r1 ", nrow(r1))
  reg1 = as(regions[regions$region_name == r, ], "Spatial")
  r2 = r1[reg1, ]
  message("size r2 ", nrow(r2))
  r2
})

rnet_nat = do.call(what = rbind, args = rnet_all)
rnet_sample = rnet_nat[sample(nrow(rnet_nat), size = 1000), ]
plot(rnet_sample, lwd = rnet_sample$govtarget_slc / mean(rnet_sample$bicycle))
mapview::mapview(rnet_sample, lwd = rnet_sample$govtarget_slc / mean(rnet_sample$bicycle) * 10)
filename_rnet_nat = "../pct-outputs-national/commute/lsoa/rnet_all.Rds"
saveRDS(rnet_nat, filename_rnet_nat, version = 2)
rnet_nat_sf = sf::st_as_sf(rnet_nat)
sf::st_write(rnet_nat_sf, "rnet_all.gpkg")
piggyback::pb_upload("rnet_all.gpkg")

# get rnet data -----------------------------------------------------------
log_data = readr::read_csv("commute/lsoa/build_params_pct_region.csv")
log_data$minflow_rnet_lsoa = NA
rs = log_data$region_name
r = rs[9]
for(r in rs) {
  message("getting log data for ", r)
  i = which(rs == r)
  filename_rnet_msoa = paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_intern_sf.Rds")
  filename_rnet = paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet.Rds")
  rn = readRDS(filename_rnet)
  log_data$minflow_rnet_lsoa[i] = min(rn$dutch_slc)
}

readr::write_csv(log_data, "commute/lsoa/build_params_pct_region.csv")

# rasterize ---------------------------------------------------------------

piggyback::pb_download("rnet_all.gpkg")
piggyback::pb_download("rnet_all.Rds")
rnet_all = readRDS("rnet_all.Rds")
rnet_all = sf::st_read("rnet_all.gpkg")
rnet_all_27700 = sf::st_transform(rnet_all, 27700)
sf::st_write(rnet_all_27700, "rnet_all_27700.gpkg")

rnet_egb = sf::st_buffer(rnet_all_27700, 10, endCapStyle = "FLAT", nQuadSegs = 2)
sf::write_sf(rnet_egb, "rnet_egb.gpkg")

# create template raster - in bash

# wget https://github.com/npct/pct-outputs-national/raw/master/commute/lsoa/ras_bicycle_all.tif
gdal_calc.py -A ras_bicycle_all.tif --outfile=empty.tif --calc "A*0" --NoDataValue=0 # takes a few minutes
# gdal_translate -ot Int16 empty.tif empty16.tif
i=0
while (( i++ < 5 )); do
cp empty.tif "empty$i.tif"
done
gdalinfo empty.tif
ogrinfo rnet_egb.gpkg
# gdalwarp -tr 30 -30 empty.tif empty30.tif # about 10 times smaller
ls -hal | grep em

# gdal_rasterize -burn -a bicycle -at rnet_egb.gpkg empty1.tif # adds to existing layer
gdal_rasterize -burn -a govtarget_slc -at rnet_egb.gpkg empty2.tif # adds to existing layer
gdal_rasterize -burn -a cambridge_slc -at rnet_egb.gpkg empty3.tif # adds to existing layer
gdal_rasterize -burn -a dutch_slc -at rnet_egb.gpkg empty4.tif # adds to existing layer
# mv empty1.tif school_bicycle_all_10.tif
mv empty2.tif school_govtarget_slc_all_10.tif
mv empty3.tif school_cambridge_slc_all_10.tif
mv empty4.tif school_dutch_slc_all_10.tif
ls -hal | grep bicycle_all
zip(
  "rschool_all_10.tif.zip",
  c("school_bicycle_all_10.tif",  "school_govtarget_slc_all_10.tif",
    "school_cambridge_slc_all_10.tif", "school_dutch_slc_all_10.tif")
)

# back in R
piggyback::pb_upload("rschool_all_10.tif.zip")

# remotes::install_github("rspatial/terra")
# v1 = terra::vect("r1.gpkg")
# r1 = terra::rast("ras.tif")
# terra::image(r1)
# r2 = terra::rasterize(x = v1, y = r1)

# ras1 = raster::raster("ras.tif")
# ras_bicycle = raster::rasterize(x = r1["bicycle"], y = ras1, field = 1, fun = sum)
# plot(ras_bicycle)
# plot(ras1)
# system.time(
#   gdalUtils::gdal_rasterize(src_datasource = "r1.gpkg", dst_filename = "ras.tif", b = "bicycle")
#   sf::gdal_rasterize(sf = r1, file = "ras.tif")
# )

# # benchmarking
# res = bench::mark(
#   check = FALSE,
#   t2_nc16 = overline2(rf_isle, scenarios, ncores = 16),
#   t2_nc10 = overline2(rf_isle, scenarios, ncores = 10),
#   t2_nc04 = overline2(rf_isle, scenarios, ncores = 4),
#   t2_nc02 = overline2(rf_isle, scenarios, ncores = 2),
#   t2_nc01 = overline2(rf_isle, scenarios, ncores = 1)
#   )
# plot(res)
# 
# rnet_isle = overline2(rf_isle, attrib = "bicycle")
# rnet_isle = overline2(rf_isle, attrib = "ebike_slc")
# 
# # works but takes longer (18 vs 8 seconds)
# system.time({
#   rnet_isle = overline2(rf_isle, attrib = "bicycle", ncores = 4)
# })
# 
# # fails
# system.time({
#   rnet_isle = overline2(rf_isle, attrib = scenarios, ncores = 4)
# })

# # rasterize ---------------------------------------------------------------
# 
# # library(gdalUtils)
# # gdal_setInstallation()
# # library(magrittr)
# # test
# download.file("https://github.com/npct/pct-outputs-regional-notR/raw/master/commute/lsoa/isle-of-wight/ras_bicycle.tif", "ras.tif")
# file.copy("ras.tif", "ras_bak.tif", overwrite = TRUE)
# rnet_eg = pct::get_pct_rnet(region = "isle-of-wight")
# rnet_eg = sf::st_transform(rnet_eg, 27700)
# sf::write_sf(rnet_eg, "r1.gpkg")
# rnet_egb = sf::st_buffer(rnet_eg, 10, endCapStyle = "FLAT", nQuadSegs = 2)
# sf::write_sf(rnet_egb, "rnet_egb.gpkg")
# plot(rnet_egb[2, ])
# r = raster::raster("ras.tif")
# summary(raster::values(r))
# r_new = fasterize::raster(rnet_egb["bicycle"], resolution = 10)
# summary(raster::values(r_new))
# raster::writeRaster(r_new, "r_new.tif")

# # test rasterize
# gdal_rasterize -burn -a bicycle r1.gpkg rg1.tif # works
# gdal_rasterize -burn -a bicycle -ot Int16 r1.gpkg rg2.tif # adds to existing layer
# gdal_calc.py -A ras.tif --outfile=empty.tif --calc "A*0" --NoDataValue=0
# gdal_rasterize -burn -a bicycle r1.gpkg empty.tif # adds to existing layer
# gdal_rasterize -burn -a bicycle -at r1.gpkg empty.tif # adds to existing layer
# gdal_rasterize -burn -a bicycle -at rnet_egb.gpkg empty.tif # adds to existing layer
# 
# browseURL("ras.tif")
# r = raster::raster("empty.tif")
# summary(r)
# summary(raster::values(r))
# raster::plot(r)
