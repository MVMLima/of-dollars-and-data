cat("\014") # Clear your console
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
setwd("~/git/of_dollars_and_data")
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #

library(dplyr)

########################## Start Program Here ######################### #

# Read in productivity data from tab-delimited text file on the web
# Use function to make this dynamic
read_in_bls <- function(string){
  name      <- deparse(substitute(string))
  temp_name <- read.csv(paste0("https://download.bls.gov/pub/time.series/oe/oe.", name), 
                             header = TRUE, 
                             sep = "\t")
  
  saveRDS(temp_name, paste0(importdir, "0005_bls-occupational_employment/bls_oe_", name, ".Rds"))
}

read_in_bls(areatype)
read_in_bls(datatype)
read_in_bls(industry)
read_in_bls(occupation)
read_in_bls(data.1.AllData)

# Process area separately because the column names that match areatype
area <- read.csv(paste0("https://download.bls.gov/pub/time.series/oe/oe.area"), 
                      header = TRUE, 
                      sep = "\t",
                      row.names = 2)

# Drop those columns that we do not need
area <- area[ , !(names(area) %in% c("area_code","area_name"))]

area <- rename(area, area_code = areatype_code, state_code = row.names)

saveRDS(area, paste0(importdir, "0005_bls_occupational_employment/bls_oe_area.Rds"))



# ############################  End  ################################## #