# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size = 1000000)

# SET INPUT PARAMETERS
purpose <- "commute"
geography <- "msoa"

if(!dir.exists(file.path(path_outputs_national, purpose))) { dir.create(file.path(path_outputs_national, purpose)) }
if(!dir.exists(file.path(path_outputs_national, purpose, geography))) { dir.create(file.path(path_outputs_national, purpose, geography)) }

#########################
### LOAD SHAPE AND SCENARIO FILES
#########################

# OPEN INPUT LINES AND ZONES SHAPE FILES
if(geography == "msoa") {
  unzip(file.path(path_inputs, "01_raw/01_geographies/msoa_boundaries/Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.zip"), exdir = path_temp_unzip)
  z_shape <- readOGR(file.path(path_temp_unzip, "Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.shp"))
  z_shape@data <- dplyr::rename(z_shape@data, geo_code = msoa11cd)
  c_shape <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/msoa_cents_mod.geojson"), layer = "OGRGeoJSON")
  c_shape@data <- dplyr::rename(c_shape@data, geo_code = msoa11cd)
} else if(geography == "lsoa") {
  unzip(file.path(path_inputs, "01_raw/01_geographies/lsoa_boundaries/Lower_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped__Boundaries_in_England_and_Wales.zip"), exdir = path_temp_unzip)
  z_shape <- readOGR(file.path(path_temp_unzip, "Lower_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped__Boundaries_in_England_and_Wales.shp"))
  z_shape@data <- dplyr::rename(z_shape@data, geo_code = `lsoa11cd`)
  c_shape <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/lsoa_cents_mod.geojson"), layer = "OGRGeoJSON")
  c_shape@data <- dplyr::rename(c_shape@data, geo_code = `lsoa11cd`)
} else {
}
z_shape <- spTransform(z_shape, proj_4326)
c_shape <- spTransform(c_shape, proj_4326)
l_shape <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "lines_cs.Rds"))
rf_shape <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "rf_shape.Rds"))
rq_shape <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "rq_shape.Rds"))
lad <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/lad.geojson"), layer = "OGRGeoJSON")
pct_regions_lowres <- readOGR(file.path(path_inputs,"02_intermediate/01_geographies/pct_regions_lowres.geojson"), layer = "OGRGeoJSON")


# OPEN ATTRIBUTE DATA 
z_all_attributes <- read_csv(file.path(path_outputs_national, purpose, geography, "z_all_attributes.csv"))
od_all_attributes <- read_csv(file.path(path_outputs_national, purpose, geography, "od_all_attributes.csv"))
lad_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, "lad_all_attributes.csv"))
pct_regions_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, "pct_regions_all_attributes.csv"))


# OPEN CODEBOOKS
z_codebook <- read_csv(file.path(path_codebooks, purpose, "z_codebook.csv"))
c_codebook <- read_csv(file.path(path_codebooks, purpose, "c_codebook.csv"))
od_l_rf_codebook <- read_csv(file.path(path_codebooks, purpose, "od_l_rf_codebook.csv"))
rq_codebook <- read_csv(file.path(path_codebooks, purpose, "rq_codebook.csv"))
lad_codebook <- read_csv(file.path(path_codebooks, purpose, "lad_codebook.csv"))


#########################
### MERGE IN SCENARIO DATA [not all of these apply to school]
#########################

# MERGE ZONE SCENARIO DATA TO ZONES FILE
summary({sel_zone <- z_shape$geo_code %in% z_all_attributes$geo_code}) # Check perfect match
z_shape <- z_shape[sel_zone,]  
z_shape@data <- data.frame(geo_code = z_shape$geo_code) 
z_shape@data <- left_join(z_shape@data, z_all_attributes, by="geo_code")
z_shape@data <- z_shape@data[z_codebook$`Variable name`]
saveRDS(z_shape, file.path(path_outputs_national, purpose, geography, "z_all.Rds"))
geojson_write(z_shape, file = file.path(path_outputs_national, purpose, geography, "z_all.geojson"))

