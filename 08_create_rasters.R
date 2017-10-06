# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)
rasterOptions(datatype = "INT2U")

## VARIABLE INPUTS
purpose <- "commute"
geography <- "lsoa"  
run_name <- "wales_1708"   # Name for this batch of routes
scenario <- "bicycle" # WHICH SCENARIO? (parts 1-4)
clusterno <- 1        # WHICH LARGE CLUSTER? (parts 2-4)

## FIXED INPUTS
grid_size <- 10000    # Dimensions of the grids
cluster_size <- 10000 # Max number of routes in a cluster
resolution <- 10      # Pixle size in meters
raster_size <- 200    # Maximum number of lines to rasterise at once
stack_size <- 40      # Max no. rasters to stack at once

# CREATE DIRECTORIES (IF NEEDED)
if(!dir.exists(file.path(path_temp_raster, purpose))) { dir.create(file.path(path_temp_raster, purpose)) }
if(!dir.exists(file.path(path_temp_raster, purpose, geography))) { dir.create(file.path(path_temp_raster, purpose, geography)) }
if(!dir.exists(file.path(path_temp_raster, purpose, geography, run_name))) { dir.create(file.path(path_temp_raster, purpose, geography, run_name)) }
if(!dir.exists(file.path(path_temp_raster, purpose, geography, run_name, "grids"))) { dir.create(file.path(path_temp_raster, purpose, geography, run_name, "grids")) }

#########################
### PART 1: BREAK ROUTE FILES INTO CHUNKS
#########################

# GENERATE INPUT DATASET
od_raster_attributes <- read_csv(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "od_raster_attributes.csv"))
routes_all <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "rf_shape.Rds"))
summary({sel_rf <- (routes_all$id %in% od_raster_attributes$id)}) # Limit to those with od_raster_attributes (at least 1 cyclist)
routes_all <- routes_all[sel_rf,]  
routes_all@data <- data.frame(id = routes_all$id) 
routes_all@data <- left_join(routes_all@data, od_raster_attributes, by="id")

# SUBSET IF DESIRED
# Wales subset
c1 <- substr(routes_all@data$id, 1, 1)
c2 <- substr(routes_all@data$id, 11, 11)
table(c1, c2)
summary({sel_wales <- ((c1 %in% "W")) | (c2 %in% "W")}) # Limit to those starting or ending in Wales
routes_all <- routes_all[sel_wales,]  
saveRDS(routes_all, file.path("../wales_raster_temp.Rds"))


#REMOVE UNNEEDED DATA & GENERATE MID-LINE POINTS
routes_all@data <- routes_all@data[,c("id",scenario)]  
names(routes_all) <- c("id","bike")
summary(!is.na(routes_all$bike))  # CHECK NONE ARE MISSING
routes_all <- routes_all[routes_all$bike >0,] # ONLY KEEP ROUTES WITH ANY CYCLING
nrow(routes_all)
routes_all <- spTransform(routes_all, proj_27700) # Need to project it, rather than lat/long, to find midpoint
points <- SpatialLinesMidPoints(routes_all)

# DEFINE SPATIALGRID OBJECT
bb <- bbox(points)
cs <- c(grid_size, grid_size)
cc <- bb[, 1] + (cs/2)  # cell offset - midpoint bottom left cell
cd <- ceiling(diff(t(bb))/cs)  # number of cells per direction
grd <- GridTopology(cellcentre.offset=cc, cellsize=cs, cells.dim=cd)
sp_grd <- SpatialGridDataFrame(grd, data=data.frame(id=1:prod(cd)), proj4string=CRS(proj4string(points)))

# ASSIGN GRID IDS TO A) POINTS THEN B) ROUTES
routes_all@data$grid <- as.integer(NA)
over <- over(points, sp_grd)
routes_all@data$grid <- over$id
remove("grid_size","bb","cs","cc","cd","grd","points","sp_grd","over")

# GENERATE TABLE OF NUMBER OF ROUTES IN EACH GRID, AND CUMULATIVE SUM
tab <- as.data.frame(table(routes_all$grid))
names(tab) <- c("grid","count")
tab$grid <- as.integer(as.character(tab$grid))
tab$count <- as.integer(tab$count)
tab <- tab[order(tab$count),]
tab$sum <- as.integer(0)
tab$sum <- cumsum(tab$count) # Cumulative sum
print(paste0("There are ",nrow(tab), " grids to do"))

# BREAK UP AND SAVE
nbatch_cluster <- ceiling(max(tab$sum)/cluster_size)
for(i in 1:nbatch_cluster){
  print(paste0("Saving cluster ",i," of ",nbatch_cluster," at ",Sys.time()))
  sum_min <- 1 + cluster_size * (i-1)
  sum_max <- if(i * cluster_size > max(tab$sum)){max(tab$sum)+1}else{i * cluster_size }
  tab_sub <- tab[tab$sum < sum_max,]
  tab_sub <- tab_sub[tab_sub$sum >= sum_min,]
  routes <- routes_all[routes_all$grid %in% tab_sub$grid,]
  saveRDS(routes,file.path(path_temp_raster, purpose, geography, run_name, paste0(scenario,i,".Rds")))
}

