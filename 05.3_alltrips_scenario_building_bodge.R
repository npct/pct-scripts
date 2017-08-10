#SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)
purpose <- "alltrips"
geography <- "msoa"  

#########################
### TEMP BODGE: DOWNLOAD EXISTING ALL TRIPS DATA AND RENAME VARIABLES TO WORK IN LATEST VERSION
#########################
region <- "greater-manchester"
z_codebook <- read_csv(file.path(path_outputs_regional, purpose, geography, region,  "alltrips_codebooks_temp/z_codebook.csv"))
c_codebook <- read_csv(file.path(path_outputs_regional, purpose, geography, region,  "alltrips_codebooks_temp/c_codebook.csv"))
od_l_rf_codebook <- read_csv(file.path(path_outputs_regional, purpose, geography, region,  "alltrips_codebooks_temp/od_l_rf_codebook.csv"))
rq_codebook <- read_csv(file.path(path_outputs_regional, purpose, geography, region,  "alltrips_codebooks_temp/rq_codebook.csv"))
rnet_codebook <- read_csv(file.path(path_outputs_regional, purpose, geography, region,  "alltrips_codebooks_temp/rnet_codebook.csv"))

z <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/z.Rds"))
z@data <- dplyr::rename(z@data, geo_name = `geo_label`)
z@data <- z@data[z_codebook$`Variable name`]
saveRDS(z, file.path(path_outputs_regional, purpose, geography, region,  "z.Rds"))

c <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/c.Rds"))
c@data <- dplyr::rename(c@data, geo_name = `geo_label`)
c@data <- c@data[c_codebook$`Variable name`]
saveRDS(c, file.path(path_outputs_regional, purpose, geography, region,  "c.Rds"))

l <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/l.Rds"))
l@data <- dplyr::rename(l@data, geo_code1 = `msoa1`, geo_code2 = `msoa2`, geo_name1 = `geo_label1`, 
                        geo_name2 = `geo_label2`, e_dist_km = `dist`, rf_dist_km = `dist_fast`,
                        rq_dist_km = `dist_quiet`, dist_rf_e = `cirquity`,
                        dist_rq_rf = `distq_f`, rf_avslope_perc = `avslope`,
                        rq_avslope_perc = `avslope_q`,  rf_time_min = `time_fast`, rq_time_min = `time_quiet`)
l@data <- l@data[od_l_rf_codebook$`Variable name`]
saveRDS(l, file.path(path_outputs_regional, purpose, geography, region,  "l.Rds"))

rf <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/rf.Rds"))
rf@data <- left_join(rf@data, l@data, by="id")
rf@data <- rf@data[od_l_rf_codebook$`Variable name`]
saveRDS(rf, file.path(path_outputs_regional, purpose, geography, region,  "rf.Rds"))

rq <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/rq.Rds"))
rq@data <- left_join(rq@data, l@data, by="id")
rq@data <- rq@data[rq_codebook$`Variable name`]
saveRDS(rq, file.path(path_outputs_regional, purpose, geography, region,  "rq.Rds"))

rnet <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/rnet.Rds"))
rnet@data <- dplyr::rename(rnet@data, singlezone = `Singlezone`)
rnet@data$local_id <- 1:nrow(rnet)
rnet@data <- rnet@data[rnet_codebook$`Variable name`]
saveRDS(rnet, file.path(path_outputs_regional, purpose, geography, region,  "rnet.Rds"))


# ## MAKE AND ISLE OF WIGHT TEST VERSION, COPY FROM COMMUTE
# region <- "isle-of-wight"
# z <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "z.Rds"))
# saveRDS(z, file.path(path_outputs_regional, purpose, geography, region,  "z.Rds"))
# 
# c <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "c.Rds"))
# saveRDS(c, file.path(path_outputs_regional, purpose, geography, region,  "c.Rds"))
# 
# l <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "l.Rds"))
# saveRDS(l, file.path(path_outputs_regional, purpose, geography, region,  "l.Rds"))
# 
# rf <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "rf.Rds"))
# saveRDS(rf, file.path(path_outputs_regional, purpose, geography, region,  "rf.Rds"))
# 
# rq <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "rq.Rds"))
# saveRDS(rq, file.path(path_outputs_regional, purpose, geography, region,  "rq.Rds"))
# 
# rnet <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "rnet.Rds"))
# saveRDS(rnet, file.path(path_outputs_regional, purpose, geography, region,  "rnet.Rds"))
