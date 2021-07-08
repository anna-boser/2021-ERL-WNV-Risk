# this file takes the raw CIMIS, LST, and Landsat data, 
# removes and points of poor quality,
# and merges the time and location pairs together in a dataframe saved as
# merged_df.RData.

library(data.table)
library(dplyr)
library(lubridate)
library(regex)
library(stringr)

################################################################################
# ECOSTRESS
################################################################################

# get the ecostress data (Cimis points)
get_eco <- function(year){
  read.csv(here::here("temperature_modeling", 
                      "data", 
                      "raw_data", 
                      "ECOSTRESS", 
                      "cimis_points", 
                      paste0("sj-points", year), 
                      paste0("SJ-points", year, "-ECO2LSTE-001-results.csv")))
}
eco <- rbindlist(lapply(2018:2020, get_eco))

# add the NOAA points (may have to do somethinga about missing "category" label)
eco <- rbind(eco, read.csv(here::here("temperature_modeling", 
                                      "data", 
                                      "raw_data", 
                                      "ECOSTRESS", 
                                      "noaa_points", 
                                      "FIX")))

# remove poor quality pixels
eco <- dplyr::filter(eco, 
                     ECO2LSTE_001_SDS_QC_Mandatory_QA_flags_Description == "Pixel produced, best quality")
eco$ECOSTRESS <- eco$ECO2LSTE_001_SDS_LST - 273.15 #in celcius not kelvin
eco <- dplyr::select(eco, Category, ID, Latitude, Longitude, Date, ECOSTRESS)
eco$dt <- ymd_hms(eco$Date, tz = "UTC") %>% with_tz("America/Los_Angeles")
eco$date <- date(eco$dt)
eco$Date <- NULL

################################################################################
# CIMIS
################################################################################

#get the cimis data
get_cimis <- function(year){#https://cimis.water.ca.gov/Stations.aspx
  rbind(read.csv(here::here("temperature_modeling", 
                            "data", 
                            "raw_data", 
                            "CIMIS", 
                            "all_points", 
                            paste0("SJ_", year, "_6.csv"))), 
        read.csv(here::here("temperature_modeling", 
                            "data", 
                            "raw_data", 
                            "CIMIS", 
                            "all_points", 
                            paste0("SJ_", year, "_8.csv"))) )
}
cimis <- rbindlist(lapply(2018:2020, get_cimis))

#add date time to cimis -- the hourly readings are averages of the minute by minute readings of the previous hour. 
cimis$mid_dt <- ymd_hms(paste(mdy(cimis$Date), 
                              paste0(as.numeric(str_extract(cimis$Hour..PST., regex("[1-9]+"))) - 1, ":30:00")), 
                        tz = "America/Los_Angeles")

cimis <- cimis[!is.na(mid_dt),] # remove NAs

#average duplicate cimis values
cimis <- cimis[, .(Air.Temp..C. = mean(Air.Temp..C.)), by = .(Stn.Id, mid_dt)]

################################################################################
# NOAA
################################################################################

# get noaa data (https://www.ncdc.noaa.gov/cdo-web/datatools/lcd)
read_noaa <- function(year){
  dataset <- read.csv(here("temperature_modeling", 
                           "data", 
                           "raw_data", 
                           "NOAA", 
                           "all_points", 
                           paste0("NOAA", year, ".csv")))
}

noaa <- rbindlist(lapply(2018:2020, read_noaa))

noaa$Stn.Id <- paste0("WBAN:", substring(noaa$STATION, 7)) # same ids as in ecostress data

#add date time to noaa
noaa$mid_dt <- ymd_hms(noaa$DATE, 
                        tz = "America/Los_Angeles")

noaa <- noaa[!is.na(mid_dt),] # remove NAs

#average duplicate cimis values
noaa <- noaa[, .(Air.Temp..C. = mean(as.numeric(HourlyDryBulbTemperature))), 
             by = .(Stn.Id, mid_dt)]

noaa <- noaa[!is.na(Air.Temp..C.),] # remove NAs

################################################################################
# Merge ECO and temperature
################################################################################

# bind temperature dfs together
temperature <- rbind(cimis, noaa)

