# Aim: check the data produced by pct-load

# check national lines data
# after downloading latest data from github, e.g. with download-data.R
fname = "../pct-bigdata/rf.Rds"
fname = "../pct-bigdata/rq.Rds"
fname = "../pct-bigdata/l_all_cc.Rds"
r = readRDS(fname)

# Are the lengths crazy long?
summary(r$length > 50)
plot(r[r$length > 50,])

r = readRDS(fname)
summary(r$dist_quiet)



