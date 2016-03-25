# profiling the script
source("set-up.R")
# devtools::install_github("rstudio/profvis")
library(profvis)
knitr::purl("load.Rmd")

profvis(expr = {source("load.R")}, interval = 0.2)
