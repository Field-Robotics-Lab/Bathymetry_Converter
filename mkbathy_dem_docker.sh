
#!/bin/bash
   gdalinfo bathymetry_source/monterey_13_navd88_2012.nc
   echo " "
   echo " "
    UpperLeftX=$(gdalinfo bathymetry_source/monterey_13_navd88_2012.nc 2>/dev/null | grep -oP 'Upper Left  \(\K[^\)\,]+')
    LowerLeftX=$(gdalinfo bathymetry_source/monterey_13_navd88_2012.nc 2>/dev/null | grep -oP 'Lower Right \(\K[^\)\,]+')
    echo $UpperLeftX
    echo $LowerLeftX

    TEXTURE_SIZE=$(awk "BEGIN {print $LowerLeftX - $UpperLeftX}")

    echo $TEXTURE_SIZE
    echo $TEXTURE_SIZE
    echo $TEXTURE_SIZE

    x=$(gdalinfo monterey_13_navd88_2012.nc 2>/dev/null | grep ^Origin)
    echo $x
# Bathymetry Converter automation script
#######################################################################

## ---------- Puerto Rico ------------ ##
PREFIX=MontereyBay
SRC=bathymetry_source/monterey_13_navd88_2012.nc
COLORMAP=color_calm.txt

# 1000 m x 1000 m, roughly.  Good for NCEI 1/9 arc-second
DLON=0.01
DLAT=0.01
OVERLON=0.0005
OVERLAT=0.0005

# Puerto Rico
STARTLON=-121.825
STARTLAT=36.790
ENDLON=-121.805
ENDLAT=36.810
#STARTLON=-67.440
#STARTLAT=17.855
#ENDLON=-66.939
#ENDLAT=18.195

## ---------- Buzz Bay ------------ ##
# PREFIX=buzzBay
# SRC=bathymetry_source/BuzzBay_10m.tif

# # 1000 m x 1000 m, roughly.  Good for NCEI 1/9 arc-second
# DLON=0.010
# DLAT=0.010
# OVERLON=0.0005
# OVERLAT=0.0005

# STARTLON=-70.70
# STARTLAT=41.50
# ENDLON=-70.65
# ENDLAT=41.60
# # STARTLON=-70.699
# # STARTLAT=41.509
# # ENDLON=-70.611
# # ENDLAT=41.529
#######################################################################

MLX=bathy.mlx
mkdir -p bathymetry_dem

gdalwarp -t_srs "EPSG:4326" $SRC bathymetry_dem/$PREFIX.tif
gdal_translate -of GMT bathymetry_dem/$PREFIX.tif bathymetry_dem/$PREFIX.grd

