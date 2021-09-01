# This script reads in the air temperature rasters and calcualtes the biting and transmission rates
# when considering the rasters at various spatial and temporal resolutions. 
# The resulting data are then saved and used in risk_map_figures to illustrate the effect of 
# Jensen's inequality. 

library(data.table)
library(raster)
library(sf)
library(lubridate)
library(dplyr)
library(stringr)

all_files <- list.files(here::here("risk_maps",
                                   "data", 
                                   "processed_data", 
                                   "ECOSTRESS", 
                                   "air_temperature"))
# all_files <- all_files[1:2] #for local testing

bite <- function(T){
  bite <- (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
  bite <- ifelse(is.nan(bite), 0, bite)
  return(bite)
}

transmit <- function(T){
  -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
}

# number 1: spatial coarsification
# for each image, I calculate the air temp, biting rate, and transmission prob at various spatial resolutions 
# (aggregate two pixels at a time, 37 times)
# as a check, air temp should always be the same

coarsify <- function(file){
  print(file)
  
  # date <- substr(file, 14, 23)
  hhmmss <- str_extract(file, regex('[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}'))
  # Year <- lubridate::year(ymd(date))
  hour_of_day <- as.numeric(substring(hhmmss, 1, 2)) + as.numeric(substring(hhmmss, 4, 5))/60
  
  landcover_shp <- filter(landcover_sf, year == Year | is.na(year))
  
  airtemp_raster <- raster(here::here("risk_maps",
                                      "data", 
                                      "processed_data", 
                                      "ECOSTRESS", 
                                      "air_temperature", 
                                      file))
  
  df <- data.table(matrix(ncol = 6, nrow = 0))
  names(df) <- c("hour_of_day", "resolution", "aggregation_num", "air_temperature", "biting_rate", "transmission_prob")
  resolution <- 70
  
  for (aggregation_num in 0:10){
    air_temperature <- mean(values(airtemp_raster))
    biting_rate <- mean(bite(values(airtemp_raster)))
    transmission_prob <- mean(transmit(values(airtemp_raster)))
    
    df <- rbind(df, data.table(hour_of_day, 
                               resolution, 
                               aggregation_num, 
                               air_temperature, 
                               biting_rate, 
                               transmission_prob))
    
    airtemp_raster <- aggregate(airtemp_raster, fact=2)
    resolution <- resolution*2
    
    print(airtemp_raster)
  }
  
  return(df)
}

df <- rbindlist(lapply(all_files, coarsify))


hi <- df %>% group_by(resolution, aggregation_num) %>%
  summarize(air_temperature = mean(air_temperature), 
            biting_rate = mean(biting_rate), 
            transmission_prob = mean(transmission_prob))

ggplot(hi) + geom_line(aes(x = aggregation_num, y = transmission_prob))
