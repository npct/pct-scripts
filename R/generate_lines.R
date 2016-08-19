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
o <- flow_cens$`Area of residence` %in% cents$geo_code
d <- flow_cens$`Area of workplace` %in% cents$geo_code
flow <- flow_cens[o & d, ] # subset OD pairs with o and d in study area

omatch = match(flow$`Area of residence`, cents$geo_code)
dmatch = match(flow$`Area of workplace`, cents$geo_code)

cents_o = cents@coords[omatch,]
cents_d = cents@coords[dmatch,]
summary(is.na(cents_o)) # check how many origins don't match
summary(is.na(cents_d))
geodist = geosphere::distHaversine(p1 = cents_o, p2 = cents_d) / 1000 # assign euclidean distanct to lines (could be a function in stplanr)
summary(is.na(geodist))

hist(geodist, breaks = 0:800)
flow$dist = geodist
flow = flow[!is.na(flow$dist),] # there are 36k destinations with no matching cents - remove
flow = flow[flow$dist < 5,] # subset based on euclidean distance
names(flow) = gsub(pattern = " ", "_", names(flow))
flow_twoway = flow
flow = onewayid(flow, attrib = 3:14)
flow[1:2] = cbind(pmin(flow[[1]], flow[[2]]), pmax(flow[[1]], flow[[2]]))
nrow(flow) # down to 0.9m, removed majority of lines
lines = od2line2(flow = flow, zones = cents)
plot(lines)

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

names(lines)

# generate the fastest routes
rf = line2route(l = lines, route_fun = route_cyclestreet, plan = "fastest")
rq = line2route(l = lines, route_fun = route_cyclestreet, plan = "quietest")
