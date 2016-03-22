# Aim: identify and then fix lines that are straight (but should be on the route network)

library(stplanr)
library(mapview)

pct_bigdata <- file.path("..", "pct-bigdata")
centsa <- rgdal::readOGR(file.path(pct_bigdata, "cents.geojson"), "OGRGeoJSON")

d = "../pct-bigdata/"

wrong_points = table(pdf$)
rq = readRDS(file.path(d, "rq.Rds"))
plot(rq[1:100,])
rf = readRDS(file.path(d, "rf.Rds"))
# plot(rf)
nverts = n_vertices(rf)
sel = nverts < 3
sum(sel)
s = which(sel)
message(paste0(length(s), " 'quiet' lines are straight"))
# pdf = sapply(rf[sel,]@lines, function(x) x@Lines[[1]]@coords)
m = leaflet() %>% addTiles() %>% addPolylines(data = rf[s,], col = "red") %>% 
  addCircles(data = centsa)

# rf2 <- line2route(l = rf[s,]) # fails - old points
rf_newdat = data.frame(nl@data)
rf_newdat = rf_newdat[-1,]
rf_newdat <- as.data.frame(matrix(nrow = length(s), ncol = ncol(rf_newdat)))
names(rf_newdat) <- names(nl)
row.names(rf_newdat) <- s
counter = 0
for(i in s){
  # mapview(rf[i,])
  # if(i == 362) next()
  # plot(rf[i,])
  p = line2points(rf[i,])
  # nl = route_cyclestreet(p[1,], p[2,], plan = "fastest")
  pdists = spDistsN1(centsa, pt = p[2,])
  sel_mindist = which.min(pdists)
  pl = spDistsN1(pts = p, pt = centsa[sel_mindist,])
  tryCatch({
    if(which.min(pl) == 2)
      nl = route_cyclestreet(p[1,], centsa[sel_mindist,], plan = "fastest") else
        nl = route_cyclestreet(p[2,], centsa[sel_mindist,], plan = "fastest") 
      rf@lines[[i]] <- Lines(nl@lines[[1]]@Lines, row.names(rf[i,]))
      rf_newdat[row.names(rf[i,]) == row.names(rf_newdat),] <- nl@data
  }, error = function(e){warning(paste0("Fail for line number ", i))})
  
  # plot(rf[i,], add = T)
  # mapview(rf[i,])
  message(i)
}
mapview(rf[s,])

nverts = n_vertices(rq)
sel = nverts < 3
sum(sel)
s = which(sel)
message(paste0(length(s), " 'quiet' lines are straight in ", d))
for(i in s){
  p = line2points(rf[i,])
  pl = spDistsN1(pts = p, pt = centsa[sel_mindist,])
  if(which.min(pl) == 2)
    nl = route_cyclestreet(p[1,], centsa[sel_mindist,], plan = "quietest") else
      nl = route_cyclestreet(p[2,], centsa[sel_mindist,], plan = "quietest") 
  rq@lines[[i]] <- Lines(nl@lines[[1]]@Lines, row.names(rf[i,]))
}
saveRDS(rf, file.path(d, "rf.Rds"))
saveRDS(rq, file.path(d, "rq.Rds"))



# do it one directory at a time (inefficient)
data_dirs = list.dirs("../pct-data/")
data_dirs = data_dirs[grep(pattern = "a//[a-z]",  data_dirs)]

p = line2points(rf)
pdf = sapply(rf[sel,], function(x) x@Lines[[1]]@coords)
wrong_points = table(pdf$)

for(d in data_dirs){
  rq = readRDS(file.path(d, "rq.Rds"))
  plot(rq)
  rf = readRDS(file.path(d, "rf.Rds"))
  plot(rf)
  nverts = n_vertices(rf)
  sel = nverts < 3
  sum(sel)
  s = which(sel)
  message(paste0(length(s), " 'quiet' lines are straight"))
  pdf = sapply(rf[sel,]@lines, function(x) x@Lines[[1]]@coords)
  plot(rf[s,])
  for(i in s){
    # if(i == 362) next()
    p = line2points(rf[i,])
    # nl = route_cyclestreet(p[1,], p[2,], plan = "fastest")
    pdists = spDistsN1(centsa, pt = p[2,])
    sel_mindist = which.min(pdists)
    pl = spDistsN1(pts = p, pt = centsa[sel_mindist,])
    if(which.min(pl) == 2)
      nl = route_cyclestreet(p[1,], centsa[sel_mindist,], plan = "fastest") else
        nl = route_cyclestreet(p[2,], centsa[sel_mindist,], plan = "fastest") 
    rf@lines[[i]] <- Lines(nl@lines[[1]]@Lines, row.names(rf[i,]))
    message(i)
  }
  mapview(rf[s,])
  nverts = n_vertices(rq)
  sel = nverts < 3
  sum(sel)
  s = which(sel)
  message(paste0(length(s), " 'quiet' lines are straight in ", d))
  for(i in s){
    p = line2points(rf[i,])
    pl = spDistsN1(pts = p, pt = centsa[sel_mindist,])
    if(which.min(pl) == 2)
      nl = route_cyclestreet(p[1,], centsa[sel_mindist,], plan = "quietest") else
        nl = route_cyclestreet(p[2,], centsa[sel_mindist,], plan = "quietest") 
    rq@lines[[i]] <- Lines(nl@lines[[1]]@Lines, row.names(rf[i,]))
  }
  saveRDS(rf, file.path(d, "rf.Rds"))
  saveRDS(rq, file.path(d, "rq.Rds"))
}

nrow(rf)
nrow(rq)
nverts = n_vertices(rf)
summary(nverts)
sel = nverts < 3
summary(sel)
s = which(sel)

for(i in s){
  p = line2points(rf[i,])
  # nl = route_cyclestreet(p[1,], p[2,], plan = "fastest")
  nl = route_cyclestreet(p[1,], centsa[sel_mindist,], plan = "fastest")
  rf@lines[[i]] <- Lines(nl@lines[[1]]@Lines, row.names(rf[i,]))
}

# analysis

# find out nearest point
leaflet() %>% addTiles() %>% addCircles(data = p[2,])
pdists = spDistsN1(centsa, pt = p[2,])
sel_mindist = which.min(pdists)
leaflet() %>% addTiles() %>% addCircles(data = p[2,]) %>%
  addCircles(data = centsa[sel_mindist,]) # that makes sense

mapview::mapview(rf[sel,])

saveRDS(rf, "../pct-data/west-yorkshire/rf.Rds")

