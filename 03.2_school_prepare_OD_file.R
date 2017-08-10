# SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)

purpose <- "school"
geography <- "lsoa"  
set.seed(12345)

#########################
# LOAD SCHOOL FLOW DATASET
#########################
sf11 <- read_tsv(file.path(path_inputs, "01_raw/02_travel_data/school/NPD_originals_PRIVATE/Spring_Census_2011.txt"))
sf11 <- sf11[,c(1, 3:4, 6:10)]
names(sf11) <- sub(paste0("_SPR11"), "", names(sf11))
names(sf11) <- tolower(names(sf11))
sf11 <- dplyr::rename(sf11, lsoa01cd = `llsoa`, bicycle = `cycle`, foot = `walk`)


#########################
### CONVERT 2001 LSOA TO 2011 SUCH THAT CHILDREN MOVED PROBABILISTICALLY TO NEW FLOWS (MAINTAINING TOTAL NUMBER)
#########################

# Open LSOA look up
unzip(file.path(path_inputs, "01_raw/01_geographies/geography_lookups/LSOA_2001_to_2011.zip"),
      files = "LSOA01_LSOA11_LAD11_EW_LU.csv", exdir = path_temp_unzip)
lsoa_lookup <- read_csv(file.path(path_temp_unzip, "LSOA01_LSOA11_LAD11_EW_LU.csv"))
lsoa_lookup <- lsoa_lookup[,c(1, 3)]
names(lsoa_lookup) <- tolower(names(lsoa_lookup))

# Identify for each LSOA the number of records (1 to max of 11)
lsoa_lookup <- lsoa_lookup[order(lsoa_lookup$lsoa01cd),]
littlen <- tapply(lsoa_lookup$lsoa01cd, lsoa_lookup$lsoa01cd,
                  function(x) seq(1,length(x),1))
lsoa_lookup$littlen <- unlist(littlen)
maxlittlen <- max(lsoa_lookup$littlen)
lsoa_lookup$littlen <- paste0("lsoa11_",lsoa_lookup$littlen)

# Reshape LSOA lookup wide, 1 column per lsoa11, and count the no. of columns
lsoa_lookup <- dcast(lsoa_lookup, lsoa01cd~littlen, value.var="lsoa11cd")
lsoa_lookup$numlsoa11 <- apply(lsoa_lookup, 1, function(x) (maxlittlen - sum(is.na(x))))

# Make school data 1 per child and merge in LSOA look up
sf11 <- melt(sf11, id.vars = c("lsoa01cd","urn", "schoolname"))  # one row per flow * mode
sf11 <- sf11[sf11$value>0,]
sf11 <- sf11[rep(seq_len(nrow(sf11)), sf11$value), 1:4]  # one row per child
sf11 <- left_join(sf11, lsoa_lookup, by="lsoa01cd")

# Randomly identify one LSOA to choose for each child
sf11$random <- runif(nrow(sf11), min = 0, max = 1)
sf11$lsoa11tochoose <- ceiling(sf11$numlsoa11 * sf11$random)
#table(sf11$numlsoa11,sf11$lsoa11tochoose)
sf11$lsoa11tochoose[is.na(sf11$lsoa11tochoose)] <- 1
for(i in 1:maxlittlen){
  sf11$lsoa11cd[sf11$lsoa11tochoose==i] <- sf11[[paste0("lsoa11_", i)]][sf11$lsoa11tochoose==i]
}

# Collapse back school data to flow level
sf11 <- sf11[,names(sf11) %in% c("lsoa11cd","urn","schoolname","variable")]
sf11 <- dcast(sf11, lsoa11cd + urn + schoolname ~ variable, fun.aggregate = length )

# Merge in LSOA name
lsoa_lookup2 <- read_csv(file.path(path_temp_unzip, "LSOA01_LSOA11_LAD11_EW_LU.csv"))
lsoa_lookup2 <- unique(lsoa_lookup2[,c(3, 4)])
names(lsoa_lookup2) <- tolower(names(lsoa_lookup2))
sf11 <- left_join(sf11, lsoa_lookup2, by="lsoa11cd")


#########################
## LOAD SCHOOL CHARACTERISTICS AND MERGE IN
########################

# Define phase of education, for 2010 and 2011
for (i in (10:11) ) {
  sd <- read_tsv(file.path(path_inputs, "01_raw/02_travel_data/school/NPD_originals_PRIVATE", paste0("SLD_CENSUS_20",i,".txt")))
  names(sd) <- sub(paste0("LEA",i,"_"), "", names(sd))
  names(sd) <- tolower(names(sd))
  sd$northing <- as.numeric(sd$northing)
  sd$easting <- as.numeric(sd$easting)
  sd$pt_girls_old <- rowSums(subset(sd, select=(pt_girls_11:pt_girls_19)))
  sd$pt_boys_old <- rowSums(subset(sd, select=(pt_boys_11:pt_boys_19)))
  sd$ft_girls_old <- rowSums(subset(sd, select=(ft_girls_11:ft_girls_19)))
  sd$ft_boys_old <- rowSums(subset(sd, select=(ft_boys_11:ft_boys_19)))
  sd$old_perc <- rowSums(subset(sd, select=(pt_girls_old:ft_boys_old))) * 100 / sd$headcount_pupils
  sd$boarding_perc <- sd$boarders_total * 100 / sd$headcount_pupils
  sd$secondary <- 0
  sd$secondary[sd$phase %in% c("Secondary", "Middle Deemed Secondary")] <- 1
  sd$secondary[sd$phase=="Not applicable" && sd$old_perc>50] <- 1
  sd <- sd[,names(sd) %in% c("urn", "northing", "easting","phase", "secondary", "boarding_perc")]
  assign(paste0("sd",i), data.frame(sd))
}

