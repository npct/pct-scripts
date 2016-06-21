# Get external data for pct - not downloaded from GH
fname = "../pct-bigdata/rf.Rds"
file.size(fname) / 1000000
file.mtime(fname)
if(!file.exists(fname))
  curl::curl_download("https://github.com/npct/pct-bigdata/releases/download/0.2/rf.Rds",
              fname, mode = "wb")
fname = "../pct-bigdata/rq.Rds"
if(!file.exists(fname))
  curl::curl_download("https://github.com/npct/pct-bigdata/releases/download/0.2/rq.Rds", 
              fname, mode = "wb")
fname = "../pct-bigdata/l_all_cc.Rds"
if(!file.exists(fname))
  curl::curl_download("https://github.com/npct/pct-bigdata/releases/download/0.1/l_all_cc.Rds",
              fname, mode = "wb")

fname = "../pct-bigdata/pct_lines.csv"
if(!file.exists(fname))
  unzip("../pct-bigdata/pct_lines.zip", exdir = "../pct-bigdata/")

