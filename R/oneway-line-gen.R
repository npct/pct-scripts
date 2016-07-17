# Aim: find and re-add 'missing lines'

# Start: get data for Cambridge
region = "cambridgeshire"
source("build_region.R") # comment out to skip build

# load excel file containing them
download.file("https://github.com/npct/pct-shiny/files/333471/160624_MissingCambLines.xlsx", "160624_MissingCambLines.xlsx")
flow_ag = readxl::read_excel("160624_MissingCambLines.xlsx")
l = readRDS("../pct-data/cambridgeshire/l.Rds")
zones = readRDS("../pct-data/cambridgeshire/z.Rds")


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
flow_cam = flow_cam[flow_cam$`All categories: Method of travel to work` > 10,]
# Convert to SpatialLines
flow_cam_sp = od2line(flow = flow_cam, zones = zones)
plot(flow_cam_sp)
flow_cam_sp_osgb = spTransform(flow_cam_sp, CRSobj = CRS("+init=epsg:27700"))
flow_cam_sp$dist = gLength(flow_cam_sp_osgb, byid = T) / 1000
summary(flow_cam_sp$dist)
flow_cam_sp = flow_cam_sp[flow_cam_sp$dist < 20,]
# Finding: 2304 lines
sum(flow_cam_sp$`All categories: Method of travel to work`)
# Finding: 227166 commuters in Cambridgeshire
sum(l$all)
# Finding: 175204 commuters, 77% of Census data


flow_cam_oneway = onewayid(flow_cam_sp, attrib = 3:ncol(flow_cam_sp))
# Finding: results in 1294 flows: lines are lost in onewayid
# flow_cam_oneway = onewaygeo(flow_cam_sp, attrib = 3:ncol(flow_cam_sp)) # finding: fewer flows still
sum(flow_cam_oneway$`All categories: Method of travel to work`)

# Solution: create new onewayid method, by creating a new id column
# Test case (to be removed)
ftest = data.frame(o = c(1, 2, 2), d = c(2, 1, 3), all = 10:8) # 3 lines
ftest$id1 = paste(ftest$o, ftest$d)
ftest$id2 = paste(ftest$d, ftest$o)
ftest$two_way = ftest$id2 %in% ftest$id1 # identify the 2 way flows
# save the 1 way flows
ftest_oneway = ftest[!ftest$two_way,]
ftest_twoway = ftest[ftest$two_way,]
u = unique(ftest$id1)
for(i in 1:length(u)){
  if(sum(ftest$id1 == u[i]) == 1)
    ftest$id1[ftest$id1 == u[i]] = ftest$id2[ftest$id1 == u[i]]
}
test_oneway = group_by(ftest, id1) %>% 
  summarise(all = sum(all))
