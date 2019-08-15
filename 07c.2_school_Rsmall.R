# Create data directory if not there & start time
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_regional_Rsmall, purpose, geography, region))) { dir.create(file.path(path_outputs_regional_Rsmall, purpose, geography, region)) }

###########################
### MAKE R SMALL OBJECTS
###########################

d <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "d.Rds"))
d <- d[d_codebook_small$`Variable name`]
saveRDS(d, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "d.Rds")) , version = 2)

z <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "z.Rds"))
z <- z[z_codebook_small$`Variable name`]
saveRDS(z, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "z.Rds")) , version = 2)

## Can remove this code...could also delete those files locally
if(file.exists(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))) {
  rnet <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))
  saveRDS(rnet, (file.path(path_outputs_regional_Rsmall, purpose, geography, region, "rnet.Rds")) , version = 2)
 # file.remove(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))
}



