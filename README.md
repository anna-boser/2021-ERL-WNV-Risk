# WNV-paper
This is the repository used to create West Nile virus risk maps with ECOSTRESS LST measurements. 

It is organized as a R project in two parts: LST to air temperature modeling **temperature_modeling** (data, code, and results/figures), and WNV risk map creation and analysis **risk_maps** (data, code, and results/figures). 

## Temperature Modeling

**temperature_modeling** has data from several sources in the **raw_data** folder that lives in the **data** folder:
- CIMIS
  - LatLon.csv: lats and lons of site locations
  - all_points: all available data during study period
- NOAA
  - LatLon.csv: lats and lons of site locations
  - all_points: all available data during study period
- ECOSTRESS
  - cimis_points: all ecostress lst images at the CIMIS locations for Jun-Sept 2018-2020 obtained using AppEARS and CIMIS **LatLon.csv** file
  - noaa_points: all ecostress lst images at the NOAA locations for Jun-Sept 2018-2020 obtained using AppEARS and NOAA **LatLon.csv** file
- Landsat
  - cimis_points: all landsat 8 images at the CIMIS locations for Jun-Sept 2018-2020 obtained using AppEARS and CIMIS **LatLon.csv** file
  - noaa_points: all landsat 8 images at the NOAA locations for Jun-Sept 2018-2020 obtained using AppEARS and NOAA **LatLon.csv** file

These data are then processed and matched together in the **merge_data.R** file that can be found in the **code** folder to create **merged_df.RData** that can be found in the **processed_data** folder. 

Under **results** an R markdown file named **temp_mod_figures.Rmd** (temperature modeling figures) and corresponding html file can be found that describes the modeling approach and houses several figures

## Risk Maps

**risk_maps** has the following **raw_data** in its **data** folder: 
- Study_extent: shapefiles of the study border created using **study_extent.R**
- regression.RData: a lm object created in **temp_mod_figures.Rmd** from the results section in the **temperature_modeling** portion of the project
- ECOSTRESS: 
  - all_ims: all ECOSTRESS images in the study area Jun-Sept 2018-2020
  - filtered_ims: Renamed images with high QC and no cloud cover (see **filter_LST.R**)
  - chosen_four: four representative images of the same year at night, dawn, midday, and dusk 
- HLS Landsat images for four chosen ECOSTRESS images
  - all_ims
  - chosen_four
- Kern_ag_layer
  - original
  - binned_cropped: binned into different categories of interest and cropped to study area using **kern_bin.R**
- Urban layer
  - original: the 2016 Statewide Crop Mapping GIS Shapefiles from the California Department of Water Resources (https://data.cnra.ca.gov/dataset/statewide-crop-mapping)
  - filtered_cropped: urban layer only cropped to the study extent using **urban_filter.R**

In the **processed_data** folder you can find the following: 
- **ECOSTRESS** which holds the corrected **air_temperatures** and corresponding **biting_rate** and **transmission_rate** maps, created in **lst_to_air_b_tx.R**
- **landcover_avgs.RData**: a file with the average risk profiles (tx and bite) over the different land cover types of interest, built in **landcover_avg.R**. 

- **all_pixels_location_match.RData**: a file with every temperature observation and risk profiles (tx and bite) resampled to grid of first image for spatial consistency, built in **all_pixels_integrate.R**. 
- **all_pixels_integrate.RData**: a file with the average risk profiles (tx and bite) over each pixel (resampled to grid of first image for spatial consistency), calculated from **all_pixels_location_match.RData** in **all_pixels_integrate.R**. 
- **all_pixels_integrate_with_landcover.RData**: a file with the average risk profiles (tx and bite) over each pixel  (resampled to grid of first image for spatial consistency), labeled by landcover of the pixel, calculated from **all_pixels_location_match.RData** in **all_pixels_integrate.R**. Pixels that change lancover from 2018-2020 are excluded. 
*- **all_pixels.RData**: every pixel within an image land cover types and vegetation, built in **all_pixels.R**.* check if still used
*- **day_pixels.RData**: every pixel within a daytime image, built in **day_pixels.R**.* check if still used
- **Landcover** which holds a shapefile with flattened geometries for the different landcover types of interest, created in **flatten_landcovers.R**

Under **results** an R markdown file named **risk_map_figures.Rmd** and corresponding html file can be found that describes the modeling approach and houses the remaining figures.
