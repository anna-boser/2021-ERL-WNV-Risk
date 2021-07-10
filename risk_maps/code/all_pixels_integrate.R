# this script makes a dataframe with all the pixels over all images 
# includung location information by resampling all ECOSTRESS images to the first raster, 
# determines their landcover type and then integrates over each location

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

all_files <- list.files(here::here("risk_maps",
                                         "data", 
                                         "processed_data", 
                                         "ECOSTRESS", 
                                         "air_temperature"))
all_files <- all_files[1:2] #for local testing

bite <- function(T){
  bite <- (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
  bite <- ifelse(is.nan(bite), 0, bite)
  return(bite)
}

transmit <- function(T){
  -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
}

resample_raster <- raster(here::here("risk_maps", #the raster to resample all others to
                            "data", 
                            "processed_data", 
                            "ECOSTRESS", 
                            "air_temperature", 
                            all_files[1]))

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
  
  airtemp_raster <- resample(airtemp_raster, resample_raster)
  
  names(airtemp_raster) <- "air_temperature"
  all_pixels <- as.data.frame(airtemp_raster, xy = TRUE)
  all_pixels$date <- date
  all_pixels$hhmmss <- hhmmss
  all_pixels$landcover = "Other"
  
  # all_pixels <- data.frame(date = date, 
  #                          hhmmss = hhmmss, 
  #                          landcover = "Other", 
  #                          air_temperature = raster::values(airtemp_raster))
  
  all_pixels$biting_rate <- bite(all_pixels$air_temperature)
  all_pixels$transmission_prob <- transmit(all_pixels$air_temperature)
  
  landcovers_of_interest <- c("Urban", "Vegetable", "Orchard", "Fruit", "Field Crop", "Uncultivated")
  
  for (lc in landcovers_of_interest){ #for some reason there's only 2019?? should probably fix
    
    masked_raster <- raster::mask(airtemp_raster, 
                           filter(landcover_shp, landcover == lc))
    names(masked_raster) <- "landcover_mask"
    
    df <- as.data.frame(masked_raster, xy = TRUE)

    all_pixels$landcover <- ifelse(is.na(df$landcover_mask), 
                                   all_pixels$landcover, 
                                   lc)
    if (lc == "Urban"){
      all_pixels$Urban <- ifelse(is.na(df$landcover_mask), 
                                     FALSE, 
                                     TRUE)
    }
  }
  
  return (all_pixels)
}

all_pixels <- rbindlist(lapply(all_files, pixelify))

saveRDS(all_pixels, here::here("risk_maps",
                               "data", 
                               "processed_data", 
                               "all_pixels_location_match.RData"))

# take the average over time (which should average the day) for 
# air temperature, biting rate, and transmission prob

all_pixels_integrate <- all_pixels %>% 
  group_by(x, y) %>%
  summarize(air_temperature = mean(air_temperature), 
            biting_rate = mean(biting_rate), 
            transmission_prob = mean(transmission_prob))

saveRDS(all_pixels_integrate, here::here("risk_maps",
                               "data", 
                               "processed_data", 
                               "all_pixels_integrate.RData"))

#keep landcover data and toss pixels that change their landcover

all_pixels_integrate <- all_pixels %>% 
  group_by(x, y, landcover, loc = paste(x, y)) %>%
  summarize(air_temperature = mean(air_temperature), 
            biting_rate = mean(biting_rate), 
            transmission_prob = mean(transmission_prob))

duplicated_locs <- all_pixels_integrate$loc[duplicated(all_pixels_integrate$loc)]
all_pixels_integrate <- filter(all_pixels_integrate, !(loc %in% duplicated_locs))

saveRDS(all_pixels_integrate, here::here("risk_maps",
                                         "data", 
                                         "processed_data", 
                                         "all_pixels_integrate_w_landcover.RData"))
