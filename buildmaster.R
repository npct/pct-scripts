source("set-up.R")
library(knitr)

# For PCT regions:
regions <- readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
la_all <- regions$Region <- as.character(regions$Region)
# select regions of interest (uncomment/change as appropriate)
# sel <- c("cambridge", "hereford", "northumberland", "devon")
# la_all <- regions$Region[charmatch(sel, regions$Region)]
# la_all <- as.character(la_all)
la_all <- c("kent") # just one region
# la_all <- la_all[2:3]

# # For custom regions:
# regions <- shapefile("/tmp/Study_Areas.shp")
# regions$Region <- tolower(regions$Name) # add region names
# la_all <- regions$Region

for(k in 1:length(la_all)){
  # What geographic level are we working at (cua or regional)
  geo_level <- "regional"
  isolated <- FALSE
  region <- la_all[k]
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


# find regions not yet built
# sel <- !regions$Region %in% list.dirs("../pct-data/", full.names = F)
# la_all <- as.character(regions@data$Region[sel])
la_all <- la_all[-grep("liv|greater-m", la_all)]

# old regional units
las <- readOGR(dsn = "../pct-bigdata/cuas-mf.geojson", layer = "OGRGeoJSON")
las_names <- las$CTYUA12NM
las$Region <- tolower(as.character(las_names))
la_all <- region <- "leeds"
regions <- las[las$Region == region,]
plot(regions)
# dput(las_names[1:4])
