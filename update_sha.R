# Update the data sha
old = setwd("../pct-data/")
(newsha = system("git rev-parse --short HEAD", intern = T))
setwd("../pct-shiny/")
writeLines(newsha, "data_sha")
system("git commit -am 'Update data'")
system("git push origin master")
setwd(old)