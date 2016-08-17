# Aim: initialise build process

# source("set-up.R") # load packages needed - commented as run in buildmaster
start_time <- Sys.time() # for timing the script

if(!exists("region")) region <- "cambridgeshire" # create LA name if none exists,  then set-up data repo
pct_data <- file.path("..", "pct-data")
pct_bigdata <- file.path("..", "pct-bigdata")
pct_privatedata <- file.path("..", "pct-privatedata")
pct_shiny_regions <- file.path("..", "pct-shiny", "regions_www")
if(!file.exists(pct_data)) stop(paste("The pct-data repository cannot be found.  Please clone https://github.com/npct/pct-data in", dirname(getwd())))
if(!file.exists(pct_bigdata)) stop(paste("The pct-bigdata repository cannot be found.  Please clone https://github.com/npct/pct-bigdata in", dirname(getwd())))
scens <- c("govtarget_slc", "gendereq_slc", "dutch_slc", "ebike_slc")

# Set local authority and ttwa zone names
region_path <- file.path(pct_data, region)
if(!dir.exists(region_path)) dir.create(region_path) # create data directory

params <- NULL # build parameters (saved for future reference)
params$mflow <- 10 # minimum flow between od pairs to show for longer lines, high means fewer lines
params$mflow_short <- 10 # minimum flow between od pairs to show for short lines, high means fewer lines
params$mdist <- 20 # maximum euclidean distance (km) for subsetting lines
params$max_all_dist <- 7 # maximum distance (km) below which more lines are selected
params$buff_dist <- 0 # buffer (km) used to select additional zones (often zero = ok)
# parameters related to the route network
params$buff_geo_dist <- 100 # buffer (m) for removing line start and end points for network
# params$min_rnet_length <- 2 # minimum segment length for the Route Network to display (may create holes in rnet)
params$rft_keep = 0.05 # how aggressively to simplify the route network (higher values - longer to run but rnet less likely to fail)
if(!exists("ukmsoas")){ # MSOA zones
  ukmsoas <- readRDS(file.path(pct_bigdata, "ukmsoas-scenarios.Rds"))
  ukmsoas$avslope = ukmsoas$avslope * 100
}
if(!exists("centsa")) # Population-weighted centroids
  centsa <- readOGR(file.path(pct_bigdata, "cents-scenarios.geojson"), "OGRGeoJSON")
centsa$geo_code <- as.character(centsa$geo_code)

# Load local authorities and districts
if(!exists("geo_level")) geo_level <- "regional"
# if you use a custom geometry, regions should already be saved from buildmaster.R

if(!exists("regions")){
  if (geo_level == "regional")
    regions <-
  readOGR(file.path(pct_bigdata, "regions.geojson"), layer = "OGRGeoJSON")
  else {
    regions <- readOGR(dsn = file.path(pct_bigdata, "cuas-mf.geojson"), layer = "OGRGeoJSON")
    regions$Region <- regions$CTYUA12NM
  }
}
region_shape <- region_orig <- # create region shape (and add buffer in m)
  regions[grep(pattern = region, x = regions$Region, ignore.case = T),]

# Only transform if needed
if(params$buff_dist > 0){
  region_shape <- spTransform(region_shape, CRS("+init=epsg:27700"))
  region_shape <- gBuffer(region_shape, width = params$buff_dist * 1000)
  if(!exists("centsa")) # Population-weighted centroids
    centsa <- readOGR(file.path(pct_bigdata, "cents-scenarios.geojson"), "OGRGeoJSON")
  region_shape <- spTransform(region_shape, proj4string(centsa))
}
if(!exists("las"))
  las <- readOGR(dsn = file.path(pct_bigdata, "las-pcycle.geojson"), layer = "OGRGeoJSON")
if(!exists("las_cents"))
  las_cents <- SpatialPoints(coordinates(las))

# load in codebook data
codebook_l = readr::read_csv("../pct-shiny/static/codebook_lines.csv")
codebook_z = readr::read_csv("../pct-shiny/static/codebook_zones.csv")

# load flow dataset, depending on availability
if(!exists("flow_nat")){
  flow_nat <- readRDS(file.path(pct_bigdata, "lines_oneway_shapes_updated.Rds"))
  flow_nat <- flow_nat[flow_nat$dist > 0,]}