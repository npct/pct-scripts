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

# 
# 
# # Rename Westminster to Westminster,City of London
# la@data[la@data$name == "Westminster",]$name <- "Westminster,City of London" 
# 
# # Rename City of London to Westminster,City of London
# la@data[la@data$name == "City of London",]$name <- "Westminster,City of London"
# 
# la@data[la@data$name == "Cornwall",]$name <- "Cornwall,Isles of Scilly" 
# la@data[la@data$name == "Isles of Scilly",]$name <- "Cornwall,Isles of Scilly" 

la_updated <- readr::read_csv(file.choose())
la_updated <- dplyr::rename(la_updated, name = la)


la@data = inner_join(la@data, la_updated, by = "name")

# Convert absolute values of cycling to percentages
for (i in 4:18){
  la@data[[i]] <- la@data[[i]] / la@data$all
}

# Save it to the bigdata
geojson_write(la, file = "../pct-bigdata/LAs.geojson")
