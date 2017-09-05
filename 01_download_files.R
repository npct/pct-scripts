# SET UP
rm(list = ls())
source("00_setup_and_funs.R")

#########################
### CREATE FOLDER STRUCTURE 
#########################

if(!dir.exists(file.path(path_inputs))) { dir.create(file.path(path_inputs)) }
if(!dir.exists(file.path(path_inputs, "01_raw"))) { dir.create(file.path(path_inputs, "01_raw")) }
if(!dir.exists(file.path(path_inputs, "01_raw/01_geographies"))) { dir.create(file.path(path_inputs, "01_raw/01_geographies")) }
if(!dir.exists(file.path(path_inputs, "01_raw/02_travel_data"))) { dir.create(file.path(path_inputs, "01_raw/02_travel_data")) }
if(!dir.exists(file.path(path_inputs, "01_raw/02_travel_data/commute"))) { dir.create(file.path(path_inputs, "01_raw/02_travel_data/commute")) }
if(!dir.exists(file.path(path_inputs, "01_raw/02_travel_data/commute/msoa"))) { dir.create(file.path(path_inputs, "01_raw/02_travel_data/commute/msoa")) }
if(!dir.exists(file.path(path_inputs, "01_raw/02_travel_data/commute/lsoa"))) { dir.create(file.path(path_inputs, "01_raw/02_travel_data/commute/lsoa")) }
if(!dir.exists(file.path(path_inputs, "01_raw/02_travel_data/school"))) { dir.create(file.path(path_inputs, "01_raw/02_travel_data/school")) }
if(!dir.exists(file.path(path_inputs, "01_raw/02_travel_data/school/lsoa"))) { dir.create(file.path(path_inputs, "01_raw/02_travel_data/school/lsoa")) }
if(!dir.exists(file.path(path_inputs, "01_raw/03_health_data"))) { dir.create(file.path(path_inputs, "01_raw/03_health_data")) }
if(!dir.exists(file.path(path_inputs, "01_raw/03_health_data/commute"))) { dir.create(file.path(path_inputs, "01_raw/03_health_data/commute")) }

if(!dir.exists(file.path(path_inputs, "02_intermediate"))) { dir.create(file.path(path_inputs, "02_intermediate")) }
if(!dir.exists(file.path(path_inputs, "02_intermediate/01_geographies"))) { dir.create(file.path(path_inputs, "02_intermediate/01_geographies")) }
if(!dir.exists(file.path(path_inputs, "02_intermediate/02_travel_data"))) { dir.create(file.path(path_inputs, "02_intermediate/02_travel_data")) }
if(!dir.exists(file.path(path_inputs, "02_intermediate/x_temporary_files"))) { dir.create(file.path(path_inputs, "02_intermediate/x_temporary_files")) }
if(!dir.exists(file.path(path_temp_cs))) { dir.create(file.path(path_temp_cs)) }
if(!dir.exists(file.path(path_temp_raster))) { dir.create(file.path(path_temp_raster)) }
if(!dir.exists(file.path(path_temp_scenario))) { dir.create(file.path(path_temp_scenario)) }
if(!dir.exists(file.path(path_temp_unzip))) { dir.create(file.path(path_temp_unzip)) }

if(!dir.exists(file.path(path_outputs_national))) { dir.create(file.path(path_outputs_national)) }
if(!dir.exists(file.path(path_outputs_regional_R))) { dir.create(file.path(path_outputs_regional_R)) }
if(!dir.exists(file.path(path_outputs_regional_notR))) { dir.create(file.path(path_outputs_regional_notR)) }


#########################
### DOWNLOAD FILES FROM INTERNET
#########################

download_path <- file.path(path_inputs, "01_raw/01_geographies/geography_lookups")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file("https://borders.ukdataservice.ac.uk/ukborders/lut_download/prebuilt/luts/engwal/OA11_LSOA11_MSOA11_LAD11_EW_LU.zip",
              file.path(download_path, "OA11_LSOA11_MSOA11_LAD11_EW_LU.zip"))

