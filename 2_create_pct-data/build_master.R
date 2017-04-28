# start with clear workspace (usually a good idea)
rm(list = ls())
# Setup libraries and functions
source("set-up.R")
# Setup paths
set_paths()
# Set geography and purpose for the build
set_geography_and_purpose(geography = "msoa", purpose = "commute")
# Check data present
data_check(geography, purpose)
# Read intructions for regions build - define region type and import local authorities
init_vars("pct-regions", purpose, geography)
# Load national variables (l_nat, rf_nat etc)
init_national_variables(purpose, geography)

# TODO rename Region to region_name
# in pct-shiny

# Read all regions
regions_all <- as.character(regions$Region)
regions_tobuild <- as.logical(build_params$to_rebuild)
regions_all <- regions_all[regions_tobuild]

starttime = proc.time()

for(k in 1:length(regions_all)){

  region <- regions_all[k]
  
  
  region_shape <- regions[grep(pattern = region, x = regions$Region, ignore.case = T),]
  
  build_regions_params <- subset(build_params, region_name == region)
  
  # Subset regions geometry to the selected region (k[i])
  regions[grep(pattern = region, x = regions$Region, ignore.case = T),]
  
  # Build the regions (comment out if the data has already been build)
  message(paste0("Building for ", region))
  #source("2_create_pct-data/build_region.R") # comment out to skip build
  
  # Write the model output files (comment out to not report data)
  message(paste0("Writing the output file for ", region))
  # pct-load\2_create_pct-data\commute\msoa
  knitr::knit2html(quiet = T,
    input = file.path("2_create_pct-data", purpose, geography, "model_output.Rmd"),
    output = file.path(pct_data, purpose, geography, region, "model-output.html"),
    envir = globalenv(), force_v1 = T
  )
  # Re read the model output file
  model_output =
    readLines(file.path(pct_data, purpose, geography, region, "model-output.html"))
  # remove style section
  model_output <- remove_style(model_output)
  # Add a special class to all tables for the shiny application
  model_output <- add_table_class(model_output)
  # Re-write the model output file
  write(model_output, file.path(pct_data, purpose, geography, region, "model-output.html"))
  message(paste0("Just built ", region))
}

endtime = proc.time()
print(endtime-starttime)

# update table tracking builds
# source("R/to_build.R")
# # # For custom regions:
# regions <- shapefile("../pct-bigdata/custom-regions/CloHAM.shp")
# regions$Region <- tolower(regions$Name) # add region names
# la_all <- regions$Region

# # # For Local Authorities
# regions <- readOGR(dsn = "../pct-bigdata/cuas-mf.geojson", layer = "OGRGeoJSON")
# regions$Region <- regions$CTYUA12NM
# regions$Region <- tolower(as.character(regions$Region))
