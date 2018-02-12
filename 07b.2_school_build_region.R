# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_R, purpose))) { dir.create(file.path(path_outputs_regional_R, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography))) { dir.create(file.path(path_outputs_regional_R, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_R, purpose_download))) { dir.create(file.path(path_outputs_regional_R, purpose_download)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose_download, geography))) { dir.create(file.path(path_outputs_regional_R, purpose_download, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose_download, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose_download, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_notR, purpose_download))) { dir.create(file.path(path_outputs_regional_notR, purpose_download)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose_download, geography))) { dir.create(file.path(path_outputs_regional_notR, purpose_download, geography)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose_download, geography, region))) { dir.create(file.path(path_outputs_regional_notR, purpose_download, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_R, purpose_private))) { dir.create(file.path(path_outputs_regional_R, purpose_private)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose_private, geography))) { dir.create(file.path(path_outputs_regional_R, purpose_private, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose_private, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose_private, geography, region)) }

start_time <- Sys.time() # for timing the script

###########################
### SUBSET ZONES & SCHOOLS TO THE REGION
###########################

# Within-region zone + school
z <- z_all[z_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
z_download <- z_all_download[z_all_download@data$lad11cd %in% region_lad_lookup$lad11cd, ]
z_private <- z_all_private[z_all_private@data$lad11cd %in% region_lad_lookup$lad11cd, ]

d <- d_all[d_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
d_download <- d_all_download[d_all_download@data$lad11cd %in% region_lad_lookup$lad11cd, ]
d_private <- d_all_private[d_all_private@data$lad11cd %in% region_lad_lookup$lad11cd, ]

###########################
### RUN RNET (UNLESS FLAGGED NOT TO IN BUILD PARAM CSV)
###########################
if (region_build_param$to_rebuild_rnet=="1") {
  # DEFINE SCENARIOS
  scenarios <- c("govtarget_slc","dutch_slc")

  # IDENTIFY WITHIN-REGION FAST ROUTES
  rnet_attributes <- rnet_all_attributes[(rnet_all_attributes$geo_code_o %in% z@data$geo_code) & (rnet_all_attributes$urn %in% d@data$urn), ]
  summary({sel_rf <- rf_shape@data$id %in% rnet_attributes$id}) 
  rf_rnet <- rf_shape[sel_rf,]  
  rf_rnet@data <- data.frame(id = rf_rnet$id) 
  rf_rnet@data <- left_join(rf_rnet@data, rnet_attributes, by="id")  
  
  # SUBSET BY MIN FLOW
  rf_rnet <- rf_rnet[rf_rnet$all >= region_build_param$minflow_rnet, ]
  rf_rnet <- rf_rnet[,c("id", "all", "bicycle", scenarios)]
  
  build_params[build_params$region_name == region, ]$n_flow_rnet <- nrow(rf_rnet)
  build_params[build_params$region_name == region, ]$n_people_rnet <- sum(rf_rnet$all)
  
  # REMOVE ZERO FLOWS & SIMPLIFY LINE GEOMETRIES TO SPEED UP BUILD (needs mapshaper installed & available: https://github.com/mbloch/mapshaper/wiki/)
  rf_rnet <- rf_rnet[(rf_rnet$dutch_slc > 0), ]
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
  rnet <- rnet[(rnet$dutch_slc > 0),] # remove segments with zero cycling flows

  # SET PROJECTION, CREATE ID
  rnet <- spTransform(rnet, proj_4326)
  rnet$local_id <- 1:nrow(rnet)
  rnet <- rnet[,c("local_id", "bicycle", scenarios)]
  
  # CHECK AGAINST CODE BOOK AND ROUND SCENARIO VALUES TO 2 DP
  rnet_codebook <- read_csv(file.path(path_codebooks, purpose, "rnet_codebook.csv"))
  rnet <- rnet[rnet_codebook$`Variable name`]
  rnet@data <- as.data.frame(apply(rnet@data, c(2), round, 2), stringsAsFactors = F)
  
  # FOR SDC CONTROLS, SET AS MISSING VALUES WHERE BICYCLE 1 OR 2, AND SCENARIO VALUE <=2
  rnet_private <- rnet
  
  rnet_download <- rnet
  rnet_download@data$bicycle[rnet_download@data$bicycle>0 & rnet_download@data$bicycle<=2] <- NA
  for(i in scenarios){
    rnet_download@data[[i]][is.na(rnet_download@data$bicycle) & rnet_download@data[[i]]<=2] <- NA
  }
  
  rnet@data$bicycle[rnet@data$bicycle>0 & rnet@data$bicycle<=2] <- 1.5
  for(i in scenarios){
    rnet@data[[i]][rnet@data$bicycle>0 & rnet@data$bicycle<=2 & rnet@data[[i]]<=2] <- 1.5
  }
  
}

###########################
### SAVE THE DATA
###########################

# SAVE OBJECTS
saveRDS(z, (file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds")))

write_csv(z_download@data, file.path(path_outputs_regional_notR, purpose_download, geography, region, "z_attributes.csv"))
saveRDS(z_download, (file.path(path_outputs_regional_R, purpose_download, geography, region, "z.Rds")))
geojson_write(z_download, file = file.path(path_outputs_regional_notR, purpose_download, geography, region, "z.geojson"))

saveRDS(z_private, (file.path(path_outputs_regional_R, purpose_private, geography, region, "z.Rds")))


saveRDS(d, (file.path(path_outputs_regional_R, purpose, geography, region, "d.Rds")))

write_csv(d_download@data, file.path(path_outputs_regional_notR, purpose_download, geography, region, "d_attributes.csv"))
saveRDS(d_download, (file.path(path_outputs_regional_R, purpose_download, geography, region, "d.Rds")))
geojson_write(d_download, file = file.path(path_outputs_regional_notR, purpose_download, geography, region, "d.geojson"))

saveRDS(d_private, (file.path(path_outputs_regional_R, purpose_private, geography, region, "d.Rds")))


if (region_build_param$to_rebuild_rnet=="1") {
  saveRDS(rnet, (file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds")))
  saveRDS(rnet_download, (file.path(path_outputs_regional_R, purpose_download, geography, region, "rnet.Rds")))
  geojson_write(rnet_download, file = file.path(path_outputs_regional_notR, purpose_download, geography, region, "rnet.geojson"))
  saveRDS(rnet_private, (file.path(path_outputs_regional_R, purpose_private, geography, region, "rnet.Rds")))
}

# SAVE UPDATED OUTPUT PARAMETERS TO CSV, AND RE-CREATE REGION PARAMS SO THEY ARE UPDATED
build_params[build_params$region_name == region, ]$build_date <- as.character(Sys.Date())
build_params[build_params$region_name == region, ]$run_min <- round(difftime(Sys.time(), start_time, units="mins"), digits=2)
write_csv(build_params, file.path(purpose, geography, "build_params_pct_region.csv"))
assign("region_build_param", subset(build_params, region_name == region), envir = .GlobalEnv)