download_path <- file.path(path_inputs, "01_raw/01_geographies/lad_boundaries")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file("http://geoportal.statistics.gov.uk/datasets/3943c2114d764294a7c0079c4020d558_4.zip",
              file.path(download_path, "Local_Authority_Districts_December_2014_Ultra_Generalised_Clipped_Boundaries_in_Great_Britain.zip"))

download_path <- file.path(path_inputs, "01_raw/01_geographies/lsoa_boundaries")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file("http://geoportal.statistics.gov.uk/datasets/da831f80764346889837c72508f046fa_3.zip",
              file.path(download_path, "Lower_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped__Boundaries_in_England_and_Wales.zip"))

download_path <- file.path(path_inputs, "01_raw/01_geographies/lsoa_centroids")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file("http://geoportal.statistics.gov.uk/datasets/b7c49538f0464f748dd7137247bbc41c_0.zip",
              file.path(download_path, "Lower_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.zip"))

download_path <- file.path(path_inputs, "01_raw/01_geographies/msoa_boundaries")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file("http://geoportal.statistics.gov.uk/datasets/826dc85fb600440889480f4d9dbb1a24_3.zip",
              file.path(download_path, "Middle_Layer_Super_Output_Areas_December_2011_Super_Generalised_Clipped_Boundaries_in_England_and_Wales.zip"))

download_path <- file.path(path_inputs, "01_raw/01_geographies/msoa_centroids")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file("http://geoportal.statistics.gov.uk/datasets/b0a6d8a3dc5d4718b3fd62c548d60f81_0.zip",
              file.path(download_path, "Middle_Layer_Super_Output_Areas_December_2011_Population_Weighted_Centroids.zip"))


#########################
### DOWNLOAD INPUT FILES CREATED BY PCT TEAM
#########################

# LSOA 2001 to 2001 lookup (Not created by PCT team.  Can download from github or download file manually from: http://www.ons.gov.uk/ons/external-links/other/2001-lower-layer-super-output-areas--lsoa--to-2011-lsoas-and-lads.html)
download.file("https://github.com/pctbike/pct-inputs/raw/master/01_raw/01_geographies/geography_lookups/LSOA_2001_to_2011.zip",
              file.path(download_path, "LSOA_2001_to_2011.zip"))

## PCT REGIONS (created by PCT team, download from github)
download_path <- file.path(path_inputs, "01_raw/01_geographies/pct_regions")
if(!dir.exists(file.path(download_path))) { dir.create(file.path(download_path)) }
download.file(url = "https://github.com/pctbike/pct-inputs/raw/master/01_raw/01_geographies/pct_regions/pct_regions_lad_lookup.csv",
                file.path(download_path, "pct_regions_lad_lookup.csv"))


#########################
### MANUALLY DOWNLOAD FILES
#########################

## TRAVEL MODE
#     1. MSOA-flow commute data: url = https://wicid.ukdataservice.ac.uk/cider/wicid/downloads.php ;
#        save dataset WU03EW to 'pct-inputs\01_raw\02_travel_data\commute\msoa\wu03ew_v2.zip'
#     2. LSOA-flow commute data: url = https://wicid.ukdataservice.ac.uk/cider/wicid/downloads.php [safe-guarded];
#        commissioned dataset = WM12EW[CT0489]_lsoa ; save to 'pct-inputs\01_raw\02_travel_data\commute\lsoa\WM12EW[CT0489]_lsoa.zip'
#     3. LSOA-flow SCHOOL data: private data supplied by NPD (request no. DR160129.02)

## MORTALITY LOOK-UPS (created by PCT team, download from github)
#     1. url = "https://github.com/pctbike/pct-inputs/raw/master/01_raw/03_health_data/commute/LA_WeightedMortality16-74_2014.xls" ;
#        download dataset = LA_WeightedMortality16-74_2014.xls; save to 'pct-inputs\01_raw\03_health_data\commute\LA_WeightedMortality16-74_2014.xls'
