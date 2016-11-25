# Aim: update the regions

devtools::install_github("eblondel/cleangeo")

# Method 1: based on current regions
u = "https://github.com/npct/pct-shiny/raw/master/regions_www/regions.geojson"
regions_data_ali = geojson_read(x = u, method = "w", what = "sp")
names(regions_data_ali)
u2 = "https://github.com/npct/pct-shiny/raw/960e30f73eef898843c2283e86e2f506fccb1d05/regions_www/regions.geojson"
regions_geo = geojson_read(x = u2, method = "w", what = "sp")
summary(regions_data_ali$Region == regions_geo$Region)
regions_geo@data = regions_data_ali@data
geojson_write(regions_geo, file = "../pct-shiny/regions_www/regions.geojson")
regions = regions_geo

# Add new region for north-east
las = geojson_read("../pct-bigdata/las-pcycle.geojson", what = "sp")
# las = cleangeo::clgeo_Clean(las)
las_ne = las[grep(pattern = "County Durham|Gateshead|Tyne|Sunderland", x = las$NAME),]

tmap_mode("view")
qtm(las_ne, fill = "red") +
  qtm(las)
las_ne_geo = rgeos::gBuffer(las_ne, width = 0)
las_ne = SpatialPolygonsDataFrame(las_ne_geo, las_ne@data[1,], match.ID = F)
qtm(regions) +
  qtm(las_ne, fill = "red")

# Add cleveland to North East
regions_ne = regions[grepl("north-east|clev", regions$Region),]
plot(regions_ne)
regions_ne_geo = gBuffer(regions_ne, width = 0)
regions_ne_geo = SpatialPolygonsDataFrame(regions_ne_geo, regions_ne@data[2,], match.ID = FALSE)
regions_ne_geo@data[,2:6] = NA
plot(regions_ne_geo)
regions = regions[!grepl("north-east|clev", regions$Region),]
regions = bind(regions, regions_ne_geo)
plot(regions)
nrow(regions)
o = order(regions$Region)
regions = regions[o,]
regions$Region
qtm(regions)
geojson_write(regions, file = "../pct-shiny/regions_www/regions.geojson")

# Method 2: based on new regions
# ...