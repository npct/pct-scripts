# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_R, purpose))) { dir.create(file.path(path_outputs_regional_R, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography))) { dir.create(file.path(path_outputs_regional_R, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_notR, purpose))) { dir.create(file.path(path_outputs_regional_notR, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography, region)) }

start_time <- Sys.time() # for timing the script


###########################
### SUBSET ZONES, CENTS AND LINES TO THE REGION
###########################

# Within-region zone and centroids
z <- z_all[z_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
zsmall <- z[z_codebook_small$`Variable name`]

c <- c_all[c_all@data$geo_code %in% z$geo_code, ]
csmall <- c[c_codebook_small$`Variable name`]

# Inter-regional attribute data
od_geo_code1 <- od_all_attributes$geo_code1 %in% z$geo_code
od_geo_code2 <- od_all_attributes$geo_code2 %in% z$geo_code
od_attributes <- od_all_attributes[od_geo_code1 | od_geo_code2, ]  # Inter-regional

# Inter-regional and within-region lines
l_geo_code1 <- l_all$geo_code1 %in% z$geo_code
l_geo_code2 <- l_all$geo_code2 %in% z$geo_code
l <- l_all[l_geo_code1 | l_geo_code2, ]  # Inter-regional

# Additional sub-setting of lines for minflow for visualisation / download, and maxdist for online
l <- l[l$all >= region_build_param$minflow_visualise, ] # for download

lsmall <- l[l@data$rf_dist_km<=maxdist_online,]
lsmall <- lsmall[od_l_rf_codebook_small$`Variable name`] # for online

# Inter-regional routes
rf <- rf_all[rf_all$id %in% l$id,]
rfsmall <- rf[rf$id %in% lsmall$id,]
rfsmall <- rfsmall[od_l_rf_codebook_small$`Variable name`]

rq <- rq_all[rq_all$id %in% l$id,]
rqsmall <- rq[rq$id %in% lsmall$id,]
rqsmall <- rqsmall[rq_codebook_small$`Variable name`]

# Save params to build_params for the study region
build_params[build_params$region_name == region, ]$n_flow <- nrow(l)
build_params[build_params$region_name == region, ]$n_people <- sum(l$all)


###########################
### SAVE THE DATA
###########################

# SAVE OBJECTS
write_csv(od_attributes, file.path(path_outputs_regional_notR, purpose, geography, region, "od_attributes.csv"))

saveRDS(z, (file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds")) , version = 2)
write_csv(z@data, file.path(path_outputs_regional_notR, purpose, geography, region, "z_attributes.csv"))
geojson_write(z, file = file.path(path_outputs_regional_notR, purpose, geography, region, "z.geojson"))
saveRDS(zsmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "z.Rds")) , version = 2)

saveRDS(c, (file.path(path_outputs_regional_R, purpose, geography, region, "c.Rds")) , version = 2)
geojson_write(c, file = file.path(path_outputs_regional_notR, purpose, geography, region, "c.geojson"))
saveRDS(csmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "c.Rds")) , version = 2)

saveRDS(l, (file.path(path_outputs_regional_R, purpose, geography, region, "l.Rds")) , version = 2)
geojson_write(l, file = file.path(path_outputs_regional_notR, purpose, geography, region, "l.geojson"))
saveRDS(lsmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "l.Rds")) , version = 2)

saveRDS(rf, (file.path(path_outputs_regional_R, purpose, geography, region, "rf.Rds")) , version = 2)
geojson_write(rf, file = file.path(path_outputs_regional_notR, purpose, geography, region, "rf.geojson"))
saveRDS(rfsmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "rf.Rds")) , version = 2)

saveRDS(rq, (file.path(path_outputs_regional_R, purpose, geography, region, "rq.Rds")) , version = 2)
geojson_write(rq, file = file.path(path_outputs_regional_notR, purpose, geography, region, "rq.geojson"))
saveRDS(rqsmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "rq.Rds")) , version = 2)


# SAVE UPDATED OUTPUT PARAMETERS TO CSV, AND RE-CREATE REGION PARAMS SO THEY ARE UPDATED
build_params[build_params$region_name == region, ]$build_date <- as.character(Sys.Date())
build_params[build_params$region_name == region, ]$run_min <- round(difftime(Sys.time(), start_time, units="mins"), digits=2)
write_csv(build_params, file.path(purpose, geography, "build_params_pct_region.csv"))
assign("region_build_param", subset(build_params, region_name == region), envir = .GlobalEnv)

