source("set-up.R")
library(knitr)

regions <- readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
la_all <- regions$Region
la_all <- as.character(la_all)

# select regions of interest (uncomment/change as appropriate)
# sel <- c("cambridge", "hereford", "northumberland", "devon")
# la_all <- regions$Region[charmatch(sel, regions$Region)]
# la_all <- as.character(la_all)
# la_all <- c("liverpool-city-region")

for(k in 1:length(la_all)){
  # What geographic level are we working at (cua or regional)
  geo_level <- "region"
  isolated <- TRUE
  region <- la_all[k]
  knitr::knit2html(quiet = T,
    input = "load.Rmd",
    output = file.path("../pct-data/", region, "/model-output.html"),
    envir = globalenv(), force_v1 = TRUE
  )
  message(paste0("Just built ", region))
}


# find regions not yet built
# sel <- !regions$Region %in% list.dirs("../pct-data/", full.names = F)
# la_all <- as.character(regions@data$Region[sel])
la_all <- la_all[-grep("liv|greater-m", la_all)]

# old regional units
# las <- readOGR(dsn = "pct-bigdata/national/cuas-mf.geojson", layer = "OGRGeoJSON")
# las_names <- las$CTYUA12NM
# las_names <- las_names[order(las_names)]
# las_names <- as.character(las_names)
# head(las_names)
# dput(las_names[1:4])
