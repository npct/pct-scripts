#libraires
library(sp)
library(raster)
library(stplanr)

path <- "../pct-bigdata/msoa"  #path to the working directory where everything is saved
rq_file <- "rq_nat.Rds"
rf_file <- "rf_nat.Rds"
l_file  <- "l_nat.Rds"

l_nat <- readRDS(file.path(path, l_file))
rf <- readRDS(file.path(path, rf_file))
rq <- readRDS(file.path(path, rq_file))

hilliness <- readr::read_csv("../pct-bigdata/161113_CorrectHilliness_rf_rq.csv")
hilliness <- hilliness[,c("id", "change_elev_q", "av_incline_q")]

to_keep <- l_nat$all > 10 & l_nat$dist <= 20 & rf$length <= 30000

l_nat <- l_nat[to_keep,]
rf    <- rf[to_keep,]
rq    <- rq[to_keep,]
rq_data <- rq@data
rq_data <- rq_data[,c("length", "time", "waypoint", "co2_saving", "calories", "busyness", "dist", "serror", "ferror", "id")]
rq_data <- dplyr::left_join(rq_data, hilliness, by = "id")
rq_data <- dplyr::rename(rq_data, change_elev = change_elev_q, av_incline = av_incline_q)
rq@data <- rq_data

l_missing <- l_nat[is.na(rq$time),]
rq_missing = line2route(l =  l_missing, route_fun = "route_cyclestreet", plan = "quietest")

for(i in 1:nrow(rq_nat)){
  id <- rq_nat$id[i]
  if(id %in% rq_missing$id){
    l_to_add <- rq_missing[id == rq_missing$id,]
    rq_nat@data[i,] <- l_to_add@data
    rq_nat@lines[[i]] <- Lines(l_to_add@lines[[1]]@Lines, row.names(rq_nat[i,]))
  }
}

remove_cols <- function(df, col_regex){
  df[,!grepl(col_regex, names(df))]
}

l_nat@data <- remove_cols(l_nat@data, "\\.x")

saveRDS(l_nat, file= file.path(path,l_file))
saveRDS(rf, file= file.path(path,rf_file))
saveRDS(rq, file= file.path(path,rq_file))
