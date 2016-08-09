rnet <- overline(rft, "bicycle")

if(require(foreach) & require(doParallel)){
  n_cores <- 4 # set max number of cores to 4
  # reduce n_cores for 2 core machines
  if(parallel:::detectCores() < 4)
    n_cores <- parallel:::detectCores()
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)
  # foreach::getDoParWorkers()
  # create list in parallel
  rft_data_list <- foreach(i = scens) %dopar% {
    rnet_tmp <- stplanr::overline(rft, i)
    rnet_tmp@data[i]
  }
  # save the results back into rnet with normal for loop
  for(j in seq_along(scens)){
    rnet@data <- cbind(rnet@data, rft_data_list[[j]])
  }
  stopCluster(cl = cl)
} else {
  for(i in scens){
    rnet_tmp <- overline(rft, i)
    rnet@data[i] <- rnet_tmp@data[i]
    rft@data[i] <- NULL
  }
}