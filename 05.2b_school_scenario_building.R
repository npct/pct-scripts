#SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)
purpose <- "school"
purpose_private <- paste0(purpose, "_private")
geography <- "lsoa"  

if(!dir.exists(file.path(path_outputs_national, purpose))) { dir.create(file.path(path_outputs_national, purpose)) }
if(!dir.exists(file.path(path_outputs_national, purpose, geography))) { dir.create(file.path(path_outputs_national, purpose, geography)) }
if(!dir.exists(file.path(path_outputs_national, purpose_private))) { dir.create(file.path(path_outputs_national, purpose_private)) }
if(!dir.exists(file.path(path_outputs_national, purpose_private, geography))) { dir.create(file.path(path_outputs_national, purpose_private, geography)) }

#########################
### ROUND AND SAVE SCENARIO ATTRIBUTE (this will be done in previous stage when move stata to R)
#########################

## OPEN ATTRIBUTE DATA
z_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, geography, "z_all_attributes_unrounded.csv"))
d_all_attributes <- read_csv(file.path(path_temp_scenario, purpose, geography, "d_all_attributes_unrounded.csv"))
z_all_attributes_private <- read_csv(file.path(path_temp_scenario, purpose, geography, "z_all_attributes_private_unrounded.csv"))
d_all_attributes_private <- read_csv(file.path(path_temp_scenario, purpose, geography, "d_all_attributes_private_unrounded.csv"))
lad_attributes <- read_csv(file.path(path_temp_scenario, purpose, "lad_all_attributes_unrounded.csv"))

## OPEN CODEBOOKS
z_codebook <- read_csv(file.path(path_codebooks, purpose, "z_codebook.csv"))
d_codebook <- read_csv(file.path(path_codebooks, purpose, "d_codebook.csv"))
lad_codebook <- read_csv(file.path(path_codebooks, purpose, "lad_codebook.csv"))

## ROUND THE PUBLIC DATA (ONLY), SUBSET TO CODEBOOK VARIABLES, SAVE
z_all_attributes <- z_all_attributes[order(z_all_attributes$geo_name),] # A bodge: sort so as not to have at the top an LSOA that has 0 cars in, as this messes up rounding.  Correct 2 lines later
z_all_attributes <- as.data.frame(apply(z_all_attributes, c(2), round_df), stringsAsFactors = F)
z_all_attributes <- z_all_attributes[order(z_all_attributes$geo_code),]
z_all_attributes <- z_all_attributes[z_codebook$`Variable name`]
write_csv(z_all_attributes,  file.path(path_outputs_national, purpose, geography, "z_all_attributes.csv"))

z_all_attributes_private <- z_all_attributes_private[z_codebook$`Variable name`]
write_csv(z_all_attributes_private,  file.path(path_outputs_national, purpose_private, geography, "z_all_attributes.csv"))


d_all_attributes <- as.data.frame(apply(d_all_attributes, c(2), round_df), stringsAsFactors = F)
d_all_attributes <- d_all_attributes[d_codebook$`Variable name`]
write_csv(d_all_attributes,  file.path(path_outputs_national, purpose, geography, "d_all_attributes.csv"))

d_all_attributes_private <- d_all_attributes_private[d_codebook$`Variable name`]
write_csv(d_all_attributes_private,  file.path(path_outputs_national, purpose_private, geography, "d_all_attributes.csv"))


lad_attributes <- as.data.frame(apply(lad_attributes, c(2), round_df), stringsAsFactors = F)
lad_attributes <- lad_attributes[lad_codebook$`Variable name`]
write_csv(lad_attributes,  file.path(path_outputs_national, purpose, "lad_attributes.csv"))
