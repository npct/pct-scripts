# profiling the script
source("set-up.R")
# devtools::install_github("rstudio/profvis")
library(profvis)
# knitr::purl("load.Rmd")

profvis({
  source("load.R")
}, 0.2)
