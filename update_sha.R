# Update the data sha
old = setwd("../pct-data/")
(newsha = system("git rev-parse --short HEAD", intern = T))
setwd("../pct-shiny/")
writeLines(newsha, "data_sha")
setwd(old)