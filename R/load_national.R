# Aim: generate route distance, hillines and other variable for UK flows

# setup
pct_data <- file.path("..", "pct-data")
pct_bigdata <- file.path("..", "pct-bigdata")
source("set-up.R")

# load flows
flow <- readRDS("../pct-bigdata/flow.Rds")

# Minimum flow between od pairs, subsetting lines. High means fewer lines
mflow <- 300
mflow_short <- 30
mdist <- 30 # maximum euclidean distance (km) for subsetting lines
max_all_dist <- 7 # maximum distance (km euclidean) below which mflow_short lines are selected

## ----plotzones, message=FALSE, warning=FALSE, results='hide', echo=FALSE----
ukmsoas <- shapefile(file.path(pct_bigdata, "msoas.shp"))
ukmsoas <- spTransform(ukmsoas, CRS("+init=epsg:4326"))

# Load population-weighted centroids
cents <- readOGR(file.path(pct_bigdata, "cents.geojson"), layer = "OGRGeoJSON")
cents$geo_code <- as.character(cents$geo_code)

# subset to only include english centroids
head(cents$geo_code)
cents <- cents[grepl("E", cents$geo_code),]
plot(cents)

# subset to only include english flows
o <- flow$Area.of.residence %in% cents$geo_code
d <- flow$Area.of.workplace %in% cents$geo_code
flow <- flow[o & d, ] # subset OD pairs with o and d in study area

# Calculate line lengths (in km)
coord_from <- coordinates(cents[match(flow$Area.of.residence, cents$geo_code),])
coord_to <- coordinates(cents[match(flow$Area.of.workplace, cents$geo_code),])
# Euclidean distance (km)
flow$dist <- geosphere::distHaversine(coord_from, coord_to) / 1000

# Subset lines
dsel <- flow$dist < mdist # all lines less than the upper threshold distance to remove
dsel_short <- flow$dist < max_all_dist # all lines less than the lower threshold distance
sel_number <- flow$All > mflow # subset OD pairs by n. people using it
sel <- (dsel & sel_number) | (dsel_short & flow$All > mflow_short)
sel <- sel & flow$dist > 0

sum(sel)

flow <- flow[sel, ]

# summary(flow$dist)
l <- od2line(flow = flow, zones = cents)
plot(l[sample(nrow(l), 1000),])

# # # # # # # # # # # # # # #
# Allocate OD pairs2network #
# Warning: time-consuming!  #
# Needs CycleStreet.net API #
# # # # # # # # # # # # # # #
saveRDS(l, "../pct-bigdata/ukflow.Rds")

line2route <- function (ldf, ...) 
{
  l <- ldf
  if (class(ldf) == "SpatialLinesDataFrame") {
    ldf <- line2df(l)
  }
  tryCatch({
    rf1 <- route_cyclestreet(from = ldf[1, 1:2], to = ldf[1, 
                                                          3:4], ...)
    rf <- rf1
    row.names(rf) <- row.names(l[1, ])
  }, error = function(e) {
    warning(paste0("Fail for line number ", 1))
  })
  for (i in 2:nrow(ldf)) {
    tryCatch({
      if (!exists("rf1")) {
        rf1 <- route_cyclestreet(from = ldf[i, 1:2], 
                                 to = ldf[i, 3:4], ...)
        rf <- rf1
        row.names(rf) <- row.names(l[i, ])
      }
      else {
        rfnew <- route_cyclestreet(from = ldf[i, 1:2], 
                                   to = ldf[i, 3:4], ...)
        row.names(rfnew) <- row.names(l[i, ])
        rf <- maptools::spRbind(rf, rfnew)
      }
    }, error = function(e) {
      warning(paste0("Fail for line number ", i))
    })
    perc_temp <- i%%round(nrow(ldf)/1)
    if (!is.na(perc_temp) & perc_temp == 0) {
      message(paste0(round(100 * i/nrow(ldf)), " % out of ", 
                     nrow(ldf), " distances calculated"))
    }
  }
  rf
}

rf <- line2route(l, silent = TRUE)
rq <- line2route(l, plan = "quietest", silent = T)
rf$length <- rf$length / 1000 # set length correctly
rq$length <- rq$length / 1000

saveRDS(rf, "../pct-bigdata/rf.Rds")
saveRDS(rq, "../pct-bigdata/rq.Rds")

# debug lines which failed
if(!(nrow(l) == nrow(rf) & nrow(l) == nrow(rq))){
  # which paths succeeded 
  path_ok <- row.names(l) %in% row.names(rf) &
                   row.names(l) %in% row.names(rq)
  # summary(path_ok)
  l <- l[path_ok,]
  path_ok <- row.names(rf) %in% row.names(l)
  rf <- rf[path_ok,]
  path_ok <- row.names(rq) %in% row.names(l)
  rq <- rq[path_ok,]
}

# add line id
l$id <- row.names(l)

# Process route data
proj4string(rf) <- proj4string(l)
proj4string(rq) <- proj4string(l)

if(!nrow(rf) == nrow(l))
  stop("Warning, lines and routes are different lengths")
l$dist_fast <- rf$length
l$dist_quiet <- rq$length
l$cirquity <- rf$length / l$dist
l$distq_f <- rq$length / rf$length
l$avslope <- rf$av_incline
l$co2_saving <- rf$co2_saving
l$calories <- rf$calories
l$busyness <- rf$busyness
l$avslope_q <- rq$av_incline
l$co2_saving_q <- rq$co2_saving
l$calories_q <- rq$calories
l$busyness_q <- rq$busyness

end_time <- Sys.time()

end_time - start_time

