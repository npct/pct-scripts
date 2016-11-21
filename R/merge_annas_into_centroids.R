# Aim: merge in the centroids data
source("set-up.R")
centsa <- readOGR(file.path(pct_bigdata, "cents-scenarios.geojson"), "OGRGeoJSON")
centsa_old = centsa # save backup - we'll overwrite the original name then compare
orignames = names(centsa)
f = "~/Dropbox/PCT/xx-PCTAreaLines_TEMP/161103_PCTarealines_csv.zip"
unzip(zipfile = f)
l_anna = readr::read_csv("161103_PCTarealines_csv/pct_lines.csv")

# find intrazonal flows
l_intra = l_anna[l_anna$msoa1 == l_anna$msoa2,]
l_intra$id = l_intra$msoa1
centsa@data = centsa@data[! names(centsa) %in% names(l_intra)] # rm duplicate names
centsa$id = centsa$geo_code

centsa@data = inner_join(centsa@data, l_intra)

# Checks
ncol(centsa) # 89 cols
ncol(centsa_old) # 84 cols
centsa@data = centsa@data[orignames]
ncol(centsa) # 84 cols - correct
head(centsa@data[1:10])
head(centsa_old[1:10]) # all looks right

cor(centsa$ebike_sico2, centsa_old$ebike_sico2, use = "complete.obs") # 99.8%

# Save the result
geojson_write(centsa, file = "../pct-bigdata/cents-scenarios.geojson")
