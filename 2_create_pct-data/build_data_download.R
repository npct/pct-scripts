knitr::knit2html(quiet = T,
                 input = file.path("2_create_pct-data", "data_download.Rmd"),
                 output = "data_download.html",
                 envir = globalenv(), force_v1 = T
)
# Re read the model output file
model_output <-  readLines(file.path("data_download.html"))
# remove style section
model_output <- remove_style(model_output)
# Add a special class to all tables for the shiny application
model_output <- add_table_class(model_output)
# Re-write the model output file
write(model_output, file.path("data_download.html"))
message(paste0("Just built ", region))
