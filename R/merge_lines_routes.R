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
path <- "../pct-bigdata/"  #path to the working directory where everything is saved
route_file <- "rq_nat" #name of the route file without .Rds
line_file <- "l_nat_noScens"  #name of the line file without .Rds
Derror <- 500 #number of meters difference between lines and route we are worried about

# Load in Files
routes <- readRDS(paste0(path,route_file,".Rds"))
lines <- readRDS(paste0(path,line_file,".Rds"))

#do some checks
nrow(routes)
nrow(lines)


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

lines_error = lines[which(tests[,1]>Derror),]
routes_error = routes[which(tests[,1]>Derror),]

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

# Save Results
saveRDS(both, file= paste0(path,route_file,"_id.Rds"))
write.csv(both, file = paste0(path,"merge_",route_file,".csv"))

#######################
#End of Code
#######################
