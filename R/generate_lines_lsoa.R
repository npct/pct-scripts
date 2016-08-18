# generate lsoa level lines
flow_lsoa = readr::read_csv("xxx_lsoa.csv") # read in secure lsoa data
saveRDS(flow_lsoa, "../pct-privatedata/flow_lsoa.Rds")
write_csv(flow_lsoa[1:1000,], "D:/tmp/lsoa_1st_1000.csv")
write_csv(flow_lsoa[sample(x = nrow(flow_lsoa), size = 1000),], "D:/tmp/lsoa_random.csv")
