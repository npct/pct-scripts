# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography, region)) }

###########################
### MAKE R SMALL OBJECTS
###########################

c <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "c.Rds"))
c <- c[c_codebook_small$`Variable name`]
saveRDS(c, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "c.Rds")) , version = 2)

l <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "l.Rds"))
l <- l[l@data$rf_dist_km<=rsmall_maxdist,]
l <- l[od_l_rf_codebook_small$`Variable name`]
saveRDS(l, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "l.Rds")) , version = 2)

rf <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "rf.Rds"))
rf <- rf[rf@data$rf_dist_km<=rsmall_maxdist,]
rf <- rf[od_l_rf_codebook_small$`Variable name`]
saveRDS(rf, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "rf.Rds")) , version = 2)

rq <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "rq.Rds"))
rq <- rq[rq@data$rf_dist_km<=rsmall_maxdist,]
rq <- rq[rq_codebook_small$`Variable name`]
saveRDS(rq, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "rq.Rds")) , version = 2)

z <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds"))
z <- z[z_codebook_small$`Variable name`]
saveRDS(z, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "z.Rds")) , version = 2)

## Can remove this code...could also delete those files locally
if(file.exists(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))) {
  rnet <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))
  saveRDS(rnet, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "rnet.Rds")) , version = 2)
 # file.remove(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))
}



