# Reads in generated routes in several files and merges them into one big file

a = readRDS("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/oldway/lines_EW_0-5.Rds")
b = readRDS("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/oldway/lines_EW_5-10.Rds")
c = readRDS("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/oldway/lines_EW_10-20.Rds")
d = readRDS("D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/oldway/lines_EW_20-30.Rds")
e = readRDS("D:/Git/pct-bigdata/msoa_rerun/oldway/lines_missing_2.Rds")
#anna = read.csv(file = "D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/xx-PCTAreaLines_TEMP/161103_PCTarealines_csv/pct_lines.csv")

#names(a)
#names(b)
#names(c)
#names(d)
#names(e)



#library(raster)
a@data <- as.data.frame(a@data)
b@data <- as.data.frame(b@data)
c@data <- as.data.frame(c@data)
d@data <- as.data.frame(d@data)
e@data <- as.data.frame(e@data)
b <- spChFIDs(b, paste("b", row.names(b), sep="."))
c <- spChFIDs(c, paste("c", row.names(c), sep="."))
d <- spChFIDs(d, paste("d", row.names(d), sep="."))
e <- spChFIDs(e, paste("e", row.names(e), sep="."))
m <- rbind(a, b, c, d, e)


rbefore <- nrow(a) + nrow(b) + nrow(c) + nrow(d) + nrow(e)

rafter <- nrow(m)

saveRDS(m,file = "D:/Users/earmmor/OneDrive - University of Leeds/Cycling Big Data/oldway/l_nat_noScens.Rds")
names(m)
head(m@data)
head(m$id)
