source("set-up.R")
library(knitr)

# sel <- c("cambridge", "hereford", "northumberland", "devon")
# la_all <- regions$Region[charmatch(sel, regions$Region)]
# la_all <- as.character(la_all)
la_all <- c("wiltshire")

for(i in la_all){
  # What geographic level are we working at (cua or regional)
  geo_level <- "region"
  isolated <- TRUE
  region <- i
  print(i) 
  knitr::knit2html(
    input = "load.Rmd",
    output = file.path("../pct-data/", region, "/model-output.html"),
    envir = globalenv()
  )
}

regions <- readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
regions$Region

regions$Region[1:10]
dput(as.character(regions$Region[2:4]))

# find regions not yet built
sel <- !regions$Region %in% list.dirs("../pct-data/", full.names = F)
la_all <- regions@data$Region[sel]

# old regional units
# las <- readOGR(dsn = "pct-bigdata/national/cuas-mf.geojson", layer = "OGRGeoJSON")
# las_names <- las$CTYUA12NM
# las_names <- las_names[order(las_names)]
# las_names <- as.character(las_names)
# head(las_names)
# dput(las_names[1:4])
