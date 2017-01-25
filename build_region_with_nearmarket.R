start_time <- Sys.time() # for timing the script

# Set pct-data to pct-data-microsim
pct_data <- file.path("..", "pct-data-microsim")

if(!exists("region")) region <- "greater-manchester" # create LA name if none exists,  then set-up data repo

if(!file.exists(pct_data)) stop(paste("The pct-data repository cannot be found.  Please clone https://github.com/npct/pct-data in", dirname(getwd())))
if(!file.exists(pct_bigdata)) stop(paste("The pct-bigdata repository cannot be found.  Please clone https://github.com/npct/pct-bigdata in", dirname(getwd())))
scens <- c("govtarget_slc", "gendereq_slc", "nearmkt_slc",  "dutch_slc", "ebike_slc")

# Set local authority and ttwa zone names
region_path <- file.path(pct_data, region)
if(!dir.exists(region_path)) dir.create(region_path) # create data directory

if(!exists("ukmsoas")){ # MSOA zones
  ukmsoas <- readRDS(file.path(pct_bigdata, "ukmsoas-scenarios-nearmkt.Rds"))
  ukmsoas$avslope = ukmsoas$avslope * 100
}
if(!exists("centsa")) # Population-weighted centroids
  centsa <- readOGR(file.path(pct_bigdata, "cents-scenarios-nearmkt.geojson"), "OGRGeoJSON")
centsa$geo_code <- as.character(centsa$geo_code)

source('shared_build.R')

# select msoas of interest
if(proj4string(region_shape) != proj4string(centsa))
  region_shape <- spTransform(region_shape, proj4string(centsa))
cents <- centsa[region_shape,]
zones <- ukmsoas[ukmsoas@data$geo_code %in% cents$geo_code, ]

# load flow dataset, depending on availability
if(!exists("flow_nat"))
  flow_nat <- readRDS(file.path(pct_bigdata, "msoa", "l_nat_nearmkt.Rds"))
  flow_nat <- flow_nat[flow_nat$dist > 0,]

# Subset by zones in the study area
o <- flow_nat$msoa1 %in% cents$geo_code
d <- flow_nat$msoa2 %in% cents$geo_code
flow <- flow_nat[o & d, ] # subset OD pairs with o and d in study area

params$n_flow_region <- nrow(flow)
params$n_commutes_region <- sum(flow$all)

# Subset lines
# subset OD pairs by n. people using it
params$sel_long <- flow$all > params$mflow & flow$dist < params$mdist
params$sel_short <- flow$dist < params$max_all_dist & flow$all > params$mflow_short
sel <- params$sel_long | params$sel_short
flow <- flow[sel, ]
l <- flow

# add geo_label of the lines
l$geo_label1 = left_join(l@data["msoa1"], zones@data[c("geo_code", "geo_label")], by = c("msoa1" = "geo_code"))[[2]]
l$geo_label2 = left_join(l@data["msoa2"], zones@data[c("geo_code", "geo_label")], by = c("msoa2" = "geo_code"))[[2]]

# proportion of OD pairs in min-flow based subset
params$pmflow <- round(nrow(l) / params$n_flow_region * 100, 1)
# % all trips covered
params$pmflowa <- round(sum(l$all) / params$n_commutes_region * 100, 1)

# # # # # # # # # # # # # # # # # # #
# Get route allocated data          #
# Use 1 of the following 3 options  #
# # # # # # # # # # # # # # # # # # #

# # 1: Load rf and rq data pre-saved for region, comment for 2 or 3
# rf = readRDS(file.path(pct_data, region, "rf.Rds"))
# rq = readRDS(file.path(pct_data, region, "rq.Rds"))

# 2: Load routes pre-generated and stored in pct-bigdata
if(!exists("rf_nat"))
  rf_nat <- readRDS(file.path(pct_bigdata, "msoa", "rf_nat.Rds"))
if(!exists("rq_nat"))
  rq_nat <- readRDS(file.path(pct_bigdata, "msoa", "rq_nat.Rds"))
