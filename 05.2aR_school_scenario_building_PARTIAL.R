#SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)

###############
## DEFINE SCHOOL STUDY POPULATION
###############
  sf11 <- read_csv(file.path(path_inputs, "02_intermediate/02_travel_data/school/lsoa", "flows_2011.csv"))
  
  ## PREPARATION CLEANING VARS
  sf11$all <- rowSums(subset(sf11, select=(bicycle:unknown)))
  sf11$schoolsize <- ave(sf11$all,sf11$urn, FUN=sum)
  sf11 <- sf11[order(sf11$urn),]
  sf11$schoolflag <- (!duplicated(sf11$urn)) * 1
  
  ## MIN SCHOOL SIZE - OR PERHAPS NOT EXCEPT FOR SO SMALL THAT DISCLOSIVE? 
  # View(sf11[sf11$schoolflag==1 & sf11$schoolsize<7,])
  # N=1: inpatients at the hospital (http://www.ashvilla.lincs.sch.uk/)
  # N=5: v. small primary
  # N=6, spires school: small special school
  # N=6, Holy Island: v. small primary in Lindisfarm Island
  sf11 <- sf11[sf11$schoolsize>=5,] ## 1 school - don't even report in write up
  
  ## MAX % SCHOOL BOARDING - OTHERWISE GET AT POTENTIAL/HEALTH IMPACTS WRONG [NB THOSE PUPILS WHO ARE BOARDING ARE PROBABY COMING FAR = CAN ASSUME NO CHANGE]
  summary(sf11$school_boarding <- (sf11$boarding_perc>=50))
  
  ## MAX % SCHOOL WITH UNKNOWN MODE OR LSOA 
  sf11$unknownmodelsoa <- ifelse(is.na(sf11$lsoa11cd), sf11$all, sf11$unknown) 
  sf11$numunknownmodelsoa <- ave(sf11$unknownmodelsoa,sf11$urn, FUN=sum)
  sf11$unknownmodelsoa_perc=(sf11$numunknownmodelsoa*100)/sf11$schoolsize
  summary(sf11$school_unknown <- (sf11$unknownmodelsoa_perc>25))
  
  ## [] 05.2 EXTRA IN ORIGINAL STATA FILE = FIND SCHOOLS WITH TOO FEW PEOPLE 2011 BUT OK 2010: FEED BACK TO 03.2 ]
  
  ## STUDYPOP: METHODS TEXT
  summary(sf11$studypop <- (sf11$school_boarding==0 & sf11$school_unknown==0))
      # Method text on no. schools/pupils included/excluded
        sum(sf11$schoolflag )
        sum(sf11$schoolflag[sf11$school_boarding==1])
        sum(sf11$schoolflag[sf11$school_boarding==0 & sf11$school_unknown==1])
        sum(sf11$schoolflag[sf11$studypop==1 & sf11$secondary==0])
        sum(sf11$all[sf11$studypop==1 & sf11$secondary==0])
        sum(sf11$schoolflag[sf11$studypop==1 & sf11$secondary==1])
        sum(sf11$all[sf11$studypop==1 & sf11$secondary==1])
        
      # Method text on % pupils in study pop, in total and by school type
        xtabs(all~studypop, data=sf11) 
        (7442531/(89511+7442531))
        prop.table(xtabs(all~studypop+secondary, data=sf11), 2)
        ((100-7.1)*(7442531/(89511+7442531))) # 92% of all pupils, inc independent schools (7.1%), are covered in PCT			
  sf11 <- sf11[sf11$studypop==1,]
    
      # Method text on % missing data on lsoa code and on mode
        (sum(sf11$all[is.na(sf11$lsoa11cd)]) * 100 / sum(sf11$all)) 
        (sum(sf11$unknown ) * 100 / sum(sf11$all))

###############
## IMPUTING UNKNOWN DATA
###############
  
  
  ## RESHAPE TO INDIVIDUAL LEVEL
  sf11 <- sf11[,c("id", "lsoa11cd","lsoa11nm", "urn","schoolname","phase","secondary", "bicycle", "foot", "car", "other","unknown")]
  sf11 <- dplyr::rename(sf11, numpupils_1 = `bicycle`, numpupils_2 = `foot`, numpupils_3 = `car`, numpupils_4 = `other`, numpupils_5 = `unknown`)
  
  
  
  #sf11$idnum <- seq(dim(sf11)[1])
  sf11long<-reshape(sf11, varying=c("numpupils_1","numpupils_2","numpupils_3","numpupils_4","numpupils_5"), timevar = "mode", direction="long", idvar="id", sep="_")
  
