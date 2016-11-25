# Aim: generate and merge new geographical data for msoa boundaries
# Go to https://census.edina.ac.uk/easy_download_data.html?data=England_msoa_2011
# Find the layer 'Middle Layer Super Output Areas (December 2011) Super Generalised Clipped Boundaries in England and Wales'
source("set-up.R")
u = "http://geoportal.statistics.gov.uk/datasets/826dc85fb600440889480f4d9dbb1a24_3.zip"
f = "../pct-bigdata/raw/Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.zip"
download.file(u, f)
unzip(f)
msoa_geo = shapefile("Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.shp")
f_remove = list.files(pattern = "Middle_L")
file.remove(f_remove)
# mapview::mapview(msoa_geo) # take a quick peak at them - looks good
ukmsoas = readRDS("../pct-bigdata/ukmsoas-scenarios.Rds")
head(ukmsoas$geo_code)
head(msoa_geo$msoa11cd)
summary({sel = msoa_geo$msoa11cd %in% ukmsoas$geo_code}) # all but 410 in there
msoa_geo = msoa_geo[sel,]
msoa_geo@data = data.frame(geo_code = msoa_geo$msoa11cd) # remove all but code
msoa_geo@data = inner_join(msoa_geo@data, ukmsoas@data)

# checking
head(ukmsoas@data)
head(msoa_geo@data)
tm_shape(ukmsoas) + tm_fill(col = "govtarget_slc")
tm_shape(msoa_geo) + tm_fill(col = "govtarget_slc")
object.size(ukmsoas)
object.size(msoa_geo)
plot(msoa_geo[1,])
plot(ukmsoas[1,])
plot(msoa_geo$dutch_sic, ukmsoas$dutch_sic)

saveRDS(msoa_geo, "../pct-bigdata/ukmsoas-scenarios.Rds")

i = 1
regions = geojson_read("../pct-shiny/regions_www/regions.geojson", what = "sp")
for(i in 1:nrow(regions)){
  f_msoa = paste0("../pct-data/", regions$Region[i], "/z.Rds")
  old_msoas = readRDS(f_msoa)
  new_msoas = msoa_geo[msoa_geo$geo_code %in% old_msoas$geo_code,]
  plot(old_msoas)
  plot(new_msoas)
  plot(old_msoas$bicycle, new_msoas$bicycle)
  order_msoas = match(old_msoas$geo_code, new_msoas$geo_code)
  new_msoas = new_msoas[order_msoas,]
  plot(old_msoas$bicycle, new_msoas$bicycle)
  saveRDS(new_msoas, f_msoa)
}