if(!file.exists("../pct-bigdata/msoa/rf_nat.Rds")) {
  stop("Error: download data from: https://github.com/npct/pct-bigdata/releases")
}
rm(list = ls()) # start with clear workspace (usually a good idea)
source("set-up.R")
to_build = read_csv("to_rebuild_updated.csv")

# For PCT regions:
pct_data <- file.path("..", "pct-data")
pct_bigdata <- file.path("..", "pct-bigdata")
pct_shiny_regions <- file.path("..", "pct-shiny", "regions_www")
regions <- geojson_read("../pct-shiny/regions_www/regions.geojson", what = "sp")
la_all <- as.character(regions$Region)
tobuild = as.logical(as.numeric(to_build$to_rebuild))
tobuild[is.na(tobuild)] = FALSE
(la_all = la_all[tobuild])
(la_all = la_all[grepl(pattern = "west-mid|north-east|leicest|notti|north-york|northamptons", x = la_all) ]) # regions to omit
# (la_all = la_all[2:3]) # the first n. not yet done
# (la_all = la_all[grep(pattern = "hereford|xxx", la_all)]) # from exist regions
# la_all = "london" # a single region

params <- NULL # build parameters (saved for future reference)
params$mflow <- 10 # minimum flow between od pairs to show for longer lines, high means fewer lines
params$mflow_short <- 10 # minimum flow between od pairs to show for short lines, high means fewer lines
params$mdist <- 20 # maximum euclidean distance (km) for subsetting lines
params$max_all_dist <- 7 # maximum distance (km) below which more lines are selected
params$buff_dist <- 0 # buffer (km) used to select additional zones (often zero = ok)
# parameters related to the route network
params$buff_geo_dist <- 100 # buffer (m) for removing line start and end points for network
# params$min_rnet_length <- 2 # minimum segment length for the Route Network to display (may create holes in rnet)

starttime = proc.time()

k = 1 # for testing in the for loop
for(k in 1:length(la_all)){
  
  # What geographic level are we working at (cua or regional)
  geo_level <- "regional"
  region <- la_all[k]
  
  # to override parameters set above
  # params = readRDS(paste0("../pct-data/", region, "/params.Rds"))
  params$rft_keep = 0.15 # how aggressively to simplify the route network
  
  isolated <- FALSE # make the region not isolated (default)
  if(grepl(pattern = "london", region))
    isolated <- TRUE
  if(isolated) file.create(file.path(pct_data, region, "isolated"))

  # Build the regions (comment out if the data has already been build)
  message(paste0("Building for ", region))
  source("shared_build.R")
  source("build_region.R") # comment out to skip build
  # Write the model output files (comment out to not report data)
  # message(paste0("Writing the output file for ", region))
  knitr::knit2html(quiet = T,
    input = "model_output.Rmd",
    output = file.path(pct_data, region, "model-output.html"),
    envir = globalenv(), force_v1 = T
  )
  # Re read the model output file
  model_output =
    readLines(file.path(pct_data, region, "model-output.html"))
  # remove style section
  model_output <- remove_style(model_output)
  # Add a special class to all tables for the shiny application
  model_output <- add_table_class(model_output)
  # Re-write the model output file
  write(model_output, file.path(pct_data, region, "model-output.html"))
  message(paste0("Just built ", region))
  # # Update the data sha - uncomment to automate this (from unix machines)
  # source("update_sha.R")
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
