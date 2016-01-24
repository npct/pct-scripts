###
### set-up.R
###
### Update installed packages and install pct-load dependencies.
### 

# CRAN packages to install.
pkgs <- c(
  "ggmap",
  "e1071", # tmap dependency
  "tmap",
  "foreign", # loads external data
  "dplyr",   # for manipulating data rapidly
  "rgeos",   # GIS functionality
  "raster",  # GIS functions
  "maptools", # GIS functions
  "stplanr", # Sustainable transport planning with R
  "tidyr", # tidies up your data!
  "readr", # reads your data fast
  "knitr" # for knitting it all together
)

# Github packages to install.
ghpkgs <- c(
  "ateucher/rmapshaper"
)

# Package names for GitHub
ghpkgns <- c(
  "rmapshaper"
)

# Ensure packages are up-to-date.
cat("It is strongly recommended that you update your installed packages.\n");
update.packages()

##
## Problematic packages
##
## Package in this section may not install due to missing libraries or toolchains, since this
## is usually catastrophic, we install them separately and issue instructions for fixing the
## problem here.
##

# Devtools may fail to install due to missing libraries or toolchains; this is catastrophic,
# so check for that here and abort setup and execution if this is the case.
if(!require(devtools)) {
  install.packages("devtools", clean = TRUE)
  if (!require(devtools)) {
    cat("---- COULD NOT INSTALL PCT DEPENDENCY: devtools ----\n")
    cat("This is usually caused by missing libgdal and libproj headers.  Try installing:\n")
    cat("\t* deb: libcurl4-openssl-dev (Debian, Ubuntu, etc)\n")
    cat("\t* rpm: libcurl-devel (Fedora, CentOS, RHEL)\n")
    cat("---- ABORTING ----\n")
    stop()
  }
}

# Install rgdal 
if(!require(rgdal)) {
  install.packages("rgdal", clean = TRUE)
  if (!require(rgdal)) {
    cat("---- COULD NOT INSTALL PCT DEPENDENCY: rgdal ----\n")
    cat("This is usually caused by missing libcurl headers.  Try installing:\n")
    cat("\t* rpm: gdal-devel proj-devel proj-nad proj-epsg (Fedora, CentOS, RHEL)\n")
    cat("---- ABORTING ----\n")
    stop()
  }
}

# Install geojsonio 
if(!require(geojsonio)) {
  install.packages("geojsonio", clean = TRUE)
  if (!require(geojsonio)) {
    cat("---- COULD NOT INSTALL PCT DEPENDENCY: geojsonio ----\n")
    cat("This is usually caused by missing GEOS headers.  Try installing:\n")
    cat("\t* rpm: geos-devel (Fedora, CentOS, RHEL)\n")
    cat("---- ABORTING ----\n")
    stop()
  }
}

# Install jpeg
if(!require(jpeg)) {
  install.packages("json", clean = TRUE)
  if(!require(jpeg)) {
    cat("---- COULD NOT INSTALL PCT DEPENDENCY: jpeg ----\n")
    cat("This is usually caused by missing libjpeg headers.  Try installing:\n")
    cat("\t* rpm: libjpeg-turbo-devel (Fedora, CentOS, RHEL)\n")
    cat("---- ABORTING ----\n")
    stop()
  }
}

# Install XML
if(!require(XML)) {
  install.packages("XML", clean = TRUE)
  if(!require(XML)) {
    cat("---- COULD NOT INSTALL PCT DEPENDENCY: XML ----\n")
    cat("This is usually caused by missing libjpeg headers.  Try installing:\n")
    cat("\t* rpm: libxml2-devel (Fedora, CentOS, RHEL)\n")
    cat("---- ABORTING ----\n")
    stop()
  }
}

##
## Bulk install
## 

# Install required packages.
reqs <- as.numeric(lapply(pkgs, require, character.only = TRUE))
if(sum(!reqs) > 0) install.packages(pkgs[!reqs], clean = T)

# Verify that packages were installed, and if not, then fail early.
ins <- as.numeric(lapply(pkgs, require, character.only = TRUE))
if(sum(!ins) > 0) {
  cat("---- COULD NOT INSTALL PCT DEPENDENCIES ----\n")
  cat("Check the console output to diagnose.\n")
  print(pkgs[!reqs])
  cat("Cowardly refusing to continue.\n")
  cat("---- ABORTING ----\n")
  stop()
}

# Install dependencies from GitHub.
ghreqs <- as.numeric(lapply(ghpkgns, require, character.only = TRUE))
if(sum(!ghreqs) > 0) install_github(ghpkgs[!ghreqs], clean = T)

# Verify that GitHub dependencies were installed, and if not, then fail early.
ghins <- as.numeric(lapply(ghpkgns, require, character.only = TRUE))
if(sum(!ghins) > 0) {
  cat("---- COULD NOT INSTALL GITHUB PCT DEPENDENCIES ----\n")
  cat("Check the console output to diagnose.\n")
  print(ghpkgs[!ghreqs])
  cat("Cowardly refusing to continue.\n")
  cat("---- ABORTING ----\n")
  stop()
}

##
## Environment
##
## We should probably check for missing API keys at this point instead of 
## during the build -- will add that at some later point.
##

# Not sure why this is here, but I'm leaving it.
cckey <- Sys.getenv('CS_API_KEY')
