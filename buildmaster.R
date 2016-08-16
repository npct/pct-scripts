rm(list = ls()) # start with clear workspace (usually a good idea)
source("set-up.R")
to_build = read_csv("to_rebuild_updated.csv")
# For PCT regions:
pct_data <- file.path("..", "pct-data")
regions <- readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
la_all <- as.character(regions$Region)
sel_text = grep(pattern = "[a-z]", x = to_build$to_rebuild)
to_build$to_rebuild[sel_text] = 1 # rebuild 'maybes'?
(la_all = la_all[as.logical(as.numeric(to_build$to_rebuild))])
(la_all = la_all[!grepl(pattern = "liv", x = la_all)])
# (la_all = la_all[2:length(la_all)]) # the first n. not yet done
# la_all = la_all[1]
# select regions of interest (uncomment/change as appropriate)
# (la_all = la_all[grep(pattern = "glouc", la_all)]) # from exist regions
# la_all = "dorset" # a single region

for(k in 1:length(la_all)){
  # What geographic level are we working at (cua or regional)
  geo_level <- "regional"
  region <- la_all[k]
  isolated <- FALSE # make the region not isolated (default)
  if(grepl(pattern = "london", region))
    isolated <- TRUE
  if(isolated) file.create(file.path(pct_data, region, "isolated"))

  # Build the regions (comment out if the data has already been build)
  message(paste0("Building for ", region))
  source("build_region.R") # comment out to skip build
  # Write the model output files (comment out to not report data)
  # message(paste0("Writing the output file for ", region))
  knitr::knit2html(quiet = T,
    input = "model_output.Rmd",
    output = file.path(pct_data, region, "model-output.html"),
    envir = globalenv(), force_v1 = T
  )
  # # Re read the model output file
  # model_output =
  #   readLines(file.path(pct_data, region, "model-output.html"))
  # # remove style section
  # model_output <- remove_style(model_output)
  # # Add a special class to all tables for the shiny application
  # model_output <- add_table_style(model_output)
  # # Re-write the model output file
  # write(model_output, file.path(pct_data, region, "model-output.html"))
  message(paste0("Just built ", region))
  # # Update the data sha - uncomment to automate this (from unix machines)
  source("update_sha.R")
}

# update table tracking builds
source("R/to_build.R")
# # # For custom regions:
# regions <- shapefile("../pct-bigdata/custom-regions/CloHAM.shp")
# regions$Region <- tolower(regions$Name) # add region names
# la_all <- regions$Region

# # # For Local Authorities
# regions <- readOGR(dsn = "../pct-bigdata/cuas-mf.geojson", layer = "OGRGeoJSON")
# regions$Region <- regions$CTYUA12NM
# regions$Region <- tolower(as.character(regions$Region))
