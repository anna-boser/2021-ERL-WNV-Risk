# this file creates a shapefile for the study extent wished. 
library(dplyr)
library(sf)
library(here)
library(tmap)

create_extent <- function(lat1, lat2, lon1, lon2){
  #function that takes the bounding latitudes and longitudes of the desired site and returns a shapefile
  df <- df <- data.frame(
    lon = c(lon1, lon1, lon2, lon2),
    lat = c(lat1, lat2, lat2, lat1)
  )
  
  polygon <- df %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
    summarise(geometry = st_combine(geometry)) %>%
    st_cast("POLYGON")
}

study_extent <- create_extent(35.30, 35.77, -119.700, -118.88)

#map the new polygon
tm_shape(study_extent) + tm_polygons()

st_write(study_extent, here::here("risk_maps", "data", "raw_data","Study_extent", "study_extent.shp"), layer = "study_extent")
