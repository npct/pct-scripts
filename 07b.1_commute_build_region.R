# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_R, purpose))) { dir.create(file.path(path_outputs_regional_R, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography))) { dir.create(file.path(path_outputs_regional_R, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_notR, purpose))) { dir.create(file.path(path_outputs_regional_notR, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography, region)) }

start_time <- Sys.time() # for timing the script


###########################
### SUBSET ZONES, CENTS AND LINES TO THE REGION
###########################

# Within-region zone and centroids
z <- z_all[z_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
c <- c_all[c_all@data$geo_code %in% z$geo_code, ]

# Inter-regional attribute data
od_geo_code1 <- od_all_attributes$geo_code1 %in% z$geo_code
od_geo_code2 <- od_all_attributes$geo_code2 %in% z$geo_code
od_attributes <- od_all_attributes[od_geo_code1 | od_geo_code2, ]  # Inter-regional

# Inter-regional and within-region lines
l_geo_code1 <- l_all$geo_code1 %in% z$geo_code
l_geo_code2 <- l_all$geo_code2 %in% z$geo_code
l <- l_all[l_geo_code1 | l_geo_code2, ]  # Inter-regional
l_regional <- l_all[l_geo_code1 & l_geo_code2, ] # Within Region

# Additional sub-setting of lines for minflow for visualisation / download
l <- l[l$all >= region_build_param$minflow_visualise, ]
l_regional <- l_regional[l_regional@data$id %in% l@data$id, ] 

# Inter-regional routes
rf <- rf_all[rf_all$id %in% l$id,]
rq <- rq_all[rq_all$id %in% l$id,]

# Save params to build_params for the study region
build_params[build_params$region_name == region, ]$n_flow <- nrow(l)
build_params[build_params$region_name == region, ]$n_people <- sum(l$all)


###########################
### RUN RNET (UNLESS FLAGGED NOT TO IN BUILD PARAM CSV)
###########################
if (region_build_param$to_rebuild_rnet=="1") {

 # DEFINE SCENARIOS
 scenarios <- c("govtarget_slc", "nearmkt_slc", "gendereq_slc", "dutch_slc", "ebike_slc")
 
 # IDENTIFY WITHIN-REGION FAST ROUTES, SUBSET BY MIN FLOW
 rf_rnet <- rf_all[rf_all$id %in% l_regional$id,]
 rf_rnet <- rf_rnet[rf_rnet$all >= region_build_param$minflow_rnet, ]
 rf_rnet <- rf_rnet[,c("id", "all", "bicycle", scenarios)]

 build_params[build_params$region_name == region, ]$n_flow_rnet <- nrow(rf_rnet)
 build_params[build_params$region_name == region, ]$n_people_rnet <- sum(rf_rnet$all)
 
 # REMOVE ZERO FLOWS & SIMPLIFY LINE GEOMETRIES TO SPEED UP BUILD (needs mapshaper installed & available: https://github.com/mbloch/mapshaper/wiki/)
 rf_rnet <- rf_rnet[(rf_rnet$ebike_slc > 0) | (rf_rnet$gendereq_slc > 0), ]
 rf_rnet <- ms_simplify(input = rf_rnet, keep = region_build_param$rnet_keep, method = "dp", keep_shapes = TRUE, snap = TRUE)

 # BUILD RNET FOR BASELINE 
 rnet <- overline(rf_rnet, "bicycle")

 # CREATE SCENARIO RESULTS IN A LIST IN PARALLEL
 n_cores <- 4 # set max number of cores to 4
 if(parallel:::detectCores() < 4) {n_cores <- parallel:::detectCores()}
 cl <- makeCluster(n_cores)
 registerDoParallel(cl)
 
 rf_rnet_data_list <- foreach(i = scenarios) %dopar% {
  rnet_tmp <- stplanr::overline(rf_rnet, i)
  rnet_tmp@data[i]
 }
 # SAVE SCENARIO RESULTS BACK INTO BASELINE
 for(j in seq_along(scenarios)){
  rnet@data <- cbind(rnet@data, rf_rnet_data_list[[j]])
 }
 stopCluster(cl = cl)

 # DIAGNOSTIC CHECK: REMOVE SEGMENTS WITH NO CYCLISTS (links to: https://github.com/npct/pct-shiny/issues/336/)
 rnet <- rnet[(rnet$ebike_slc > 0) | (rnet$gendereq_slc > 0),] # remove segments with zero cycling flows

 # IDENTIFY LINES IN A SINGLE ZONE [ANNA COMMENT - COULD REMOVE THIS VARIABLE, NOT SURE MUCH USED?]
 rnet$singlezone <- rowSums(gContains(z, rnet, byid = TRUE))
 rnet@data[rnet$singlezone == 0, grep(pattern = "upto", names(rnet))] = NA 

 # SET PROJECTION, CREATE ID
 rnet <- spTransform(rnet, proj_4326)
 rnet$local_id <- 1:nrow(rnet)
 rnet <- rnet[,c("local_id", "bicycle", scenarios,"singlezone")]
 
 # CHECK AGAINST CODE BOOK AND ROUND SCENARIO VALUES TO 2 DP
 rnet_codebook <- read_csv(file.path(path_codebooks, purpose, "rnet_codebook.csv"))
 rnet <- rnet[rnet_codebook$`Variable name`]
 rnet@data <- as.data.frame(apply(rnet@data, c(2), round, 2), stringsAsFactors = F)
}


###########################
### SAVE THE DATA
###########################

# SAVE OBJECTS
write_csv(od_attributes, file.path(path_outputs_regional_notR, purpose, geography, region, "od_attributes.csv"))
write_csv(z@data, file.path(path_outputs_regional_notR, purpose, geography, region, "z_attributes.csv"))
saveRDS(z, (file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds")))
geojson_write(z, file = file.path(path_outputs_regional_notR, purpose, geography, region, "z.geojson"))
saveRDS(c, (file.path(path_outputs_regional_R, purpose, geography, region, "c.Rds")))
geojson_write(c, file = file.path(path_outputs_regional_notR, purpose, geography, region, "c.geojson"))
saveRDS(l, (file.path(path_outputs_regional_R, purpose, geography, region, "l.Rds")))
geojson_write(l, file = file.path(path_outputs_regional_notR, purpose, geography, region, "l.geojson"))
saveRDS(rf, (file.path(path_outputs_regional_R, purpose, geography, region, "rf.Rds")))
geojson_write(rf, file = file.path(path_outputs_regional_notR, purpose, geography, region, "rf.geojson"))
saveRDS(rq, (file.path(path_outputs_regional_R, purpose, geography, region, "rq.Rds")))
geojson_write(rq, file = file.path(path_outputs_regional_notR, purpose, geography, region, "rq.geojson"))
if (region_build_param$to_rebuild_rnet=="1") {
  saveRDS(rnet, (file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds")))
  geojson_write(rnet, file = file.path(path_outputs_regional_notR, purpose, geography, region, "rnet.geojson"))
}

# SAVE UPDATED OUTPUT PARAMETERS TO CSV, AND RE-CREATE REGION PARAMS SO THEY ARE UPDATED
build_params[build_params$region_name == region, ]$build_date <- as.character(Sys.Date())
build_params[build_params$region_name == region, ]$run_min <- round(difftime(Sys.time(), start_time, units="mins"), digits=2)
write_csv(build_params, file.path(purpose, geography, "build_params_pct_region.csv"))
assign("region_build_param", subset(build_params, region_name == region), envir = .GlobalEnv)

