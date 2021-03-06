cat("\014") # Clear your console
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
setwd("~/git/of_dollars_and_data")
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #

library(scales)
library(readxl)
library(lubridate)
library(ggrepel)
library(survey)
library(lemon)
library(mitools)
library(Hmisc)
library(tidyverse)

folder_name <- "0165_ycharts_spx_2day"
out_path <- paste0(exportdir, folder_name)
dir.create(file.path(paste0(out_path)), showWarnings = FALSE)

########################## Start Program Here ######################### #

n_days_back <- 2

raw <- read.csv(paste0(importdir, "/0165_ycharts_spx/SPX_data.csv"),
                col.names = c("date","index_sp500")) %>%
  mutate(date = as.Date(date)) %>%
  arrange(date) %>%
  mutate(ret_lag = index_sp500/lag(index_sp500, n_days_back) - 1)

first_year <- year(min(raw$date))
last_year <- year(max(raw$date))

run_fwd_rets <- function(n_days_fwd){

  df <- raw %>%
    mutate(lead_date = lead(date, n_days_fwd))

  less_than_6pct_dates <- df %>%
                          filter(ret_lag < -0.06) %>%
                          select(date, lead_date)
  
  if(n_days_fwd == 5){
    assign("less_than_6pct", less_than_6pct_dates, envir = .GlobalEnv)
  }
  
  for(d in 1:nrow(less_than_6pct_dates)){
    
    my_date <- less_than_6pct_dates[d, "date"]
    future_date <- less_than_6pct_dates[d, "lead_date"]
    
    tmp <- df %>%
            filter(date > my_date, date <= future_date) %>%
            mutate(start_date = as.character(my_date)) %>%
            select(date, index_sp500, start_date)
    
    first_value <- tmp[1, "index_sp500"]
    
    tmp <- tmp %>%
            mutate(index_sp500 = index_sp500/first_value,
                   day = row_number())
    
    if(my_date == min(less_than_6pct_dates$date)){
      to_plot <- tmp
    } else{
      to_plot <- bind_rows(to_plot, tmp)
    }
  }
  
  avg <- to_plot %>%
          group_by(day) %>%
          summarize(index_sp500 = mean(index_sp500)) %>%
          ungroup() %>%
          mutate(start_date = "2100-01-01")
  
  final_avg <- avg[nrow(avg), "index_sp500"] - 1
  
  if(final_avg > 0){
    up_down <- "up"
  } else{
    up_down <-"down"
  }
  
  to_plot <- to_plot %>%
              bind_rows(avg)
  
  n_days_fwd_string <- str_pad(n_days_fwd, width = 3, side="left", pad = "0")
  
  n_days <- length(unique(to_plot$start_date))
  
  text_labels <- avg %>%
                  filter(day == n_days_fwd) %>%
                  mutate(label = "Average")
  
  last_day <- to_plot %>%
                filter(day == n_days_fwd)
  
  print(paste0("N-days = ", n_days_fwd))
  print(max(last_day$index_sp500) - 1)
  print(min(last_day$index_sp500) - 1)
  
  file_path <- paste0(out_path, "/fwd_ret_", n_days_fwd_string, "_sessions.jpeg")
  source_string <- paste0("Source:  YCharts, ", first_year, "-", last_year, " (OfDollarsAndData.com)")
  note_string <- str_wrap(paste0("Note:  There were ", n_days-1, " trading days where the S&P 500 dropped by 6% or more over the prior 2 sessions.  ",
                        "Over the next ", n_days_fwd, 
                        " sessions, the market was ", up_down, " by ", 
                        round(100*final_avg, 1),
                        "% on average."),
                        width = 85)
  
  plot <- ggplot(to_plot, aes(x=day, y=index_sp500, col = as.factor(start_date))) + 
    geom_line() +
    geom_hline(yintercept = 1, linetype = "dashed") +
    geom_text_repel(data=text_labels, aes(x=day, y=index_sp500, label=label),
                    col = "red",
                    nudge_y = 0.02,
                    segment.colour = "transparent") +
    scale_color_manual(guide = FALSE, values = c(rep("gray", n_days-1), "red")) +
    scale_y_continuous(label = dollar) +
    of_dollars_and_data_theme +
    ggtitle(paste0("S&P 500 Over Next ", n_days_fwd, " Sessions\nFollowing 6%+ Drop")) +
    labs(x = "Session" , y = "Growth of $1",
         caption = paste0("\n", source_string, "\n", note_string))  
  
  # Save the plot
  ggsave(file_path, plot, width = 15, height = 12, units = "cm")
}

n_fwd_days <- c(5, 10, 20, 60, 120, 250, 500, 1250)

for(n in n_fwd_days){
  run_fwd_rets(n)
}

# Plot all 6% drop dates
file_path <- paste0(out_path, "/index_w_drop_days_dots.jpeg")
source_string <- paste0("Source:  YCharts (OfDollarsAndData.com)")

to_plot <- raw

points <- to_plot %>%
            inner_join(less_than_6pct) %>%
            select(date, index_sp500)

plot <- ggplot(to_plot, aes(x=date, y=index_sp500)) + 
  geom_line(col = "black") +
  geom_point(data = points, aes(x=date, y=index_sp500), col = "red", size = 1.5, alpha = 0.5) +
  scale_y_continuous(label = comma, trans = log10_trans()) +
  of_dollars_and_data_theme +
  ggtitle(paste0("S&P 500 with 6%+\n2-Session Drops Highlighted")) +
  labs(x = "Date" , y = "S&P 500 Index",
       caption = paste0("\n", source_string))  

# Save the plot
ggsave(file_path, plot, width = 15, height = 12, units = "cm")

# ############################  End  ################################## #