# this script takes the original 2016 ag layer, 
# filters it to only include urban areas, 
# and crops it to the study extent. 

library(sf)
library(here)
library(dplyr)

study_extent <- st_read(here::here("risk_maps", 
                                   "data", 
                                   "raw_data", 
                                   "Study_extent", 
                                   "study_extent.shp"))

ag_2016 <- st_read(here::here("risk_maps", 
                              "data",
                              "raw_data", 
                              "Urban", 
                              "original", 
                              "i15_crop_mapping_2016_shp", 
                              "i15_Crop_Mapping_2016.shp")) %>% 
  st_transform(st_crs(study_extent)) %>%
  st_make_valid() %>%
  st_crop(study_extent)

built <- ag_2016 %>% filter(Crop2016 == "Urban")

st_write(built, here::here("risk_maps", 
                           "data",
                           "raw_data", 
                           "Urban", 
                           "filtered_cropped", 
                           "urban.shp"))

# To map it: 
# library(tmap)
# tm_shape(study_extent) +
#   tm_borders() +
#   tm_shape(built) +
#   tm_polygons()

