#SET UP
rm(list = ls())
source("00_setup_and_funs.R")
memory.limit(size=1000000)

# SET INPUT PARAMETERS
purpose <- "commute"
purpose_private <- paste0(purpose, "_private")
geography <- "lsoa"  
init_region("pct_regions", geography, purpose) # Define region type and projection, import local authorities
init_outputs_national(purpose, geography) # Load national data
init_Rsmall(purpose) # Load R small codebooks


#########################
### READ IN REGIONS AND RUN BUILD MASTER FOR EACH
#########################

# DEFINE WHICH REGIONS TO BUILD [modify in input csv file]
regions_tobuild <- as.character(build_params$region_name[build_params$to_rebuild==1])

for(k in 1:length(regions_tobuild)){

  # SUBSET TO THE SELECTED REGION
  region <- regions_tobuild[k]
  region_build_param <- build_params[build_params$region_name == region,]
  region_lad_lookup <- pct_regions_lad_lookup[pct_regions_lad_lookup$region_name==region,]

  # BUILD THE REGION
  message(paste0("Building for ", region, " (region ", k, ") at ",Sys.time()))
  #region_build_param$to_rebuild_rnet <- 0 # uncomment to forcibly skip rnet
  if (purpose=="commute") {
    source("07b.1_commute_build_region.R") # comment out to skip build entirely
    rsmall_maxdist <- 10
    source("07b.2_commute_Rsmall.R") 
  } else if (purpose=="school") {
    source("07c.1_school_build_region.R") # comment out to skip build entirely
    source("07c.2_school_Rsmall.R") 
  }
  
  # WRITE REGION STATS FILE
      # Create region stats directory if not there
      if(!dir.exists(file.path(path_shiny, "regions_www/tabs/region_stats", purpose))) { dir.create(file.path(path_shiny, "regions_www/tabs/region_stats", purpose)) }
      if(!dir.exists(file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography))) { dir.create(file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography)) }
      if(!dir.exists(file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography, region))) { dir.create(file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography, region)) }
    
      # Knit file
      knitr::knit2html(quiet = T,
                      input = file.path(purpose, geography, "region_stats.Rmd"),
                      output = file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography, region, "region_stats.html"),
                      envir = globalenv(), force_v1 = T
                      )

      # Re read region stats file and tidy
      region_stats <- readLines(file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography, region, "region_stats.html"))
      region_stats <- remove_style(region_stats)  # remove style section
      region_stats <- gsub("<table>", "<table class='region_stats_table'>", region_stats)
      
      # Change 'Wales region' to 'Wales'
      if (region == "wales") {
        region_stats <- gsub("The Wales region", "Wales", region_stats)
        region_stats <- gsub("the Wales region", "Wales", region_stats)
      }

      write(region_stats, file.path(path_shiny, "regions_www/tabs/region_stats", purpose, geography, region, "region_stats.html"))

  message(paste0("Finished ", region," at ",Sys.time()))
}

# TEST RNETS VISUALLY, ONE BY ONE
# for(k in 1) {
#   region <- regions_tobuild[k]
#   rnet <- readRDS(file.path(path_outputs_regional_R, purpose, geography, region, "rnet.Rds"))
#   plot(rnet)  
# }

# DELETE THE TEMP FILES CREATED BY MARKDOWN DOC
unlink("figure", recursive=TRUE)
file.remove("region_stats.md")


