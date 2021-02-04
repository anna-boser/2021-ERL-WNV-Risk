# this script takes OG kern ag data, cuts it to the study extent, and then bins it based on crop type. 

library(here)
library(sf)
library(dplyr)

study_extent <- st_read(here::here("risk_maps", 
                                   "data", 
                                   "raw_data", 
                                   "Study_extent", 
                                   "study_extent.shp"))

getkern <- function(year){
  shapefile <- st_read(here::here("risk_maps", 
                                  "data", 
                                  "raw_data", 
                                  "Kern_ag", 
                                  "original", 
                                  paste0("kern", year), 
                                  paste0("kern", year, ".shp"))) %>%
    st_transform(st_crs(study_extent)) %>% 
    st_make_valid() %>%
    st_crop(study_extent)
}

kern2018 <- getkern(2018)
kern2019 <- getkern(2019)
kern2020 <- getkern(2020)

# tm_shape(study_extent) + 
#   tm_borders() + 
#   tm_shape(kern2020) + 
#   tm_polygons(col = "SYMBOL")

# catrgory wishlist: 
# uncultivated
# fodder/covercrop/grass
# vegetable
# fruit
# nut orchard
# fruit orchard

#remove greenhouse

add_cat_col <- function(kerndata){
  kerndata$category <- ifelse(kerndata$COMM %in% c("UNCULTIVATED AG", "UNCULTIVATED AG - ORGANIC"), 
                              "Uncultivated", 
                              "Other") #industrial hemp will be other, along with greenhouse and outdoor. 
  kerndata$category[kerndata$SYMBOL %in% c("FRUIT_TROP", "FRUIT_POME", "FRUIT_TREE", "CITRUS", "NUTS")] <- "Orchard" #tropical fruits only contain pomegranates and persimmons, pome are all trees. 
  kerndata$category[kerndata$SYMBOL %in% c("FRUIT", "BERRIES")] <- "Fruit"
  kerndata$category[kerndata$SYMBOL %in% c("MELONS", "VEGETABLE")] <- "Vegetable"
  kerndata$category[kerndata$SYMBOL %in% c("FIELD")] <- "Field Crop" #not sure if this is actually an accurate description
  return(kerndata)
}

col_and_save <- function(kerndata, year){
  kerndata <- add_cat_col(kerndata)
  dir.create(here::here("risk_maps", 
                        "data", 
                        "raw_data", 
                        "Kern_ag", 
                        "binned_cropped", 
                        paste0("kern", year)))
  st_write(kerndata, here::here("risk_maps", 
                                "data", 
                                "raw_data", 
                                "Kern_ag", 
                                "binned_cropped", 
                                paste0("kern", year), 
                                paste0("kern", year, ".shp")), 
           layer = paste0("kern", year))
  
}

col_and_save(kern2018, 2018)
col_and_save(kern2019, 2019)
col_and_save(kern2020, 2020)


