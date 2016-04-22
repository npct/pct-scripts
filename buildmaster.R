source("set-up.R")
library(knitr)

# For PCT regions:
regions <- readOGR("../pct-bigdata/regions-london.geojson", layer = "OGRGeoJSON")
la_all <- regions$Region <- as.character(regions$Region)
la_all = la_all[-which(la_all == "london")]
# select regions of interest (uncomment/change as appropriate)
# sel <- c("cambridge", "hereford", "northumberland", "devon")
# la_all <- regions$Region[charmatch(sel, regions$Region)]
# la_all <- as.character(la_all)
la_all <- c("kent") # just one region
# la_all <- la_all[1:20]

# # For custom regions:
# regions <- shapefile("/tmp/Study_Areas.shp")
# regions$Region <- tolower(regions$Name) # add region names
# la_all <- regions$Region

for(k in 1:length(la_all)){
  # What geographic level are we working at (cua or regional)
  geo_level <- "regional"
  region <- la_all[k]
  isolated <- FALSE # make the region not isolated (default)
  if(grepl(pattern = "london", region))
    isolated <- TRUE
  if(geo_level == "regional")
    file.remove(file.path("..", "pct-data", region, "isolated"))
  message(paste0("Building for ", region))
  knitr::knit2html(quiet = T,
    input = "load.Rmd",
    output = file.path("../pct-data/", region, "/model-output.html"),
    envir = globalenv(), force_v1 = TRUE
  )
  # Re read the model output file
  moutput <- readLines(file.path("../pct-data/", region, "/model-output.html"))
  # Remove all style and javascript tags
  moutput <- moutput[-c(5:200)]
  # Re-write the model output file
  write(moutput, file.path("../pct-data/", region, "/model-output.html"))

  message(paste0("Just built ", region))
}

# # Update the data sha
# source("update_sha.R")

# las <- readOGR(dsn = "../pct-bigdata/cuas-mf.geojson", layer = "OGRGeoJSON")
# las_names <- las$CTYUA12NM
# las$Region <- tolower(as.character(las_names))
# regions <- las[las$Region == region,]
