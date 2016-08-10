source("set-up.R")
l = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
l = l[l$dist > 0,]

# # subset lines for cambridge (temporary - comment out for generating all routes)
# z = readRDS("../pct-data/cambridgeshire/z.Rds")
# l = l[z,]
# plot(l)

rf = line2route(l = l, route_fun = "route_cyclestreet", plan = "fastest")
rq = line2route(l = l, route_fun = "route_cyclestreet", plan = "quietest")
# summary(rf$length)

rf$id = l$id
rq$id = l$id

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

# bind the routes together
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
rf$id = l$id[1:nrow(rf)]

saveRDS(rf, "../pct-bigdata/rf_1_to_35_missing_39.Rds")

# testing
rq = readRDS("../pct-bigdata/rq_nat.Rds")
summary(l$id == rq$id) # all match
summary(rf$id == l$id[1:nrow(rf)])

n = 100000
plot(l[n,])
plot(rq[n,], add = T, col = "green")
plot(rf[n,], add = T, col = "red")

summary(rf@data)



test_route_complete


