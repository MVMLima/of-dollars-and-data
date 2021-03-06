cat("\014") # Clear your console
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
setwd("~/git/of_dollars_and_data")
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #

library(dplyr)

########################## Start Program Here ######################### #

in_path <- paste0(importdir, "0003_scf_data/SCF")

# Create a year list to loop through
year_list <- seq(1989, 2016, 3)

for (x in year_list){
  print(paste0("Now processing: ", x))
  # Load SCF data into memory
  t <- readRDS(paste0(in_path, "/scf ", x, ".rds"))
  print("Data read in")
  
  # Subset to only the variables we care about in the data
  # Definitions are from here:
  #
  # https://www.federalreserve.gov/econresdata/scf/files/bulletin.macro.txt
  # 
  # networth = total networth (asset - debt)
  # asset = value of all assets
  # debt = value of all debt // DEBT=MRTHEL+RESDBT+OTHLOC+CCBAL+INSTALL+ODEBT
  # liq = all types of transactions accounts (liquid assets)
  # homeeq = value of home equity
  # reteq = retirement equity
  # hdebt = dummy, 1 if has debt, 0 if no debt
  # fin = total finanical assets
  # mrthel = mortgage debt
  # resdbt = other residential debt
  # ccbal = credit card balance
  # agecl = age class, 1:<35, 2:35-44, 3:45-54, 4:55-64, 5:65-74, 6:>=75
  # hhsex = gender, 1 = male , 2 = female
  # race = race, 1 = white non-Hispanic, 2 = nonwhite or Hispanic
  # edcl = education class, 1 = no high school diploma/GED, 2 = high school diploma or GED,
  #   3 = some college, 4 = college degree
  # married = marital status, 1 = married/living with partner, 2 = neither married nor living with partner
  # kids = number of kids
  
  vars_to_keep <- c('y1', 'yy1', 'networth', 'debt', 'asset', 'liq', 'reteq',
                    'homeeq', 'hdebt', 'fin', 'mrthel', 'resdbt', 'ccbal', 
                    'income', 'wageinc', 'intdivinc', 'bussefarminc', 'equitinc', 'ssretinc',
                    'agecl', 'hhsex', 'race', 'edcl', 'married', 'kids', 'wgt')
  
  # Write a function to subset our data
  subset_data <- function(name){
    data <- get(name)
    data <- data[ , vars_to_keep]
    data["year"] <- x
    assign(name, data, envir = .GlobalEnv)
  }
  
  # Loop through each of the imp datasets to subset them to relevant variables
  for (i in 1:5){
    assign(paste0("imp", i), as.data.frame(t[i]), envir = .GlobalEnv)
    string <- paste0("imp", i)
    subset_data(string)
  }
  
  # Stack the datasets
  if (x == year_list[1]){
    scf_stack <- rbind(imp1, imp2, imp3, imp4, imp5)
  } else{
    scf_stack <- rbind(scf_stack, imp1, imp2, imp3, imp4, imp5)
  }
}

# Clean some additional variables
scf_stack <- mutate(scf_stack, married = married %% 2,
                    white = race %% 2,
                    male = hhsex %% 2) %>%
              select(-hhsex, - race)

# Define strings for each age class based on the definitions above
scf_stack$agecl <- ifelse(scf_stack[,"agecl"] == 1, "<35", 
                          ifelse(scf_stack[,"agecl"] == 2, "35-44",
                                 ifelse(scf_stack[,"agecl"] == 3, "45-54",   
                                        ifelse(scf_stack[,"agecl"] == 4, "55-64",
                                               ifelse(scf_stack[,"agecl"] == 5, "65-74",
                                                      ifelse(scf_stack[,"agecl"] == 6, "75+", "99"))))))

# Define strings for education class
scf_stack$edcl <- ifelse(scf_stack[,"edcl"]  == 1, "No High School", 
                         ifelse(scf_stack[,"edcl"] == 2, "High School",
                                ifelse(scf_stack[,"edcl"] == 3, "Some College",   
                                       ifelse(scf_stack[,"edcl"] == 4, "College Degree", "99"))))

# Make edcl into a factor
scf_stack$edcl <- factor(scf_stack$edcl,levels = c("No High School", 
                                                   "High School", 
                                                   "Some College", 
                                                   "College Degree"))

# Make agecl into a factor
scf_stack$agecl <- factor(scf_stack$agecl,levels = c("<35", "35-44", "45-54", "55-64",
                                                   "65-74", "75+"))

scf_stack <- scf_stack %>%
              rename(hh_id = yy1,
                     imp_id = y1)

# Save down data to permanent file
saveRDS(scf_stack, paste0(localdir, "0003_scf_stack.Rds"))

# ############################  End  ################################## #