# Update the route network for a region (run within buildmaster.R loop)

# Pre-amble from build_region
start_time <- Sys.time() # for timing the script
if(!exists("region")) region <- "cambridgeshire"
pct_data <- file.path("..", "pct-data")
pct_bigdata <- file.path("..", "pct-bigdata")
pct_privatedata <- file.path("..", "pct-privatedata")
pct_shiny_regions <- file.path("..", "pct-shiny", "regions_www")
if(!file.exists(pct_data)) stop(paste("The pct-data repository cannot be found.  Please clone https://github.com/npct/pct-data in", dirname(getwd())))
if(!file.exists(pct_bigdata)) stop(paste("The pct-bigdata repository cannot be found.  Please clone https://github.com/npct/pct-bigdata in", dirname(getwd())))
scens <- c("govtarget_slc", "gendereq_slc", "dutch_slc", "ebike_slc")

rf = readRDS(file.path(pct_data, region, "rf.Rds"))
rq = readRDS(file.path(pct_data, region, "rq.Rds"))

rft_too_large <-  too_large(rf)
rft <- rf
rft@data <- cbind(rft@data, l@data[c("bicycle", scens)])
rft <- ms_simplify(input = rft, keep = 0.05, keep_shapes = T, no_repair = rft_too_large)

source("R/generate_rnet.R
       ")