cat("\014") # Clear your console
rm(list = ls()) #clear your environment

# Import the Orion data to ensure we have the most updated Orion data
setwd("~/git/of_dollars_and_data")
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #

library(RGA)
library(scales)
library(RColorBrewer)
library(quantmod)
library(ggrepel)
library(slackr)
library(lubridate)
library(readxl)
library(ggjoy)
library(tidyverse)

folder_name <- "xxxx_spx_dow_hot_hand"
out_path <- paste0(exportdir, folder_name)
dir.create(file.path(paste0(out_path)), showWarnings = FALSE)

########################## Start Program Here ######################### #

# set.seed(12345)
# 
# df <- data.frame(pos=sample(0:1, 10000, replace = TRUE), ret = runif(10000, 0, 1))
# 
# df <- read_excel(paste0(importdir, "0097_spx_daily/spx_daily.xlsx")) %>%
#         rename(date = Period,
#                index = `S&P 500 Level`) %>%
#         mutate(ret = index/lag(index) - 1,
#                pos = ifelse(ret > 0 , 1, 0)) %>%
#         filter(!is.na(ret)) %>%
#         select(date, ret, pos)

df <- read_excel(paste0(importdir, "xxxx_dow_daily/dow_daily.xlsx")) %>%
      rename(date = Date,
             index = PX_LAST) %>%
      mutate(ret = index/lag(index) - 1,
             pos = ifelse(ret > 0 , 1, 0)) %>%
      filter(!is.na(ret)) %>%
      select(date, ret, pos)

for (i in 1:nrow(df)){
  pos <- df[i, "pos"]
  
  if(i == 1){
      df[i, "pos_streak"] <- pos
      df[i, "neg_streak"] <- (1 - pos)
  } else {
    prior_pos <- df[(i-1), "pos"]
    prior_pos_streak <- df[(i-1), "pos_streak"]
    prior_neg_streak <- df[(i-1), "neg_streak"]
    
    if(prior_pos == 1 & pos == 1){
      df[i, "pos_streak"] <- prior_pos_streak + 1
      df[i, "neg_streak"] <- 0
    } else if (prior_pos == 1 & pos == 0){
      df[i, "pos_streak"] <- 0
      df[i, "neg_streak"] <- 1
    } else if (prior_pos == 0 & pos == 0){
      df[i, "pos_streak"] <- 0
      df[i, "neg_streak"] <- prior_neg_streak + 1
    } else if (prior_pos == 0 & pos == 1){
      df[i, "pos_streak"] <- 1
      df[i, "neg_streak"] <- 0
    }
  }
}

df <- df %>%
        mutate(pos_next = lead(pos),
               next_ret = lead(ret)) %>%
        filter(!is.na(pos_next))

final_results <- data.frame(pos_neg = c(), streak_length = c(),
                            pct_next_day_same = c(), pct_next_day_change = c(),
                            ret_next_day = c(), sd_next_day = c(), 
                            t_pval = c(), n_days = c())

counter <- 1
for (i in 1:max(df$pos_streak, df$neg_streak)){
    summary <- df %>%
                filter(pos_streak >= i)
  
    final_results[counter, "pos_neg"]             <- "Positive"
    final_results[counter, "streak_length"]       <- i
    final_results[counter, "pct_next_day_same"]   <- mean(summary$pos_next)
    final_results[counter, "pct_next_day_change"] <- 1 - mean(summary$pos_next)
    final_results[counter, "ret_next_day"]        <- mean(summary$next_ret)
    final_results[counter, "sd_next_day"]         <- sd(summary$next_ret)
    
    final_results[counter, "n_days"]              <- nrow(summary)
    
  if (final_results[counter, "n_days"] >= 100){
    final_results[counter, "t_pval"]  <- t.test(df$pos, summary$pos_next)$p.value
  } else {
    final_results[counter, "t_pval"]  <- NA
  }
  counter <- counter + 1

  summary <- df %>%
    filter(neg_streak >= i)
  
  final_results[counter, "pos_neg"]             <- "Negative"
  final_results[counter, "streak_length"]       <- i
  final_results[counter, "pct_next_day_same"]   <- 1-mean(summary$pos_next)
  final_results[counter, "pct_next_day_change"] <- mean(summary$pos_next)
  final_results[counter, "ret_next_day"]        <- mean(summary$next_ret)
  final_results[counter, "sd_next_day"]         <- sd(summary$next_ret)
  final_results[counter, "n_days"]              <- nrow(summary)
  
  if (final_results[counter, "n_days"] >= 100){
    final_results[counter, "t_pval"]  <- t.test(df$pos, summary$pos_next)$p.value
  } else {
    final_results[counter, "t_pval"]  <- NA
  }
  
  counter <- counter + 1
}

final_results <- final_results %>%
                  mutate(sig_diff = ifelse(t_pval < 0.05, 1, 0))

# ############################  End  ################################## #
