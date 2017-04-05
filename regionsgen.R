# This updates regions.geojson
# Run to update the cycling levels on the front page map

lapply(c("geojsonio", "sp"), library, character.only = T)

regions = geojson_read("../pct-shiny/regions_www/regions.geojson", what = "sp", stringsAsFactors = F)

proj4string(regions)=CRS("+init=epsg:4326 +proj=longlat")

``
geojson_write(regions, file = "../pct-shiny/regions_www/regions.geojson")
