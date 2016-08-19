# Aim: find and re-add 'missing lines'
source("set-up.R")
cents = geojsonio::geojson_read("../pct-bigdata/cents-scenarios.geojson", what = "sp")
# load OD data - source http://wicid.ukdataservice.ac.uk/
unzip("../pct-bigdata/wu03ew_msoa.zip")
flow_cens = readr::read_csv("wu03ew_msoa.csv")
file.remove("wu03ew_msoa.csv")
nrow(flow_cens) # 2.4 m

# subset the centroids for testing (comment to generate national data)

cents = cents[grep(pattern = "Camb", x = cents$geo_label),]
plot(cents)

omatch = match(flow_cens$`Area of residence`, cents$geo_code)
dmatch = match(flow_cens$`Area of workplace`, cents$geo_code)

cents_o = cents@coords[omatch,]
cents_d = cents@coords[dmatch,]
summary(is.na(cents_o)) # check how many origins don't match
summary(is.na(cents_d))
geodist = geosphere::distHaversine(p1 = cents_o, p2 = cents_d) / 1000 # superfast - NB: soon to be function in stplanr
summary(is.na(geodist))

hist(geodist, breaks = 0:800)
flow_cens$dist = geodist
flow_cens = flow_cens[!is.na(flow_cens$dist),] # there are 36k destinations with no matching cents - remove
flow = flow_cens[flow_cens$dist < 20,]
names(flow) = gsub(pattern = " ", "_", names(flow))
flow_twoway = flow
flow = onewayid(flow, attrib = 3:14)
flow[1:2] = cbind(pmin(flow[[1]], flow[[2]]), pmax(flow[[1]], flow[[2]]))
nrow(flow) # down to 0.9m, removed majority of lines
lines = od2line2(flow = flow, zones = cents)

class(lines)
length(lines)
lines = SpatialLinesDataFrame(sl = lines, data = flow)
names(lines)
proj4string(lines) = CRS("+init=epsg:4326") # set crs

sum(lines$`All_categories:_Method_of_travel_to_work`)
summary(lines$`All_categories:_Method_of_travel_to_work`)

# to be removed when this is in stplanr
od_dist <- function(flow, zones){
  omatch = match(flow[[1]], cents@data[[1]])
  dmatch = match(flow[[2]], cents@data[[1]])
  cents_o = cents@coords[omatch,]
  cents_d = cents@coords[dmatch,]
  geosphere::distHaversine(p1 = cents_o, p2 = cents_d)
}

lines$dist = od_dist(flow = lines@data, zones = cents) / 1000

summary(lines$dist)

l_new <- readr::read_csv("D:/160708_AreaLinesPCT/160708_AreaLinesPCT/pct_lines.csv")

lines@data <- dplyr::rename(lines@data,
                        msoa1 = Area_of_residence,
                        msoa2 = Area_of_workplace,
                        all = `All_categories:_Method_of_travel_to_work`,
                        bicycle = Bicycle,
                        train = Train,
                        bus = `Bus,_minibus_or_coach`,
                        car_driver = `Driving_a_car_or_van`,
                        car_passenger = `Passenger_in_a_car_or_van`,
                        foot = On_foot,
                        taxi = Taxi,
                        motorbike = `Motorcycle,_scooter_or_moped`,
                        light_rail = `Underground,_metro,_light_rail,_tram`,
                        other = Other_method_of_travel_to_work
)

lines$Work_mainly_at_or_from_home <- NULL

names(l_new)
names(lines)
l_new$id <- paste(pmin(l_new$msoa1, l_new$msoa2), pmax(l_new$msoa1, l_new$msoa2))
# names in old data but not new
names(lines)[!names(lines) %in% names(l_new)]
duplicated_idx = names(l_new) %in% names(lines)

lines$id <- paste(pmin(lines$msoa1, lines$msoa2), pmax(lines$msoa1, lines$msoa2))


# which flows are included?
nrow(lines)
nrow(l_new)

summary(l_new$all) # all lines
summary(lines$all) # much higher average

# check they are the same - nope!
# plot(l$All, l_new$All)
head(lines$id)
head(l_new$id)

# creat placeholder variable names
lines$geo_label1	<- lines$geo_label2	<- lines$cirquity <- NA
# lines$co2_saving <- lines$busyness <- # commented - additional variables will be added during merge

newdat <- left_join(lines@data, l_new[!duplicated_idx], by="id")

nrow(newdat)
nrow(lines)

lines@data <- newdat
names(newdat)
# save the new data:
proj4string(lines)

# saveRDS(lines, "../pct-bigdata/lines_oneway_shapes_updated.Rds") # 
# lines = readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds") # load the pre-saved lines
summary(lines$msoa1 <= lines$msoa2)
head(lines@data[1:5])
# ord = order(lines$msoa1, lines$msoa2)
# plot(ord)

# Create rf and rq datasets with matching indices
# rf = readRDS("../pct-bigdata/rf.Rds")
# rq = readRDS("../pct-bigdata/rf.Rds")
# 
# head(rf)
# 
# # rename vars to merge in 
# rfdata = dplyr::select(rf@data, id, dist_fast = length, avslope = av_incline, time_fast = time, busyness_fast = busyness)
# rqdata = dplyr::select(rq@data, id, dist_quiet = length, avslope_q = av_incline, time_quiet = time, busyness_quiet = busyness)

