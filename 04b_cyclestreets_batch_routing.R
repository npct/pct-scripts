#########################
### PART 2: RUN ROUTES THROUGH CYCLESTREETS
#########################

# LOAD DATA AND RUN BATCHES.  FOR QUIET LINES, RESTRICT TO THOSE WITH FAST ROUTE UNDER MAX. VISUALSE LENGTH
lines_cs <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, "lines_cs.Rds"))
if (route_type=="quietest") {
  rf_all_data <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("archive/rf_",file_name,"_data.Rds")))
  rf_all_data <- rf_all_data[(rf_all_data$length < (maxdist_scenario * 1000)),]
  summary({sel_q_line <- lines_cs$id %in% rf_all_data$id})
  lines_cs <- lines_cs[sel_q_line,]
}
size_limit <- 5000 # maximum size of a batch
nbatch <- ceiling(nrow(lines_cs) / size_limit)

# RUN BATCHES (1000 lines 5 min)] (before start national build ask for cycle streets update?)
for(i in 1:nbatch){
  l_start <- as.integer(1 + (i - 1) * size_limit)
  if (i * size_limit < nrow(lines_cs)) {
    l_fin <- as.integer(i * size_limit)
  } else {
    l_fin <- as.integer(nrow(lines_cs))
  }
  lines_cs_sub <- lines_cs[c(l_start:l_fin), ]
  
  routes <- line2route(lines_cs_sub, route_fun = route_cyclestreet, plan = route_type, n_processes = 10, base_url = "http://pct.cyclestreets.net/api/")
  routes@data <- routes@data[,!names(routes@data) %in% c("plan","start","finish")] # drop fields not wanted
  routes@data <- left_join(routes@data, lines_cs_sub@data, by = "id")  # merge in data in lines file
  saveRDS(routes,file = file.path(path_temp_cs, purpose, geography, paste0("r",substr(route_type, 1, 1),"_",file_name,"_",i,"of",nbatch,".Rds")))
  print(paste0("Batch ",i," of ",nbatch," finished at ",Sys.time()))
}

#########################
### PART 3: MERGE BATCHES FOR a) DATA AND b) ROUTES [do in 2 stages otherwise LSOA routes files get too big to handle]
#########################

# REJOIN THE FILES FOR **DATA** (ALL LENGTHS, USED FOR SCENARIO BUILDING) & CHECK
file_first <- readRDS(file.path(path_temp_cs, purpose, geography, paste0("r",substr(route_type, 1, 1),"_",file_name,"_",1,"of",nbatch,".Rds")))
rownames(file_first@data) <- sapply(1:length(file_first), function(j) file_first@lines[[j]]@ID) # FORCE DATA ROW NAMES TO BE SAME AS ID IN LINES (in case don't start from '1')
stack_data <- file_first@data
if(nbatch > 1) {
  for(i in 2:nbatch){
    file_next <- readRDS(file.path(path_temp_cs, purpose, geography, paste0("r",substr(route_type, 1, 1),"_",file_name,"_",i,"of",nbatch,".Rds")))
    rownames(file_next@data) <- sapply(1:length(file_next), function(j) file_next@lines[[j]]@ID)
    file_next_data <- file_next@data
    stack_data <- rbind(stack_data, file_next_data)
    #print(paste0("Stack ",i," of ",nbatch," added at ",Sys.time()))
  }
}

nrow(stack_data) == nrow(lines_cs)
summary(stack_data$id == lines_cs@data$id) # check route IDS - should all be True

# REDO FAILED LINES IF THERE ARE ANY, AND MERGE INTO STACK DATA
if(any(is.na(stack_data$length))) {
  stack_keep <- stack_data[!is.na(stack_data$length) & !is.na(stack_data$av_incline) & !is.na(stack_data$time) & is.na(stack_data$error), ] 
  id1 <- (stack_data$id[1])
  stack_redo <- stack_data[is.na(stack_data$length) | is.na(stack_data$av_incline) | is.na(stack_data$time) | !is.na(stack_data$error) | (stack_data$id==id1), ] #   ## put in the top line, assuming it has not failed, so that first re-done line does not fail and cause line2route to give error
  summary(stack_redo$error)
  # View(stack_redo[c("geo_code1", "geo_code2", "id", "e_dist_km", "error")]) # view errors interactively if needs be
  stack_redo_data <- stack_redo[c("geo_code1", "geo_code2", "id", "e_dist_km")]
  if (purpose=="commute")  {
    stack_redo_lines <- od2line2(flow = stack_redo_data, zones = cents_all)
  } else if (purpose=="school")  {
    stack_redo_lines <- od2line(flow = stack_redo_data, zones = cents_o, destinations = cents_d)
  } else {
  }
  row.names(stack_redo_lines) <- row.names(stack_redo_data)
  stack_redo <- SpatialLinesDataFrame(sl = stack_redo_lines, data = stack_redo_data)
  stack_redo <- spTransform(stack_redo, proj_4326)
  routes_redo <- line2route(l = stack_redo, route_fun = route_cyclestreet, plan = route_type, n_processes = 10, base_url = "http://pct.cyclestreets.net/api/")
  routes_redo@data <- routes_redo@data[,!names(routes_redo@data) %in% c("plan","start","finish")] # drop fields not wanted
  routes_redo@data <- left_join(routes_redo@data, stack_redo@data, by = "id")
  routes_redo <- routes_redo[routes_redo@data$id!=id1,] # REMOVE THE FIRST LINE, THAT WAS REPEATED JUST TO MAKE SURE LINE2ROUTE RAN OK
  row.names(routes_redo@data) <- sapply(1:length(routes_redo), function(j) routes_redo@lines[[j]]@ID)
  saveRDS(routes_redo,file = file.path(path_temp_cs, purpose, geography, paste0("r",substr(route_type, 1, 1),"_",file_name,"_redo_of",nbatch,".Rds")))
  routes_redo_data <- routes_redo@data
  stack_data <- rbind(stack_keep, routes_redo_data)
  stack_redo2 <- stack_data[is.na(stack_data$length) | is.na(stack_data$av_incline) | is.na(stack_data$time) | !is.na(stack_data$error), ]
  summary(stack_redo2$error) # SHOULD BE ZERO - IF NOT RUN THIS SECTION AGAIN? OR ADD IMPOSSIBLE LINES TO EXCLUDED LIST OF PROBLEM IDS
}

