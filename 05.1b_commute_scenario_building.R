#SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)
purpose <- "commute"
geography <- "msoa"  

#########################
### ROUND AND SAVE SCENARIO ATTRIBUTE (this will be done in previous stage when move stata to R)
#########################

## OPEN ATTRIBUTE DATA
z_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, geography, "z_all_attributes_unrounded.csv"))
od_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, geography, "od_all_attributes_unrounded.csv"))
lad_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, "lad_all_attributes_unrounded.csv"))

## APPLY MINIMUM SIZE, ROUND AND SAVE
z_all_attributes <- as.data.frame(apply(z_all_attributes, c(2), round_df), stringsAsFactors = F)
write_csv(z_all_attributes,  file.path(path_outputs_national, purpose, geography, "z_all_attributes.csv"))

od_all_attributes <- as.data.frame(apply(od_all_attributes, c(2), round_df), stringsAsFactors = F)
write_csv(od_all_attributes,  file.path(path_outputs_national, purpose, geography, "od_all_attributes.csv"))

lad_all_attributes <- as.data.frame(apply(lad_all_attributes, c(2), round_df), stringsAsFactors = F)
write_csv(lad_all_attributes,  file.path(path_temp_scenario, purpose, "lad_all_attributes.csv"))
