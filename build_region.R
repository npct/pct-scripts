source("set-up.R") # load packages needed

# ms_simplify gives Error: RangeError: Maximum call stack size exceeded
# for large objects.  Turning the repair off fixed it...
too_large <- function(to_save, max_size = 5.6){ format(object.size(to_save), units = 'Mb') > max_size }
remove_cols <- function(df, col_regex){
  df[,!grepl(col_regex, names(df))]
}

# Create default LA name if none exists
start_time <- Sys.time() # for timing the script

if(!exists("region")) region <- "cambridgeshire"
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
params <- NULL

params$mflow <- 10
params$mflow_short <- 10

# Distances
params$mdist <- 20 # maximum euclidean distance (km) for subsetting lines
params$max_all_dist <- 7 # maximum distance (km) below which more lines are selected
params$buff_dist <- 0 # buffer (km) used to select additional zones (often zero = ok)
params$buff_geo_dist <- 100 # buffer (m) for removing line start and end points for network
params$min_rnet_length <- 2 # minimum segment length for the Route Network to display - low currently due to holes in routes
if(!exists("ukmsoas")) # MSOA zones
  ukmsoas <- readRDS(file.path(pct_bigdata, "ukmsoas-scenarios.Rds"))
ukmsoas$avslope = ukmsoas$avslope * 100 # Put in units of percentages
if(!exists("centsa")) # Population-weighted centroids
  centsa <- readOGR(file.path(pct_bigdata, "cents-scenarios.geojson"), "OGRGeoJSON")
centsa$geo_code <- as.character(centsa$geo_code)

source('shared_build.R')

# load in codebook data
codebook_l = read.csv("../pct-shiny/static/codebook_lines.csv")

# select msoas of interest
if(proj4string(region_shape) != proj4string(centsa))
  region_shape <- spTransform(region_shape, proj4string(centsa))
cents <- centsa[region_shape,]
zones <- ukmsoas[ukmsoas@data$geo_code %in% cents$geo_code, ]

# load flow dataset, depending on availability
if(!exists("flow_nat"))
  flow_nat <- readRDS(file.path(pct_bigdata, "lines_oneway_shapes_updated.Rds"))
  flow_nat <- flow_nat[flow_nat$dist > 0,]
summary(flow_nat$dutch_slc / flow_nat$all)

if(!exists("rf_nat")){
  rf_nat <- readRDS(file.path(pct_bigdata, "rf_cam.Rds"))
  rf_nat <- remove_cols(rf_nat, "(waypoint|co2_saving|calories|busyness|plan|start|finish|nv)")
}
if(!exists("rq_nat")){
  rq_nat <- readRDS(file.path(pct_bigdata, "rq_cam.Rds"))
  rq_nat <- remove_cols(rq_nat, "(waypoint|co2_saving|calories|busyness|plan|start|finish|nv)")
}
# Subset by zones in the study area
o <- flow_nat$msoa1 %in% cents$geo_code
d <- flow_nat$msoa2 %in% cents$geo_code
flow <- flow_nat[o & d, ] # subset OD pairs with o and d in study area
flow <- flow[!is.na(flow$dutch_slc),] # remove flows with no scenario data

# Remove Webtag, increase in walkers and base_
zones <- remove_cols(zones, "(webtag|siw$|siw$|base_)")
flow <- remove_cols(flow, "(webtag|siw$|siw$|base_)")

params$n_flow_region <- nrow(flow)
params$n_commutes_region <- sum(flow$all)

# Subset lines
# subset OD pairs by n. people using it
params$sel_long <- flow$all > params$mflow & flow$dist < params$mdist
params$sel_short <- flow$dist < params$max_all_dist & flow$all > params$mflow_short
sel <- params$sel_long | params$sel_short
flow <- flow[sel, ]
# summary(flow$dist)
# l <- od2line(flow = flow, zones = cents)
l <- flow

# add geo_label of the lines
l$geo_label1 = left_join(l@data["msoa1"], zones@data[c("geo_code", "geo_label")], by = c("msoa1" = "geo_code"))[[2]]
l$geo_label2 = left_join(l@data["msoa2"], zones@data[c("geo_code", "geo_label")], by = c("msoa2" = "geo_code"))[[2]]

# proportion of OD pairs in min-flow based subset
params$pmflow <- round(nrow(l) / params$n_flow_region * 100, 1)
# % all trips covered
params$pmflowa <- round(sum(l$all) / params$n_commutes_region * 100, 1)

rf_nat$id <- gsub('(?<=[0-9])E', ' E', rf_nat$id, perl=TRUE) # temp fix to ids
rq_nat$id <- gsub('(?<=[0-9])E', ' E', rq_nat$id, perl=TRUE)
rf <- rf_nat[rf_nat$id %in% l$id,]
rq <- rq_nat[rq_nat$id %in% l$id,]

# # To create routes on-the-fly, uncomment the next 4 lines:
# rf = line2route(l = l, route_fun = "route_cyclestreet", plan = "fastest")
# rq = line2route(l = l, route_fun = "route_cyclestreet", plan = "quietest")
# rf$id = l$id
# rq$id = l$id

# Allocate route characteristics to OD pairs
l$dist_fast <- rf$length / 1000 # convert m to km
l$dist_quiet <- rq$length / 1000 # convert m to km
l$time_fast <- rf$time
l$time_quiet <- rq$time
l$cirquity <- rf$length / l$dist
l$distq_f <- rq$length / rf$length
l$avslope <- rf$av_incline * 100
l$avslope_q <- rq$av_incline * 100

