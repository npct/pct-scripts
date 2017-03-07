# Aim: merge in the centroids data
source("set-up.R")

# For PCT regions:
pct_data <- file.path("..", "pct-data")
pct_bigdata <- file.path("..", "pct-bigdata")
pct_shiny_regions <- file.path("..", "pct-shiny", "regions_www")

la <- readOGR(file.path(pct_bigdata, "las-pcycle.geojson"), "OGRGeoJSON")
la_old <- la # save backup - we'll overwrite the original name then compare

orignames <- names(la)

# Set all columns but CODE to NULL
for (i in 3:length(orignames)){
  la[[orignames[i]]] <- NULL
}

la$NAME <- as.character(la$NAME)
la@data <- dplyr::rename(la@data, name = NAME)

la_updated <- readr::read_csv("http://pct.bike/laresults.csv")
la_updated <- dplyr::rename(la_updated, name = la)

# find intrazonal flows
la@data = inner_join(la@data, la_updated, by = "name")