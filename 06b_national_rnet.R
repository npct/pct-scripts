

# setup -------------------------------------------------------------------

max_nrow_net = 20000 # max size of rnet to show (from 2/3 of what worked for schools)
memfree <- as.numeric(system("awk '/MemFree/ {print $2}' /proc/meminfo", intern=TRUE))
memfree / 1e6
packageVersion("stplanr") # should be 0.2.8
library(sf)
library(stplanr)
scenarios = c("bicycle", "govtarget_slc", "govnearmkt_slc", "gendereq_slc", 
             "dutch_slc", "ebike_slc")

# preparation -------------------------------------------------------------

# rf_all_sp = readRDS("../pct-largefiles/rf_shape.Rds")
# rf_all_sf = sf::st_as_sf(rf_all_sp)
# names(rf_all_sf) # id variable to join
# rf_all_data = readr::read_csv("../pct-largefiles/od_raster_attributes.csv")
# nrow(rf_all_sf) == nrow(rf_all_data) # not of equal number of rows, data has fewer...
# summary({sel_has_data = rf_all_sf$id %in% rf_all_data$id}) # all data rows have an id in the routes
# 
# rf_all_sub = rf_all_sf[sel_has_data, ]
# 
# summary(rf_all_sub$id == rf_all_data$id) # they are identical
# rf_all = sf::st_sf(rf_all_data, geometry = rf_all_sub$geometry)
summary(rf_all$ebike_slc == 0) # only 120 with 0 score in data
summary(rf_all) # looks good:
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
# saveRDS(rf_all, "../pct-largefiles/rf_all.Rds")

# read-in cleaned file
rf_all = readRDS("../pct-largefiles/rf_all.Rds")
l_all = readRDS("../pct-outputs-national/commute/lsoa/l_all.Rds")
regions = sf::read_sf("../pct-inputs/02_intermediate/01_geographies/pct_regions_highres.geojson")

# tests -------------------------------------------------------------------

od_test = readr::read_csv("https://github.com/npct/pct-outputs-regional-notR/raw/master/commute/lsoa/isle-of-wight/od_attributes.csv")
od_test$id = paste(od_test$geo_code1, od_test$geo_code2)
summary({sel_isle = rf_all$id %in% od_test$id}) # 110 not in there out of 1698, ~5%
rf_isle = rf_all[sel_isle, ]
nrow(rf_isle) / nrow(rf_all) * 100 # less than 3% of data - should take ~10 time longer than test to run...

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

log_data = data.frame(
  region_name = regions$region_name,
  rnet_lsoa_shiny_dutch_slc_min = NA,
  rnet_lsoa_shiny_n_row = NA,
  rnet_lsoa_full_n_row = NA,
  build_start_time = NA,
  build_end_time = NA
)

# create_rnet_region = function(r = "isle-of-wight") {
rs = c("isle-of-wight", "avon") # for testing...
rs = regions$region_name
for(r in rs) {
  i = log_data$region_name == r
  message("Reading in data for ", r)
  log_data$build_start_time[i] = Sys.time()
  
  l = pct::get_pct_lines(region = r, purpose = "commute", geography = "lsoa")
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
  
  saveRDS(rnet_intern, filename_intern)
  saveRDS(rnet_extern, filename_extern)
  
  message("Generating combined rnet")
  rnet_combined = rbind(rnet_intern, rnet_extern)
  rnet = overline2(rnet_combined, attrib = scenarios)
  # plot(rnet)
  
  saveRDS(rnet, paste0("../pct-outputs-regional-R/commute/lsoa/", r, "/rnet_sf.Rds"))
  rnet_full = cbind(local_id = 1:nrow(rnet), rnet)
  saveRDS(as(rnet_full, "Spatial"), filename_full)
  
  rnet_subset = rnet_full[tail(order(rnet_full$dutch_slc), max_nrow_net), ]
  dutch_slc_min = round(min(rnet_subset$dutch_slc / 10)) * 10
  rnet = rnet_full[rnet_full$dutch_slc >= dutch_slc_min, ]
  plot(rnet[rnet$dutch_slc > 100, ]) # test it works
  saveRDS(as(rnet, "Spatial"), filename_rnet)
  
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
saveRDS(rnet_nat, filename_rnet_nat)
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

# library(gdalUtils)
# gdal_setInstallation()
# library(magrittr)
# test
download.file("https://github.com/npct/pct-outputs-regional-notR/raw/master/commute/lsoa/isle-of-wight/ras_bicycle.tif", "ras.tif")
file.copy("ras.tif", "ras_bak.tif", overwrite = TRUE)
rnet_eg = pct::get_pct_rnet(region = "isle-of-wight")
rnet_eg = sf::st_transform(rnet_eg, 27700)
sf::write_sf(rnet_eg, "r1.gpkg")
rnet_egb = sf::st_buffer(rnet_eg, 10, endCapStyle = "FLAT", nQuadSegs = 2)
sf::write_sf(rnet_egb, "rnet_egb.gpkg")
plot(rnet_egb[2, ])
r = raster::raster("ras.tif")
summary(raster::values(r))
r_new = fasterize::raster(rnet_egb["bicycle"], resolution = 10)
summary(raster::values(r_new))
raster::writeRaster(r_new, "r_new.tif")

# test rasterize
gdal_rasterize -burn -a bicycle r1.gpkg rg1.tif # works
gdal_rasterize -burn -a bicycle -ot Int16 r1.gpkg rg2.tif # adds to existing layer
gdal_calc.py -A ras.tif --outfile=empty.tif --calc "A*0" --NoDataValue=0
gdal_rasterize -burn -a bicycle r1.gpkg empty.tif # adds to existing layer
gdal_rasterize -burn -a bicycle -at r1.gpkg empty.tif # adds to existing layer
gdal_rasterize -burn -a bicycle -at rnet_egb.gpkg empty.tif # adds to existing layer

browseURL("ras.tif")
r = raster::raster("empty.tif")
summary(r)
summary(raster::values(r))
raster::plot(r)

piggyback::pb_download("rnet_all.gpkg")
piggyback::pb_download("rnet_all.Rds")
rnet_all = readRDS("rnet_all.Rds")
rnet_all = sf::st_read("rnet_all.gpkg")
rnet_all_27700 = sf::st_transform(rnet_all, 27700)
sf::st_write(rnet_all_27700, "rnet_all.shp")
sf::st_write(rnet_all_27700, "rnet_all.gpkg")

# create template raster - in bash
wget https://github.com/npct/pct-outputs-national/raw/master/commute/lsoa/ras_bicycle_all.tif
gdal_calc.py -A ras_bicycle_all.tif --outfile=empty.tif --calc "A*0" --NoDataValue=0 # takes a few minutes
# gdal_translate -ot Int16 empty.tif empty16.tif
cp empty.tif empty1.tif empty2.tif empty3.tif empty4.tif empty5.tif
i=0
while (( i++ < 5 )); do
cp empty30.tif "empty30$i.tif"
done
gdalinfo empty.tif
ogrinfo rnet_all.gpkg
gdalwarp -tr 30 -30 empty.tif empty30.tif # about 10 times smaller
ls -hal | grep em

gdal_rasterize -burn -a bicycle -at rnet_all.gpkg empty30.tif # adds to existing layer
cp empty30.tif ras_bicycle_all_new_30.tif


# back in R
piggyback::pb_upload("ras_bicycle_all_new_30.tif")

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




