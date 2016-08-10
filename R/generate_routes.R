source("set-up.R")
l = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
l = l[l$dist > 0,]

# # subset lines for cambridge (temporary - comment out for generating all routes)
# z = readRDS("../pct-data/cambridgeshire/z.Rds")
# l = l[z,]
# plot(l)

# rf = line2route(l = l, route_fun = "route_cyclestreet", plan = "fastest")
# rq = line2route(l = l, route_fun = "route_cyclestreet", plan = "quietest")
# # summary(rf$length)
# 
# rf$id = l$id
# rq$id = l$id

# breaking lines into n pieces
n = 50
x = 1:nrow(l)
sel = split(x, cut(x, n, labels = FALSE))
rf_n = as.list(1:n)
num_names = formatC(1:n, flag = "0", width = 2)
sel_names = paste0("rf", num_names, ".Rds")
for(i in 34:39){
  rf_n[[i]] = line2route(l = l[sel[[i]],], route_fun = "route_cyclestreet", plan = "fastest")
  saveRDS(rf_n[[i]], paste0("../pct-bigdata/", sel_names[i]))
}

l = l[sel[[39]],]
n = 10
x = 1:nrow(l)
sel = split(x, cut(x, n, labels = FALSE))
rf_n = as.list(1:n)
num_names = formatC(1:n, flag = "0", width = 2)
sel_names = paste0("rf_39_", num_names, ".Rds")
for(i in 1:n){
  rf_n[[i]] = line2route(l = l[sel[[i]],], route_fun = "route_cyclestreet", plan = "fastest")
  saveRDS(rf_n[[i]], paste0("../pct-bigdata/", sel_names[i])) # failes in 8th set
}

# recreate chunk 39
for(i in c(1:7)){
  if(i == 1){
    rf = readRDS(paste0("../pct-bigdata/", sel_names[i]))
    rf$id = l$id[sel[[i]]]
  }else{
    rn = readRDS(paste0("../pct-bigdata/", sel_names[i]))
    rn$id = l$id[sel[[i]]]
    rf = sbind(rf, rn)
    print(i)
  }
}

for(i in c(8:9)){
    rn = rf[1:length(sel[[i]]),]
    rn@data = as.data.frame(sapply(rn@data, function(x) rep(NA, length(x))))
    rn = update_line_geometry(rn, l[sel[[i]],])
    rn$id = l$id[sel[[i]]]
    rf = sbind(rf, rn)
    print(i)
}

i = 10
rn = readRDS(paste0("../pct-bigdata/", sel_names[i]))
rn$id = l$id[sel[[i]]]
rf = sbind(rf, rn)

nrow(rf)
nrow(l)
summary(rf$id == l$id)
n = 3333
plot(rf[n,])
plot(l[n,], add = T)
saveRDS(rf, "../pct-bigdata/rf39.Rds")

# bind the routes together
l = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
l = l[l$dist > 0,]
n = 50
x = 1:nrow(l)
sel = split(x, cut(x, n, labels = FALSE))
rf_n = as.list(1:n)
num_names = formatC(1:n, flag = "0", width = 2)
sel_names = paste0("rf", num_names, ".Rds")
f = list.files(path = "../pct-bigdata/", pattern = "rf[0-9]", full.names = T)
for(i in 1:length(f)){
  if(i == 1){
    rf = readRDS(f[i])
    rf$id = l$id[sel[[i]]]
  }else{
    rn = readRDS(f[i])
    rn$id = l$id[sel[[i]]]
    rf = sbind(rf, rn)
    print(i)
  }
}
nrow(rf) == nrow(l)
summary(rf$id == l$id)

# testing
rq = readRDS("../pct-bigdata/rq_nat.Rds")
summary(l$id == rq$id) # all match
summary(rf$id == l$id[1:nrow(rf)])

n = nrow(l)
n = 99999
      
plot(l[n,])
plot(rq[n,], add = T, col = "green")
plot(rf[n,], add = T, col = "red")

summary(rf@data)

saveRDS(rf, "../pct-bigdata/rf_nat.Rds")


test_route_complete


