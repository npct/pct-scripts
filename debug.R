# Aim: debug the data in the pct-data directory

# setup
source("set-up.R")
regions <- readOGR("../pct-bigdata/regions.geojson", layer = "OGRGeoJSON")
la_all <- as.character(regions$Region)

# create data frame of variables to check - ADD MORE for debugging
df <- data.frame(matrix(nrow = nrow(regions), ncol = 10))
names(df) <- c("name", "nl", "nrf", "nrq")
df["name"] <- la_all

for(i in 1:length(la_all)){
  tryCatch({
  l <- readRDS(file.path("..", "pct-data", la_all[i], "l.Rds"))
  rf <- readRDS(file.path("..", "pct-data", la_all[i], "rf.Rds"))
  rq <- readRDS(file.path("..", "pct-data", la_all[i], "rq.Rds"))
  df$nl[i] <- nrow(l)
  df$nrf[i] <- nrow(rf)
  df$nrq[i] <- nrow(rq)
  }, finally = message(paste0("Failed for ", i)))
}

df$is_ok <- df$nl == df$nrf & df$nl == df$nrq
df$is_ok[is.na(df$is_ok)] <- F

la_all <- la_all[!df$is_ok]
