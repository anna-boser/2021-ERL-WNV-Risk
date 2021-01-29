# we begin with 211 ECOSTRESS scenes. 
# in this script, we: 
# 1. filter the ones that are bad
# 2. change them from Kelvin to Celcius
# 3. rename them and save them in the "filtered_ims" folder

library(here)
library(raster)
library(regex)
library(stringr)


# lstfiles_fullnames <- list.files(path = here::here("risk_maps", 
#                                                    "data", 
#                                                    "raw_data", 
#                                                    "ECOSTRESS",
#                                                    "all_ims",
#                                                    "LST"), pattern = "tif", recursive = TRUE, full.names = TRUE)
lstfiles <- list.files(path = here::here("risk_maps", 
                                         "data", 
                                         "raw_data", 
                                         "ECOSTRESS",
                                         "all_ims",
                                         "LST"), pattern = "tif", recursive = TRUE, full.names = FALSE)

# manually pic out the good files -- QC is useless 
# (see commented portion at the bottom of the script)
good_full <- c(2, 7, 8, 30, 36, 40, 44, 45, 49, 50, 56, 61, 64, 65, 66, 69, 74, 76, 
               78, 80, 83, 85, 86, 89, 92, 93, 96, 101, 102, 109, 111, 115, 119, 
               120, 122, 126, 130, 139, 140, 142, 144, 146, 159, 165, 167, 169, 
               170, 172, 173, 174, 175, 176, 177, 180, 183, 191, 192, 195, 200, 
               201, 202, 204, 207, 210, 211)
good_chopped <- c(4, 5, 10, 12, 15, 19, 20, 21, 22, 24, 25, 38, 42, 51, 
                  67, 70, 81, 91, 98, 99, 104, 116, 128, 131, 132, 134, 147, 149, 
                  162, 178, 181, 184, 196, 197, 199, 203, 205, 206, 208, 209)
bad <- c(1, 3, 6, 9, 11, 13, 14, 16, 17, 18, 23, 26, 27, 28, 29, 31, 32, 33, 34, 
         35, 37, 39, 41, 43, 46, 47, 48, 51, 52, 53, 54, 55, 57, 58, 59, 60, 
         62, 63, 68, 71, 72,  73, 75, 77, 79, 82, 84, 87, 88, 90, 94, 95, 97, 100, 103, 
         105, 106, 107, 108, 110, 112, 113, 114, 115, 117, 118, 121, 123, 124, 125,
         127, 129, 133, 135, 136, 137, 138, 141, 143, 145, 148, 150, 151, 152, 
         153, 154, 155, 156, 157, 158, 160, 161, 163, 164, 166, 168, 171, 179, 182, 185, 186, 187, 188, 
         189, 190, 193, 194, 198)

goodfiles <- lstfiles[good_full]

#move files to new folder
move.file <- function(file){
  file.copy(from = here::here("risk_maps", 
                                 "data", 
                                 "raw_data", 
                                 "ECOSTRESS",
                                 "all_ims",
                                 "LST", 
                                 file),
               to = here::here("risk_maps", 
                               "data", 
                               "raw_data", 
                               "ECOSTRESS",
                               "filtered_ims",
                                file))
}

lapply(goodfiles, move.file)

#change files to celcius
files <- list.files(path = here::here("risk_maps", 
                                      "data",
                                      "raw_data",
                                      "ECOSTRESS",
                                      "filtered_ims"), 
                    pattern = "tif", 
                    recursive = TRUE, 
                    full.names = TRUE)
  

celcius <- function(file){
  raster <- raster(file)
  raster <- raster*.02 - 273.15
  writeRaster(raster, file, overwrite = TRUE)
}

lapply(files, celcius)

#rename files
files <- list.files(path = here::here("risk_maps", 
                                      "data",
                                      "raw_data",
                                      "ECOSTRESS",
                                      "filtered_ims"), 
                    pattern = "tif", 
                    recursive = TRUE, 
                    full.names = FALSE)

rename <- function(file){
  
  nums <- str_extract(file, regex('(?<=doy)[0-9]+'))
  year <- substr(nums, 1, 4)
  doy <- substr(nums, 5, 7) %>% as.numeric()
  hhmmss <- substr(nums, 8, 13)
  date <- as.Date(doy - 1, origin = paste0(year, "-01-01"))
  dt <- ymd_hms(paste(date, hhmmss), tz = "UTC") %>% with_tz("America/Los_Angeles")
  month <- format(dt,"%m")
  hour <- hour(dt)
  day <- format(dt,"%d")
  time <- substr(dt, 12, 19)
  
  name <- paste0("lst", "_", time, "_", year, "_", month, "_", day, ".tif")
  
  file.rename(from = here::here("risk_maps", 
                                "data",
                                "raw_data",
                                "ECOSTRESS",
                                "filtered_ims", 
                                file), 
              to = here::here("risk_maps", 
                              "data",
                              "raw_data",
                              "ECOSTRESS",
                              "filtered_ims", 
                              name))
}

lapply(files, rename)


# plot the files to determine chosen 4
files <- list.files(path = here::here("risk_maps", 
                                      "data",
                                      "raw_data",
                                      "ECOSTRESS",
                                      "filtered_ims"), 
                    pattern = "tif", 
                    recursive = TRUE, 
                    full.names = FALSE)


plotfile <- function(file){
  date <- ymd(substr(file, 14, 23))
  hhmmss <- str_extract(file, regex('[0-9]{2}:{1}[0-9]{2}:{1}[0-9]{2}'))
  dt <- ymd_hms(paste(date, hhmmss), tz = "America/Los_Angeles")
  
  rast <- raster(here::here("risk_maps", 
                            "data",
                            "raw_data",
                            "ECOSTRESS",
                            "filtered_ims", 
                            file))
  
  pal <- colorRampPalette(c("purple", "blue", "green", "yellow", "orange", "red"))
  
  plot(rast, 
       col = pal(50), 
       # xlim=c(0,55),
       # ylim=c(-10,50),
       zlim=c(0, 70),
       xlab="Longitude", 
       ylab = "Latitude")
  title(dt)
}


lapply(files, plotfile)

#manually copied best ones













# excellent_files <- c()
# ok_files <- c()
# 
# files <- list.files(path = here::here("risk_maps", 
#                                       "data", 
#                                       "raw_data", 
#                                       "ECOSTRESS",
#                                       "all_ims",
#                                       "QC"), pattern = "tif", recursive = TRUE, full.names = TRUE)
# 
# for (file in files){
#   raster <- raster(file)
#   vector <- as.vector(raster)
#   first2bits <- function(integer){
#     intToBits(integer)[1] 
#   }
#   bits <- sapply(vector, first2bits) %>% as.character()
#   time <- str_extract(file, regex("doy[0-9]*"))
#   if (all(bits == "00")){
#     excellent_files <- c(excellent_files, time)
#   } else if (all(bits %in% c("00", "01"))){
#     ok_files <- c(ok_files, time)
#   }
# }