#########################
### PART 2 RUN RASTER CLUSTER (SEPARATELY BY CLUSTER NUMBER)
#########################

#INPUT DATASETS
routes_cluster <- readRDS(file.path(path_temp_raster, purpose, geography, run_name, paste0(scenario,clusterno,".Rds")))

# COUNT NUMBER OF GRIDS
tab <- as.data.frame(table(routes_cluster$grid))
names(tab) <- c("grid","count")
tab$grid <- as.integer(as.character(tab$grid))
tab$count <- as.integer(tab$count)
tab <- tab[order(tab$count),]
print(paste0("In cluster ",clusterno," there are ",nrow(tab), " grids to do"))
# Special subsetting for restarting after running out of memory
#tab <- tab[tab$count > XXXXX,]
#routes_cluster <- routes_cluster[routes_cluster$grid %in% tab$grid,]

# RUN RASTER FOR EACH GRID SQUARE
for(i in tab$grid){
  print(paste0("Running rasters in grid ",i," with ",tab$count[tab$grid==i]," lines, at ",Sys.time()))
  lines <- routes_cluster[routes_cluster$grid == i,]
  #names(lines) <- c("id","bike","grid")
  polys <- gBuffer(lines, byid = T, width = 10) # ADD A BUFFER TO...?? ASK MALCOLM WHY
  remove(lines)
  
  #Set Up Raster
  raster_master <- raster(resolution = resolution, ext = extent(polys), crs= proj_27700, vals = 0)
  dataType(raster_master) <- "INT2U"
  vx <- velox(raster_master, extent=extent(polys), res=c(resolution,resolution), crs=proj_27700)
  remove(raster_master)

  if(nrow(polys) <= raster_size){
    #Make and empty raster stack
    lx <- list(vx)
    for (j in 1:nrow(polys)) lx[[j]] <- vx
    vx_sub2 <- velox(lx, extent=extent(polys), res=c(resolution,resolution), crs=proj_27700)
    remove(lx, vx)

    #loop though each line and rasterize
    for(k in 1:nrow(polys) ){  
      lines2raster = polys[k,]
      vx_sub2$rasterize(lines2raster, field="bike", band= k, background = 0)
    }
    remove(lines2raster, polys)
    #print(paste0("Rastered ",Sys.time()))
    
    #Add rasters togther
    rs <- vx_sub2$as.RasterStack()
    remove(vx_sub2)
    rsum <- stackApply(rs, 1, sum)

    writeRaster(rsum,file.path(path_temp_raster, purpose, geography, run_name, "grids", paste0(scenario,clusterno,"-grd-",i,".tif")), format ="GTiff", overwrite=TRUE)

    removeTmpFiles(h = 1)
    remove(rs,rsum)
  } else {
    
    print("Too large breaking into chunks")
    for(l in 1:ceiling(nrow(polys)/raster_size)){
      print(paste0("Doing part ",l," of ",ceiling(nrow(polys)/raster_size)," at ",Sys.time()))
      lstart <- 1 + raster_size * (l-1)
      lfin <- if(raster_size * l > nrow(polys)){nrow(polys)}else{raster_size*l}
      lx <- list(vx)
      for (j in 1:raster_size) lx[[j]] <- vx
      vx_sub2 <- velox(lx, extent=extent(polys), res=c(resolution,resolution), crs=proj_27700)
      remove(lx)

      #loop though each line and rasterize
      for(k in lstart:lfin ){  
        lines2raster = polys[k,]
        vx_sub2$rasterize(lines2raster, field="bike", band= (k - lstart + 1), background = 0)
      }
      remove(lines2raster)
      #print(paste0("Rastered ",Sys.time()))
      
      #Add rasters togther
      rs <- vx_sub2$as.RasterStack()
      remove(vx_sub2)
      rsum <- stackApply(rs, 1, sum)
      writeRaster(rsum,file.path(path_temp_raster, purpose, geography, run_name, "grids", paste0(scenario,clusterno,"-grd-",i,"-",l,".tif")), format ="GTiff", overwrite=TRUE)
      removeTmpFiles(h = 1)
      remove(rs,rsum)
      
    }
  }
}
print(paste0("Running rasters finished running raster at ",Sys.time()))

#########################
### PART 3: RENAME RASTER TIF FILES TO ADD ZEROS
#########################

common_start <- paste0(scenario,clusterno,"-grd-") # text that appears at the start of every file

