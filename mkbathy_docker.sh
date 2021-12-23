
#!/bin/bash

# Bathymetry Converter automation script
#######################################################################

## ---------- Puerto Rico ------------ ##
PREFIX=puertoRico
SRC=bathymetry_source/mayaguez_13_mhw_2007.tif

# 1000 m x 1000 m, roughly.  Good for NCEI 1/9 arc-second
DLON=0.010
DLAT=0.010
OVERLON=0.0005
OVERLAT=0.0005

# Puerto Rico
STARTLON=-67.30
STARTLAT=17.90
ENDLON=-67.20
ENDLAT=17.95
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

MLX=/Bathymetry_Converter/mkbathy_dependencies/bathy.mlx
mkdir -p bathymetry

gdalwarp -t_srs "EPSG:4326" $SRC bathymetry/$PREFIX.tif
gdal_translate -of GMT bathymetry/$PREFIX.tif bathymetry/$PREFIX.grd

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
		gmt grdcut bathymetry/$PREFIX.grd -Gbathymetry/$PREFIX.$fname.grd -R$sslon/$eelon/$sslat/$eelat

		# translate into a list of points for reprojection.
		echo "Translate for reprojection..."
		gmt grd2xyz bathymetry/$PREFIX.$fname.grd > bathymetry/$PREFIX.$fname.xyz
		sed -i 's#\t# #g' bathymetry/$PREFIX.$fname.xyz # gmt though produces xyz separated by tabs.  gdaltransform silently ignores.

		# generate approximate bounds in projected coordinate system and insert these into filename.
		#proj=($(echo $lon $lat 0 | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:26987))
		#sproje=$(calc -p "round(${proj[0]})")
		#sprojn=$(calc -p "round(${proj[1]})")
		#proj=($(echo $elon $elat 0 | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:26987))
		#eproje=$(calc -p "round(${proj[0]})")
		#eprojn=$(calc -p "round(${proj[1]})")
		#projfname=R$sproje.$eproje.$sprojn.$eprojn
		#echo $projfname
		# Much easier to search in regular lat/lon grid.
		projfname=$fname

		echo "Project..."
		# Save x/y value
		cat  bathymetry/$PREFIX.$fname.xyz |  gdaltransform -s_srs EPSG:4326 -t_srs EPSG:3857 -output_xy >> bathymetry/$PREFIX.$projfname.asc
		echo "Combine..."
		python3 /Bathymetry_Converter/mkbathy_dependencies/combine.py bathymetry/$PREFIX.$fname.xyz bathymetry/$PREFIX.$projfname.asc bathymetry/$PREFIX.$projfname.epsg3857.asc

		# while IFS=$'\t' read -r asc xyz
		# do
        #     A="$(cut -d' ' -f3 <<<"$xyz")"
        #     echo $(printf '%s' "$asc $A") >> bathymetry/$PREFIX.$projfname.epsg3857.asc
		# done < <(paste bathymetry/$PREFIX.$projfname.asc bathymetry/$PREFIX.$fname.xyz)
		sed -i '1s/^/X Y Z\n/' bathymetry/$PREFIX.$projfname.epsg3857.asc # header will be necessary in next step.

		# while IFS=$'\t' read -r asc xyz
		# do
        #     A="$(cut -d' ' -f3 <<<"$xyz")"
        #     echo $(printf "$asc $A \n") >> $name.a
		# done < <(paste $name.asc $name.xyz)

		# 2D delaunay translation to generate a ply file to import into meshlab for simplification and texture mapping.  Requires pdal >= 1.9  (i.e. compile from source)
		# Single core...  Use blah&; blah&; wait
		# This produces walls at the edges where the mesh is concave.  convex edges work fine.
		echo "Start triangulation..."
		pdal translate --reader text -i bathymetry/$PREFIX.$projfname.epsg3857.asc -o bathymetry/$PREFIX.$projfname.epsg3857.ply --writers.ply.faces=true -f delaunay
		# greedymesh (now called greedyprojection) should be much more suited to this, but it segfaults without any useful error even with debugging turned on.  I doubt these
		# clouds are too big.  Could be the numbers are too big?  No.  small files and small numbers made no difference.
		#pdal translate --reader text -i bathymetry/$PREFIX.$projfname.epsg26987.asc -o bathymetry/$PREFIX.$projfname.epsg26987.ply --writers.ply.faces=true -f greedyprojection  --filters.greedyprojection.multiplier=2 --filters.greedyprojection.radius=4
		echo "Done."

		# Simplify in meshlab and get rid of spurious faces at edges from triangulation.  Vertex normals need to be retained.
		#meshlabserver -i bathymetry/$PREFIX.$projfname.epsg26987.ply -s /Bathymetry_Converter/mkbathy_dependencies/bathy.mlx -o bathymetry/$PREFIX.$projfname.epsg26987.obj -om vn
		# script bathy3.mlx works in version 2020.03.  many syntax changes between versions.
		xvfb-run -a -s "-screen 0 800x600x24" meshlabserver -i bathymetry/$PREFIX.$projfname.epsg3857.ply -s $MLX -o bathymetry/$PREFIX.$projfname.epsg3857.obj -m vn wt

		# texture map?!  Not useful for underwater stuff anyway and we can use tiling in gazebo.

		# put the final product in a folder that conforms to gazebo model database structure
		#@@@ move this from bathymetry/ obviously.
		MODEL_URI=$PREFIX.$projfname.epsg3857
		MODEL_DIR=bathymetry/$MODEL_URI
		mkdir -p $MODEL_DIR/meshes
		cp bathymetry/$PREFIX.$projfname.epsg3857.obj $MODEL_DIR/meshes/
		cp bathymetry/$PREFIX.$projfname.epsg3857.obj.mtl $MODEL_DIR/meshes/

		# create model.config
		cat /Bathymetry_Converter/mkbathy_dependencies/templates/model.config | sed s#MODEL_NAME#$PREFIX.$projfname#g > $MODEL_DIR/model.config

		# create model.sdf
		cat /Bathymetry_Converter/mkbathy_dependencies/templates/model.sdf | sed s#MODEL_NAME#$PREFIX.$projfname#g | sed s#MODEL_URI#model://$MODEL_URI/meshes/$MODEL_URI.obj#g  > $MODEL_DIR/model.sdf

		#exit 0

		lat=$elat

    done # while lat

    lon=$elon
    lat=$STARTLAT

	echo " "
	echo " "

done # while lon


# delete temp files ecept model directories
rm bathymetry/*
