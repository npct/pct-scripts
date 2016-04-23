source("set-up.R") # load packages needed

# Create default LA name if none exists
if(!exists("region")) region <- "west-yorkshire"
pct_data <- file.path("..", "pct-data")
pct_bigdata <- file.path("..", "pct-bigdata")
pct_privatedata <- file.path("..", "pct-privatedata")
pct_shiny_regions <- file.path("..", "pct-shiny", "regions_www")
if(!file.exists(pct_data)) stop(paste("The pct-data repository cannot be found.  Please clone https://github.com/npct/pct-data in", dirname(getwd())))
if(!file.exists(pct_bigdata)) stop(paste("The pct-bigdata repository cannot be found.  Please clone https://github.com/npct/pct-bigdata in", dirname(getwd())))
scens <- c("govtarget_slc", "gendereq_slc", "dutch_slc", "ebike_slc")

# Set local authority and ttwa zone names
region # name of the region
region_path <- file.path(pct_data, region)
if(!dir.exists(region_path)) dir.create(region_path) # create data directory

# Minimum flow between od pairs to show. High means fewer lines
mflow <-10
mflow_short <- 10

# Distances
mdist <- 20 # maximum euclidean distance (km) for subsetting lines
max_all_dist <- 7 # maximum distance (km) below which more lines are selected
buff_dist <- 0 # buffer (km) used to select additional zones (often zero = ok)
buff_geo_dist <- 100 # buffer (m) for removing line start and end points for network

# Save the initial parameters to reproduce results
save(region, mflow, mflow_short, mdist, max_all_dist, buff_dist, buff_geo_dist, file = file.path(region_path, "params.RData"))

if(!exists("ukmsoas")) # MSOA zones
  ukmsoas <- readRDS(file.path(pct_bigdata, "ukmsoas-scenarios.Rds"))
if(!exists("centsa")) # Population-weighted centroids
  centsa <- readOGR(file.path(pct_bigdata, "cents-scenarios.geojson"), "OGRGeoJSON")
centsa$geo_code <- as.character(centsa$geo_code)
if(!exists("las"))
  las <- readOGR(dsn = file.path(pct_bigdata, "las-pcycle.geojson"), layer = "OGRGeoJSON")
if(!exists("las_cents"))
  las_cents <- SpatialPoints(coordinates(las))

# Load local authorities and districts
if(!exists("geo_level")) geo_level <- "regional"
# if you use a custom geometry, regions should already be saved from buildmaster.R

if(!exists("regions")){
  if (geo_level == "regional")
    regions <-
  readOGR(file.path(pct_bigdata, "regions.geojson"), layer = "OGRGeoJSON")
  else {
    regions <- readOGR(dsn = file.path(pct_bigdata, "cuas-mf.geojson"), layer = "OGRGeoJSON")
    regions$Region <- regions$CTYUA12NM
  }
}
region_shape <- region_orig <- # create region shape (and add buffer in m)
  regions[grep(pattern = region, x = regions$Region, ignore.case = T),]

# Only transform if needed
if(buff_dist > 0){
  region_shape <- spTransform(region_shape, CRS("+init=epsg:27700"))
  region_shape <- gBuffer(region_shape, width = buff_dist * 1000)
  region_shape <- spTransform(region_shape, proj4string(centsa))
}

las_in_region <- gIntersects(las_cents, region_shape, byid = T)
las_in_region <- las_in_region[1,]
las_in_region <- las[las_in_region,]

# select msoas of interest
if(proj4string(region_shape) != proj4string(centsa))
  region_shape <- spTransform(region_shape, proj4string(centsa))
cents <- centsa[region_shape,]
zones <- ukmsoas[ukmsoas@data$geo_code %in% cents$geo_code, ]

nzones <- nrow(zones) # how many zones?
zones_wgs <- spTransform(zones, CRS("+init=epsg:27700"))
mzarea <- round(median(gArea(zones_wgs, byid = T) / 10000), 1) # average area of zones, sq km

# load flow dataset, depending on availability
if(!exists("flow_nat"))
  flow_nat <- readRDS(file.path(pct_bigdata, "pct_lines_oneway_shapes.Rds"))
summary(flow_nat$dutch_slc / flow_nat$All)

if(!exists("rf_nat"))
  rf_nat <- readRDS(file.path(pct_bigdata, "rf.Rds"))
