* The converter script was developed by Micahel Jakuba at WHOI and modified/implemented to the dave project by Woensug Choi.

![image](https://user-images.githubusercontent.com/7955120/149531647-2ba86a11-955d-4684-9d0b-bd53ea0fec3d.png)

## Proclaimer
The Gazebo includes direct uploads of DEM data on the simulator ([Gazebo tutorial for DEM link](http://gazebosim.org/tutorials?tut=dem&cat=build_world)). However, it handles only grids and suggests downsampling to coarse resolutions. Also, Gazebo only allow one heightmap per scene unable to change on the fly. The pipeline of this converter constructs simplified triangular meshes that retain detail where it is needed. The pipeline also creates overlap and generates tiles with the special/arbitrary filenames required by the plugin.

For tutorials, how to use the bathymetry tiles, please visit [Bathymetry Integration Wiki page](https://github.com/Field-Robotics-Lab/dave/wiki/Bathymetry-Integration) of the [Dave project](https://github.com/Field-Robotics-Lab/dave/wiki)

- Any bathymetry file (GeoTiFF, GMT, XYZ, and etc..) can be used as long as the GDAL library supports it
  - Current dockerized GDAL library supports followings
    ```bash
    ['VRT', 'DERIVED', 'GTiff', 'COG', 'NITF', 'RPFTOC', 'ECRGTOC', 'HFA', 'SAR_CEOS', 'CEOS', 'JAXAPALSAR', 'GFF', 'ELAS', 'ESRIC', 'AIG', 'AAIGrid', 'GRASSASCIIGrid', 'ISG', 'SDTS', 'DTED', 'PNG', 'JPEG', 'MEM', 'JDEM', 'GIF', 'BIGGIF', 'ESAT', 'FITS', 'BSB', 'XPM', 'BMP', 'DIMAP', 'AirSAR', 'RS2', 'SAFE', 'PCIDSK', 'PCRaster', 'ILWIS', 'SGI', 'SRTMHGT', 'Leveller', 'Terragen', 'GMT', 'netCDF', 'HDF4', 'HDF4Image', 'ISIS3', 'ISIS2', 'PDS', 'PDS4', 'VICAR', 'TIL', 'ERS', 'JP2OpenJPEG', 'L1B', 'FIT', 'GRIB', 'RMF', 'WCS', 'WMS', 'MSGN', 'RST', 'INGR', 'GSAG', 'GSBG', 'GS7BG', 'COSAR', 'TSX', 'COASP', 'R', 'MAP', 'KMLSUPEROVERLAY', 'WEBP', 'PDF', 'Rasterlite', 'MBTiles', 'PLMOSAIC', 'CALS', 'WMTS', 'SENTINEL2', 'MRF', 'TileDB', 'PNM', 'DOQ1', 'DOQ2', 'PAux', 'MFF', 'MFF2', 'FujiBAS', 'GSC', 'FAST', 'BT', 'LAN', 'CPG', 'IDA', 'NDF', 'EIR', 'DIPEx', 'LCP', 'GTX', 'LOSLAS', 'NTv2', 'CTable2', 'ACE2', 'SNODAS', 'KRO', 'ROI_PAC', 'RRASTER', 'BYN', 'ARG', 'RIK', 'USGSDEM', 'GXF', 'DODS', 'KEA', 'BAG', 'HDF5', 'HDF5Image', 'NWT_GRD', 'NWT_GRC', 'ADRG', 'SRP', 'BLX', 'PostGISRaster', 'SAGA', 'XYZ', 'HF2', 'OZI', 'CTG', 'ZMap', 'NGSGEOID', 'IRIS', 'PRF', 'RDA', 'EEDAI', 'EEDA', 'DAAS', 'SIGDEM', 'TGA', 'OGCAPI', 'STACTA', 'STACIT', 'GNMFile', 'GNMDatabase', 'ESRI Shapefile', 'MapInfo File', 'UK .NTF', 'LVBAG', 'OGR_SDTS', 'S57', 'DGN', 'OGR_VRT', 'REC', 'Memory', 'CSV', 'NAS', 'GML', 'GPX', 'LIBKML', 'KML', 'GeoJSON', 'GeoJSONSeq', 'ESRIJSON', 'TopoJSON', 'Interlis 1', 'Interlis 2', 'OGR_GMT', 'GPKG', 'SQLite', 'OGR_DODS', 'WAsP', 'PostgreSQL', 'OpenFileGDB', 'DXF', 'CAD', 'FlatGeobuf', 'Geoconcept', 'GeoRSS', 'GPSTrackMaker', 'VFK', 'PGDUMP', 'OSM', 'GPSBabel', 'OGR_PDS', 'WFS', 'OAPIF', 'EDIGEO', 'SVG', 'CouchDB', 'Cloudant', 'Idrisi', 'ARCGEN', 'XLS', 'ODS', 'XLSX', 'Elasticsearch', 'Carto', 'AmigoCloud', 'SXF', 'Selafin', 'JML', 'PLSCENES', 'CSW', 'VDV', 'GMLAS', 'MVT', 'NGW', 'MapML', 'TIGER', 'AVCBin', 'AVCE00', 'GenBin', 'ENVI', 'EHdr', 'ISCE', 'Zarr', 'HTTP']
    ```
- Can generate tiles at any position (lat/lon) if the bathymetry file exists
- Resolution (size of each tile), the size of the overlaping region can be defined
- The color texture is applied according to depths
- Everything is dockerized for dependencies

# Method 1: Run with precompiled docker image

## Step 1: Install Docker
* Follow the [Docker installation instructions](https://docs.docker.com/engine/install/ubuntu/).
* Complete the [Linux Postinstall steps](https://docs.docker.com/engine/install/linux-postinstall/) to allow you to manage Docker as a non-root user.

## Step 2: Prepare source bathymetry file and the shell script
- Targeting directory structure
```
working_dir (parent directory which will be mounted when running the docker image)
└── bathymetry_source
|    └── source bathymetry file (e.g. input.tif)
└── mkbathy.py
```

### Bathymetry source file location
Go to the working directory and make a child directory named with `bathymetry_source` and put the source bathymetry file inside.
- Where to find the source bathymetry file
  - `Continuously Updated Digital Elevation Model (CUDEM)` works amazingly with this converter
    - It can be access thorugh [NOAA Digital Coast: Data Access Viewer - CUDEM](https://coast.noaa.gov/dataviewer/#/lidar/search/where:ID=8483)
    - Draw region you want the data with 'Draw' button at the top left and request. It will take about 10 minutes to receive.
  - NOAA bathymetry database
    - It can be access through [NOAA Bathymetetric Data Viewer](https://www.ncei.noaa.gov/maps/bathymetry/)
    - Look for `Bathymetric Surveys / NOAA NOS Hydrographic Data / All Surveys with Digital Data` and `Digital Elevation Models / All DEMs`
    - For XYZ cloud point datasets, you may need to modify the format to match with [GDAL's ASCII XYZ format](https://gdal.org/drivers/raster/xyz.html)
      - > starting with GDAL 3.2.1, cells with same X coordinates must be placed on consecutive lines. For a same X coordinate value, the columns must be organized by increasing or decreasing Y values.
  - For all other datasets, you may rearrance and modify the format into GDAL's ASCII XYZ format
  - The ones by Multibeam surveys and Lidar datasets without continous bathymetry dataset has low compatability for converting process when generating mesh file and smoothing


### Download `mkbathy.py` script and make modifications
At the working directory
```bash
wget https://raw.githubusercontent.com/Field-Robotics-Lab/Bathymetry_Converter/master/mkbathy.py
```
You may want to change following parameters on top of the script,
- `PREFIX` : prefix for the model names
- `SOURCE`: path to source bathymetry file
- `STARTLON` : starting Longitude
- `STARTLAT` : starting Latitude
- `ENDLON` : ending Longitude
- `ENDLAT` : ending Latitude
- `DLON`: size of the bathymetry output tiles in Longitude direction
- `DLAT`: size of the bathymetry output tiles in Latitude direction
- `OVERLON`: size of the buffer zone when transitioning between tiles in Longitude direction
- `OVERLAT`: size of the buffer zone when transitioning between tiles in Latitude direction

* Note : The script transforms the any bathymetry file that gdal can read into a EPSG:4326 (GPS; lat/lon) in the process and output the final bathymetry tile in EPSG:3857 (UTM; X/Y) to be read correctly in the simulator

## Step 3: Pull a precompiled docker image from Docker Hub and run
Pull precompiled docker image and run at the working directory
```bash
# At the working directory which includes bathymetry_source directory with source bathymetry file inside
docker run -it --rm -v $PWD:/home/mkbathy/workdir -w /home/mkbathy/workdir bathymetry_converter:release python mkbathy.py
```

# Method 2: Installation directly at the Host machine
* This process takes much time (approx. 2 hours)

## Clone the bathymetry converter repository
```bash
git clone git@github.com:Field-Robotics-Lab/Bathymetry_Converter.git
```

## Install prerequisite packages (approx. 1.5 hours)
* Installation based on Ubuntu 18.04 LTS

### download bathymetry source file
```bash
cd Bathymetry_Converter
wget -O bathymetry_source.tar.bz2 https://www.dropbox.com/s/x3acdnnpw3ej9b4/bathymetry_source.tar.bz2?dl=1
tar xvfj bathymetry_source.tar.bz2
cd ..
```

### unzip dependency files (meshlab portable; included in the repository)
from dave project folder
```bash
cd Bathymetry_Converter/mkbathy_dependencies
tar xvfj meshlab_linux_portable.tar.bz2
cd ../../
```

### Packages for the bash script

```bash
sudo apt-get install gmt gmt-dcw gmt-gshhg apcalc sqlite3 checkinstall libudunits2-dev libgdal-dev libgeos-dev libproj-dev
```

### Install gdal and pdal

- Install proj version ≥ 6.0

     - Download proj release at '[https://github.com/OSGeo/PROJ/releases](https://github.com/OSGeo/PROJ/releases)' or [version 7.1.1](https://www.dropbox.com/s/4rjx9vutlezt0yx/proj-7.1.1.tar.gz?dl=1)

     - unzip and install from downloaded source file (here, flag -j4 means using 4 cores)

```bash
tar -xzf proj-$VERSION.tar.gz && cd proj-$VERSION
./configure && make -j4
sudo checkinstall -y -install
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
proj --version
```

- Install gdal

     - Download gdalrelease at '[https://github.com/OSGeo/gdal/releases](https://github.com/OSGeo/gdal/releases)' or [version 3.1.3](https://www.dropbox.com/s/uucd3qwee43bhj9/gdal-3.1.3.tar.gz?dl=1)

     - unzip and install from downloaded source file (here, flag -j4 means using 4 cores)

```bash
tar -xzf gdal-$VERSION.tar.gz && cd gdal-$VERSION
./configure --enable-shared --with-python=python3 --with-proj=/usr/local
make -j4
sudo checkinstall -y -install
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc
gdalinfo --version
```

- Install pdal

     - Download latest PADAL release at '[https://github.com/PDAL/PDAL/releases](https://github.com/PDAL/PDAL/releases)' or [version 2.2.0](https://www.dropbox.com/s/27qt50yh86exo9c/PDAL-2.2.0-src.tar.bz2?dl=1)

     - unzip and install from downloaded latest source file (here, flag -j4 means using 4 cores)

     * if stopped at log file opened with vi, type ':q' to quit

```bash
tar xvfj PDAL-$VERSION-src.tar.bz2 && cd PDAL-$VERSION-src
cmake . && sudo checkinstall -y -install
pdal --version
```

## Run mkbathy.sh script to convert data (approx. 0.5 hours)

```bash
chmod +x mkbathy.sh
./mkbathy.sh
```
converted gazebo model files will be saved at Bathymetry_Converter/bathymetry to be called using the bathymetry plugin [bathymetry plugin tutorial](https://github.com/Field-Robotics-Lab/dave/wiki/Bathymetry-Integration)


# To colorize the grey bathymetry image
```bash
docker run -it --rm -v $PWD:/home/mkbathy/workdir -w /home/mkbathy/workdir woensugchoi/bathymetry_converter:release bash
# copy color.txt from this repo, which is a colormap definition
gdaldem color-relief input.tif color.txt output.tif
```
