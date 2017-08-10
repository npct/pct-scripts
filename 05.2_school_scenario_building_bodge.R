#SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)
purpose <- "school"
geography <- "lsoa"  

if(!dir.exists(file.path(path_outputs_national, purpose))) { dir.create(file.path(path_outputs_national, purpose)) }
if(!dir.exists(file.path(path_outputs_national, purpose, geography))) { dir.create(file.path(path_outputs_national, purpose, geography)) }


#########################
### TEMP BODGE: DOWNLOAD EXISTING SCHOOLS DATA AND RENAME VARIABLES TO WORK IN LATEST VERSION
#########################
# region <- "west-yorkshire"
# z <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/z.Rds"))
# z@data <- dplyr::rename(z@data, geo_name = `geo_label`)
# saveRDS(z, file.path(path_outputs_regional, purpose, geography, region,  "z.Rds"))
# 
# rnet <- readRDS(file.path(path_outputs_regional, purpose, geography, region,  "github_originals/rnet.Rds"))
# rnet$local_id <- 1:nrow(rnet)
# saveRDS(rnet, file.path(path_outputs_regional, purpose, geography, region,  "rnet.Rds"))

# ## MAKE AND ISLE OF WIGHT TEST VERSION, COPY FROM COMMUTE
# region <- "isle-of-wight"
# z <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "z.Rds"))
# z@data <- dplyr::rename(z@data, car = `car_driver`)
# saveRDS(z, file.path(path_outputs_regional, purpose, geography, region,  "z.Rds"))
# 
# rnet <- readRDS(file.path(path_outputs_regional, "commute", geography, region,  "rnet.Rds"))
# saveRDS(rnet, file.path(path_outputs_regional, purpose, geography, region,  "rnet.Rds"))



#########################
### ALTERNATIVE TEMP BODGE: QUICKLY APPLY ILAN
#########################
# Improvements: consider what schools to exclude (many children travelling 'unknown' mode/location); exclude e.g. boarding schools, or those where many children travelling far; redo modelling, and do for primary school; do mode shift/carbon etc...

# Identify England LSOA
lsoa_england <- read_csv(file.path(path_temp_unzip, "LSOA01_LSOA11_LAD11_EW_LU.csv"))
lsoa_england <- unique(lsoa_england[,c(3,4,6,7)])
lsoa_england <- dplyr::rename(lsoa_england, geo_code = `LSOA11CD`, geo_name = `LSOA11NM`, lad11cd = `LAD11CD`, lad_name = `LAD11NM`)
lsoa_england <- lsoa_england[substr(lsoa_england$geo_code, 1, 1)=="E",]

# Load school data
flows_2011 <- read_csv(file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa", "flows_2011.csv"))
rfrq_all_data <- read_csv(file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa", "rfrq_all_data.csv"))
od_all_attributes <- left_join(flows_2011, rfrq_all_data, by = "id")

# Secondary schools only, and merge in distance data
od_all_attributes <- dplyr::rename(od_all_attributes, geo_code1 = `lsoa11cd`, geo_name1 = `lsoa11nm`, geo_code2 = `urn`, geo_name2 = `schoolname`)
od_all_attributes <- od_all_attributes[!is.na(od_all_attributes$geo_code1),]
od_all_attributes <- od_all_attributes[od_all_attributes$secondary==1,]
od_all_attributes$all <- rowSums(subset(od_all_attributes, select=(bicycle:unknown))) # in future consider dropping or imputing unknown children??

# Use 27 Jan Ilan parameters
od_all_attributes$pred_base <- -7.940 + ( -2.596 * od_all_attributes$rf_dist_km) + (7.140 * (od_all_attributes$rf_dist_km ^ 0.5)) + (.06041 * (od_all_attributes$rf_dist_km ^ 2)) + (-0.2894 * od_all_attributes$rf_avslope_perc) + (-0.03229 * od_all_attributes$rf_dist_km*od_all_attributes$rf_avslope_perc) 
od_all_attributes$pred_dutch <- od_all_attributes$pred_base + 4.914 
od_all_attributes$pred_base <- exp(od_all_attributes$pred_base)/(1+exp(od_all_attributes$pred_base))
od_all_attributes$pred_base[is.na(od_all_attributes$pred_base)] <- 0
od_all_attributes$pred_dutch <- exp(od_all_attributes$pred_dutch)/(1+exp(od_all_attributes$pred_dutch))
od_all_attributes$pred_dutch[is.na(od_all_attributes$pred_dutch)] <- 0

od_all_attributes$govtarget_slc <- od_all_attributes$bicycle + (od_all_attributes$pred_base * od_all_attributes$all)
od_all_attributes$dutch_slc <- od_all_attributes$pred_dutch * od_all_attributes$all
od_all_attributes$dutch_slc <- ifelse(od_all_attributes$dutch_slc > od_all_attributes$bicycle, od_all_attributes$dutch_slc, od_all_attributes$bicycle)
z_variables <- c("all", "car", "bicycle", "foot", "other","unknown", "govtarget_slc", "dutch_slc")
od_all_attributes <- od_all_attributes[,c("id", "geo_code1", "geo_code2", "phase","secondary", z_variables)]
       
# create and save zones, merging in absent and setting to zero, and restricting to England
z_all_attributes <- od_all_attributes[,c("geo_code1", z_variables)]
z_all_attributes <- dplyr::rename(z_all_attributes, geo_code = `geo_code1`)
z_all_attributes <- aggregate(cbind(all, bicycle, foot, car, other, unknown, govtarget_slc, dutch_slc) ~ geo_code, z_all_attributes, sum)
z_all_attributes <- left_join(lsoa_england, z_all_attributes, by = "geo_code")
foreach(i = z_variables) %do% {
  z_all_attributes[z_variables][is.na(z_all_attributes[z_variables])] <- 0
}
z_all_attributes <- as.data.frame(apply(z_all_attributes, c(2), round_df), stringsAsFactors = F)
write_csv(z_all_attributes,  file.path(path_outputs_national, purpose, geography, "z_all_attributes.csv"))

# save flows
od_all_attributes <- as.data.frame(apply(od_all_attributes, c(2), round_df), stringsAsFactors = F)
write_csv(od_all_attributes,  file.path(path_outputs_national, purpose, geography, "od_all_attributes.csv"))



# #########################
# ### METHODS FOR FUTURE FOR MAIN SCHOOLS DATABASE
# #########################
# Remove schools were more than half (or perhaps a lower threshold) of the pupils either have unknown mode or unknown LSOA

# # 8815 schools out of 21649 with some missing LSOA data
# length(unique(sf11$URN_SPR11))
# length(sf11$URN_SPR11[is.na(sf11$LLSOA_SPR11)])
# length(unique(sf11$URN_SPR11[is.na(sf11$LLSOA_SPR11)]))
# # Range 1-49 children missing, 0.3% of all children
# summary(sf11$TOTAL[is.na(sf11$LLSOA_SPR11)])
# (sum(sf11$TOTAL[is.na(sf11$LLSOA_SPR11)]) * 100 / sum(sf11$TOTAL))
# 