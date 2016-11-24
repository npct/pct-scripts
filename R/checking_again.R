lines <- readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
rf <- readRDS("../pct-bigdata/rf_nat.Rds") 
head(lines@data)
n = "E02003592 E02003593" #IoW12 to IoW13 #blue
m = "E02003585 E02003590" #IoW05 to IoW10 #red
o = "E02003588 E02003589" #Iow08 to Iow09 #green
p = "E02003581 E02003593" #Iow01 to Iow13 #black

plot(lines[lines$id == n,], col = "black"); plot(lines[lines$id == m,], add = T)# yes, good
plot(rf[2,], col = "red")
l <- readRDS("../pct-data/isle-of-wight/l.Rds")
library(leaflet)

#check lines
leaflet() %>% 
  addTiles() %>% 
  addPolylines(data = l[l$id == n,], color = "blue") #%>% 
  #addPolylines(data = lines[lines$id == m,], color = "red") %>%
  #addPolylines(data = lines[lines$id == o,], color = "green") %>% 
  #addPolylines(data = lines[lines$id == p,], color = "black") 

#check routes
leaflet() %>% 
  addTiles() %>% 
  addPolylines(data = rf[rf$id == n,], color = "blue") #%>% 
  addPolylines(data = rf[rf$id == m,], color = "red") %>%
  addPolylines(data = rf[rf$id == o,], color = "green") %>% 
  addPolylines(data = rf[rf$id == p,], color = "black") 


#Get Centroids
cents = geojsonio::geojson_read("../pct-bigdata/cents-scenarios.geojson", what = "sp")
cents@data <- subset(cents@data, select = "geo_code")
lookup <- as.data.frame(cents)
remove(cents)

lines@data$dist_1 <- NULL
lines@data$dist_2 <- NULL

lines_test = lines[8000:9000,]
for(numb in 1:nrow(lines_test)){
  scord <- lines_test@lines[[numb]]@Lines[[1]]@coords[1,]
  fcord <- lines_test@lines[[numb]]@Lines[[1]]@coords[2,]
  Smsoa <- lines_test$msoa1[numb]
  Fmsoa <- lines_test$msoa2[numb]
  ScordC <- lookup[which(lookup$geo_code == Smsoa),2:3]
  FcordC <- lookup[which(lookup$geo_code == Fmsoa),2:3]
  lines_test@data$dist_1 <- geosphere::distHaversine(scord, ScordC)
  lines_test@data$dist_2 <- geosphere::distHaversine(fcord, FcordC)
}




lines$all[lines$id == n]

plot(lines[lines$id == n,])
plot(lines[lines$id == m,])
     