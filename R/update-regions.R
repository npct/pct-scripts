# Aim: update the regions

# Method 1: based on current regions
u = "https://github.com/npct/pct-shiny/raw/master/regions_www/regions.geojson"
regions_data_ali = geojson_read(x = u, method = "w", what = "sp")
names(regions_data_ali)
u2 = "https://github.com/npct/pct-shiny/raw/960e30f73eef898843c2283e86e2f506fccb1d05/regions_www/regions.geojson"
regions_geo = geojson_read(x = u2, method = "w", what = "sp")
summary(regions_data_ali$Region == regions_geo$Region)
regions_geo@data = regions_data_ali@data
geojson_write(regions_geo, file = "../pct-shiny/regions_www/regions.geojson")

# Add new region for northwest

# Method 2: based on new regions
# ...