files <- list.files(file.path(path_temp_raster, purpose, geography, run_name, "grids"), full.names = T) #,pattern="searchPattern")
sapply(files,FUN=function(eachPath){
  #Take off the common start and end
  crop <- sub(paste0(path_temp_raster,"/",purpose, "/", geography, "/",run_name, "/grids/",common_start),"",eachPath)
  crop <- sub(".tif","",crop)
  #Remove any -number where grid was broken into chunks
  split <- unlist(strsplit(crop, "-"))
  numb <- split[1]
  #Add in the zeros
  if(nchar(numb)==1){
    out <- paste0("000",numb)
  } else if (nchar(numb)==2){
    out <- paste0("00",numb)
  } else if (nchar(numb)==3){
    out <- paste0("0",numb)
  } else {
    out <- numb
  }
  #Rebuild the file name
  if(length(split)==2){
    fin <- paste0(path_temp_raster,"/",purpose, "/", geography, "/",run_name, "/grids/",common_start,out,"-",split[2],".tif")
  } else {
    fin <- paste0(path_temp_raster,"/",purpose, "/", geography, "/",run_name, "/grids/",common_start,out,".tif")
  }
  #Rename the file  
  file.rename(from=eachPath,to=fin)
})
print(paste0("Renaming rasters finished at ",Sys.time()))

#########################
### PART 4: RASTER STACK
#########################
rasterOptions(maxmemory = 1e+09)
master_list <- list.files(file.path(path_temp_raster, purpose, geography, run_name, "grids"), pattern = ".tif$",full.names = TRUE )
nbatch_stack <- ceiling(length(master_list)/stack_size)

for(m in 1:nbatch_stack){
  print(paste0("Stacking rasters: doing batch ",m," of ",nbatch_stack," at ",Sys.time()))
  lstart <- 1 + stack_size * (m-1)
  lfin <- if(stack_size * m > length(master_list)){length(master_list)}else{stack_size*m}
  raster_files <- master_list[lstart:lfin]
  
  #Make a list of rasters
  raster.list <- list()
  for (i in 1:(length(raster_files))){ 
    raster_file <- raster::raster(raster_files[i])
    raster.list <- append(raster.list, raster_file)
  }
  remove(raster_file)
  remove(raster_files)
  
  #Make a list of extents, then make the union to get whole extent
  extent_list <- list()
  for (j in 1:length(raster.list)){
    ext <- extent(raster.list[[j]])
    extent_list <- append(extent_list,ext)
  }
  Uext <- extent_list[[1]]
  for (k in 2:length(raster.list)){
    Uext <- union(Uext,extent_list[[k]])
  }
  remove(extent_list,ext)
  
  #Make Snap Raster
  snap <- raster(resolution = c(10,10), ext = Uext, crs = "+init=epsg:27700") 
  
  #Resample Rasters to snap
  for (l in 1:(length(raster.list))){ 
    raster.list[[l]] <- projectRaster(raster.list[[l]], snap, method = "ngb")
    print(paste0("Snapping rasters: done ",l," of ",length(raster.list)," parts at ",Sys.time()))
  }
  remove(snap, Uext)
  
  # edit settings of the raster list for use in do.call and mosaic
  names(raster.list) <- NULL
  
  #####This function deals with overlapping areas
  raster.list$fun <- sum
  
  #run do call to implement mosaic over the list of raster objects.
  mos <- do.call(raster::mosaic, raster.list)
  
  #set crs of output
  crs(mos) <-"+init=epsg:27700"
  
  writeRaster(mos,file.path(path_temp_raster, purpose, geography, run_name, paste0(scenario,clusterno,"-merge-",m,".tif")), format = "GTiff")
  remove(raster.list, mos)
  gc()
  
}
print(paste0("Stacking rasters finished at ",Sys.time()))

#########################
### PART 5: CREATE NATIONAL RASTERS IN ARC GIS AND SAVE
#########################
## ANNA NOTE: NOW NEED TO STITCH THE STACKS TOGETHER IN ARC GIS - MALCOLM TO PROVIDE INSTRUCTIONS IN DUE COURSE ON THIS STAGE
## FILES WHEN COMPLETE TO BE SAVED TO path_rasters_national, purpose, geography

## FOR NOW, AS A TEMPORARY FIX, WE DOWNLOAD THESE RASTERS FROM THEIR RELEASE (correcting names to be consistent with those used elsewhere, e.g. in rnet / scenarios)
raster_url <- "https://github.com/npct/pct-lsoa/releases/download/1.0/"

url_dl <- paste0(raster_url, "census-all.tif")
download.file(url_dl, file.path(path_outputs_national, purpose, geography, "ras_bicycle_all.tif"), mode="wb")
url_dl <- paste0(raster_url, "gov-all.tif")
download.file(url_dl, file.path(path_outputs_national, purpose, geography, "ras_govtarget_all.tif"), mode="wb")
url_dl <- paste0(raster_url, "gender-all.tif")
download.file(url_dl, file.path(path_outputs_national, purpose, geography, "ras_gendereq_all.tif"), mode="wb")
url_dl <- paste0(raster_url, "ducht-all.tif")
download.file(url_dl, file.path(path_outputs_national, purpose, geography, "ras_dutch_all.tif"), mode="wb")
url_dl <- paste0(raster_url, "ebikes-all.tif")
download.file(url_dl, file.path(path_outputs_national, purpose, geography, "ras_ebike_all.tif"), mode="wb")





 