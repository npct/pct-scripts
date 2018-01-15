# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
# Source parallel version of line2route (depreciated in stplanr 0.1.9) - to make it faster
source("https://github.com/ropensci/stplanr/raw/18a598674bb378d5577050178da1561489496157/R/od-funs.R")
memory.limit(size = 1000000)

## ORDER OF RUNNING
# RUN SECTION 1 [prepares input for both fast and quiet]
# RUN SECTION 2 AND 3 FOR FAST THEN QUIET ROUTES
# RUN SECTION 4 [merges fast and quiet routes]

# Code to only run for one region (comment out following lines for national build)
region <- "isle-of-wight"
pct_regions <- geojson_read(file.path(path_inputs, "02_intermediate/01_geographies/pct_regions_lowres.geojson"), what = "sp")
region_shp <- pct_regions[grep(pattern = region, x = pct_regions$region_name),]

# SET INPUT PARAMETERS
purpose <- "commute"
geography <- "msoa"  
file_name <- "nat1707"   # Name for this batch of routes

# CREATE DIRECTORIES (IF NEEDED)
if(!dir.exists(file.path(path_inputs, "02_intermediate/02_travel_data", purpose))) { dir.create(file.path(path_inputs, "02_intermediate/02_travel_data", purpose)) }
if(!dir.exists(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography))) { dir.create(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography)) }
if(!dir.exists(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "archive"))) { dir.create(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "archive")) }
if(!dir.exists(file.path(path_temp_cs, purpose))) { dir.create(file.path(path_temp_cs, purpose)) }
if(!dir.exists(file.path(path_temp_cs, purpose, geography))) { dir.create(file.path(path_temp_cs, purpose, geography)) }

#########################
### PART 1: PREPARE TO RUN CS ROUTES
#########################

# OPEN LINES AND CENTS FILES, & SET INPUT PARAMETERS
if (geography=="msoa" & purpose=="commute") {
  maxdist_scenario <- 30  # max distance (km) model fastest route impact in scenario building
  maxdist_visualise <- 20 # max distance (km) provide route shape files in downloads/interface
  unzip(file.path(path_inputs, "01_raw/02_travel_data/commute/msoa/wu03ew_v2.zip"), exdir = path_temp_unzip) 
  lines <- readr::read_csv(file.path(path_temp_unzip, "wu03ew_v2.csv"), col_names = FALSE)  
  lines <- dplyr::rename(lines, o = X1, d = X2)
  cents_o <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/msoa_cents_mod.geojson"))
  cents_o@data <- dplyr::rename(cents_o@data, geo_code = msoa11cd)
  cents_all <- cents_d <- cents_o
} else if (geography=="lsoa" & purpose=="commute")  {
  maxdist_scenario <- 30  
  maxdist_visualise <- 20 
  #minflow_visualise <- 3
  #Anna note: in future, could add variable 'all' to 'lines_cs' and set 'minflow_visualise', such that for rq you only route those above minflow_visualise
  unzip(file.path(path_inputs, "01_raw/02_travel_data/commute/lsoa/WM12EW[CT0489]_lsoa.zip"), exdir = path_temp_unzip)
  lines <- data.table::fread(file.path(path_temp_unzip, "WM12EW[CT0489]_lsoa.csv"),select=c(1,3))
  lines <- dplyr::rename(lines, o = `Area of usual residence`, d = `Area of Workplace`)
  cents_o <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/lsoa_cents_mod.geojson"))
  cents_o@data <- dplyr::rename(cents_o@data, geo_code = `lsoa11cd`)
  cents_all <- cents_d <- cents_o
} else if (geography=="lsoa" & purpose=="school")  {
  maxdist_scenario <- 15
  maxdist_visualise <- 15
  lines <- data.table::fread(file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa", "flows_2011.csv"),select=c(1,2,4))
  lines <- dplyr::rename(lines, o = `lsoa11cd`, d = `urn`)
  cents_o <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/lsoa_cents_mod.geojson"))
  cents_o@data <- dplyr::rename(cents_o@data, geo_code = `lsoa11cd`)
  cents_d <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/urn_cents.geojson"))
  cents_d@data <- dplyr::rename(cents_d@data, geo_code = `urn`)
} else {
}

# SUBSET TO CENTS STARTING IN A SINGLE REGION IF REGION SPECIFIED
if(exists("region_shp")) {
  cents_o <- cents_o[region_shp,]
}

# ADD CENTS COODRINATES & GET DIST
omatch <- match(lines$o, cents_o$geo_code) # generates a number - where in cents is found each $home in lines
dmatch <- match(lines$d, cents_d$geo_code)
lines <- lines[!is.na(omatch) & !is.na(dmatch),] # remove line outside the rquired build region, or no geographical origin/dest
coords_o <- cents_o@coords[match(lines$o, cents_o$geo_code),] # gets the coords from 'omatch' position of cents
coords_d <- cents_d@coords[match(lines$d, cents_d$geo_code),]
lines$e_dist_km <- geosphere::distHaversine(p1 = coords_o, p2 = coords_d) / 1000 # assign euclidean dist

# SUBSET LINES FOR CYCLE STREETS (between-zone & under maxdist_scenario) & MAKE 2-WAY ID
lines_cs_data <- lines[(lines$e_dist_km < maxdist_scenario) & !is.na(lines$e_dist_km) & (lines$o != lines$d),]
if (purpose=="commute")  {
  lines_cs_data$geo_code1 <- pmin(lines_cs_data$o, lines_cs_data$d)
  lines_cs_data$geo_code2 <- pmax(lines_cs_data$o, lines_cs_data$d)  
  lines_cs_data$id <- paste(lines_cs_data$geo_code1, lines_cs_data$geo_code2)
} else if (purpose=="school")  {
  lines_cs_data$geo_code1 <- lines_cs_data$o
  lines_cs_data$geo_code2 <- lines_cs_data$d
} else {
}
lines_cs_data <- unique(lines_cs_data[,c("geo_code1", "geo_code2", "id", "e_dist_km")])
lines_cs_data <- lines_cs_data[order(lines_cs_data$id),]

# MAKE A SPATIAL OBJECT OF CS LINES
if (purpose=="commute")  {
  lines_cs_lines <- od2line2(flow = lines_cs_data, zones = cents_all) # faster implementation for where o and d have same geography
} else if (purpose=="school")  {
  lines_cs_lines <- od2line(flow = lines_cs_data, zones = cents_o, destinations = cents_d) # slower implementation for where o and d have different geography
} else {
}
lines_cs <- SpatialLinesDataFrame(sl = lines_cs_lines, data = lines_cs_data)
proj4string(lines_cs) <- proj_4326
saveRDS(lines_cs, (file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "lines_cs.Rds")))

