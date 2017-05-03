# Project settings - libraries you'll need to load
# NB: devtools allows installation of the latest packages
if(!require(devtools)) install.packages("devtools")
if(!require(rmapshaper)) install.packages("rmapshaper")
# capitalize_region() below requires capitalizeStrings() from the dev branch of BBmisc
if(!require(BBmisc)) install_github("berndbischl/BBmisc")

pkgs <- c(
  "ggmap",
  "e1071", # tmap dependency
  "tmap",
  "foreign", # loads external data
  "rgdal",   # for loading and saving geo* data
  "dplyr",   # for manipulating data rapidly
  "rgeos",   # GIS functionality
  "raster",  # GIS functions
  "maptools", # GIS functions
  "stplanr", # Sustainable transport planning with R
  "tidyr", # tidies up your data!
  "readr", # reads your data fast
  "knitr", # for knitting it all together
  "geojsonio",
  "rmapshaper" # To simplify rnet
  )
# Which packages do we require?
# lapply(pkgs, library, character.only = T)
reqs <- as.numeric(lapply(pkgs, require, character.only = TRUE))
# Install packages we require
if(sum(!reqs) > 0) install.packages(pkgs[!reqs])

# Option 1: clone the repository directly - if you have git installed
# system2("git", args=c("clone", "git@github.com:Robinlovelace/pct-data.git", "--depth=1"))

# Option 2: download and unzip the pct-data repository
# download.file("https://github.com/Robinlovelace/pct-data/archive/master.zip", destfile = "pct-data.zip", method = "wget")
# unzip("pct-data.zip", exdir = "pct-data")
# list.files(pattern = "pct") # check the data's been downloaded

# Option 3: download data manually from https://github.com/Robinlovelace/pct-data/archive/master.zip

cckey <- Sys.getenv('CS_API_KEY')

# function to remove style from html page
remove_style = function(x){
  style_starts = grep("<style", x)
  style_ends = grep("</style", x)
  # Remove lines ONLY when the 'style' tag exists
  if ((length(style_starts) != 0 && length(style_ends) != 0))
    x[-(style_starts:style_ends)]
  else
    x
}

# function to add model_output_table class to all tables
add_table_class <- function(x){
  x <- gsub("<table>", "<table class='model_output_table'>", x)
  x
}

save_formats <- function(to_save, purpose, geography, region, name = F){
  if (name == F){
    name <- substitute(to_save)
  }
  # purpose, geography, region, 
  saveRDS(to_save, file.path(pct_data, purpose, geography, region, paste0(name, ".Rds")))
}

# ms_simplify gives Error: RangeError: Maximum call stack size exceeded
# for large objects.  Turning the repair off fixed it...
remove_cols <- function(df, col_regex){
  df[,!grepl(col_regex, names(df))]
}

# A function which capitalizes all words in a region (except 'and' and 'of')
capitalize_region <- function (region_name){
  require(BBmisc)
  region_name <- gsub(pattern = "-", replacement = " ", x = region_name)
  region_name <- capitalizeStrings(region_name, all.words = T)
  region_name <- gsub(pattern = "And", replacement = "and", x = region_name)
  region_name <- gsub(pattern = "Of", replacement = "of", x = region_name)

  region_name
}

set_paths <- function(){
  # For PCT regions:
  assign("pct_data", file.path("..", "pct-data"), envir = .GlobalEnv)
  assign("pct_bigdata", file.path("..", "pct-bigdata"), envir = .GlobalEnv)
  assign("pct_shiny_regions", file.path("..", "pct-shiny", "regions_www"), envir = .GlobalEnv)
  
}

set_geography_and_purpose <- function(geography, purpose){
  assign("geography", geography, envir = .GlobalEnv)
  assign("purpose", purpose, envir = .GlobalEnv)
  
  cat(" Geogrpahy set to ", geography, " and purpose to ", purpose, "\n")
}


data_check <- function(geography, purpose){
  if (geography == "msoa" && purpose == "commute"){
    
    if(!file.exists(file.path(pct_bigdata, "4_output_data", purpose, geography, "l_nat.Rds"))) {
      stop("Error: download l_nat data from: https://github.com/npct/pct-bigdata/releases")
    }
    # Read msoa's rf_nat for commuting data
    if(!file.exists(file.path(pct_bigdata, "4_output_data", purpose, geography, "rf_nat.Rds"))) {
      stop("Error: download rf_nat data from: https://github.com/npct/pct-bigdata/releases")
    }
    
    if(!file.exists(file.path(pct_bigdata, "4_output_data", purpose, geography, "rq_nat.Rds"))) {
      stop("Error: download rq_nat data from: https://github.com/npct/pct-bigdata/releases")
    }
  }
}

init_vars <- function(region_type, purpose, geography){
  if (region_type == "pct-regions"){
    assign("regions", geojson_read(file.path(pct_shiny_regions, "regions.geojson"), what = "sp"), envir = .GlobalEnv)
    assign("build_params", read_csv(file.path("2_create_pct-data", purpose, geography, "build_params_region.csv")), envir = .GlobalEnv)
  }
  
  ## If region_type is other than "pct-regions" (like CUAS), adapt the commented code below
  # else {
  #   regions <- readOGR(dsn = file.path(pct_bigdata, "2_input_data", "cuas-mf.geojson"), layer = "OGRGeoJSON")
  #   regions$Region <- regions$CTYUA12NM
  # }
  
  # ASSIGN LAs
  assign("las", readOGR(dsn = file.path(pct_bigdata, "2_input_data", "spatial_data", "las-pcycle.geojson"), layer = "OGRGeoJSON"), envir = .GlobalEnv)
  assign("las_cents", SpatialPoints(coordinates(las)), envir = .GlobalEnv)
  
  

}

init_national_variables <- function(purpose, geography){
  
  assign("l_nat", readRDS(file.path(pct_bigdata, "4_output_data", purpose, geography, "l_nat.Rds")), envir = .GlobalEnv)
  
  assign("rf_nat", readRDS(file.path(pct_bigdata, "4_output_data", purpose, geography, "rf_nat.Rds")), envir = .GlobalEnv)
  
  assign("rq_nat", readRDS(file.path(pct_bigdata, "4_output_data", purpose, geography, "rq_nat.Rds")), envir = .GlobalEnv)
  
  assign("z_nat", readRDS(file.path(pct_bigdata, "4_output_data", purpose, geography,  "z_nat.Rds")), envir = .GlobalEnv)
  
  assign("c_nat", readOGR(file.path(pct_bigdata, "4_output_data",  purpose, geography,  "c_nat.geojson"), "OGRGeoJSON"), envir = .GlobalEnv)
  
}