rf <- rf_nat[rf_nat$id %in% l$id,]
rq <- rq_nat[rq_nat$id %in% l$id,]
if(nrow(rf) != nrow(rq)) next()

# # 3: Create routes on-the-fly, uncomment the next 4 lines:
# rf = line2route(l = l, route_fun = "route_cyclestreet", plan = "fastest")
# rq = line2route(l = l, route_fun = "route_cyclestreet", plan = "quietest")
# rf$id = l$id
# rq$id = l$id

# Remove unwanted columns from routes
rf <- remove_cols(rf, "(waypoint|co2_saving|calories|busyness|plan|start|finish|nv)")
rq <- remove_cols(rq, "(waypoint|co2_saving|calories|busyness|plan|start|finish|nv)")

# create rq_increase variable
rq$rq_incr <- rq$length / rf$length

# Allocate route characteristics to OD pairs
l$dist_fast <- rf$length / 1000 # convert m to km
l$dist_quiet <- rq$length / 1000 # convert m to km
l$time_fast <- rf$time
l$time_quiet <- rq$time
l$cirquity <- l$dist_fast / l$dist
l$distq_f <- rq$length / rf$length
l$avslope <- rf$av_incline * 100
l$avslope_q <- rq$av_incline * 100

# Simplify line geometries (if mapshaper is available)
# this greatly speeds up the build (due to calls to overline)
# needs mapshaper installed and available to system():
# see https://github.com/mbloch/mapshaper/wiki/
rft <- rf
rft@data <- cbind(rft@data, l@data[c("bicycle", scens)])
rft <- ms_simplify(input = rft, keep = params$rft_keep, method = "dp", keep_shapes = TRUE, snap = TRUE)
# Stop rnet lines going to centroid (optional)
# rft <- toptailgs(rf, toptail_dist = params$buff_geo_dist) # commented as failing
# if(length(rft) == length(rf)){
#   row.names(rft) <- row.names(rf)
#   rft <- SpatialLinesDataFrame(rft, rf@data)
# } else print("Error: toptailed lines do not match lines")

source("R/generate_rnet.R") # comment out to avoid slow rnet build
# rnet = readRDS(file.path(pct_data, region, "rnet.Rds")) # uncomment if built

# diagnostic check of the segments with no cyclists
# links to: https://github.com/npct/pct-shiny/issues/336
rnet = rnet[rnet$govtarget_slc > 0,] # remove segments with zero cycling flows

proj4string(rnet) = proj4string(zones)

# Are the lines contained by a single zone?
rnet$Singlezone = rowSums(gContains(zones, rnet, byid = TRUE))
rnet@data[rnet$Singlezone == 0, grep(pattern = "upto", names(rnet))] = NA

if(!"gendereq_slc" %in% scens)
  rnet$gendereq_slc <- NA

# create id variable
rnet$id <- 1:nrow(rnet)

# # # # # # # # #
# Save the data #
# # # # # # # # #

# Creation of clc current cycling variable (temp)
l$clc <- l$bicycle / l$all * 100

# Transfer zones data to cents
cents@data$avslope <- NULL
## Calculate missing columns in cents, when compared with zones
col_missing_in_new <- !names(zones) %in% names(cents)[names(cents) != "geo_code"]
## Add missing columns to cents
cents@data <- left_join(cents@data, zones@data[col_missing_in_new],  by= "geo_code")


# # Save objects
#l@data = round_df(l@data, 5)
l@data <- as.data.frame(l@data) # convert from tibble to data.frame
save_formats(zones, 'z')
save_formats(l)
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
file.copy("build_region.R", file.path(pct_data, region, "build_region.R"), overwrite = T)

# Create folder in shiny app folder
region_dir <- file.path(file.path(pct_shiny_regions, region))
dir.create(region_dir)
ui_text <- 'source("../../ui-base.R", local = T, chdir = T)'
server_text <- paste0('starting_city <- "', region, '"\n',
                      'shiny_root <- file.path("..", "..")\n',
                      'source(file.path(shiny_root, "server-base.R"), local = T)')
write(ui_text, file = file.path(region_dir, "ui.R"))
write(server_text, file = file.path(region_dir, "server.R"))
