#Main Input Data Checker
# Reachis in the main datasets and check for errors that may cause trouble
l1 <- readRDS("../pct-bigdata/lines_oneway_shapes_updated.Rds")
ukmsoas <- readRDS("../pct-bigdata/ukmsoas-scenarios.Rds")
rf_nat <- readRDS("../pct-bigdata/rf_nat.Rds")
rq_nat <- readRDS("../pct-bigdata/rq_nat.Rds")

#Libs


#Funcs
'%!in%' <- function(x,y)!('%in%'(x,y))

E1 <- rf_nat[which(rf_nat$id %!in% rq_nat$id),]
E2 <- rq_nat[which(rq_nat$id %!in% rf_nat$id),]
E3 <- l1[which(l1$id %!in% rq_nat$id),]
E4 <- l1[which(l1$id %!in% rf_nat$id),]

nrow(E4)

allid <-c(rf_nat$id,rq_nat$id,l1$id)
allid <-  allid[!duplicated(allid)]
compare <- data.frame(id=allid,l1=0,rf=0,rq=0,tot=0)
for(i in 1:233478){
  if(compare$id[i] %in% l1$id){compare$l1[i] = 1}
  if(compare$id[i] %in% rf_nat$id){compare$rf[i] = 1}
  if(compare$id[i] %in% rq_nat$id){compare$rq[i] = 1}
  compare$tot[i] <- compare$l1[i] + compare$rf[i] + compare$rq[i]
}
compare_sub <- compare[which(compare$tot < 3),]
write.csv(compare_sub,"../pct-bigdata/MismachedLines.csv")
