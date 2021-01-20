# WNV-paper
This is the repository used to create West Nile virus risk maps with ECOSTRESS LST measurements. 

It is organized as a R project in two parts: LST to air temperature modeling **temperature_modeling** (data, code, and results/figures), and WNV risk map creation and analysis **risk_maps** (data, code, and results/figures). 

## Temperature Modeling

**temperature_modeling** has data from several sources in the **raw_data** folder that lives in the **data** folder:
- CIMIS
  - latlons.csv
  - all
- ECOSTRESS
  - all_ims: all ecostress lst images at the CIMIS locations for Jun-Sept 2018-2020 obtained using AppEARS and CIMIS **latlons.csv** file
  - filtered: remove any points that are not the highest quality using **QC_ECOSTRESS.R**
- Landsat 8
  - all_ims: all landsat 8 images at the CIMIS locations for Jun-Sept 2018-2020 obtained using AppEARS and CIMIS **latlons.csv** file
  - filtered: remove any points that are not the highest quality using **QC_Landsat.R**

These data are then processed and matched together in the **merge_data.R** file that can be found in the **code** folder to create **merged_df.RData** that can be found in the **processed_data** folder. This dataset is then further modified by creating a "Vegetation" category by performing linear unmixing of the the Landsat 8 reflectances. The final dataset used to generate results is named **modeling_df.Rdata**. 

Under **results** an R markdown file and corresponding html filecan be found that describes the modeling approach and houses the following figures: 
- fig 3 - LST vs air temp scatterplots - raw data 
- fig 4 - breakdown vs vegetation - [showing no real impact?] 
- fig 5 - Corrected relationship w/ nice 1:1 scatter

## Risk Maps

**risk_maps** has the following **raw_data** in its **data** folder: 
- Study_extent: shapefiles of the study border
- ECOSTRESS: 
  - all_ims: all ECOSTRESS images in the study area Jun-Sept 2018-2020
  - filtered_ims: Images with high QC and no cloud cover (hand picked? or use their QC...?)
  - chosen_four: four images of the same year at night, dawn, midday, and dusk (how do you choose these?)
- LSF (?) Landsat images for four chosen ECOSTRESS images
  - all_ims
  - chosen_four
- Kern_ag_layer
  - original
  - binned into different categories of interest
- Urban layer?? maybe needed. 

In the **processed_data** folder you can find the following: 
- **land_cover_avgs.RData**: a file with the average risk profiles (tx and bite) over the different land cover types of interest, built in **land_cover_avg.R**. 
- **all_pixels.RData**: every pixel within one of the four chosen images (labeled) with labels for land cover types and vegetation, built in **all_pixels.R**. 

Under **results** an R markdown file and corresponding html file can be found that describes the modeling approach and houses the following figures: 
- fig 2 - Mordecai equation plot
- fig 6 - Tx wrt time of day (land cover type)
- fig 7 - maps for each time of day
- fig 8 - statistical illustration showing breakdown by land cover 
    - Different ag types vs urban 
    - Heterogeneity within urban 
    - Veg continuous vs risk 
