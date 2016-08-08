# testing the data generated for regions
# eventually to be run alongside buid_region.R in buildmaster.R

if(!exists("region")) region <- "cambridgeshire"
dataDir = paste0("../pct-data/", region)

# check files in pct-shiny
list.files(dataDir) # are all files there?

# To set initialize toPlot
l <- readRDS(file.path(dataDir, "l.Rds"))
z = readRDS(file.path(dataDir, "z.Rds"))
rf <- readRDS(file.path(dataDir, "rf.Rds" ))
rq <- readRDS(file.path(dataDir, "rq.Rds"))
cents <-   readRDS(file.path(dataDir, "c.Rds"))
rnet <- readRDS(file.path(dataDir, "rnet.Rds"))
rnet$id <- 1:nrow(rnet)

# load old data (e.g. after checking out previous version of data dir)
l_old <- readRDS(file.path(dataDir, "l.Rds"))
z_old = readRDS(file.path(dataDir, "z.Rds"))
rf_old <- readRDS(file.path(dataDir, "rf.Rds" ))
rq_old <- readRDS(file.path(dataDir, "rq.Rds"))
z_old <-  readRDS(file.path(dataDir, "z.Rds"))
cents_old <-   readRDS(file.path(dataDir, "c.Rds"))
rnet_old <- readRDS(file.path(dataDir, "rnet.Rds"))
rnet_old$id <- 1:nrow(rnet_old)

identical(z, z_old) # are the zones data the same?
ncol(z) == ncol(z_old) # same number of columns
cor(z@data$all, z_old@data$all) # all trips are equal
names(z) == names(z_old) # but some discrepancy in names
names(z)[!names(z) == names(z_old)]
names(z_old)[!names(z) == names(z_old)]

# Shared variables
sel <- names(rFast) %in% names(l)
df <- l@data
df2 <- rFast@data
summary(l@data[which(sel)] - rFast@data)

# testing rnet data
summary(rnet$dutch_slc) # some zero values in there for Go Dutch

# render it

leaflet() %>%
  addTiles() %>%
  addCircleMarkers(., data = cents, color = "black") %>%
  addPolylines(data = l)

# initial data
c <- readRDS(file.path(data_dir, "c.Rds"))
z <- readRDS(file.path(data_dir, "z.Rds"))




dfc <- c@data
dfc2 <-
  
  sapply(z@data, class)
df <- z@data[4:ncol(z)]

head(df)
z@data[4:ncol(z)] <- 1

saveRDS(z, file.path(data_dir, "z.Rds"))

apply(df, 1, is.nan)
is.nan(df$cirquity)

df <- data.frame(
  v1 = c(1, 2, 3),
  v2 = c(NaN, 4, 5),
  v3 = c(6, NA, 7)
)

df[is.na(df)]
is.nan(df)

df[apply(df, 2, is.nan)]


df <- sapply(z@data[4:ncol(z)], function(x){
  x[is.nan(x)] <- 1
  x
}
)



l <- readRDS(file.path(data_dir, "l.Rds"))
rf <- readRDS(file.path(data_dir, "rf.Rds"))
rq <- readRDS(file.path(data_dir, "rq.Rds"))
rnet <- readRDS(file.path(data_dir, "rnet.Rds"))

plot(z)
bbox(z)
plot(l, col = "blue", add = T)
plot(rf, col = "red", add = T)
plot(rq, col = "green", add = T)
plot(rnet, col = "grey", add = T)

leaflet() %>% addTiles() %>% addPolylines(data = l)
leaflet() %>% addTiles() %>% addCircles(data = c)


plot(rnet)

# check CRS
proj4string(c)
proj4string(z)

ll <- list(l, c, rf, z, rq)

lapply(, proj4string)

# debug lines
l <- readRDS("pct-data/liverpool-city-region/l.Rds")
l2 <- readRDS("pct-data/leeds/l.Rds")
names(l2)[!names(l2) %in% names(l)] # found missing vars