rft_too_large <-  too_large(rf)
rft <- rf
rft@data <- cbind(rft@data, l@data[c("bicycle", scens)])
rft <- ms_simplify(input = rft, keep = 0.05, keep_shapes = T, no_repair = rft_too_large)
# Stop rnet lines going to centroid (optional)
# rft <- toptailgs(rf, toptail_dist = params$buff_geo_dist) # commented as failing
# if(length(rft) == length(rf)){
#   row.names(rft) <- row.names(rf)
#   rft <- SpatialLinesDataFrame(rft, rf@data)
# } else print("Error: toptailed lines do not match lines")

# Simplify line geometries (if mapshaper is available)
# this greatly speeds up the build (due to calls to overline)
# needs mapshaper installed and available to system():
# see https://github.com/mbloch/mapshaper/wiki/
if (rft_too_large){
  file.create(file.path(pct_data, region, "rft_too_large"))
}

rnet <- overline(rft, "bicycle")

if(require(foreach) & require(doParallel)){
  n_cores <- 4 # set max number of cores to 4
  # reduce n_cores for 2 core machines
  if(parallel:::detectCores() < 4)
    n_cores <- parallel:::detectCores()
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)
  # foreach::getDoParWorkers()
    # create list in parallel
    rft_data_list <- foreach(i = scens) %dopar% {
      rnet_tmp <- stplanr::overline(rft, i)
      rnet_tmp@data[i]
    }
    # save the results back into rnet with normal for loop
    for(j in seq_along(scens)){
      rnet@data <- cbind(rnet@data, rft_data_list[[j]])
    }
    stopCluster(cl = cl)
} else {
  for(i in scens){
    rnet_tmp <- overline(rft, i)
    rnet@data[i] <- rnet_tmp@data[i]
    rft@data[i] <- NULL
  }
}

# debug rnet so it is smaller and contains only useful results
# summary(rnet) # diagnostic check of what it contains
sel_rnet_zero = rnet$govtarget_slc > 0
# plot(rnet[!sel_rnet_zero,]) # diagnostic check of the segments with no cyclists
# links to: https://github.com/npct/pct-shiny/issues/336
rnet = rnet[rnet$govtarget_slc > 0,] # remove segments with zero cycling flows
# # Add maximum amount of interzone flow to rnet
# create line midpoints (sp::over does not work with lines it seems)
rnet_osgb <- spTransform(rnet, CRS("+init=epsg:27700"))
rnet_cents <- SpatialLinesMidPoints(rnet_osgb)
rnet_cents <- spTransform(rnet_cents, CRS("+init=epsg:4326"))
rnet_lengths = gLength(rnet_osgb, byid = T)
summary(rnet_lengths)
rnet = rnet[rnet_lengths > params$min_rnet_length,]

proj4string(rnet) = proj4string(zones)
rm(rnet_osgb, rnet_cents)

# Are the lines contained by a single zone?
rnet$Singlezone = rowSums(gContains(zones, rnet, byid = TRUE))
rnet@data[rnet$Singlezone == 0, grep(pattern = "upto", names(rnet))] = NA

if(!"gendereq_slc" %in% scens)
  rnet$gendereq_slc <- NA

# # # # # # # # #
# Save the data #
# # # # # # # # #

# Creation of clc current cycling variable (temp)
l$clc <- l$bicycle / l$all * 100

# Transfer cents data to zones
cents@data$avslope <- NULL
cents@data <- left_join(cents@data, zones@data)

# # Save objects
# Save objects # uncomment these lines to save model output
save_formats <- function(to_save, name = F, csv = F){
  if (name == F){
    name <- substitute(to_save)
  }
  saveRDS(to_save, file.path(pct_data, region, paste0(name, ".Rds")))

  # Simplify data checked with before and after using:
  # plot(l$gendereq_sideath_webtag)
  to_save@data <- round_df(to_save@data, 5)

  # Simplify geom
  geojson_write( ms_simplify(to_save, keep = 0.1, no_repair = too_large(to_save)), file = file.path(pct_data, region, name))
  if(csv) write.csv(to_save@data, file.path(pct_data, region, paste0(name, ".csv")))
}

round_df <- function(df, digits) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))

  df[,nums] <- round(df[,nums], digits = digits)

  (df)
}

l@data = round_df(l@data, 5)

save_formats(zones, 'z', csv = T)

l@data <- as.data.frame(l@data) # convert from tibble to data.frame
l@data <- l@data[codebook_l$Variable.name] # fix order and vars kept in l

save_formats(l, csv = T)
save_formats(rf)
save_formats(rq)
save_formats(rnet)

saveRDS(cents, file.path(pct_data, region, "c.Rds"))

# gather params
params$nrow_flow = nrow(flow)
params$build_date = Sys.Date()
params$run_time = Sys.time() - start_time

saveRDS(params, file.path(pct_data, region, "params.Rds"))

# Save the initial parameters to reproduce results

# # Save the script that loaded the lines into the data directory
file.copy("build_region.R", file.path(pct_data, region, "build_region.R"))

# Create folder in shiny app folder
region_dir <- file.path(file.path(pct_shiny_regions, region))
dir.create(region_dir)
ui_text <- 'source("../../ui-base.R", local = T, chdir = T)'
server_text <- paste0('starting_city <- "', region, '"\n',
                      'shiny_root <- file.path("..", "..")\n',
                      'source(file.path(shiny_root, "server-base.R"), local = T)')
write(ui_text, file = file.path(region_dir, "ui.R"))
write(server_text, file = file.path(region_dir, "server.R"))
if(!file.exists( file.path(region_dir, "www"))){ file.symlink(file.path("..", "..","www"), region_dir) }
