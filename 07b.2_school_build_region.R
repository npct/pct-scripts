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

# Within-region zone
z <- z_all[z_all@data$lad11cd %in% region_lad_lookup$lad11cd, ]

# to do :add in subset of regions and schools, with shcools either via spatial look up or via LA code [latter safer?]

###########################
### SAVE THE DATA
###########################

# SAVE OBJECTS
saveRDS(z, (file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds")))
geojson_write(z, file = file.path(path_outputs_regional_notR, purpose, geography, region, "z.geojson"))
