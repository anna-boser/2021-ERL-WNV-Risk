# creates a dataframe of all pixels found between 11 and 16h. 

library(data.table)
library(raster)
library(sf)
library(lubridate)
library(dplyr)
library(stringr)

landcover_sf <- st_read(here::here("risk_maps", 
                                   "data", 
                                   "processed_data", 
                                   "Landcover", 
                                   "landcover.shp"))

day_files_11_16 <- list.files(here::here("risk_maps",
                                         "data", 
                                         "processed_data", 
                                         "ECOSTRESS", 
                                         "air_temperature"))
day_files_11_16 <- day_files_11_16[as.integer(substr(day_files_11_16, 5, 6)) %in% 11:15] # the hour is 11 to 15 so this goes until 16

bite <- function(T){
  bite <- (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
  bite <- ifelse(is.nan(bite), 0, bite)
  return(bite)
}

transmit <- function(T){
  -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
}

pixelify <- function(file){
  
  date <- substr(file, 14, 23)
  hhmmss <- str_extract(file, regex('[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}'))
  Year <- lubridate::year(ymd(date))
  
  landcover_shp <- filter(landcover_sf, year == Year | is.na(year))
  
  airtemp_raster <- raster(here::here("risk_maps",
                                      "data", 
                                      "processed_data", 
                                      "ECOSTRESS", 
                                      "air_temperature", 
                                      file))
  
  all_pixels <- data.frame(date = date, 
                           hhmmss = hhmmss, 
                           landcover = "Other", 
                           air_temperature = raster::values(airtemp_raster))
  all_pixels$biting_rate <- bite(all_pixels$air_temperature)
  all_pixels$transmission_prob <- transmit(all_pixels$air_temperature)
  
  landcovers_of_interest <- c("Urban", "Vegetable", "Orchard", "Fruit", "Field Crop", "Uncultivated")
  
  for (lc in landcovers_of_interest){
    all_pixels$landcover <- ifelse(is.na(raster::values(raster::mask(airtemp_raster, 
                                                                     filter(landcover_shp, landcover == lc)))), 
                                   all_pixels$landcover, 
                                   lc)
  }
  
  all_pixels$Urban <- ifelse(is.na(raster::values(raster::mask(airtemp_raster, 
                                                               filter(landcover_shp, landcover == "Urban")))), 
                             FALSE, 
                             TRUE)
  
  return (all_pixels)
}

day_pixels <- rbindlist(lapply(day_files_11_16, pixelify))

saveRDS(day_pixels, here::here("risk_maps",
                               "data", 
                               "processed_data", 
                               "day_pixels.RData"))