# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_R, purpose))) { dir.create(file.path(path_outputs_regional_R, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography))) { dir.create(file.path(path_outputs_regional_R, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_notR, purpose))) { dir.create(file.path(path_outputs_regional_notR, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography, region)) }

start_time <- Sys.time() # for timing the script


###########################
### SUBSET ZONES & SCHOOLS TO THE REGION
###########################

# Within-region zone + school
z <- z_all[z_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
d <- d_all[d_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]

###########################
### RUN RNET (UNLESS FLAGGED NOT TO IN BUILD PARAM CSV)
###########################
if (region_build_param$to_rebuild_rnet=="1") {
  
  # DEFINE SCENARIOS
  scenarios <- c("govtarget_slc","dutch_slc")
xrestart  
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
saveRDS(z, (file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds")))
geojson_write(z, file = file.path(path_outputs_regional_notR, purpose, geography, region, "z.geojson"))
saveRDS(d, (file.path(path_outputs_regional_R, purpose, geography, region, "d.Rds")))
geojson_write(d, file = file.path(path_outputs_regional_notR, purpose, geography, region, "d.geojson"))
