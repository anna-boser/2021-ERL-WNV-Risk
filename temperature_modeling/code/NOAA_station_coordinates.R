library(here)

ID <- c("WBAN:23155", 
        "WBAN:93104", 
        "WBAN:53144", 
        "WBAN:23114", 
        "WBAN:03183", 
        "WBAN:00479", 
        "WBAN:23149", 
        "WBAN:93144", 
        "WBAN:23110", 
        "WBAN:53119", 
        "WBAN:93193", 
        "WBAN:93242", 
        "WBAN:23203", 
        "WBAN:93243", 
        "WBAN:23257", 
        "WBAN:23258", 
        "WBAN:23237")

Latitude <- c(35.4344, 
              35.6875, 
              34.98833, 
              34.9, 
              35.06667, 
              35.1349, 
              36.02944, 
              36.31667, 
              36.33333, 
              36.31889, 
              36.78, 
              36.98778, 
              37.38333, 
              37.2381, 
              37.28472, 
              37.6241, 
              37.8891)

Longitude <- c(-119.0542, 
               -117.6931, 
               -117.86472, 
               -117.86667, 
               -118.15, 
               -118.4393, 
               -119.0625, 
               -119.4, 
               -119.95, 
               -119.62889, 
               -119.7194, 
               -120.11056, 
               -120.56667, 
               -120.8825, 
               -120.51278, 
               -120.9505, 
               -121.2258)

dataset <- data.frame(ID, Latitude, Longitude)

dataset <- filter(dataset, !(ID %in% c("WBAN:23114", "WBAN:53144", "WBAN:03183", "WBAN:00479", "WBAN:93104"))) #turns out these aren't really in the SJV

write.csv(dataset, here("temperature_modeling", "data", "raw_data", "NOAA", "LatLon.csv"), row.names = FALSE)