# FOR FASTEST LINE, LIMIT TO LINES UNDER MAXIMUM SCENARIO LENGTH & SAVE
if (route_type == "fastest") {
  stack_data <- stack_data[(stack_data$length < (maxdist_scenario * 1000)),]  # NB length in metres, maxdist_scenario in km
}
saveRDS(stack_data, file = file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("archive/r",substr(route_type, 1, 1),"_",file_name,"_data.Rds")))

# REJOIN THE FILES FOR **ROUTES** (FASTEST ROUTE LENGTH < VISUALISE DISTANCE), MERGE IN ROUTES THAT INITIALLY FAILED, & SAVE SHAPE
rf_data_visualise <- readRDS(file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("archive/rf_",file_name,"_data.Rds")))
rf_data_visualise <- rf_data_visualise[(rf_data_visualise$length < (maxdist_visualise * 1000)),]
size_per_stack <- 50  
nbatch_stacks <- ceiling(nbatch/size_per_stack)
if(nbatch_stacks > 1) {
  for(j in 1:nbatch_stacks) {
    # DEFINE WHICH FILES TO LOAD IN THIS BATCH
    numload <- ((j-1) * size_per_stack) + 1
    numstart <- numload + 1
    if(j==nbatch_stacks){ numend <- nbatch} else {numend <- (j * size_per_stack)}
    # MERGE SELECTED BATCH
    print(paste0("Starting stack batch ",j," of ",nbatch_stacks," at ",Sys.time()))
    stack_next <- readRDS(file.path(path_temp_cs, purpose, geography, paste0("r", substr(route_type, 1, 1), "_", file_name, "_", numload, "of", nbatch, ".Rds")))
    rownames(stack_next@data) <- sapply(1:length(stack_next), function(j) stack_next@lines[[j]]@ID) # FORCE DATA ROW NAMES TO BE SAME AS ID IN LINES (in case don't start from '1')
    stack_next <- stack_next[((stack_next@data$id %in% rf_data_visualise$id) & is.na(stack_next@data$error)),]
    for(i in numstart:numend){
      file_next <- readRDS(file.path(path_temp_cs, purpose, geography, paste0("r",substr(route_type, 1, 1),"_",file_name,"_",i,"of",nbatch,".Rds")))
      rownames(file_next@data) <- sapply(1:length(file_next), function(j) file_next@lines[[j]]@ID)
      file_next <- file_next[((file_next@data$id %in% rf_data_visualise$id) & is.na(file_next@data$error)),]
      stack_next <- spRbind(stack_next, file_next)
      print(paste0("Stack ",i," of ",nbatch," added at ",Sys.time()))
    }
    # APPEND TO MAIN BATCH
    if(j==1){
      stack <- stack_next
    } else {
      stack <- spRbind(stack, stack_next)
    }
  }
} else {
  stack <- readRDS(file.path(path_temp_cs, purpose, geography, paste0("r", substr(route_type, 1, 1), "_", file_name, "_1", "of", nbatch, ".Rds")))
}

if(file.exists(file.path(path_temp_cs, purpose, geography, paste0("r", substr(route_type, 1, 1), "_", file_name, "_redo_of", nbatch,".Rds")))) {
  routes_redo <- readRDS(file.path(path_temp_cs, purpose, geography, paste0("r", substr(route_type, 1, 1), "_", file_name, "_redo_of", nbatch,".Rds")))
  routes_redo <- routes_redo[((routes_redo@data$id %in% rf_data_visualise$id) & is.na(routes_redo@data$error)),]
  stack <- spRbind(stack, routes_redo)
}
stack@data <- stack@data["id"]

saveRDS(stack,file = file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("archive/r",substr(route_type, 1, 1),"_",file_name,"_shape.Rds")))
saveRDS(stack,file = file.path(path_inputs, "02_intermediate/02_travel_data", purpose, geography, paste0("r",substr(route_type, 1, 1),"_shape.Rds")))
