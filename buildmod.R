# Aim: build custom builds of the Propensity to Cycle Tool
# This is a modified version of buildmaster.R

source("set-up.R")
# Load custom region for the pct build

regions <- shapefile("/tmp/Study_Areas.shp")
regions$Region <- tolower(regions$Name) # add region names
la_all <- regions

for(k in 1:length(la_all)){
  # What geographic level are we working at (cua or regional)
  geo_level <- "custom"
  isolated <- TRUE
  region <- la_all$Region[k]
  knitr::knit2html(quiet = T,
                   input = "load.Rmd",
                   output = file.path("../pct-data/", region, "/model-output.html"),
                   envir = globalenv(), force_v1 = TRUE
  )
  message(paste0("Just built ", region))
}

