# Aim: find and re-add 'missing lines'

# Start: get data for Cambridge
source("set-up.R")
region = "cambridgeshire"
# source("build_region.R") # comment out to skip build

# load excel file containing them
download.file("https://github.com/npct/pct-shiny/files/333471/160624_MissingCambLines.xlsx", "160624_MissingCambLines.xlsx")
flow_ag = readxl::read_excel("160624_MissingCambLines.xlsx")
l = readRDS("../pct-data/cambridgeshire/l.Rds")
zones = readRDS("../pct-data/cambridgeshire/z.Rds")
cents = readRDS("../pct-data/cambridgeshire/c.Rds")

sum(flow_ag$visualised_anna)
nrow(l)
# Finding: there are more lines in 'visualised anna' (1347) than the pct (1110)
# Which ones are missing?

# Start with the flow data from the census
flow_cens = readr::read_csv("../pct-bigdata/wu03ew_v2.csv")

# Subset by zones in the study area
o <- flow_cens$`Area of residence` %in% cents$geo_code
d <- flow_cens$`Area of workplace` %in% cents$geo_code
flow_cam <- flow_cens[o & d, ] # subset OD pairs with o and d in study area
# Remove flows with all < 10
# flow_cam = flow_cam[flow_cam$`All categories: Method of travel to work` > 10,]
# Convert to SpatialLines
flow_cam_sp = od2line(flow = flow_cam, zones = zones)
plot(flow_cam_sp)
flow_cam_sp_osgb = spTransform(flow_cam_sp, CRSobj = CRS("+init=epsg:27700"))
flow_cam_sp$dist = gLength(flow_cam_sp_osgb, byid = T) / 1000
summary(flow_cam_sp$dist)
flow_cam_sp = flow_cam_sp[flow_cam_sp$dist < 20 & flow_cam_sp$dist > 0.5,]
plot(flow_cam_sp, lwd = flow_cam_sp$`All categories: Method of travel to work` /
       mean(flow_cam_sp$`All categories: Method of travel to work`))# Finding: 2304 lines
sum(flow_cam_sp$`All categories: Method of travel to work`)
# Finding: 227166 commuters in Cambridgeshire
sum(l$all)
# Finding: 175204 commuters, 77% of Census data


# flow_cam_oneway = onewaygeo(flow_cam_sp, attrib = 3:ncol(flow_cam_sp)) # finding: fewer flows still
# Finding: results in 1294 flows: lines are lost in original onewayid

# Solution: update stplanr::onewayid() function
flow_cam_oneway = onewayid(flow_cam_sp@data, attrib = 3:14)
# flow_cam_oneway = onewayid(flow_cam_sp@data, attrib = 3:ncol(flow_cam_sp))

sum(flow_cam_oneway$`All categories: Method of travel to work`) ==
  sum(flow_cam_sp$`All categories: Method of travel to work`)
# Finding: fixed, they have the same total flow now
flow_cam_oneway = flow_cam_oneway[flow_cam_oneway$`All categories: Method of travel to work` > 10,]
summary(flow_cam_oneway$dist)
flow_cam_oneway$dist = flow_cam_oneway$dist / 2

flow_cam_oneway_sp = od2line(flow_cam_oneway, cents)
flow_cam_sp_osgb = spTransform(flow_cam_oneway_sp, CRSobj = CRS("+init=epsg:27700"))
flow_cam_oneway_sp$dist2 = gLength(flow_cam_sp_osgb, byid = T) / 1000
plot(flow_cam_oneway_sp$dist2, flow_cam_oneway_sp$dist)

summary(flow_cam_oneway_sp$dist2)
plot(flow_cam_oneway_sp, lwd = flow_cam_oneway_sp$`All categories: Method of travel to work` /
       mean(flow_cam_oneway_sp$`All categories: Method of travel to work`))

df = flow_cam_oneway_sp@data
write_csv(df, "/tmp/cam-oneway-updated-rl.csv")
