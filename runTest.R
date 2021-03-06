library(raster)
library(sp)
library(devtools)
install_github("SEEG-Oxford/seegSDM", ref="0.1-8")
library(seegSDM)
## This is fork of runABRAID from SEEG-Oxford/seegSDM @ 0.1-8
runTest <- function (name,
                     mode, 
                     disease,
                     admin_extract_mode="random",
                     crop_bias=TRUE, # used with mode "bias"
                     filter_bias=TRUE, # used with mode "bias"
                     use_weights=TRUE,
                     use_temporal_covariates=TRUE) {
  
  # Create a temp dir for intermediate rasters
  dir.create('temp')
  rasterOptions(tmpdir="temp")
  
  # Get file paths
  occurrence_path <- paste0(disease,"_data/occurrences.csv")
  extent_path <- paste0(disease,"_data/extent.tif")
  supplementary_occurrence_path <- paste0(disease,"_data/supplementary_occurrences.csv")
  admin_path <- list(
    "admin0"="admins/admin0.tif",
    "admin1"="admins/admin1.tif",
    "admin2"="admins/admin2.tif",
    "admin3"="admins/admin2.tif" # This one wont be used, but is needed for compatablity with older bits of seegSDM
  )
  water_mask <- "admins/waterbodies.tif"
  disease_type <- list(
    "cchf"="virus",
    "chik"="virus",
    "deng"="virus",
    "hat"="parasite",
    "melio"="bacteria",
    "nwcl"="parasite",
    "owcl"="parasite",
    "scrub"="bacteria"
  )[[disease]]
  
  all_covs <- list(
    "access"="covariates/access.tif",
    "aegypti"="covariates/aegypti_fill.tif",
    "albo"="covariates/albo_fill.tif",
    "c01"=list(
      "2001"="covariates/2001.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class01_Evergreen_Needleleaf_Forest.5km.Percentage.abraid.tif"
    ),
    "c02"=list(
      "2001"="covariates/2001.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class02_Evergreen_Broadleaf_Forest.5km.Percentage.abraid.tif"
    ),
    "c03"=list(
      "2001"="covariates/2001.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class03_Deciduous_Needleleaf_Forest.5km.Percentage.abraid.tif"
    ),
    "c04"=list(
      "2001"="covariates/2001.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class04_Deciduous_Broadleaf_Forest.5km.Percentage.abraid.tif"
    ),
    "c05"=list(
      "2001"="covariates/2001.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class05_Mixed_Forest.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class05_Mixed_Forest.5km.Percentage.abraid.tif"
    ),
    "c06"=list(
      "2001"="covariates/2001.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class06_Closed_Shrublands.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class06_Closed_Shrublands.5km.Percentage.abraid.tif"
    ),
    "c07"=list(
      "2001"="covariates/2001.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class07_Open_Shrublands.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class07_Open_Shrublands.5km.Percentage.abraid.tif"
    ),
    "c08"=list(
      "2001"="covariates/2001.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class08_Woody_Savannas.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class08_Woody_Savannas.5km.Percentage.abraid.tif"
    ),
    "c09"=list(
      "2001"="covariates/2001.Class09_Savannas.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class09_Savannas.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class09_Savannas.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class09_Savannas.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class09_Savannas.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class09_Savannas.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class09_Savannas.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class09_Savannas.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class09_Savannas.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class09_Savannas.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class09_Savannas.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class09_Savannas.5km.Percentage.abraid.tif"
    ),
    "c10"=list(
      "2001"="covariates/2001.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class10_Grasslands.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class10_Grasslands.5km.Percentage.abraid.tif"
    ),
    "c11"=list(
      "2001"="covariates/2001.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class11_Permanent_Wetlands.5km.Percentage.abraid.tif"
    ),
    "c12"=list(
      "2001"="covariates/2001.Class12_Croplands.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class12_Croplands.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class12_Croplands.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class12_Croplands.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class12_Croplands.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class12_Croplands.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class12_Croplands.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class12_Croplands.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class12_Croplands.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class12_Croplands.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class12_Croplands.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class12_Croplands.5km.Percentage.abraid.tif"
    ),
    "c13"=list(
      "2001"="covariates/2001.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class13_Urban_And_Built_Up.5km.Percentage.abraid.tif"
    ),
    "c14"=list(
      "2001"="covariates/2001.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class14_Cropland_Natural_Vegetation_Mosaic.5km.Percentage.abraid.tif"
    ),
    "c15"=list(
      "2001"="covariates/2001.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class15_Snow_And_Ice.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class15_Snow_And_Ice.5km.Percentage.abraid.tif"
    ),
    "c16"=list(
      "2001"="covariates/2001.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2002"="covariates/2002.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2003"="covariates/2003.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2004"="covariates/2004.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2005"="covariates/2005.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2006"="covariates/2006.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2007"="covariates/2007.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2008"="covariates/2008.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2009"="covariates/2009.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2010"="covariates/2010.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2011"="covariates/2011.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif",
      "2012"="covariates/2012.Class16_Barren_Or_Sparsely_Populated.5km.Percentage.abraid.tif"
    ),
    "duffy"="covariates/duffy_neg.tif",
    "evi_mean"="covariates/EVI_Fixed_Mean_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "evi_sd"="covariates/EVI_Fixed_SD_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "gecon"="covariates/gecon.tif",
    "lst_day_mean"="covariates/LST_Day_Mean_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "lst_day_sd"="covariates/LST_Day_SD_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "lst_night_mean"="covariates/LST_Night_Mean_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "lst_night_sd"="covariates/LST_Night_SD_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "mod_dem"="covariates/mod_dem.tif",
    "prec57a0"="covariates/prec57a0.tif",
    "prec57a1"="covariates/prec57a1.tif",
    "prec57a2"="covariates/prec57a2.tif",
    "prec57mn"="covariates/prec57mn.tif",
    "prec57mx"="covariates/prec57mx.tif",
    "prec57p1"="covariates/prec57p1.tif",
    "prec57p2"="covariates/prec57p2.tif",
    "tcb_mean"="covariates/TCB_Mean_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "tcb_sd"="covariates/TCB_SD_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "tcw_mean"="covariates/TCW_Mean_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "tcw_sd"="covariates/TCW_SD_5km_Mean_DEFLATE.ABRAID_Extent.Gapfilled.tif",
    "tempaucpf"="covariates/tempaucpf.tif",
    "tempaucpv"="covariates/tempaucpv.tif",
    "tempsuit"="covariates/tempsuit.tif",
    "upr_p"="covariates/upr_p.tif",
    "upr_u"="covariates/upr_u.tif",
    "wd0107a0"="covariates/wd0107a0.tif",
    "wd0107mn"="covariates/wd0107mn.tif",
    "wd0107mx"="covariates/wd0107mx.tif",
    "wd0114a0"="covariates/wd0114a0.tif",
    "wd0114mn"="covariates/wd0114mn.tif",
    "wd0114mx"="covariates/wd0114mx.tif",
    "worldpop"="covariates/worldpop_gpwv4_mosaic_export_5k_MG_Reallocated_filled.tif"
  )
  
  all_discrete <- list(
    "access"=FALSE,
    "aegypti"=FALSE,
    "albo"=FALSE,
    "c01"=FALSE,
    "c02"=FALSE,
    "c03"=FALSE,
    "c04"=FALSE,
    "c05"=FALSE,
    "c06"=FALSE,
    "c07"=FALSE,
    "c08"=FALSE,
    "c09"=FALSE,
    "c10"=FALSE,
    "c11"=FALSE,
    "c12"=FALSE,
    "c13"=FALSE,
    "c14"=FALSE,
    "c15"=FALSE,
    "c16"=FALSE,
    "duffy"=FALSE,
    "evi_mean"=FALSE,
    "evi_sd"=FALSE,
    "gecon"=FALSE,
    "lst_day_mean"=FALSE,
    "lst_day_sd"=FALSE,
    "lst_night_mean"=FALSE,
    "lst_night_sd"=FALSE,
    "mod_dem"=FALSE,
    "prec57a0"=FALSE,
    "prec57a1"=FALSE,
    "prec57a2"=FALSE,
    "prec57mn"=FALSE,
    "prec57mx"=FALSE,
    "tcb_mean"=FALSE,
    "tcb_sd"=FALSE,
    "tcw_mean"=FALSE,
    "tcw_sd"=FALSE,
    "tempaucpf"=FALSE,
    "tempaucpv"=FALSE,
    "tempsuit"=FALSE,
    "upr_p"=TRUE,
    "upr_u"=TRUE,
    "wd0107a0"=FALSE,
    "wd0107mn"=FALSE,
    "wd0107mx"=FALSE,
    "wd0114a0"=FALSE,
    "wd0114mn"=FALSE,
    "wd0114mx"=FALSE,
    "worldpop"=FALSE
  )

  covariate_diseases <- list(
    "cchf"=  c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "lst_day_mean", "lst_day_sd", "lst_night_mean", "lst_night_sd", "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "chik"=  c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "tempsuit",                                                     "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "deng"=  c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "tempsuit",                                                     "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "hat"=   c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "lst_day_mean", "lst_day_sd", "lst_night_mean", "lst_night_sd", "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "melio"= c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "lst_day_mean", "lst_day_sd", "lst_night_mean", "lst_night_sd", "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "nwcl"=  c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "lst_day_mean", "lst_day_sd", "lst_night_mean", "lst_night_sd", "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "owcl"=  c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "lst_day_mean", "lst_day_sd", "lst_night_mean", "lst_night_sd", "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop"),
    "scrub"= c("c01", "c02", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "access", "evi_mean", "evi_sd", "gecon", "lst_day_mean", "lst_day_sd", "lst_night_mean", "lst_night_sd", "mod_dem", "tcb_mean", "tcb_sd", "tcw_mean", "tcw_sd", "worldpop")
  )
  
  covariate_path <- all_covs[covariate_diseases[[disease]]]
  discrete <- all_discrete[covariate_diseases[[disease]]]
  
  # Functions to assist in the loading of raster data. 
  # This works around the truncation of crs metadata in writen geotiffs.
  abraidCRS <- crs("+init=epsg:4326")
  abraidStack <- function(paths) {
    s <- stack(paths)
    crs(s) <- abraidCRS
    extent(s) <- extent(-180, 180, -60, 85)
    return (s)
  }
  abraidRaster <- function(path) {
    r <- raster(path)
    crs(r) <- abraidCRS
    extent(r) <- extent(-180, 180, -60, 85)
    return (r)
  }
  
  # ~~~~~~~~
  # load data
  
  # occurrence data
  occurrence <- read.csv(occurrence_path, stringsAsFactors = FALSE)
  occurrence <- occurrence2SPDF(occurrence, crs=abraidCRS)
  
  # load the definitve extent raster
  extent <- abraidRaster(extent_path)
  
  # load the admin rasters as a stack
  admin <- abraidStack(admin_path)
  
  if (!use_temporal_covariates) {
    # For our data sets selectLatestCovariates is simple enough (will pick 2012 layer),
    # for more complex covariate sets a better approach may be nessesary
    # load_stack = noop, we just want the strings
    covariate_path <- selectLatestCovariates(covariate_path, load_stack=function(x) { return (x) })
  }
  
  # get the required number of cpus
  nboot <- 64

  # start the cluster
  sfInit(parallel = TRUE, cpus = nboot)
  
  # load seegSDM and dependencies on every cluster
  sfLibrary(seegSDM)

  cat('\nseegSDM loaded on cluster\n\n')

  # prepare absence data
  if (mode == 'bhatt') {
    sub <- function(i, pars) {
      # get the $i^{th}$ row of pars 
      pars[i, ]
    }
    
    # set up range of parameters for use in `extractBhatt`
    # use a similar, but reduced set to that used in Bhatt et al. (2013)
    # for dengue.
    
    # number of pseudo-absences per occurrence
    na <- c(1, 4, 8, 12)
    
    # number of pseudo-presences per occurrence (none)
    np <- c(0, 0, 0, 0)
    
    # maximum distance from occurrence data
    mu <- c(10, 20, 30, 40)
    
    # get all combinations of these
    pars <- expand.grid(na = na,
                        np = np,
                        mu = mu)
    
    # convert this into a list
    par_list <- lapply(1:nrow(pars),
                       sub,
                       pars)
    
    # generate pseudo-data in parallel
    data_list <- sfLapply(par_list,
                          seegSDM:::abraidBhatt,
                          occurrence = occurrence,
                          covariates = covariate_path,
                          consensus = extent,
                          admin = admin, 
                          factor = discrete,
                          admin_mode = admin_extract_mode,
                          load_stack = abraidStack)
    cat('extractBhatt done\n\n')
  } else if (substr(mode, 1, 4) == "bias") {
    # Load bias data
    supplementary_occurrence <- read.csv(supplementary_occurrence_path, stringsAsFactors = FALSE)
    supplementary_occurrence <- occurrence2SPDF(supplementary_occurrence, crs=abraidCRS)
    
    presence <- occurrence
    presence <- occurrence2SPDF(cbind(PA=1, presence@data), crs=abraidCRS)
    absence <- supplementary_occurrence
    absence <- occurrence2SPDF(cbind(PA=0, absence@data[, 1:2], Weight=1, absence@data[, 3:6]), crs=abraidCRS)
    
    disease_filters <- list(
      'bacteria'=c(34, 35, 43, 48, 52, 64, 71, 92, 132, 135, 187, 192, 193, 194, 199, 201, 211, 245, 266, 271, 284, 304, 315, 325, 340, 343, 351, 361, 362, 364, 367, 377, 34, 35, 43, 48, 52, 64, 71, 92, 132, 135, 187, 192, 193, 194, 199, 201, 211, 245, 266, 271, 284, 304, 315, 325, 340, 343, 351, 361, 362, 364, 367, 377, 34, 35, 43, 48, 52, 64, 71, 92, 132, 135, 187, 192, 193, 194, 199, 201, 211, 245, 266, 271, 284, 304, 315, 325, 340, 343, 351, 361, 362, 364, 367, 377, 34, 35, 43, 48, 52, 64, 71, 92, 132, 135, 187, 192, 193, 194, 199, 201, 211, 245, 266, 271, 284, 304, 315, 325, 340, 343, 351, 361, 362, 364, 367, 377),
      'fungus'=c(72, 80, 152, 254, 331),
      'parasite'=c(22, 26, 41, 81, 84, 93, 96, 109, 118, 119, 131, 133, 157, 171, 202, 215, 240, 255, 258, 341, 349, 350, 353, 356, 359, 360),
      'prion'=c(78),
      'virus'=c(4, 42, 60, 74, 79, 85, 87, 97, 98, 141, 142, 143, 144, 145, 149, 154, 159, 164, 173, 186, 208, 220, 222, 234, 277, 278, 286, 290, 302, 305, 307, 313, 332, 374, 386, 387, 391, 393)
    )
    if (filter_bias) {
      # Filter by disease type
      if (as.character(disease_type) %in% names(disease_filters)) {
        absence <- absence[absence$Disease %in% disease_filters[[disease_type]], ]
        cat('filtered bias to disease subset\n\n')
      }
    } else {
      if (as.character(disease_type) %in% names(disease_filters)) {
        absence <- absence[absence$Disease %in% unlist(disease_filters, use.names=FALSE), ]
        cat('filtered bias to all classified diseases \n\n')
      }
    }
    
    if (crop_bias) {
      # Filter to consensus
      absence_consensus <- extractBatch(absence, list("consensus"=extent), list("consensus"=TRUE), admin, admin_mode="latlong", load_stack=abraidStack)
      absence_cropped <- !is.na(absence_consensus$consensus) & (absence_consensus$consensus == 100 | absence_consensus$consensus == 50)
      absence <- absence[absence_cropped, ]
      cat('filtered bias to extent\n\n')
    }

    all <- rbind(presence, absence)
    
    # create batches
    batches <- replicate(nboot, subsample(all@data, nrow(all), replace=TRUE), simplify=FALSE)
    batches <- lapply(batches, occurrence2SPDF, crs=abraidCRS)
    cat('batches ready for extract\n\n')

    # Do extractions
    data_list <- sfLapply(batches,
                          extractBatch,
                          covariates = covariate_path,
                          admin = admin, 
                          factor = discrete,
                          admin_mode = admin_extract_mode)
  } else if (mode == "uniform") {
    batches <- sfLapply(1:64, function(i, presence_points=NA, disease_extent=NA, target_crs=NA, limit_sample=NA) {
      presence_points <- occurrence2SPDF(cbind(PA=1, presence_points@data), crs=target_crs)
      if (limit_sample) {
        keep <- c(100,50)
      } else {
        keep <- c(100,50,0,-50,-100)
      }
      selection_mask <- calc(disease_extent, function (cells) {
        return (ifelse(cells %in% keep, 1, 0))
      })
      absence <- bgSample(selection_mask, n=nrow(presence_points), prob=TRUE, replace=TRUE, spatial=FALSE)
      absence <- seegSDM:::xy2AbraidSPDF(absence, target_crs, 0, 1, sample(presence_points$Date, nrow(presence_points), replace=TRUE))
      all <- rbind(presence_points, absence)
      return(all)
    },
      presence_points=occurrence, 
      disease_extent=extent, 
      target_crs=abraidCRS, 
      limit_sample=crop_bias)
    
    cat('random bias generated\n\n')
    # Do extractions
    data_list <- sfLapply(batches,
                          extractBatch,
                          covariates = covariate_path,
                          admin = admin, 
                          factor = discrete,
                          admin_mode = admin_extract_mode)
  } else {
    exit(1)
  }
  
  cat('extraction done\n\n')

  if (use_weights) {
    # balance weights
    data_list <- sfLapply(data_list, seegSDM:::balanceWeights)
    cat('balance done\n\n')
    
    # run BRT submodels in parallel
    model_list <- sfLapply(data_list,
                           runBRT,
                           wt = 'Weight',
                           gbm.x = names(covariate_path),
                           gbm.y = 'PA',
                           pred.raster = selectLatestCovariates(covariate_path, load_stack=abraidStack),
                           gbm.coords = c('Longitude', 'Latitude'),
                           verbose = TRUE)
    cat('model fitting done (with weights)\n\n')
  } else {
    # balance weights
    data_list <- lapply(data_list, function (extracted_batch) {
      return (extracted_batch[, names(extracted_batch) != 'Weight', drop=FALSE])
    })
    
    # run BRT submodels in parallel
    model_list <- sfLapply(data_list,
                           runBRT,
                           gbm.x = names(covariate_path),
                           gbm.y = 'PA',
                           pred.raster = selectLatestCovariates(covariate_path, load_stack=abraidStack),
                           gbm.coords = c('Longitude', 'Latitude'),
                           verbose = TRUE)
    cat('model fitting done (without weights)\n\n')
  }

  # get cross-validation statistics in parallel
  stat_lis <- sfLapply(model_list,
                       getStats)
  
  cat('statistics extracted\n\n')

  # combine and output results
  
  # make a results directory
  dir.create(paste0("results/",name), recursive = TRUE)
  
  # cross-validation statistics (with pairwise-weighted distance sampling)
  stats <- do.call("rbind", stat_lis)
  
  # keep only the relevant statistics
  stats <- stats[, c('auc', 'sens', 'spec', 'pcc', 'kappa',
                     'auc_sd', 'sens_sd', 'spec_sd', 'pcc_sd', 'kappa_sd')]
  
  # write stats to disk
  write.csv(stats,
            paste0("results/",name,'/statistics.csv'),
            na = "",
            row.names = FALSE)
  
  # relative influence statistics
  relinf <- getRelInf(model_list)
  
  # append the names to the results
  relinf <- cbind(name = rownames(relinf), relinf)
  
  # output this file
  write.csv(relinf,
            paste0("results/",name,'/relative_influence.csv'),
            na = "",
            row.names = FALSE)
  
  # marginal effect curves
  effects <- getEffectPlots(model_list)
  
  # convert the effect curve information into the required format
  
  # keep only the first four columns of each dataframe
  effects <- lapply(effects,
                    function (x) {
                      x <- x[, 1:4]
                      names(x) <- c('x',
                                    'mean',
                                    'lower',
                                    'upper')
                      return(x)
                    })
  
  # paste the name of the covariate in as extra columns
  for(i in 1:length(effects)) {
    
    # get number of evaluation points
    n <- nrow(effects[[i]])
    
    # append name to effect curve
    effects[[i]] <- cbind(name = rep(names(effects)[i], n),
                          effects[[i]])
  }
  
  # combine these into a single dataframe
  effects <- do.call(rbind, effects)
  
  # clean up the row names
  rownames(effects) <- NULL
  
  # save the results
  write.csv(effects,
            paste0("results/",name,'/effect_curves.csv'),
            na = "",
            row.names = FALSE)
  
  # get summarized prediction raster layers
  
  # lapply to extract the predictions into a list
  preds <- lapply(model_list,
                  function(x) {x$pred})
  
  # coerce the list into a RasterStack
  preds <- stack(preds)
  
  # summarize predictions
  preds <- combinePreds(preds, parallel=TRUE)

  # stop the cluster
  sfStop()
  
  # get the width of the 95% confidence envelope as a metric of uncertainty
  uncertainty <- preds[[4]] - preds[[3]]
  
  # save the mean predicitons and uncerrtainty as rasters
  writeRaster(preds[[1]],
              paste0("results/",name,'/mean_prediction'),
              format = 'GTiff',
              NAflag = -9999,
              options = c("COMPRESS=DEFLATE",
                          "ZLEVEL=9"),
              overwrite = TRUE)
  
  writeRaster(uncertainty,
              paste0("results/",name,'/prediction_uncertainty'),
              format = 'GTiff',
              NAflag = -9999,
              options = c("COMPRESS=DEFLATE",
                          "ZLEVEL=9"),
              overwrite = TRUE)
  
  ###crop/mask
  water <- abraidRaster(water_mask)
  mean <- preds[[1]]
  mean <- mask(mean, extent, maskvalue=-100, updatevalue=9999)
  uncertainty <- mask(uncertainty, extent, maskvalue=-100, updatevalue=9999)
  mean <- mask(mean, extent)
  uncertainty <- mask(uncertainty, extent)
  mean <- mask(mean, water, inverse=TRUE)
  uncertainty <- mask(uncertainty, water, inverse=TRUE)
  
  writeRaster(mean,
              paste0("results/",name,'/mean_prediction_masked'),
              format = 'GTiff',
              NAflag = -9999,
              options = c("COMPRESS=DEFLATE",
                          "ZLEVEL=9"),
              overwrite = TRUE)
  
  writeRaster(uncertainty,
              paste0("results/",name,'/prediction_uncertainty_masked'),
              format = 'GTiff',
              NAflag = -9999,
              options = c("COMPRESS=DEFLATE",
                          "ZLEVEL=9"),
              overwrite = TRUE)
  
  cols <- colorRampPalette(c('#91ab84', '#c3d4bb', '#ffffcb', '#cf93ba', '#a44883'))
   
  png(paste0("results/",name,'/effects.png'),
      width = 2000,
      height = 2500,
      pointsize = 30)
  
  par(mfrow = n2mfrow(length(covariate_path)))
  
  getEffectPlots(model_list, plot = TRUE)
  
  dev.off()
     
  if (mode=="bias") {
    write.csv(absence,
              paste0("results/",name,'/absence.csv'),
              na = "",
              row.names = FALSE)
  }
  
  # return an exit code of 0, as in the ABRAID-MP code
  return (0)
}