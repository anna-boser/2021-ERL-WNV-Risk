# This script takes all the landcovers of interest to be used in landcover_avg
# and flattens them and puts them in a single shapefile by year (since ag has different years). 
# The landcovers of interest are: 
# All,
# Urban,
# Agriculture,
# and all the agriculture subcategories. 

library(here)
library(sf)

study_extent <- st_read(here::here("risk_maps", 
                                   "data", 
                                   "raw_data", 
                                   "Study_extent", 
                                   "study_extent.shp"))

urban <- st_read(here::here("risk_maps", 
                            "data",
                            "raw_data", 
                            "Urban", 
                            "filtered_cropped", 
                            "urban.shp"))

years <- c(2018:2020)

for (year in years){
  assign(paste0("ag", year), 
         st_read(here::here("risk_maps", 
                            "data", 
                            "raw_data", 
                            "Kern_ag", 
                            "binned_cropped", 
                            paste0("kern", year), 
                            paste0("kern", year, ".shp")), 
                 layer = paste0("kern", year)))
}

landcover <- c()

lc_sf <- function(lctype, year, shapefile){
  geom <- st_union(shapefile)
  lc_sf <- st_sf(landcover = lctype, year = year, geom)
}

# all
landcover <- rbind(landcover, 
                   lc_sf(lctype = "All", 
                         year = NA, 
                         shapefile = study_extent))

# urban
landcover <- rbind(landcover, 
                   lc_sf(lctype = "Urban", 
                         year = NA, 
                         shapefile = urban))

#ag and ag subtypes
for (year in years){
  ag <- get(paste0("ag", year))
  
  landcover <- rbind(landcover, 
                     lc_sf(lctype = "Agriculture", 
                           year = year, 
                           shapefile = ag))
  
  for(subtype in unique(ag$category)){
    ag_sub <- filter(ag, category == subtype)
    landcover <- rbind(landcover, 
                       lc_sf(lctype = subtype, 
                             year = year, 
                             shapefile = ag_sub))
  }
}

st_write(landcover, here::here("risk_maps", 
                               "data", 
                               "processed_data", 
                               "Landcover", 
                               "landcover.shp"))



