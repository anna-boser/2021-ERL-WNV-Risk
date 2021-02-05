#this script reads in the air temperature rasters, 
# subsets an area of interest by land cover, 
# and calculates the average temperature, biting rate, and transmission prob for that area. 
# The results are stored in a data frame as land_cover_avgs.RData
library(here)
library(raster)
library(sf)
library(lubridate)
library(data.table)

files <- list.files(here::here("risk_maps",
                               "data", 
                               "processed_data", 
                               "ECOSTRESS", 
                               "air_temperature"))

landcover_sf <- st_read(here::here("risk_maps", 
                                "data", 
                                "processed_data", 
                                "Landcover", 
                                "landcover.shp"))

bite <- function(T){
  bite <- (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
  bite[is.nan(bite)] <- 0
  return(bite)
}

transmit <- function(T){
  -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
}


mask_and_mean <- function(raster, landcover_shp, inverse = FALSE){
  mask <- raster::mask(raster,
                      landcover_shp,
                      inverse = inverse)
  
  bx <- bite(mask)
  tx <- transmit(mask)
  
  air_temperature <- cellStats(mask, "mean", na.rm = TRUE)
  biting_rate <- cellStats(bx, "mean", na.rm = TRUE)
  transmission_prob <- cellStats(tx, "mean", na.rm = TRUE)
  
  return(c(air_temperature, biting_rate, transmission_prob))
}


make_avgs <- function(file){
  
  print(paste("New file:", file))
  
  averages <- data.table()
  
  # read in raster
  airtemp_raster <- raster(here::here("risk_maps",
                              "data", 
                              "processed_data", 
                              "ECOSTRESS", 
                              "air_temperature", 
                              file))
  
  # get the dt
  date <- substr(file, 14, 23)
  hhmmss <- str_extract(file, regex('[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}'))
  Year <- year(ymd(date))
  
  #make the rows
  lc <- filter(landcover_sf, is.na(year) | year == Year)
  
  for (landtype in lc$landcover){
    lt <- filter(lc, landcover == landtype)
    abt <- mask_and_mean(airtemp_raster, lt)
    averages <- rbind(averages, 
                      data.table(date = date, 
                                 hhmmss = hhmmss, 
                                 landcover = landtype, 
                                 air_temperature = abt[1], 
                                 biting_rate = abt[2], 
                                 transmission_prob = abt[3]))
  }
  
  return(averages)
}

landcover_avgs <- rbindlist(lapply(files, FUN = make_avgs))

landcover_avgs$date <- ymd(landcover_avgs$date)
landcover_avgs$dt <- ymd_hms(paste(landcover_avgs$date, 
                                   landcover_avgs$hhmmss), 
                             tz = "America/Los_Angeles")
landcover_avgs$hhmmss <- NULL

saveRDS(landcover_avgs, here::here("risk_maps",
                                   "data", 
                                   "processed_data", 
                                   "landcover_avgs.RData"))

