# Aim: generate routes for all regions
devtools::install_github("ropensci/stplanr") # install dev version of stplanr
library(stplanr)
l = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
l = readRDS("../pct-data/isle-of-wight/l.Rds") # test for scalability

# chunks
n = 9
x = 1:nrow(l)
sel = split(x, cut(x, n, labels = FALSE))
rf_n = rq_n = as.list(1:n)
num_names = formatC(1:n, flag = "0", width = 2)
sel_names_rf = paste0("rf", num_names, ".Rds")
sel_names_rq = paste0("rq", num_names, ".Rds")
for(i in 1:n){
  rf_n = line2route(l = l[sel[[i]],], route_fun = "route_cyclestreet",
                  plan = "fastest", base_url = "http://pct.cyclestreets.net/api/")
  rf_n$id = l[sel[[i]],]$id
  print(sel_names_rf[i])
  saveRDS(rf_n, paste0("../pct-bigdata/chunks/", sel_names_rf[i]))
}


# bind the routes together
x = 1:nrow(l)
f = list.files(path = "../pct-bigdata/chunks/", pattern = "rf[0-9]", full.names = T)
for(i in 1:length(f)){
  if(i == 1){
    rf = readRDS(f[i])
  }else{
    rn = readRDS(f[i])
    rf = raster::bind(rf, rn)
    print(i)
  }
}

rf@data = dplyr::select(rf@data,
  length,
  time,
  change_elev,
  av_incline,
  id
)

nrow(rf) == nrow(l)
summary(rf$id == l$id)
# plot(rf)
saveRDS(rf, "../pct-bigdata/rf_nat.Rds")

# now for rq
for(i in 1:n){
  rq_n = line2route(l = l[sel[[i]],], route_fun = "route_cyclestreet",
                  plan = "quietest")
  rq_n$id = l[sel[[i]],]$id
  print(sel_names_rq[i])
  saveRDS(rq_n, paste0("../pct-bigdata/chunks/", sel_names_rq[i]))
}


# bind the routes together
x = 1:nrow(l)
f = list.files(path = "../pct-bigdata/chunks/", pattern = "rq[0-9]", full.names = T)
for(i in 1:length(f)){
  if(i == 1){
    rq = readRDS(f[i])
  }else{
    rn = readRDS(f[i])
    rq = raster::bind(rq, rn)
    print(i)
  }
}

rq@data = dplyr::select(rq@data,
                        length,
                        time,
                        change_elev,
                        av_incline,
                        id
)

nrow(rq) == nrow(l)
summary(rq$id == l$id)
# plot(rq)
saveRDS(rq, "../pct-bigdata/rq_nat.Rds")

