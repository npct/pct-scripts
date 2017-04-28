source("set-up.R")
library(lubridate)
regions = readOGR("../pct-shiny/regions_www/regions.geojson", layer = "OGRGeoJSON")
regions = as.character(regions$Region)
dat <- NULL
for(i in 1:length(regions)){
  params <- readRDS(paste0("../pct-data/", regions[i], "/params.rds"))
  cat(params$buff_geo_dist, "\n")
  # "mflow", "mdist", "rft_keep", "n_flow_region", "n_commutes_region", "build_date", "run_time"  
  # dat$region[i] <- regions[i]
  # dat$mflow[i] <- params$mflow
  # dat$mdist[i] <- params$mdist
  # dat$rft_keep[i] <- params$rft_keep
  # dat$n_flow_region[i] <- params$n_flow_region
  # dat$n_commutes_region[i] <- params$n_commutes_region
  # dat$build_date[i] <- params$build_date
  # dat$run_time[i] <- params$run_time
}
class(dat$build_date) <- "Date"
write_csv(as.data.frame(dat), "build_params.csv")
