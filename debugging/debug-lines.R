# # for testing: reduce to top n lines
top_n <- 100 # e.g. top 5, 10, 100
sel_top <- order(l$All, decreasing = T)[1:top_n]
l_old <- l
l <- l[sel_top,]
rf <- rf[sel_top,]
rq <- rq[sel_top,]

# # small manual test to check the data is ok
i = 2
plot(rf[i,])
plot(l[i,], add = T)
plot(rq[i,], add = T)
row.names(l[i,])
row.names(rf[i,])