# Generates simplified csv and geojson files for all the regions

library(rgdal)
library(rmapshaper)

# For PCT regions:
pct_data <- file.path("..", "pct-data")
regions <- readOGR("../pct-bigdata/regions-london.geojson", layer = "OGRGeoJSON")

la_all <- regions$Region <- as.character(regions$Region)
rm(regions)

too_large <- function(to_save, max_size = 5.3){ format(object.size(to_save), units = 'Mb') > max_size }

save_formats <- function(to_save, name = F){
  if (name == F){
    name <- substitute(to_save)
  }
  to_save <- to_save[,!grepl("(webtag|siw$|base_)", names(to_save@data))]
  saveRDS(to_save, file.path(pct_data, region, paste0(name, ".Rds")))
  to_save@data <- round_df(to_save@data, 5)
  geojson_write(ms_simplify(to_save, keep = 0.1, no_repair = too_large(to_save)) , file = file.path(pct_data, region, name))
  write.csv(to_save@data, file.path(pct_data, region, paste0(name, ".csv")))
}

round_df <- function(df, digits) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))

  df[,nums] <- round(df[,nums], digits = digits)

  (df)
}

require(foreach) & require(doParallel)
cl <- makeCluster(parallel:::detectCores())
registerDoParallel(cl)

foreach(k = 1:length(la_all)) %dopar%{
  library(rgdal)
  library(rmapshaper)
  library(geojsonio)
  region <- la_all[k]

  if(file.exists(file.path(pct_data, region, "z.Rds"))){
    zones <- readRDS(file.path(pct_data, region, "z.Rds"))
    save_formats(zones, "z")
    rm(zones)

    l <- readRDS(file.path(pct_data, region, "l.Rds"))
    save_formats(l)
    rm(l)

    rf <- readRDS(file.path(pct_data, region, "rf.Rds"))
    save_formats(rf)
    rm(rf)

    rq = readRDS(file.path(pct_data, region, "rq.Rds"))
    save_formats(rq)
    rm(rq)

    rnet = readRDS(file.path(pct_data, region, "rnet.Rds"))
    save_formats(rnet)
    rm(rnet)
  }
}

