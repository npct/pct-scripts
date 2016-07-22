# Aim: find and re-add 'missing lines'
source("set-up.R")
source("../stplanr/R/overline.R")
cents = geojsonio::geojson_read("../pct-bigdata/cents-scenarios.geojson", what = "sp")

flow_cens = readr::read_csv("../pct-bigdata/wu03ew_v2.csv")
nrow(flow_cens) # 2.4 m

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
flow = onewayid(flow, attrib = 3:14)
nrow(flow) # down to 0.9m, removed majority of lines
lines = od2line2(flow = flow, zones = cents)

class(lines)
length(lines) 
lines = SpatialLinesDataFrame(sl = lines, data = flow)
names(lines)
proj4string(lines) = CRS("+init=epsg:4326") # set crs
lines = lines[lines$`All_categories:_Method_of_travel_to_work` > 10,]
sum(lines$`All_categories:_Method_of_travel_to_work`)
sum(l$all, na.rm = T)
summary(lines$`All_categories:_Method_of_travel_to_work`)

# to be removed when this is in stplanr
od_dist <- function(flow, zones){ 
  omatch = match(flow[[1]], cents@data[[1]])
  dmatch = match(flow[[2]], cents@data[[1]])
  cents_o = cents@coords[omatch,]
  cents_d = cents@coords[dmatch,]
  geosphere::distHaversine(p1 = cents_o, p2 = cents_d)
}

lines$dist = od_dist(flow = lines@data, zones = cents)

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

head(l_new$id)

# names in old data but not new
names(lines)[!names(lines) %in% names(l_new)]
duplicated_idx = names(l_new) %in% names(lines)

lines$id <- paste(pmin(lines$Area_of_residence, lines$Area_of_workplace), pmax(lines$Area_of_residence, lines$Area_of_workplace))
l_new$id <- paste(pmin(l_new$msoa1, l_new$msoa2), pmax(l_new$msoa1, l_new$msoa2))

# which flows are included?
nrow(lines)
nrow(l_new)

summary(l_new$all) # all lines
summary(lines$all) # much higher average

# check they are the same - nope!
# plot(l$All, l_new$All)
head(l$id)
head(l_new$id)

lines$geo_label_o	<- lines$geo_label_d	<- lines$dist_fast	<-
lines$dist_quiet <- lines$time_fast	<- lines$time_quiet <-
lines$cirquity <- lines$distq_f <- lines$avslope <-
lines$co2_saving <- lines$busyness <- lines$avslope_q <-
  NA

newdat <- left_join(lines@data, l_new[!duplicated_idx], by="id")

nrow(newdat)
nrow(lines)

lines@data <- newdat
names(newdat)
# save the new data:
proj4string(lines)

saveRDS(lines, "../pct-bigdata/lines_oneway_shapes_updated.Rds")


Sys.time() - start
