#!/usr/bin/env python
import sys, os, math
from time import sleep
import numpy as np
from pathlib import Path
import pygmt
from osgeo import gdal
from osgeo import ogr
from osgeo import osr
import pymeshlab as ml
from tqdm import trange

# Bathymetry Converter - automation script
###################################################################
PREFIX = 'MontereyBay'
SOURCE = 'bathymetry_source/monterey_13_navd88_2012.nc'
# Range
STARTLON = -121.825
STARTLAT = 36.790
ENDLON = -121.805
ENDLAT = 36.810
# Resolution
DLON = 0.01
DLAT = 0.01
OVERLON = 0.0005
OVERLAT = 0.0005
###################################################################
TEMPLATE_DIR = '/Bathymetry_Converter/'

print("\n")
print("#--------------------------------------------------------#")
print("#----------------  Bathymetry Converter  ----------------#")
print("#--------------------------------------------------------#")
print("# Prefix : " + PREFIX)
print("# Source : " + SOURCE)
print("# Range -- Latitude (N) : " + repr(STARTLAT) + " ~ " + repr(ENDLAT))
print("#       \_ longitude(E) : " + repr(STARTLON) + " ~ " + repr(ENDLON))
print("# Resolution -- Latitude  : " + repr(DLAT) + " with " + repr(OVERLAT) + " overlaps")
print("#            \_ longitude : " + repr(DLON) + " with " + repr(OVERLON) + " overlaps")
print("#--------------------------------------------------------#\n")

nLon = int(math.ceil((ENDLON-OVERLON-STARTLON)/DLON))
nLat = int(math.ceil((ENDLAT-OVERLAT-STARTLAT)/DLAT))
nTot = nLon * nLat

# Make bathymetry directory (if not exist)
Path('bathymetry').mkdir(parents=True, exist_ok=True) # Template directory
Path(PREFIX).mkdir(parents=True, exist_ok=True) # Final product directory
PATH = "bathymetry/"

# Reproject into WGS (EPSG:4326)
print("Initiating... (It may take longer to initiate for large source")
os.system("PROJ_NETWORK=ON gdalwarp -t_srs 'EPSG:4326' -of GMT " \
          + SOURCE + " " + PATH + PREFIX + '.grd')

# Get No Data Value (to skip later)
source = gdal.Open(SOURCE)
band = source.GetRasterBand(1)
NoDataValue = band.GetNoDataValue()