#using the renamed file names, get the list of date times that are closest to the ecostress date times
get_mid_dts <- function(dt){
  dt <- temperature$mid_dt[abs(temperature$mid_dt - dt) == min(abs(temperature$mid_dt - dt))][1]
  dt
}
eco$mid_dt <- lapply(eco$dt, get_mid_dts) %>% purrr::reduce(c) #the closest dts to the times the cimis sensors give us
eco$Stn.Id <- eco$ID
eco$ID <- NULL

#merge ecostress and temperature data by location and date time
Comp_temp <- base::merge(x = eco, 
                         y = dplyr::select(temperature, Stn.Id, mid_dt, Air_Temp = Air.Temp..C.), 
                         by = c("Stn.Id", "mid_dt"), 
                         all.x = TRUE, all.y = FALSE) #sometimes there is more than 1 cimis measurement which is what makes the dataset grow. 

Comp_temp <- Comp_temp[!is.na(Air_Temp),]

Comp_temp$Location <- Comp_temp$Category #This is just what AppEEARS called it when I got the data
Comp_temp$Category <- NULL

################################################################################
# Landsat
################################################################################

#read in landsat data
get_landsat <- function(year){
  read.csv(here::here("temperature_modeling", 
                      "data", 
                      "raw_data", 
                      "Landsat", 
                      "cimis_points", 
                      paste0("landsat-", year), paste0("Landsat-", year, "-CU-LC08-001-results.csv")))
}
#FIX: ALSO NEED TO READ IN noaa points
landsat <- rbindlist(lapply(2018:2020, get_landsat))
landsat <-landsat[CU_LC08_001_PIXELQA != 1,]
landsat$year <- year(ymd(landsat$Date))
landsat <- landsat[,.(landsat_date = ymd(Date),
                      Stn.Id = ID,
                      Band1 = CU_LC08_001_SRB1, 
                      Band2 = CU_LC08_001_SRB2, 
                      Band3 = CU_LC08_001_SRB3, 
                      Band4 = CU_LC08_001_SRB4, 
                      Band5 = CU_LC08_001_SRB5, 
                      Band6 = CU_LC08_001_SRB6, 
                      Band7 = CU_LC08_001_SRB7)]

################################################################################
# Merge Comp_temp with Landsat
################################################################################

# the closest available landsat point to the date of the ecostress for a given location and date
get_landsat_date <- function(Id, date){
  l_dates <- filter(landsat, Stn.Id == Id)$landsat_date
  l_date <- l_dates[abs(l_dates - date) == min(abs(l_dates - date))][1]
  return(l_date)
}

Comp_temp$landsat_date <- mapply(get_landsat_date, Comp_temp$Stn.Id, Comp_temp$date) %>% as.Date(origin = dmy("01-01-1970"))

Comp_temp <- base::merge(x = Comp_temp, 
                         y = landsat, 
                         by = c("Stn.Id", "landsat_date"), 
                         all.x = TRUE, all.y = FALSE) # sometimes there is more than 1 cimis measurement which is what makes the dataset grow. 


# save file
saveRDS(Comp_temp, here::here("temperature_modeling", 
                              "data", 
                              "processed_data", 
                              "merged_df.RData"))

# also as csv to send to Dan
write.csv(Comp_temp, here::here("temperature_modeling", 
                              "data", 
                              "processed_data", 
                              "merged_df.csv"))

################################################################################
# Fractional vegetation
################################################################################

# Dan sent me the unmixed vegetation stuff so now I just need to add it to add it
Comp_temp <- readRDS(here::here("temperature_modeling", 
                                "data", 
                                "processed_data", 
                                "merged_df.RData"))
Dan_unmix <- read.csv(here::here("temperature_modeling", 
                        "data", 
                        "raw_data", 
                        "Landsat",
                        "Landsat_unmixed.csv"))
Comp_temp$V <- Dan_unmix$V2

#remove values less than 0:
Comp_temp <- filter(Comp_temp, V >= 0)
  
# save file
saveRDS(Comp_temp, here::here("temperature_modeling", 
                              "data", 
                              "processed_data", 
                              "merged_df.RData"))
  
