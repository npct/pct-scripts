#####
#This file takes routes that do not have IDs and prepares them for the national build
###
### It assumes that the inputs are in the same order, but does some checks to help you see if that is true
#libraires
library(sp)
library(raster)
library(maptools)
library(leaflet)
library(dplyr)

#Set up these parameters
path <- "D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/ToNatBuild/"  #path to the working directory where everything is saved
route_file <- "rf_allonefile" #name of the route file without .Rds
line_file <- "lines_allonefile"  #name of the line file without .Rds
Derror <- 200 #number of meters difference between lines and route we are worried about

# Load in Files
lines <- readRDS(paste0(path,line_file,".Rds"))
cents = geojsonio::geojson_read("../pct-bigdata/cents-scenarios.geojson", what = "sp")
cents@data <- subset(cents@data, select = "geo_code")
lookup <- as.data.frame(cents)
remove(cents)

# Stage 2
routes <- readRDS(paste0(path,route_file,".Rds"))
old = readRDS("../pct-bigdata/rf_old.Rds")
lines_old <- readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")


plot(lines_old[2,])

##### New Checks
lines$id <- paste0(lines@data$msoa1," ",lines@data$msoa2)
lines_sub <- lines[lines$id %in% lines_old$id,]
nrow(lines_sub)

sample_old <- lines_old[1:50,]
nrow(sample_old)
sample_new <- lines[lines$id %in% sample_old$id,]
nrow(sample_new)

leaflet() %>% 
  addTiles() %>% 
  addPolylines(data = sample_old, color = "blue") %>% 
  addPolylines(data = sample_new, color = "red")

tests_lines <- matrix(nrow = nrow(lines_sub), ncol = 2)

for(numb in 1:nrow(lines)){
  ocord <- lines_sub@lines[[numb]]@Lines[[1]]@coords[c(1,nrow(lines_sub@lines[[numb]]@Lines[[1]]@coords)),]
  ncord <- lines_old@lines[[numb]]@Lines[[1]]@coords[,]
  sdist <- geosphere::distHaversine(ocord[1,], ncord[1,])
  fdist <- geosphere::distHaversine(ocord[2,], ncord[2,])
  tests_lines[numb,1] <-sdist
  tests_lines[numb,2] <-fdist
}




##########
tests <- matrix(nrow = nrow(lines), ncol = 2)

for(numb in 1:nrow(lines)){
rcord <- routes@lines[[numb]]@Lines[[1]]@coords[c(1,nrow(routes@lines[[numb]]@Lines[[1]]@coords)),]
lcord <- lines@lines[[numb]]@Lines[[1]]@coords[,]
sdist <- geosphere::distHaversine(rcord[1,], lcord[1,])
fdist <- geosphere::distHaversine(rcord[2,], lcord[2,])
tests[numb,1] <-sdist
tests[numb,2] <-fdist
}
print(paste0("The max difference in starting locations is ", as.integer(max(tests[,1]))," m in row number ",which.max(tests[,1])))
print(paste0("The max difference in finishing locations is ", as.integer(max(tests[,2]))," m in row number ",which.max(tests[,2])))

#Histograms!
hist(tests[,1])
hist(tests[,2])

lines_error = lines[which((tests[,1]>Derror)&(tests[,2]>Derror)),]
routes_error = routes[which((tests[,1]>Derror)&(tests[,2]>Derror)),]

#plot the results
print("plotting the largest errors for you")
leaflet() %>% 
  addTiles() %>% 
  addPolylines(data = lines_error) %>% 
  addPolylines(data = routes_error)

#cbind them togther
both <- cbind(routes,lines)
both$serror <- tests[,1]
both$ferror <- tests[,2]

nrow(both)
nrow(both@data)


#drop out some unneeded columns
both@data$id <- paste0(both@data$msoa1," ",both@data$msoa2)
both@data$plan <- NULL
both@data$start <- NULL
both@data$finish <- NULL
both@data$all <- NULL
both@data$light_rail <- NULL
both@data$train <- NULL
both@data$bus <- NULL
both@data$taxi <- NULL
both@data$motorbike <- NULL
both@data$car_driver <- NULL
both@data$car_passenger <- NULL
both@data$bicycle <- NULL
both@data$foot <- NULL
both@data$other <- NULL
both@data$is_two_way <- NULL
both@data$msoa1  <- NULL
both@data$msoa2  <- NULL
both@data$change_elev <- NULL
both@data$av_incline <- NULL

# Now bring in Anna's Data
anna_hill = readr::read_csv("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/ToNatBuild/Hilliness/Hilliness/161109_CorrectedHilliness.csv")
anna_hill$id <- paste0(anna_hill$msoa1," ",anna_hill$msoa2)
anna_hill$msoa1  <- NULL
anna_hill$msoa2  <- NULL

merged <- left_join(both@data, anna_hill, by = "id")
both@data <- merged
names(merged)

# Save Results
saveRDS(both, file= paste0(path,route_file,"_withIDandANNA.Rds"))

#Now subset to the ID that we used to use
merged_sub <- both[which(both$id %in% old$id),]

#Check for duplicates
dup = duplicated(merged_sub$id)
summary(dup)
nodup = merged_sub[!dup,]


nrow(old)
nrow(nodup)

# Save Results
saveRDS(nodup, file= paste0(path,route_file,"_subsetToOldData.Rds"))
