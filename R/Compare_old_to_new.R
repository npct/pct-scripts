#This code compares two datasets and tells you if they have differences


#Inputs
new = readRDS("../pct-bigdata/rq_nat_id.Rds")
old = readRDS("../pct-bigdata/rq_old.Rds")
l_nat = readRDS("../pct-bigdata/l_nat.Rds")
l_nat_noScens = readRDS("../pct-bigdata/l_nat_noScens.Rds")

#libs
library(leaflet)

names(old)
names(new)
names(l_nat)
names(l_nat_noScens)

new@data = new@data[,which(names(new@data) %in% names(old@data))] #Remove columns in new that are not it old
new@data$length = new@data$length/1000

new_sub = new[which(new$id %in% old$id),]
new_sub = new_sub[which(!is.na(new_sub$length)),]



length(unique(old$id)) == nrow(old)
n_occur <- data.frame(table(new_sub$id))
n_occur <- n_occur[n_occur$Freq != 1,]
duplicates = new_sub[which(new_sub$id %in% n_occur$Var1),]

n_occur_old <- data.frame(table(old$id))
n_occur_DUP <- data.frame(table(NoDUP$id))
n_occur_old <- n_occur[n_occur_old$Freq != 1,]
n_occur_DUP <- n_occur_DUP[n_occur_DUP$Freq != 1,]
duplicates_old = old[which(old$id %in% n_occur_old $Var1),]
duplicates_DUP = NoDUP[which(NoDUP$id %in% n_occur_DUP $Var1),]

missing = old[which(!(old$id %in% new_sub$id)),]
NoDUP = new_sub[!duplicated(new_sub@data),]

'%!in%' <- function(x,y)!('%in%'(x,y))
NoDUP2 = NoDUP[which(rownames(NoDUP@data) %!in% rownames(duplicates_DUP@data)),]

NoDUP2 = subset(NoDUP, rownames(NoDUP) != c("e.12","e.14","e.15","e.16","e.17","e.17","e.18", "e.21", "e.24", "e.29"))
NoDUP2 = NoDUP[which(rownames(NoDUP) != c("e.12","e.14","e.15","e.16","e.17","e.17","e.18", "e.21", "e.24", "e.29") ),]

duplicates_DUP = duplicates_DUP[10:18,]

remove = rownames(duplicates)

nrow(error)

leaflet() %>% 
  addTiles() %>% 
  addPolylines(data = duplicates_DUP) #%>% 
  addPolylines(data = duplicates_old)


head(old@data$length,100)


head(old@data)
head(new@data,100)
head(l_nat@data)
head(l_nat_noScens@data)

struct(old)
struct(new)


summary(old)
summary(new)

nrow(old@data)
nrow(new@data)


plot(head(l_nat_noScens))
plot(head(new))

saveRDS(new,"../pct-bigdata/rq_nat_all.Rds")
saveRDS(fin,"../pct-bigdata/rq_nat.Rds")
