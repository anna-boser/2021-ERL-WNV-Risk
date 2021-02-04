#this script takes the four chosen images and labels each pixel by the land cover type
library(raster)
library(sf)
library(lubridate)
library(dplyr)
library(stringr)
# library(data.table)

landcover_sf <- st_read(here::here("risk_maps", 
                                   "data", 
                                   "processed_data", 
                                   "Landcover", 
                                   "landcover.shp"))

chosen_four <- list.files(here::here("risk_maps",
                                     "data", 
                                     "raw_data", 
                                     "ECOSTRESS", 
                                     "chosen_four"))

bite <- function(T){
  bite <- (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
  # bite <- ifelse(is.nan(bite), 0, bite)
  return(bite)
}

transmit <- function(T){
  -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
}

pixelify <- function(file, time_of_day){
  
  date <- ymd(substr(file, 14, 23))
  hhmmss <- str_extract(file, regex('[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}'))
  dt <- ymd_hms(paste(date, hhmmss), tz = "America/Los_Angeles")
  Year <- year(date) 
  
  landcover_shp <- filter(landcover_sf, year == Year | is.na(year))
  
  airtemp_raster <- raster(here::here("risk_maps",
                              "data", 
                              "processed_data", 
                              "ECOSTRESS", 
                              "air_temperature", 
                              file))
  
  all_pixels <- data.frame(time_of_day = time_of_day, 
                           date = date, 
                           dt = dt, 
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
  
  return (all_pixels)
}
      
night <- pixelify(chosen_four[1], "Night")
dawn <- pixelify(chosen_four[2], "Dawn")
day <- pixelify(chosen_four[3], "Day")
dusk <- pixelify(chosen_four[4], "Dusk")

all_pixels <- rbind(night, dawn, day, dusk)

#if you want to look at the other scenes

# for (image in all_other_images){
#   all_pixels <- rbind(all_pixels, pixelify(image, NA))
# }

all_pixels$biting_rate <- ifelse(is.nan(all_pixels$biting_rate), 0, all_pixels$biting_rate)

saveRDS(all_pixels, here::here("risk_maps",
                               "data", 
                               "processed_data", 
                               "all_pixels.RData"))
