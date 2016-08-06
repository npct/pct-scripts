# Renaming/updating data for pct-shiny

library(dplyr)

# load original data for zones
ukmsoas_old <- readRDS("../pct-bigdata/ukmsoas-scenarios.Rds")
names(ukmsoas_old)
ukmsoas_new <- readr::read_csv("../pct-bigdata/pct_area.csv")

names(ukmsoas_new)
ukmsoas_new <- dplyr::rename(ukmsoas_new,
                       geo_code = home_msoa,
                       geo_label = home_msoa_name
                       )

ukmsoas = ukmsoas_old[ukmsoas_old$geo_code %in% ukmsoas_new$geo_code,]

# check they are the same - nope!
plot(ukmsoas$all, ukmsoas_new$all)

col_missing_in_new <- !names(ukmsoas_old) %in% names(ukmsoas_new)[names(ukmsoas_new) != "geo_code"]
ukmsoas_new <- left_join(ukmsoas@data[col_missing_in_new], ukmsoas_new, by= "geo_code")

plot(ukmsoas$all, ukmsoas_new$all) # now they fit!
ukmsoas@data <- ukmsoas_new

names(ukmsoas)
head(ukmsoas)

# plot to ensure it makes sense
library(tmap)
tm_shape(ukmsoas) +
  tm_fill(col = "bicycle", breaks = c(0, 30, 300, 3000))

saveRDS(ukmsoas, "../pct-bigdata/ukmsoas-scenarios.Rds")