if(!exists("rq_nat"))
  rq_nat <- readRDS(file.path(pct_bigdata, "rq.Rds"))
# Subset by zones in the study area
o <- flow_nat$Area.of.residence %in% cents$geo_code
d <- flow_nat$Area.of.workplace %in% cents$geo_code
flow <- flow_nat[o & d, ] # subset OD pairs with o and d in study area
n_flow_region <- nrow(flow)
n_commutes_region <- sum(flow$All)

# Subset lines
# subset OD pairs by n. people using it
sel_long <- flow$All > mflow & flow$dist < mdist
sel_short <- flow$dist < max_all_dist & flow$All > mflow_short
sel <- sel_long | sel_short
flow <- flow[sel, ]
# summary(flow$dist)
# l <- od2line(flow = flow, zones = cents)
l <- flow

# nrow(flow) # how many OD pairs in the study area?
# proportion of OD pairs in min-flow based subset
pmflow <- round(nrow(l) / n_flow_region * 100, 1)
# % all trips covered
pmflowa <- round(sum(l$All) / n_commutes_region * 100, 1)

rf_nat$id <- gsub('(?<=[0-9])E', ' E', rf_nat$id, perl=TRUE) # temp fix to ids
rq_nat$id <- gsub('(?<=[0-9])E', ' E', rq_nat$id, perl=TRUE)
rf <- rf_nat[rf_nat$id %in% l$id,]
rq <- rq_nat[rf_nat$id %in% l$id,]

# Allocate route characteristics to OD pairs
l$dist_fast <- rf$length
l$dist_quiet <- rq$length
l$time_fast <- rf$time
l$time_quiet <- rq$time
l$cirquity <- rf$length / l$dist
l$distq_f <- rq$length / rf$length
l$avslope <- rf$av_incline
l$co2_saving <- rf$co2_saving
l$calories <- rf$calories
l$busyness <- rf$busyness
l$avslope_q <- rq$av_incline
l$co2_saving_q <- rq$co2_saving
l$calories_q <- rq$calories
l$busyness_q <- rq$busyness

luk <- readRDS(file.path(pct_bigdata, "l_sam8.Rds"))

hdfl <- dplyr::select(l@data, All, dist_fast)
hdfl$Scope <- "Local"
hdfl$All <- hdfl$All / sum(hdfl$All)

hdfu <- dplyr::select(luk@data, All, dist_fast)
hdfu$Scope <- "National"
hdfu$All <- hdfu$All / sum(hdfu$All)

histdf <- rbind(hdfl, hdfu)

rcycle <- round(100 * sum(l$Bicycle) / sum(l$All), 1)
# rcarusers <- round (100 * sum(l$Car_driver+l$Car_passenger) / sum(l$All), 1)
rcarusers <- NA # when we don't have car drivers
natcyc <- sum(luk$Bicycle) / sum(luk$All)

dfscen <- dplyr::select(l@data, contains("slc"), -contains("co2"), All, olc = Bicycle, dist_fast)
dfsp <- gather(dfscen, key = scenario, value = slc, -dist_fast)
dfsp$scenario <- factor(dfsp$scenario)
dfsp$scenario <-
  factor(dfsp$scenario, levels = levels(dfsp$scenario)[c(1, 3, 2, 4, 5, 6)])
levels(dfsp$scenario)[1] <- c("All modes")
levels(dfsp$scenario)[6] <- c("Current (2011)")
scalenum <- sum(l$All)

rft <- rf
# Stop rnet lines going to centroid (optional)
rft <- toptailgs(rf, toptail_dist = buff_geo_dist)
if(length(rft) == length(rf)){
  row.names(rft) <- row.names(rf)
  rft <- SpatialLinesDataFrame(rft, rf@data)
} else print("Error: toptailed lines do not match lines")
rft$Bicycle <- l$Bicycle

# Simplify line geometries (if mapshaper is available)
# this greatly speeds up the build (due to calls to overline)
# needs mapshaper installed and available to system():
# see https://github.com/mbloch/mapshaper/wiki/
rft <- ms_simplify(rft, keep = 0.06)
rnet <- overline(rft, "Bicycle")