# prepare for merge - analysis commented out
# sel_rf_match = rf$id %in% lines$id
# summary(sel_rf_match) # 8k lines don't match - distance?
# ids_nomatch = rf$id[!sel_rf_match] # ids in rf but not lines
# summary(ids_nomatch %in% flow_cens$id)
# head(flow_cens[flow_cens$id %in% ids_nomatch, 1:5])
# 
# rf$msoa1 = stringr::str_sub(string = rf$id, start = 1, end = 9)
# rf$msoa2 = stringr::str_sub(string = rf$id, start = 11, end = 19)
# new_rf_ids = paste(rf$msoa2, rf$msoa1)
# summary(new_rf_ids[!sel_rf_match] %in% lines$id)
# new_ids_nomatch = new_rf_ids[!sel_rf_match] # ids in rf but not lines
# summary(new_ids_nomatch %in% lines$id)
# 
# summary(sel_flow_nomatch)
# summary(flow_cens[sel_flow_nomatch,]) 

# merge the distances that *do* match
# newdat_rf = left_join(lines@data, rfdata, by = "id")
# sum(newdat_rf$all[!is.na(newdat_rf$dist_fast)], na.rm = T) # 98% flows captured ++
# cor(newdat_rf$dist_fast, newdat_rf$dist, use = "complete.obs") # very good correlation (0.98)
# newdat_rf_rq = left_join(newdat_rf, rq@data, by = "id")
# lines@data = newdat_rf_rq

# add the missing routes - for subset of the data (cambridge) to test first
cents = readRDS("../pct-data/cambridgeshire/c.Rds")
lines <- lines[lines$msoa1 != lines$msoa2,] # Remove inter msoa commuters
o <- lines$msoa1 %in% cents$geo_code
d <- lines$msoa2 %in% cents$geo_code
# lines_orig = lines
lines_cam <- lines[o & d, ] # subset OD pairs with o and d in study area

# Looks line some scenario data is missing
missing_scenario_data <- lines_cam[is.na(lines_cam$dutch_slco2),]@data[,c("msoa1", "msoa2")]

# rf <- rf[rf$id %in% lines$id,]
# rq <- rq[rq$id %in% lines$id,]
# sel_no_rf = is.na(lines$dist_fast)
# summary(sel_no_rf)

# regenerate lines - commented out, 100,000 lines per day
rf_cam = line2route(l = lines_cam, plan = "fastest")
rf_cam$id = lines_cam$id
rf_cam$nv = stplanr::n_vertices(rf_cam)
summary(rf_cam$nv == 2) # check for failed lines
# rf_new@data = rf_new@data[match(names(rf), names(rf_new))]

# rf_updated = sbind(rf, rf_new)
# nrow(rf_updated) == nrow(lines) # now: 1 to 1 match with lines
# plot(order(rf_updated$id)) # shows ids are out
# plot(order(lines$id)) # correct ids
# rf_updated = rf_updated[order(rf_updated$id),]
#

plot(rf_cam[70:73,], col="green") # yes
plot(lines_cam[70:73,], add = T) # check they match

#
# # the same for the quietest routes
# sel_no_rq = is.na(lines$dist_fast)
# summary(sel_no_rq)
rq_cam = line2route(l = lines_cam, plan = "quietest")
rq_cam$id = lines_cam$id
rq_cam$nv = stplanr::n_vertices(rq_cam)
summary(rq_cam$nv == 2) # check for failed lines
# rq_new@data = rq_new@data[match(names(rq), names(rq_new))]
# 
# rq_updated = sbind(rq, rq_new)
# nrow(rq_updated) == nrow(lines) # now: 1 to 1 match with lines
# plot(order(rq_updated$id)) # shows ids are out
# plot(order(lines$id)) # correct ids
# rq_updated = rq_updated[order(rq_updated$id),]
#
plot(rq_cam[110:112,], col="green") # yes
plot(lines_cam[110:112,], add = T) # check they match
#
#
# # save for the local area

# Remove long routes
too_long_ids <- rf_cam[rf_cam$length > 30000, ]$id
rf_cam <- rf_cam[!rf_cam$id %in% too_long_ids,]
rq_cam <- rq_cam[!rq_cam$id %in% too_long_ids,]
lines  <- lines[!lines$id %in% too_long_ids,]
lines_cam  <- lines_cam[!lines_cam$id %in% too_long_ids,]


saveRDS(rf_cam, "../pct-bigdata/rf_cam.Rds")
saveRDS(rq_cam, "../pct-bigdata/rq_cam.Rds")
rf_updated = readRDS("../pct-bigdata/rf_updated.Rds")
rq_updated = readRDS("../pct-bigdata/rq_updated.Rds")

sel_rf_in_lines = match(lines$id, rf_updated$id) # rq is the same
summary(sel_rf_in_lines)
rf_new = rf_updated[sel_rf_in_lines,]
rq_new = rq_updated[sel_rf_in_lines,]
test_index = 100000
plot(rf_new[test_index,])
lines(lines[test_index,])
lines(rq_new[test_index,])

saveRDS(lines, "../pct-bigdata/lines_oneway_shapes_updated.Rds")
saveRDS(rf_new, "../pct-bigdata/rf_new.Rds")
saveRDS(rq_new, "../pct-bigdata/rq_new.Rds")

# # fix inconsistencies in rf/rq data - run build_region.R first
# rf_nat <- readRDS(file.path(pct_bigdata, "rf_new.Rds"))
# rf_nat = rf_nat[!is.na(rf_nat$length),]
# rf_nat$length[rf_nat$length > 100] = rf_nat$length / 1000
# summary(rf_nat)
# rq_nat <- readRDS(file.path(pct_bigdata, "rq_new.Rds"))
# rq_nat = rq_nat[!is.na(rq_nat$length),]
# rq_nat$length[rq_nat$length > 100] = rq_nat$length / 1000
# summary(rq_nat)
# saveRDS(rf_nat, "../pct-bigdata/rf_new.Rds")
# saveRDS(rq_nat, "../pct-bigdata/rq_new.Rds")
