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
lad_attributes <- read_csv(file.path(path_temp_scenario, purpose, "lad_all_attributes_unrounded.csv"))

## OPEN CODEBOOKS
z_codebook <- read_csv(file.path(path_codebooks, purpose, "z_codebook.csv"))
od_l_rf_codebook <- read_csv(file.path(path_codebooks, purpose, "od_l_rf_codebook.csv"))
lad_codebook <- read_csv(file.path(path_codebooks, purpose, "lad_codebook.csv"))

## APPLY MINIMUM SIZE + ROUND, SUBSET TO CODEBOOK VARIABLES, SAVE
z_all_attributes <- as.data.frame(apply(z_all_attributes, c(2), round_df), stringsAsFactors = F)
z_all_attributes <- z_all_attributes[z_codebook$`Variable name`]
write_csv(z_all_attributes,  file.path(path_outputs_national, purpose, geography, "z_all_attributes.csv"))

od_all_attributes <- as.data.frame(apply(od_all_attributes, c(2), round_df), stringsAsFactors = F)
od_all_attributes <- od_all_attributes[od_l_rf_codebook$`Variable name`]
write_csv(od_all_attributes,  file.path(path_outputs_national, purpose, geography, "od_all_attributes.csv"))

lad_attributes <- as.data.frame(apply(lad_attributes, c(2), round_df), stringsAsFactors = F)
lad_attributes <- lad_attributes[lad_codebook$`Variable name`]
write_csv(lad_attributes,  file.path(path_outputs_national, purpose, "lad_attributes.csv"))
