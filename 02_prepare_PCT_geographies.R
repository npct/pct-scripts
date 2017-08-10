# SET UP
rm(list = ls())
source("00_setup_and_funs.R")

#########################
### CREATE LOCAL AUTHORITIES AND PCT REGIONS FROM MSOA
#########################

# LOAD FILES
unzip(file.path(path_inputs, "01_raw/01_geographies/geography_lookups/OA11_LSOA11_MSOA11_LAD11_EW_LU.zip"), files = "OA11_LSOA11_MSOA11_LAD11_EW_LUv2.csv", exdir = path_temp_unzip)
msoa_lad_lookup <- read_csv(file.path(path_temp_unzip, "OA11_LSOA11_MSOA11_LAD11_EW_LUv2.csv"))[ ,c('MSOA11CD', 'LAD11CD', 'LAD11NM')]

pct_regions_lad_lookup <- read_csv(file.path(path_inputs, "01_raw/01_geographies/pct_regions/pct_regions_lad_lookup.csv"))

unzip(file.path(path_inputs, "01_raw/01_geographies/msoa_boundaries/Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.zip"), exdir = path_temp_unzip)
msoa_geo <- readOGR(file.path(path_temp_unzip, "Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.shp"))
msoa_geo <- spTransform(msoa_geo, proj_4326)

unzip(file.path(path_inputs, "01_raw/01_geographies/lad_boundaries/Local_Authority_Districts_December_2014_Ultra_Generalised_Clipped_Boundaries_in_Great_Britain.zip"), exdir = path_temp_unzip)
lad_ultragen <- readOGR(file.path(path_temp_unzip, "Local_Authority_Districts_December_2014_Ultra_Generalised_Clipped_Boundaries_in_Great_Britain.shp"))
lad_ultragen <- spTransform(lad_ultragen, proj_4326)

# MERGE LAD INTO MSOA
msoa_lad_lookup <- unique(msoa_lad_lookup)
names(msoa_lad_lookup) <- tolower(names(msoa_lad_lookup))
msoa_geo@data <- left_join(msoa_geo@data, msoa_lad_lookup, by = "msoa11cd")
  ## add in merge City of London and Isles of Scilly?

# DISSOLVE MSOA TO GIVE LAD, AND REMOVE ISLANDS
min_island_size <- 2500000 # choose this number as minimum island size to keep
lad <- ms_dissolve(msoa_geo, field = "lad11cd") 
lad <- ms_filter_islands(lad, min_area = min_island_size) 
lad <- spTransform(lad, proj_4326)
lad@data <- lad@data[, c(2,1)]
# mapview::mapview(lad)
geojson_write(lad, file = file.path(path_inputs, "02_intermediate/01_geographies/lad.geojson"))

# MERGE PCT-REGIONS INTO LAD, DISSOLVE TO HIGH-RES REGIONS
lad@data <- left_join(lad@data, pct_regions_lad_lookup, by = "lad11cd")
pct_regions_highres <- ms_dissolve(lad, field = "region_name")
pct_regions_highres@data <- pct_regions_highres@data[, c(2,1)]
#mapview::mapview(pct_regions_highres)
geojson_write(pct_regions_highres, file = file.path(path_inputs, "02_intermediate/01_geographies/pct_regions_highres.geojson"))
# Save a copy in pct_interface, so don't need to clone inputs folder
geojson_write(pct_regions_highres, file = file.path(path_shiny, "regions_www/pct_regions_highres.geojson"))

# MERGE PCT-REGIONS INTO LAD-ULTRAGEN, DISSOLVE INTO REGIONS FOR FRONT PAGE
summary({sel_ew <- lad_ultragen$lad14cd %in% pct_regions_lad_lookup$lad14cd}) 
lad_ultragen <- lad_ultragen[sel_ew,]  # subset to those with attribute data, i.e. England and Wales
lad_ultragen <- ms_filter_islands(lad_ultragen, min_area = min_island_size) 