#########################
### PARTS 2 AND 3: ROUTING 
#########################

route_type <- "fastest" # run for fastest then quietest
source("04.1_batch_routing.R")

# RE-RUN FOR QUIET ROUTES
route_type <- "quietest" 
source("04.1_batch_routing.R")

#########################
### PART 4: PREPARE CS VARIABLES FOR SCENARiOS/ATTRIBUTES
#########################

rf_all_data <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("archive/rf_",file_name,"_data.Rds")))
rq_all_data <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("archive/rq_",file_name,"_data.Rds")))

rf_all_data$rf_dist_km <- rf_all_data$length / 1000
rq_all_data$rq_dist_km <- rq_all_data$length / 1000
rf_all_data$rf_avslope_perc <- rf_all_data$av_incline * 100
rq_all_data$rq_avslope_perc <- rq_all_data$av_incline * 100
rf_all_data$rf_time_min <- rf_all_data$time / 60
rq_all_data$rq_time_min <- rq_all_data$time / 60

rf_all_data <- rf_all_data[,names(rf_all_data) %in% c("id","geo_code1","geo_code2","e_dist_km","rf_dist_km","rf_avslope_perc","rf_time_min")]
rq_all_data <- rq_all_data[,names(rq_all_data) %in% c("id","rq_dist_km","rq_avslope_perc","rq_time_min")]
rfrq_all_data <- left_join(rf_all_data, rq_all_data, by = "id")
rfrq_all_data$dist_rf_e  <- rfrq_all_data$rf_dist_km / rfrq_all_data$e_dist_km   # occasionally just under 1, due to CS snapping centroids
rfrq_all_data$dist_rq_rf <- rfrq_all_data$rq_dist_km / rfrq_all_data$rf_dist_km
rfrq_all_data <- rfrq_all_data[, c(1:4, 5, 8, 11, 12, 6, 9, 7, 10)]
write_csv(rfrq_all_data, file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "rfrq_all_data.csv"))
# saveRDS(rfrq_all_data,file = file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "rfrq_all_data.Rds"))