lat=$STARTLAT
lon=$STARTLON
while [[ $(calc "($lon < $ENDLON)") -eq 1 ]]; do

    elon=$(calc -p "($lon+$DLON)")
    sslon=$(calc -p "($lon-$OVERLON)")
    eelon=$(calc -p "($elon+$OVERLON)")

    while [[ $(calc "($lat < $ENDLAT)") -eq 1 ]]; do

		elat=$(calc -p "($lat+$DLAT)")
		sslat=$(calc -p "($lat-$OVERLAT)")
		eelat=$(calc -p "($elat+$OVERLAT)")

		echo $lon $elon $lat $elat
		echo $sslon $eelon $sslat $eelat

		# create output filename
		fname=$(printf R_%.03f_%.03f_%0.3f_%.03f $lon $elon $lat $elat)

		# cut the lat/lon grid to this region.
		echo "Cut to region..."
		gmt grdcut bathymetry_dem/$PREFIX.grd -Gbathymetry_dem/$PREFIX.$fname.grd -R$sslon/$eelon/$sslat/$eelat

		# translate into a list of points for reprojection.
		echo "Translate for reprojection..."
		gmt grd2xyz bathymetry_dem/$PREFIX.$fname.grd > bathymetry_dem/$PREFIX.$fname.xyz
		sed -i 's#\t# #g' bathymetry_dem/$PREFIX.$fname.xyz

		echo "Project..."
    cat  bathymetry_dem/$PREFIX.$fname.xyz |  gdaltransform -s_srs EPSG:4326 -t_srs EPSG:3857 -output_xy >> bathymetry_dem/$PREFIX.$fname.asc
    echo "Combine..."
		python3 /Bathymetry_Converter/mkbathy_dependencies/combine.py bathymetry_dem/$PREFIX.$fname.xyz bathymetry_dem/$PREFIX.$fname.asc bathymetry_dem/$PREFIX.$fname.epsg3857.asc.tmp
    echo "Sort..."
    python3 sort.py bathymetry_dem/$PREFIX.$fname.epsg3857.asc.tmp bathymetry_dem/$PREFIX.$fname.epsg3857.asc

		# translate into USGSDEM
		echo "Generate DEM..."
    gdal_translate -of GTiff -a_srs EPSG:3857 -unscale bathymetry_dem/$PREFIX.$fname.epsg3857.asc bathymetry_dem/$PREFIX.$fname.epsg3857.tif

    echo "Generate texture..."
    # generate color texture
    gdaldem color-relief bathymetry_dem/$PREFIX.$fname.epsg3857.tif $COLORMAP bathymetry_dem/$PREFIX.$fname.epsg3857.color.tif
    gdal_translate -of PNG -ot UInt16 -scale 32.53501 767.4913 0 65535 bathymetry_dem/$PREFIX.$fname.epsg3857.color.tif bathymetry_dem/$PREFIX.$fname.epsg3857.texture.png
    UpperLeftX=$(gdalinfo bathymetry_dem/$PREFIX.$fname.epsg3857.texture.png 2>/dev/null | grep -oP 'Upper Left  \(\K[^\)\,]+')
    LowerLeftX=$(gdalinfo bathymetry_dem/$PREFIX.$fname.epsg3857.texture.png 2>/dev/null | grep -oP 'Lower Right \(\K[^\)\,]+')
    TEXTURE_SIZE=$(awk "BEGIN {print $LowerLeftX - $UpperLeftX}")

		# put the final product in a folder that conforms to gazebo model database structure
		MODEL_URI=$PREFIX.$fname.epsg3857
		MODEL_DIR=bathymetry_dem/$MODEL_URI
		mkdir -p $MODEL_DIR/heightmap
		cp bathymetry_dem/$PREFIX.$fname.epsg3857.tif $MODEL_DIR/heightmap/
		cp bathymetry_dem/$PREFIX.$fname.epsg3857.texture.png $MODEL_DIR/heightmap/

		# create model.config
		cat templates/model.config | sed s#MODEL_NAME#$PREFIX.$fname#g > $MODEL_DIR/model.config

		# create model.sdf
    COORD="$(gdalinfo bathymetry_dem/$PREFIX.$fname.epsg3857.tif 2>/dev/null | grep -oP 'Center      \(\K[^\)]+' | sed 's/,/\ /g') 0.0"
		cat templates/model.sdf > $MODEL_DIR/model.sdf
    sed -i s#MODEL_NAME#$PREFIX.$fname#g $MODEL_DIR/model.sdf
    sed -i s#MODEL_URI#model://$MODEL_URI/heightmap/$MODEL_URI.tif#g $MODEL_DIR/model.sdf
    sed -i "s#MODEL_LOC#$COORD#g" $MODEL_DIR/model.sdf
    sed -i s#TEXTURE_URI#model://$MODEL_URI/heightmap/$MODEL_URI.texture.png#g $MODEL_DIR/model.sdf
    sed -i "s#TEXTURE_SIZE#$TEXTURE_SIZE#g" $MODEL_DIR/model.sdf

	  echo " "
		#exit 0

		lat=$elat

    done # while lat

    lon=$elon
    lat=$STARTLAT

	echo " "
	echo " "

done # while lon


# delete temp files ecept model directories
rm bathymetry_dem/*