# MERGE OD SCENARIO DATA TO CENTS FILE [commute, not schools]
# Combine 2 parts such that have zone names even when there is no within-zone travel
c_all_attributes1 <- z_all_attributes[,names(z_all_attributes) %in% c("geo_code", "geo_name", "lad11cd", "lad_name")]
c_all_attributes2 <- od_all_attributes[(od_all_attributes$geo_code1==od_all_attributes$geo_code2),]  # subset to within-zone lines  
c_all_attributes <- left_join(c_all_attributes1, c_all_attributes2, by=c("geo_code" = "geo_code1"))
for(i in 1:nrow(c_all_attributes)){
  if(is.na(c_all_attributes$all[i])) {c_all_attributes[i,c(13:75)] <- round(0)}
}
summary({sel_c <- c_shape$geo_code %in% c_all_attributes$geo_code}) # Check perfect match
c_shape <- c_shape[sel_c,] 
c_shape@data <- data.frame(geo_code = c_shape$geo_code) 
c_shape@data <- left_join(c_shape@data, c_all_attributes, by="geo_code")
c_shape@data <- c_shape@data[c_codebook$`Variable name`]
saveRDS(c_shape, file.path(path_outputs_national, purpose, geography, "c_all.Rds"))
geojson_write(c_shape, file = (file.path(path_outputs_national, purpose, geography, "c_all.geojson")))

# MERGE LINE SCENARIO DATA TO BETWEEN-ZONE LINES FILE
summary({sel_line1 <- (l_shape$id %in% rf_shape$id)}) # Limit to in rf (maxdist_visualise)
l_shape <- l_shape[sel_line1,]  
summary({sel_line2 <- (l_shape$id %in% od_all_attributes$id)}) # Limit to those with od_attributes (minflow_visualise)
l_shape <- l_shape[sel_line2,]  
l_shape@data <- data.frame(id = l_shape$id) 
l_shape@data <- left_join(l_shape@data, od_all_attributes, by="id")
l_shape@data <- l_shape@data[od_l_rf_codebook$`Variable name`]
saveRDS(l_shape, (file.path(path_outputs_national, purpose, geography, "l_all.Rds")))

# MERGE LINE SCENARIO DATA TO FAST ROUTES FILE
summary({sel_rf <- (rf_shape$id %in% od_all_attributes$id)}) # Limit to those with od_attributes (minflow_visualise)
rf_shape <- rf_shape[sel_rf,]  
rf_shape@data <- data.frame(id = rf_shape$id) 
rf_shape@data <- left_join(rf_shape@data, od_all_attributes, by="id")
rf_shape@data <- rf_shape@data[od_l_rf_codebook$`Variable name`]
saveRDS(rf_shape, (file.path(path_outputs_national, purpose, geography, "rf_all.Rds")))

# MERGE LINE SCENARIO DATA TO QUIET ROUTES FILE 
summary({sel_rq <- (rq_shape$id %in% od_all_attributes$id)}) # Limit to those with od_attributes (minflow_visualise)
rq_shape <- rq_shape[sel_rq,]  
rq_shape@data <- data.frame(id = rq_shape$id) 
rq_shape@data <- left_join(rq_shape@data, od_all_attributes, by="id")
rq_shape@data <- rq_shape@data[rq_codebook$`Variable name`]
saveRDS(rq_shape, (file.path(path_outputs_national, purpose, geography, "rq_all.Rds")))

# MERGE LA DATA TO LA GEO FILE [SAME REGARDLESS OF MSOA/LSOA] 
summary({sel_lad <- (lad$lad11cd %in% lad_all_attributes$lad11cd)}) # Should be perfect match
lad <- lad[sel_lad,]  
lad@data <- left_join(lad@data, lad_all_attributes, by = "lad11cd")
lad@data <- lad@data[lad_codebook$`Variable name`]
saveRDS(lad, (file.path(path_outputs_national, purpose, "lad.Rds")))
geojson_write(lad, file = file.path(path_outputs_national, purpose, "lad.geojson"))

# MERGE REGION DATA TO REGION GEO FILE [SAME REGARDLESS OF MSOA/LSOA] [NB CURRENTLY ONLY COMMUTE DATA, IN FUTURE ADD IN MORE THINGS HERE]
summary({sel_regions <- (pct_regions_lowres$region_name %in% pct_regions_all_attributes$region_name)}) # Should be perfect match
pct_regions_lowres <- pct_regions_lowres[sel_regions,]  
pct_regions_lowres@data <- left_join(pct_regions_lowres@data, pct_regions_all_attributes, by = "region_name")
geojson_write(pct_regions_lowres, file = file.path(path_shiny,"regions_www/pct_regions_lowres_scenario.geojson"))