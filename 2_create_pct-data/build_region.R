start_time <- Sys.time() # for timing the script
# Assumes that init and other functions have been run using build_master.R
scens <- c("govtarget_slc", "gendereq_slc", "dutch_slc", "ebike_slc")

# Set data directory with the region subfolder
region_path <- file.path(pct_data, purpose, geography, region)

if(!dir.exists(region_path)){
  # create data directory
  dir.create(region_path) 
}

# In future create this variable in z_nat
z_nat$avslope_perc <- z_nat$avslope * 100

c_nat$geo_code <- as.character(c_nat$geo_code)

if(proj4string(region_shape) != proj4string(c_nat))
  region_shape <- spTransform(region_shape, proj4string(c_nat))
# select centroids within the region
cents <- c_nat[region_shape,]
# select zones of interest
zones <- z_nat[z_nat@data$geo_code %in% cents$geo_code, ]

# Keep lines with distane greater than 0
l_nat <- l_nat[l_nat$dist > 0,]

# Subset lines to those starting or ending in the study area: inter-regional
geo_code1 <- l_nat$msoa1 %in% cents$geo_code
geo_code2 <- l_nat$msoa2 %in% cents$geo_code

l <- l_nat[geo_code1 | geo_code2, ] # subset OD pairs with msoa1 or msoa2 in study area
l <- l[l$all > build_params[build_params$region_name == region, ]$mflow & 
                            l$dist < build_params[build_params$region_name == region, ]$mdist, ]

# Subset inter-regional lines to be those starting AND ending in the study region
geo_code1 <- l$msoa1 %in% cents$geo_code
geo_code2 <- l$msoa2 %in% cents$geo_code
l_regional <- l[geo_code1 & geo_code2, ] # subset OD pairs with o and msoa2 in study area

# Inter-regional centroids
zone_codes_inter_regional <- unique(c(l$msoa1, l$msoa2))
cents_inter_regional <- c_nat[c_nat$geo_code %in% zone_codes_inter_regional,]

# Subset lines
# subset OD pairs by n. people using it
# params$sel_long <- lines$all > params$mflow & lines$dist < params$mdist
# params$sel_short <- lines$dist < params$max_all_dist & lines$all > params$mflow_short

# Save params to build_params for the study region
(build_params[build_params$region_name == region, ]$n_flow <- nrow(l_regional))
(build_params[build_params$region_name == region, ]$n_flow_inter_regional <- nrow(l))
(build_params[build_params$region_name == region, ]$n_people <- sum(l_regional$all))
(build_params[build_params$region_name == region, ]$n_people_inter_regional <- sum(l$all))

# add geo_label of the lines
l$geo_label1 = left_join(l@data["msoa1"], zones@data[c("geo_code", "geo_label")], by = c("msoa1" = "geo_code"))[[2]]
l$geo_label2 = left_join(l@data["msoa2"], zones@data[c("geo_code", "geo_label")], by = c("msoa2" = "geo_code"))[[2]]

# # proportion of OD pairs in min-flow based subset
# params$pmflow <- round(nrow(l) / params$n_flow_region * 100, 1)
# # % all trips covered
# params$pmflowa <- round(sum(l$all) / params$n_commutes_region * 100, 1)

# # # # # # # # # # # # # # # # # # #
# Get route allocated data          #
# Use 1 of the following 3 options  #
# # # # # # # # # # # # # # # # # # #

# # 1: Load rf and rq data pre-saved for region, comment for 2 or 3
# rf = readRDS(file.path(pct_data, region, "rf.Rds"))
# rq = readRDS(file.path(pct_data, region, "rq.Rds"))

# 2: Load routes pre-generated and stored in pct-bigdata
# # C:\RStudio Projects\pct-bigdata\4_output_data\commute\msoa
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
# rft <- ms_simplify(input = rft, keep = params$rft_keep, method = "dp", keep_shapes = TRUE, snap = TRUE)
# Stop rnet lines going to centroid (optional)
# rft <- toptailgs(rf, toptail_dist = params$buff_geo_dist) # commented as failing
# if(length(rft) == length(rf)){
#   row.names(rft) <- row.names(rf)
#   rft <- SpatialLinesDataFrame(rft, rf@data)
# } else print("Error: toptailed lines do not match lines")

## Comment out all rnet related code
## Dated: 27th April 2017

# # source("R/generate_rnet.R") # comment out to avoid slow rnet build
# rnet = readRDS(file.path(pct_data, purpose, geography, region, "rnet.Rds")) # uncomment if built
# 
# # diagnostic check of the segments with no cyclists
# # links to: https://github.com/npct/pct-shiny/issues/336
# rnet <- rnet[rnet$govtarget_slc > 0,] # remove segments with zero cycling flows
# 
# proj4string(rnet) <- proj4string(zones)
# 
# # Are the lines contained by a single zone?
# rnet$Singlezone <- rowSums(gContains(zones, rnet, byid = TRUE))
# rnet@data[rnet$Singlezone == 0, grep(pattern = "upto", names(rnet))] = NA
# 
# if(!"gendereq_slc" %in% scens)
#   rnet$gendereq_slc <- NA
# 
# # create id variable
# rnet$id <- 1:nrow(rnet)

# # # # # # # # #
# Save the data #
# # # # # # # # #

# Don't need the variable
# # Creation of clc current cycling variable (temp)
# l$clc <- l$bicycle / l$all * 100

# # Transfer zones data to cents
# cents@data$avslope <- NULL
# cents@data <- left_join(cents@data, zones@data)

# # Save objects
#l@data = round_df(l@data, 5)
l@data <- as.data.frame(l@data) # convert from tibble to data.frame
save_formats(zones, purpose, geography, region, 'z')
save_formats(cents, purpose, geography, region, 'c')
save_formats(l, purpose, geography, region)
save_formats(rf, purpose, geography, region)
save_formats(rq, purpose, geography, region)
# save_formats(rnet, purpose, geography, region)

(build_params[build_params$region_name == region, ]$build_date <- as.character(Sys.Date()))
(build_params[build_params$region_name == region, ]$run_time <- Sys.time() - start_time)


# Save the input parameters to reproduce results
write_csv(build_params, file.path("2_create_pct-data", purpose, geography, "build_params_region.csv"))

assign("build_regions_params", subset(build_params, region_name == region), envir = .GlobalEnv)

# gather params
# params$nrow_flow = nrow(flow)
# params$build_date = Sys.Date()
# params$run_time = Sys.time() - start_time
# 
# saveRDS(params, file.path(pct_data, region, "params.Rds"))

# Save the initial parameters to reproduce results

# # Save the script that loaded the lines into the data directory
# file.copy("build_region.R", file.path(pct_data, region, "build_region.R"), overwrite = T)
# 
# # Create folder in shiny app folder
# region_dir <- file.path(file.path(pct_shiny_regions, region))
# dir.create(region_dir)
# ui_text <- 'source("../../ui-base.R", local = T, chdir = T)'
# server_text <- paste0('starting_city <- "', region, '"\n',
#                       'shiny_root <- file.path("..", "..")\n',
#                       'source(file.path(shiny_root, "server-base.R"), local = T)')
# write(ui_text, file = file.path(region_dir, "ui.R"))
# write(server_text, file = file.path(region_dir, "server.R"))
