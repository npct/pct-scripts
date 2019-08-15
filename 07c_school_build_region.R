# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_R, purpose))) { dir.create(file.path(path_outputs_regional_R, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography))) { dir.create(file.path(path_outputs_regional_R, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_notR, purpose))) { dir.create(file.path(path_outputs_regional_notR, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_notR, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_notR, purpose, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_R, purpose_private))) { dir.create(file.path(path_outputs_regional_R, purpose_private)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose_private, geography))) { dir.create(file.path(path_outputs_regional_R, purpose_private, geography)) }
if(!dir.exists(file.path(path_outputs_regional_R, purpose_private, geography, region))) { dir.create(file.path(path_outputs_regional_R, purpose_private, geography, region)) }

if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography, region)) }

start_time <- Sys.time() # for timing the script

###########################
### SUBSET ZONES & SCHOOLS TO THE REGION
###########################

# Within-region zone + school
z <- z_all[z_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
zsmall <- z[z_codebook_small$`Variable name`]
z_private <- z_all_private[z_all_private@data$lad11cd %in% region_lad_lookup$lad11cd, ]

d <- d_all[d_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]
dsmall <- d[d_codebook_small$`Variable name`]
d_private <- d_all_private[d_all_private@data$lad11cd %in% region_lad_lookup$lad11cd, ]


###########################
### SAVE THE DATA
###########################

# SAVE OBJECTS
write_csv(z@data, file.path(path_outputs_regional_notR, purpose, geography, region, "z_attributes.csv"))
saveRDS(z, (file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds")) , version = 2)
geojson_write(z, file = file.path(path_outputs_regional_notR, purpose, geography, region, "z.geojson"))

saveRDS(zsmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "z.Rds")) , version = 2)
saveRDS(z_private, (file.path(path_outputs_regional_R, purpose_private, geography, region, "z.Rds")) , version = 2)


write_csv(d@data, file.path(path_outputs_regional_notR, purpose, geography, region, "d_attributes.csv"))
saveRDS(d, (file.path(path_outputs_regional_R, purpose, geography, region, "d.Rds")) , version = 2)
geojson_write(d, file = file.path(path_outputs_regional_notR, purpose, geography, region, "d.geojson"))

saveRDS(dsmall, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "d.Rds")) , version = 2)
saveRDS(d_private, (file.path(path_outputs_regional_R, purpose_private, geography, region, "d.Rds")) , version = 2)


# SAVE UPDATED OUTPUT PARAMETERS TO CSV, AND RE-CREATE REGION PARAMS SO THEY ARE UPDATED
build_params[build_params$region_name == region, ]$build_date <- as.character(Sys.Date())
build_params[build_params$region_name == region, ]$run_min <- round(difftime(Sys.time(), start_time, units="mins"), digits=2)
write_csv(build_params, file.path(purpose, geography, "build_params_pct_region.csv"))
assign("region_build_param", subset(build_params, region_name == region), envir = .GlobalEnv)