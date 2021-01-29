library(here)
library(raster)

files <- list.files(here::here("risk_maps",
                               "data", 
                               "raw_data",
                               "ECOSTRESS",
                               "filtered_ims"))

temp_bite_tx <- function(file){
  print(file)
  T <- raster(here::here("risk_maps",
                         "data", 
                         "raw_data",
                         "ECOSTRESS",
                         "filtered_ims", 
                         file))
  
  ones <- T
  ones[] <- 1 #make a raster of ones
  
  # correct temperature
  T <- 3.7001008*ones + 1.0591731*T - 0.0086070*(T^2)
  
  writeRaster(T, here::here("risk_maps",
                                 "data", 
                                 "processed_data",
                                 "ECOSTRESS",
                                 "air_temperature", 
                                 file))
  
  # biting rates
  
  equation <- function(T){
    (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
    }
  
  raster <- equation(T)
  raster[is.na(raster[])] <- 0 # because of the square root
  
  writeRaster(T, here::here("risk_maps",
                            "data", 
                            "processed_data",
                            "ECOSTRESS",
                            "biting_rates", 
                            file))
  
  #transmission rates
  
  equation <- function(T){
    -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
    }
  
  raster <- equation(T)
  raster[is.na(raster[])] <- 0 

  writeRaster(T, here::here("risk_maps",
                            "data", 
                            "processed_data",
                            "ECOSTRESS",
                            "transmission_rates", 
                            file))
}

lapply(files, temp_bite_tx)
