# Get external data for pct - not downloaded via git clone
# download the data from: https://github.com/npct/pct-bigdata/releases
# maybe faster to do this from the browser - the below commands are slow!
fname = "../pct-bigdata/rf_nat.Rds"
file.size(fname) / 1000000
file.mtime(fname)
if(!file.exists(fname))
  curl::curl_download("https://github.com/npct/pct-bigdata/releases/download/1.1/rf_nat.Rds", 
              fname, mode = "wb")
fname = "../pct-bigdata/rq_nat.Rds"
if(!file.exists(fname))
  curl::curl_download("https://github.com/npct/pct-bigdata/releases/download/1.1/rq_nat.Rds", 
              fname, mode = "wb")

rf_nat = readRDS("../pct-bigdata/rf_nat.Rds")

# convert to .csv quick
download.file("https://github.com/npct/pct-bigdata/releases/download/1.1/rf_nat.Rds",
              "rf_nat.Rds", mode = "wb")
rf_nat = readRDS("rf_nat.Rds")
write.csv(rf_nat@data, "rf_nat.csv")