longitude = STARTLON
latitude = STARTLAT
# Loop longitude
for lon in trange(nLon):

    west = longitude
    east = longitude + DLON
    west_edge = longitude - OVERLON
    east_edge = east + OVERLON

    # Loop latitude
    for lat in range(nLat):

        south = latitude
        north = latitude + DLAT
        south_edge = latitude - OVERLAT
        north_edge = north + OVERLAT

        # Create output filename
        tileName = "R_" + "{:.3f}".format(west) + '_' + "{:.3f}".format(east) \
                   + '_' + "{:.3f}".format(south) + '_' + "{:.3f}".format(north)

        # Cut and translate into XYZ point cloud (verbose error only)
        xyz = pygmt.grd2xyz(PATH + PREFIX + '.grd', output_type='numpy', \
             verbose='e', region=[west_edge, east_edge, south_edge, north_edge])

        # Transform project coordniate system from WGS(EPSG:4326) to UTM(EPSG:3857)
        source = osr.SpatialReference(); source.ImportFromEPSG(4326)
        target = osr.SpatialReference(); target.ImportFromEPSG(3857)
        transform = osr.CoordinateTransformation(source, target)
        for pt in xyz:
            if pt[2] == NoDataValue or np.isnan(pt[2]):
                pt[2] = -9999
            point = ogr.CreateGeometryFromWkt( \
                    "POINT (" + repr(pt[1]) + " " + repr(pt[0]) + ")")
            point.Transform(transform)
            pt[0] = point.ExportToWkt().split(" ")[1].split("(")[1]
            pt[1] = point.ExportToWkt().split(" ")[2].split(")")[0]

        # Save asc file with 'X Y Z' header for meshlab
        filename = PATH + PREFIX + "." + tileName + '.epsg3857'
        np.savetxt(filename + '.meshlab.asc', xyz, fmt='%10.5f', delimiter=' ')
        os.system("sed -i '1 i\X Y Z' " + filename + '.meshlab.asc')

        # Save asc (without header) file after sorting
        # https://gdal.org/drivers/raster/xyz.html
        # starting with GDAL 3.2.1, cells with same X coordinates must
        # be placed on consecutive lines. For a same X coordinate value,
        # the columns must be organized by increasing or decreasing Y values.
        index = np.lexsort((xyz[:,1],xyz[:,0]))
        np.savetxt(filename + '.asc', xyz[index], fmt='%10.5f', delimiter=' ')

        # Make texture using colormap
        gdal.Translate(filename + '.tif', filename + '.asc', \
              options='-of GTiff -a_srs EPSG:3857')
        gdal.DEMProcessing(filename + '.color.tif', filename + '.tif', "color-relief", \
              colorFilename=TEMPLATE_DIR+'color.txt')
        texture = gdal.Translate(filename + '.texture.png', filename + '.color.tif', \
              options='-of PNG -ot UInt16 -scale 32.53501 767.4913 0 65535')

        # Make mesh (obj) with meshlab
        ms = ml.MeshSet()
        ms.load_new_mesh(filename + '.meshlab.asc', triangulate=True)
        ms.apply_filter('taubin_smooth')
        ms.apply_filter('invert_faces_orientation')
        ms.apply_filter('parametrization_flat_plane', projectionplane='XY')
        ms.save_current_mesh(filename + '.obj')
        sys.stdout.write("\033[F"+"\r") # supress load_new_mesh output

        # Construct model object
        TEMPLATE_PATH = TEMPLATE_DIR + 'templates'
        MODEL_URI = PREFIX + "." + tileName + '.epsg3857'
        MODEL_DIR = filename
        Path(MODEL_DIR + "/mesh").mkdir(parents=True, exist_ok=True)
        os.system("cp " + MODEL_DIR + ".obj " + MODEL_DIR + "/mesh/" )
        os.system("cp " + MODEL_DIR + ".obj.mtl " + MODEL_DIR + "/mesh/" )

        # create model.config
        os.system("cat " + TEMPLATE_PATH + "/model.config | sed s#MODEL_NAME#" + PREFIX + "." + tileName + "#g > " + MODEL_DIR + "/model.config")

        # create model.sdf
        os.system("cat " + TEMPLATE_PATH + "/model.sdf > " + MODEL_DIR +"/model.sdf")
        os.system("sed -i s#MODEL_NAME#" + PREFIX + "." + tileName + "#g " + MODEL_DIR + "/model.sdf")
        os.system("sed -i s#MODEL_URI#model://" + MODEL_URI + "/mesh/" + MODEL_URI + ".obj#g " + MODEL_DIR + "/model.sdf")

        # Create material
        os.system("cp -r " + TEMPLATE_PATH + "/materials " + MODEL_DIR + "/.")
        os.system("cp " + MODEL_DIR + ".texture.png " + MODEL_DIR + "/materials/textures/.")
        os.system("sed -i s#MODEL_NAME#" + PREFIX + "." + tileName + "#g " + MODEL_DIR + "/materials/scripts/texture.material")
        os.system("sed -i s#TEXTURE_NAME#" + MODEL_URI + ".texture.png#g " + MODEL_DIR + "/materials/scripts/texture.material")
        os.system("sed -i s#TEXTURE_URI#model://" + MODEL_URI + "#g " + MODEL_DIR + "/model.sdf")

        # Relocate final product
        os.system("cp -r " + MODEL_DIR + " " + PREFIX + "/.")

        # update latitude
        latitude = north

    # update longitude
    longitude = east
    latitude = STARTLAT

# Remove template directory
os.system("rm -r bathymetry")

# DONE!
print("\n Done.\n")
