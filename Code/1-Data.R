# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                     LIBRARIES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(raster)
library(sf)
library(magrittr)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   DOWNLOAD DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The data used to characterize inorganic pollution comes from the global
# cumulative impacts assessment on habitats (Halpern et al., 2015, 2008) and
# available on the NCEAS online data repository.
# https://knb.ecoinformatics.org/#view/doi:10.5063/F1S180FS
# For more information read the repo's README.md document

# Output location for downloaded data
output <- './Data/RawData'

# ID of file to download on repository
fileID <- data.frame(id     = 'inorganic',
                     year   = 2013,
                     link   = "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/raw_2013_inorganic_mol_20150714095441",
                     export = "raw_2013_inorganic_mol.zip",
                     stringsAsFactors = F)

# Build string to send wget command to the terminal throught R
wgetString <- paste0('wget --user-agent Mozilla/5.0 "',
                     fileID$link,
                     '" -O ',
                     output,
                     '/',
                     fileID$export)

# Download data using `wget`
system(noquote(wgetString), intern = T)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   IMPORT DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# File name
fileName <- dir(output, pattern = '.zip')

# Unzip kmz file
unzip(zipfile = paste0(output, '/', fileName),
      exdir = output)

# Identify newly extracted files
fileName <- dir(output, pattern = 'tif$', full.names = T)

# Import tif file
inorg <- raster(fileName)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   CLIP DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# We clip the data to the extent of the St. Lawrence to make it easier to work with
# Remove this part of the code if you wish to work with the global data or
# modify the extent if you want to use it on a different extent

# Study area extent
# Roughly selecting the St. Lawrence
ext <- c(xmin = -5750000, xmax = -4000000, ymin = 5350000, ymax = 6150000) %>%
       extent()

# Crop raster to extent
inorg <- crop(inorg, ext)

# Copy raster values to memory to that export is done properly
values(inorg) <- values(inorg)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                    FORMAT DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Modify projection
# We use the Lambert projection as a default, which allows us to work in meters
# rather than in degrees
prj <- st_crs(32198)$proj4string
inorg <- projectRaster(inorg, crs = prj)

# We also work with polygons rather than rasters, so we need to transform raster
# cells to polygons. Data could be left as rasters, but we elected to work with
# a hexagonal grid and so have decided to convert everything in polygons.
# Transform raster to polygon
inorg <- rasterToPolygons(inorg)

# Transform to sf object
inorg <- st_as_sf(inorg)

# Select only features with values > 0
id0 <- inorg$inorganic > 0
inorg <- inorg[id0, ]


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                  EXPORT DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Export object as .RData
save(inorg, file = './data/rawData/inorganic.RData')
