#####
#This file merges lines and route data so that the routes contain the relavant origin and desination codes
###
# NOTE this file assumes the data in each file comes in exactly the same order
#####

#libraires
library(sp)
library(raster)
library(maptools)
library(leaflet)

#Set up these parameters
path <- "../pct-bigdata/msoa_rerun/oldway/"  #path to the working directory where everything is saved
route_file <- "rq_500_test2" #name of the route file without .Rds
line_file <- "lines_500_test2"  #name of the line file without .Rds

# Load in Files
routes <- readRDS(paste0(path,route_file,".Rds"))
lines <- readRDS(paste0(path,line_file,".Rds"))

#do some checks
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

#plot the results
print("plotting the largest errors for you")
#leaflet() %>% 
#  addTiles() %>% 
#  addPolylines(data = routes[which.max(tests[,1]),]) %>% 
#  addPolylines(data = lines[which.max(tests[,1]),])  %>%
#  addPolylines(data = routes[which.max(tests[,2]),]) %>% 
#  addPolylines(data = lines[which.max(tests[,2]),])

#cbind them togther
both <- cbind(routes,lines)
both$serror <- tests[,1]
both$ferror <- tests[,2]

# Save Results
saveRDS(both, file= paste0(path,"merge_",route_file,".Rds"))
write.csv(both, file = paste0(path,"merge_",route_file,".csv"))

#######################
#End of Code
#######################