# Merge school details into school flow
sf11 <- left_join(sf11, sd11, by="urn")
sf11 <- left_join(sf11, sd10, by="urn")
sf11$northing <- ifelse(!is.na(sf11$northing.x), sf11$northing.x, sf11$northing.y)
sf11$easting <- ifelse(!is.na(sf11$easting.x), sf11$easting.x, sf11$easting.y)
sf11$phase <- ifelse(!is.na(sf11$phase.x), sf11$phase.x, sf11$phase.y)
sf11$secondary <- ifelse(!is.na(sf11$secondary.x), sf11$secondary.x, sf11$secondary.y)
sf11$boarding_perc <- ifelse(!is.na(sf11$boarding_perc.x), sf11$boarding_perc.x, sf11$boarding_perc.y)

# Asign phase of education + easting/northing where missing from current edubase, based on urn: http://www.education.gov.uk/edubase/establishment/viewMapTab.xhtml?urn=136087
sd_extra <- unique(sf11[is.na(sf11$easting), c("urn", "schoolname", "northing", "easting", "phase", "secondary", "boarding_perc")])
write_csv(sd_extra, file.path(path_inputs, "01_raw/02_travel_data/school/x-manual_extras", "1_missing_schools_details.csv"))
# [ manually edit]
sd_extra <- read_csv(file.path(path_inputs, "01_raw/02_travel_data/school/x-manual_extras", "1_missing_schools_details_manualedit.csv"))
sd_extra <- dplyr::rename(sd_extra, schoolname_edit = `schoolname`, northing_edit = `northing`, easting_edit = `easting`, phase_edit = `phase`, secondary_edit = `secondary`, boarding_perc_edit = `boarding_perc`)
sf11 <- left_join(sf11, sd_extra, by="urn")
sf11$northing <- ifelse(!is.na(sf11$northing), sf11$northing, sf11$northing_edit)
sf11$easting <- ifelse(!is.na(sf11$easting), sf11$easting, sf11$easting_edit)
sf11$phase <- ifelse(!is.na(sf11$phase), sf11$phase, sf11$phase_edit)
sf11$secondary <- ifelse(!is.na(sf11$secondary), sf11$secondary, sf11$secondary_edit)
sf11$boarding_perc <- ifelse(!is.na(sf11$boarding_perc), sf11$boarding_perc, sf11$boarding_perc_edit)

# Correct errors in easting/northing on edubase (manual checking in pct-inputs\01_raw\02_travel_data\school\x-manual_extras\2_check_school_address_manual.csv)
sf11$easting[sf11$urn==102080] <- 530010
sf11$northing[sf11$urn==102080] <- 191371
sf11$easting[sf11$urn==116174] <- 458567
sf11$northing[sf11$urn==116174] <- 104136	
sf11$easting[sf11$urn==120753] <- 494887
sf11$northing[sf11$urn==120753] <- 369344	
sf11$easting[sf11$urn==134971] <- 636019
sf11$northing[sf11$urn==134971] <- 166570	

#Adjust school easting/northing if is (after snapping to road) too close to LSOA centroid to route (<4m): (manual checking in pct-inputs\01_raw\02_travel_data\school\x-manual_extras\3_shorttrips_adjust_manual.csv)
adjust_ne <- read_csv(file.path(path_inputs, "01_raw/02_travel_data/school/x-manual_extras", "3_adjust_urn_near_cents_manual.csv"))
adjust_ne <- unique(adjust_ne[,names(adjust_ne) %in% c("urn","northing_new", "easting_new")])
sf11 <- left_join(sf11, adjust_ne, by="urn")
sf11$northing <- ifelse(!is.na(sf11$northing_new), sf11$northing_new, sf11$northing)
sf11$easting <- ifelse(!is.na(sf11$easting_new), sf11$easting_new, sf11$easting)

#######################
# PREPARE FOR CYCLE STREETS MERGE
#######################

# Create flows dataset with attribute data
sf11$id <- paste0(sf11$lsoa11cd, " urn", sf11$urn)
flows_2011 <- sf11[,c("id", "lsoa11cd","lsoa11nm", "urn","schoolname","phase","secondary", "boarding_perc", "bicycle", "foot", "car", "other","unknown")]
if(!dir.exists(file.path(path_inputs, "02_intermediate/02_travel_data/school"))) { dir.create(file.path(path_inputs, "02_intermediate/02_travel_data/school")) }
if(!dir.exists(file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa"))) { dir.create(file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa")) }
write_csv(flows_2011, file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa", "flows_2011.csv"))

# Create cents dataset, 
urn_data <- unique(sf11[,names(sf11) %in% c("urn","schoolname", "northing", "easting")])
row.names(urn_data) <- c(1:nrow(urn_data))  
urn_coords <- cbind(as.numeric(urn_data$easting), as.numeric(urn_data$northing))
urn_data <- unique(sf11[,names(sf11) %in% c("urn","schoolname")])
urn_cents <- SpatialPointsDataFrame(coords = urn_coords, data = urn_data, proj4string = proj_27700)
urn_cents <- spTransform(urn_cents, proj_4326) # make it lat-long as this is pct standard
geojson_write(urn_cents, file = file.path(path_inputs, "02_intermediate/01_geographies/urn_cents.geojson"))