lad_ultragen@data <- left_join(lad_ultragen@data, pct_regions_lad_lookup, by = "lad14cd")
pct_regions_lowres <- ms_dissolve(lad_ultragen, field = "region_name")
pct_regions_lowres@data <- pct_regions_lowres@data[, c(2,1)]
#mapview::mapview(pct_regions_lowres)
geojson_write(pct_regions_lowres, file = file.path(path_inputs, "02_intermediate/01_geographies/pct_regions_lowres.geojson"))


#########################
### UPDATE ZONE CENTROIDS OF FAR-FROM-ROADS POINTS, SO WORK WITH CYCLE STREETS [https://gridreferencefinder.com/]
#########################

# ANNA NOTE: NEXT NAT BUILD, DO THIS USING 'NEAREST POINT'

# OPEN MSOA CENTS FILE & MODIFY EASTINGS/NORTHINGS OF 9 POINTS
unzip(file.path(path_inputs, "01_raw/01_geographies/msoa_centroids/Middle_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.zip"), exdir = path_temp_unzip)
msoa_cents <- readOGR(file.path(path_temp_unzip, "Middle_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp"))
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005708", 1] <- -1.9114494
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005708", 2] <- 55.55233
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005810", 1] <- -1.2026666
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005810", 2] <- 53.835739 
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02002770", 1] <- -0.55274963
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02002770", 2] <- 53.481202 
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02004068", 1] <- -1.7088461
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02004068", 2] <- 53.311314
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005564", 1] <- 0.46159744
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005564", 2] <- 52.679661 
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005921", 1] <- -1.3786057
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02005921", 2] <- 52.096699
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02003655", 1] <- -0.99923582
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02003655", 2] <- 51.935956 
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02004228", 1] <- -4.257803
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02004228", 2] <- 50.813311 
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02003005", 1] <- -2.6020436
msoa_cents@coords[msoa_cents@data$msoa11cd=="E02003005", 2] <- 51.33469 
msoa_cents@data <- msoa_cents@data[,c("msoa11cd", "msoa11nm")]
msoa_cents <- spTransform(msoa_cents, proj_4326)
geojson_write(msoa_cents, file = file.path(path_inputs, "02_intermediate/01_geographies/msoa_cents_mod.geojson"))

# OPEN LSOA CENTS FILE & MODIFY EASTINGS/NORTHINGS OF 10 POINTS
unzip(file.path(path_inputs, "01_raw/01_geographies/lsoa_centroids/Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.zip"), exdir = path_temp_unzip)
lsoa_cents <- readOGR(file.path(path_temp_unzip, "Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.shp"))
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01013048", 1] <- -0.194517  
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01013048", 2] <- 53.917793
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01013787", 1] <- -0.745443   
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01013787", 2] <- 52.622431
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019091", 1] <- -3.444470  
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019091", 2] <- 54.631903
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019131", 1] <- -3.049498   
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019131", 2] <- 54.765063
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019309", 1] <- -2.321939  
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019309", 2] <- 54.513082 
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019310", 1] <- -2.580216   
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019310", 2] <- 54.556885
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019313", 1] <- -2.931806   
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01019313", 2] <- 54.657754
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01022207", 1] <- -1.832686   
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="E01022207", 2] <- 51.690425
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="W01001933", 1] <- -4.0169191
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="W01001933", 2] <- 52.588397
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="W01000776", 1] <- -4.1819715
lsoa_cents@coords[lsoa_cents@data$lsoa11cd=="W01000776", 2] <- 51.604265
lsoa_cents@data <- lsoa_cents@data[,c("lsoa11cd", "lsoa11nm")]
lsoa_cents <- spTransform(lsoa_cents, proj_4326)
geojson_write(lsoa_cents, file = file.path(path_inputs, "02_intermediate/01_geographies/lsoa_cents_mod.geojson"))


#########################
### DELETE TEMP FILES
#########################

# do.call(file.remove, list(list.files(file.path(path_temp_unzip), full.names = TRUE)))
