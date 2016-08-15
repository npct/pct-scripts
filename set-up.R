# Project settings - libraries you'll need to load
# NB: devtools allows installation of the latest packages
if(!require(devtools)) install.packages("devtools")
if(!require(rmapshaper)) install_github("ateucher/rmapshaper")

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
 # Load publicly available test data

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
add_table_style <- function(x){
  
  x <- gsub("<table>", "<table class='model_output_table'>", x)
  x
}

save_formats <- function(to_save, name = F, csv = F){
  if (name == F){
    name <- substitute(to_save)
  }
  saveRDS(to_save, file.path(pct_data, region, paste0(name, ".Rds")))
  
  # Simplify data checked with before and after using:
  # plot(l$gendereq_sideath_webtag)
  to_save@data <- round_df(to_save@data, 5)
  
  # Simplify geom
  geojson_write( ms_simplify(to_save, keep = 0.1), file = file.path(pct_data, region, name))
  if(csv) write.csv(to_save@data, file.path(pct_data, region, paste0(name, ".csv")))
}

round_df <- function(df, digits) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))
  
  df[,nums] <- round(df[,nums], digits = digits)
  
  (df)
}
# ms_simplify gives Error: RangeError: Maximum call stack size exceeded
# for large objects.  Turning the repair off fixed it...
remove_cols <- function(df, col_regex){
  df[,!grepl(col_regex, names(df))]
}
