library(here)
library(raster)

files <- list.files(here::here("risk_maps",
                               "data", 
                               "raw_data",
                               "ECOSTRESS",
                               "filtered_ims"))

regression <- readRDS(file = here("risk_maps", "data", "raw_data", "regression.RDS"))

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
  T <- regression[["coefficients"]][[1]]*ones + 
    regression[["coefficients"]][[2]]*T + 
    regression[["coefficients"]][[3]]*(T^2) + 
    regression[["coefficients"]][[4]]*(T^3)
  
  writeRaster(T, here::here("risk_maps",
                                 "data", 
                                 "processed_data",
                                 "ECOSTRESS",
                                 "air_temperature", 
                                 file), 
              overwrite=TRUE)
  
  # biting rates
  
  equation <- function(T){
    (1.67*10^-4) * T * (T- 2.3) * (32.0 - T)^(1/2)
    }
  
  raster <- equation(T)
  raster[is.na(raster[])] <- 0 # because of the square root
  
  writeRaster(raster, here::here("risk_maps",
                            "data", 
                            "processed_data",
                            "ECOSTRESS",
                            "biting_rates", 
                            file), 
              overwrite=TRUE)
  
  #transmission rates
  
  equation <- function(T){
    -(2.94*10^-3) * T * (T - 11.3) * (T - 41.9)
    }
  
  raster <- equation(T)
  raster[is.na(raster[])] <- 0 

  writeRaster(raster, here::here("risk_maps",
                            "data", 
                            "processed_data",
                            "ECOSTRESS",
                            "transmission_rates", 
                            file), 
              overwrite=TRUE)
}

lapply(files, temp_bite_tx)