if(require(foreach) & require(doParallel)){
  cl <- makeCluster(4)
  registerDoParallel(cl)
  # foreach::getDoParWorkers()
    # create list in parallel
    rft_data_list <- foreach(i = scens) %dopar% {
      rft@data[i] <- l@data[i]
      rnet_tmp <- stplanr::overline(rft, i)
      rnet_tmp@data[i]
    }
    # save the results back into rnet with normal for loop
    for(j in seq_along(scens)){
      rnet@data <- cbind(rnet@data, rft_data_list[[j]])
    }
} else {
  for(i in scens){
    rft@data[i] <- l@data[i]
    rnet_tmp <- overline(rft, i)
    rnet@data[i] <- rnet_tmp@data[i]
    rft@data[i] <- NULL
  }
}

# # Add maximum amount of interzone flow to rnet
# create line midpoints (sp::over does not work with lines it seems)
rnet_osgb <- spTransform(rnet, CRS("+init=epsg:27700"))
rnet_cents <- SpatialLinesMidPoints(rnet_osgb)
rnet_cents <- spTransform(rnet_cents, CRS("+init=epsg:4326"))

proj4string(rnet) = proj4string(zones)
for(i in c("Bicycle", scens)){
  nm = paste0(i, "_upto") # new variable name
  zones@data[nm] = left_join(zones@data[c("geo_code")], cents@data[c("geo_code", i)])[2]
  rnet@data = cbind(rnet@data, over(rnet_cents, zones[nm]))
  zones@data[nm] = NULL
}

# Are the lines contained by a single zone?
gtest = gContains(zones, rnet, byid = TRUE)
rnet$Singlezone = rowSums(gtest)
rnet@data[rnet$Singlezone == 0, grep(pattern = "upto", names(rnet))] = NA

if(!"gendereq_slc" %in% scens)
  rnet$gendereq_slc <- NA

# # # # # # # # #
# Save the data #
# # # # # # # # #

# Remove/change private/superfluous variables
l$Male <- l$Female <- l$From_home <- l$calories <-
  l$co2_saving_q <-l$calories_q <- l$busyness_q <-
  # data used in the model - superflous for pct-shiny
  l$dist_fastsq <- l$dist_fastsqrt <- l$ned_avslope <-
  l$interact <- l$interactsq <- l$interactsqrt <- NULL

# Make average slope a percentage
l$avslope <- l$avslope * 100

# Creation of clc current cycling variable (temp)
l$clc <- l$Bicycle / l$All * 100

# Transfer cents data to zones
cents@data$avslope <- NULL
cents@data <- left_join(cents@data, zones@data)

# Remove NAN numbers (cause issues with geojson_write)
na_cols  <- which(names(zones) %in%
  c("av_distance", "cirquity", "distq_f", "base_olcarusers", "gendereq_slc", "gendereq_sic"))
for(ii in na_cols){
  zones@data[[ii]][is.nan(zones@data[[ii]])] <- NA
}

# # Save objects
# Save objects # uncomment these lines to save model output
saveRDS(zones, file.path(pct_data, region, "z.Rds"))
geojson_write( ms_simplify(zones, keep = 0.1), file = file.path(pct_data, region, "z"))
saveRDS(cents, file.path(pct_data, region, "c.Rds"))
saveRDS(l, file.path(pct_data, region, "l.Rds"))
saveRDS(rf, file.path(pct_data, region, "rf.Rds"))
saveRDS(rq, file.path(pct_data, region, "rq.Rds"))
saveRDS(rnet, file.path(pct_data, region, "rnet.Rds"))

# # Save the script that loaded the lines into the data directory
file.copy("load.Rmd", file.path(pct_data, region, "load.Rmd"))

# Create folder in shiny app folder
region_dir <- file.path(file.path(pct_shiny_regions, region))
dir.create(region_dir)
ui_text <- 'source("../../ui-base.R", local = T, chdir = T)'
server_text <- paste0('startingCity <- "', region, '"\n',
                      'shinyRoot <- file.path("..", "..")\n',
                      'source(file.path(shinyRoot, "server-base.R"), local = T)')
write(ui_text, file = file.path(region_dir, "ui.R"))
write(server_text, file = file.path(region_dir, "server.R"))
if(!file.exists( file.path(region_dir, "www"))){ file.symlink(file.path("..", "..","www"), region_dir) }

end_time <- Sys.time()