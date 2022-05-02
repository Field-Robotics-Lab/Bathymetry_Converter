* The converter script was developed by Micahel Jakuba at WHOI and modified/implemented to the dave project by Woensug Choi.

![image](https://user-images.githubusercontent.com/7955120/149531647-2ba86a11-955d-4684-9d0b-bd53ea0fec3d.png)

## Proclaimer
The Gazebo includes direct uploads of DEM data on the simulator ([Gazebo tutorial for DEM link](http://gazebosim.org/tutorials?tut=dem&cat=build_world)). However, it handles only grids and suggests downsampling to coarse resolutions. Also, Gazebo only allow one heightmap per scene unable to change on the fly. The pipeline of this converter constructs simplified triangular meshes that retain detail where it is needed. The pipeline also creates overlap and generates tiles with the special/arbitrary filenames required by the plugin.

For tutorials, how to use the bathymetry tiles, please visit [Bathymetry Integration Wiki page](https://field-robotics-lab.github.io/dave.doc/contents/dave_env/Bathymetry-Integration/) of the [Dave project documentation](https://field-robotics-lab.github.io/dave.doc/)

- Any bathymetry file (GeoTiFF, GMT, XYZ, and etc..) can be used as long as the GDAL library supports it
  - Current dockerized GDAL library supports followings
    ```bash
    ['VRT', 'DERIVED', 'GTiff', 'COG', 'NITF', 'RPFTOC', 'ECRGTOC', 'HFA', 'SAR_CEOS', 'CEOS', 'JAXAPALSAR', 'GFF', 'ELAS', 'ESRIC', 'AIG', 'AAIGrid', 'GRASSASCIIGrid', 'ISG', 'SDTS', 'DTED', 'PNG', 'JPEG', 'MEM', 'JDEM', 'GIF', 'BIGGIF', 'ESAT', 'FITS', 'BSB', 'XPM', 'BMP', 'DIMAP', 'AirSAR', 'RS2', 'SAFE', 'PCIDSK', 'PCRaster', 'ILWIS', 'SGI', 'SRTMHGT', 'Leveller', 'Terragen', 'GMT', 'netCDF', 'HDF4', 'HDF4Image', 'ISIS3', 'ISIS2', 'PDS', 'PDS4', 'VICAR', 'TIL', 'ERS', 'JP2OpenJPEG', 'L1B', 'FIT', 'GRIB', 'RMF', 'WCS', 'WMS', 'MSGN', 'RST', 'INGR', 'GSAG', 'GSBG', 'GS7BG', 'COSAR', 'TSX', 'COASP', 'R', 'MAP', 'KMLSUPEROVERLAY', 'WEBP', 'PDF', 'Rasterlite', 'MBTiles', 'PLMOSAIC', 'CALS', 'WMTS', 'SENTINEL2', 'MRF', 'TileDB', 'PNM', 'DOQ1', 'DOQ2', 'PAux', 'MFF', 'MFF2', 'FujiBAS', 'GSC', 'FAST', 'BT', 'LAN', 'CPG', 'IDA', 'NDF', 'EIR', 'DIPEx', 'LCP', 'GTX', 'LOSLAS', 'NTv2', 'CTable2', 'ACE2', 'SNODAS', 'KRO', 'ROI_PAC', 'RRASTER', 'BYN', 'ARG', 'RIK', 'USGSDEM', 'GXF', 'DODS', 'KEA', 'BAG', 'HDF5', 'HDF5Image', 'NWT_GRD', 'NWT_GRC', 'ADRG', 'SRP', 'BLX', 'PostGISRaster', 'SAGA', 'XYZ', 'HF2', 'OZI', 'CTG', 'ZMap', 'NGSGEOID', 'IRIS', 'PRF', 'RDA', 'EEDAI', 'EEDA', 'DAAS', 'SIGDEM', 'TGA', 'OGCAPI', 'STACTA', 'STACIT', 'GNMFile', 'GNMDatabase', 'ESRI Shapefile', 'MapInfo File', 'UK .NTF', 'LVBAG', 'OGR_SDTS', 'S57', 'DGN', 'OGR_VRT', 'REC', 'Memory', 'CSV', 'NAS', 'GML', 'GPX', 'LIBKML', 'KML', 'GeoJSON', 'GeoJSONSeq', 'ESRIJSON', 'TopoJSON', 'Interlis 1', 'Interlis 2', 'OGR_GMT', 'GPKG', 'SQLite', 'OGR_DODS', 'WAsP', 'PostgreSQL', 'OpenFileGDB', 'DXF', 'CAD', 'FlatGeobuf', 'Geoconcept', 'GeoRSS', 'GPSTrackMaker', 'VFK', 'PGDUMP', 'OSM', 'GPSBabel', 'OGR_PDS', 'WFS', 'OAPIF', 'EDIGEO', 'SVG', 'CouchDB', 'Cloudant', 'Idrisi', 'ARCGEN', 'XLS', 'ODS', 'XLSX', 'Elasticsearch', 'Carto', 'AmigoCloud', 'SXF', 'Selafin', 'JML', 'PLSCENES', 'CSW', 'VDV', 'GMLAS', 'MVT', 'NGW', 'MapML', 'TIGER', 'AVCBin', 'AVCE00', 'GenBin', 'ENVI', 'EHdr', 'ISCE', 'Zarr', 'HTTP']
    ```
- Can generate tiles at any position (lat/lon) if the bathymetry file exists
- Resolution (size of each tile), the size of the overlaping region can be defined
- The color texture is applied according to depths
- Everything is dockerized for dependencies

# Run `mkbathy.py` script with precompiled docker image

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

### For tutorial source (Monterey Bay)
- Download tutorial source bathymetry file
   downloading a file from google drive became compliated. Install and use gdown. Or, use [this link](https://drive.google.com/file/d/1OdgqNJG9Xr-RSDoTYIHKHDnMkSSUdE9K/view?usp=sharing)

   ```bash
   # Install gdown
   pip3 install gdown
   # Download the data from google drive
   gdown --id 1OdgqNJG9Xr-RSDoTYIHKHDnMkSSUdE9K
   ```

   Then extract the tutorial data. Here, working directory `MontereyBay` will be created.

   ```bash
   tar -xzvf Bathy_Converter_tutorial.tar.gz
   ```


### Bathymetry source file location
Go to the working directory and make a child directory named with `bathymetry_source` and put the source bathymetry file inside.

For tutorial, Small portion of the [NetCDF format dataset (760MB)](https://www.ngdc.noaa.gov/thredds/fileServer/regional/monterey_13_navd88_2012.nc) of the [1/3 arc-second Monterey Bay bathymetry by NCEI](https://www.ncei.noaa.gov/metadata/geoportal/rest/metadata/item/gov.noaa.ngdc.mgg.dem:3544/html) is included which can also be found at [NOAA Bathymetetric Data Viewer](https://www.ncei.noaa.gov/maps/bathymetry/). For how-to find the bathymetry, read below.

- Explorering [NOAA Bathymetetric Data Viewer](https://www.ncei.noaa.gov/maps/bathymetry/) to obtain bathymetry source

  - Look for `Bathymetric Surveys / NOAA NOS Hydrographic Data / All Surveys with Digital Data` and `Digital Elevation Models / All DEMs (Click checkbox of DEM Footprints)`

  - For Global regions (typically moderate resolution)
    - [ETOPO1 Global Relief Model](https://www.ngdc.noaa.gov/mgg/global/global.html)
      - ETOPO1 is a 1 arc-minute global relief model of Earth's surface that integrates land topography and ocean bathymetry
      - Custom range dataset can be extracted at [Grid Extract Tool](https://maps.ngdc.noaa.gov/viewers/grid-extract/index.html)
    - [GEBCO 2021](https://www.gebco.net/data_and_products/gridded_bathymetry_data/)
      - GEBCO consits slightly finer resolution than ETOPO1
    - [NOAA Multibeam Bathymetry Database](https://www.ngdc.noaa.gov/mgg/bathymetry/multibeam.html)
      - [NOAA AutoGrid](https://www.ngdc.noaa.gov/maps/autogrid/) will create a NetCFD binary grid of the data in your area of interest which this converter can read

  - For Costal Regions (possibly high resolution)
    - [NOAA Costal Elevation Models](https://www.ngdc.noaa.gov/mgg/coastal/coastal.html)
    - `Continuously Updated Digital Elevation Model (CUDEM)` works amazingly with this converter
      - [NOAA Digital Coast: Data Access Viewer - CUDEM](https://coast.noaa.gov/dataviewer/#/lidar/search/where:ID=8483) can generate a custom range bathymetry
        - Draw region you want the data with 'Draw' button at the top left and request. It takes about 10 minutes to receive

    - All others
      - For XYZ cloud point datasets, you may need to modify the format to match with [GDAL's ASCII XYZ format](https://gdal.org/drivers/raster/xyz.html)
        > starting with GDAL 3.2.1, cells with same X coordinates must be placed on consecutive lines. For a same X coordinate value, the columns must be organized by increasing or decreasing Y values.
      - The ones by Multibeam surveys and Lidar datasets without continous bathymetry dataset has low compatability for converting process when generating mesh file and smoothing


### Download `mkbathy.py` script and make modifications
At the working directory (For tutorial case, `MontereyBay` is the working directory)
```bash
# get mkbathy.py script
wget https://raw.githubusercontent.com/Field-Robotics-Lab/Bathymetry_Converter/master/mkbathy.py
# get color table template
wget https://raw.githubusercontent.com/Field-Robotics-Lab/Bathymetry_Converter/master/color.txt
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

The `color.txt` consists of (depth, R,G,B) columns.
You may want to adjust depth column according to your source.

* Note : The script transforms the any bathymetry file that gdal can read into a EPSG:4326 (GPS; lat/lon) in the process and output the final bathymetry tile in EPSG:3857 (UTM; X/Y) to be read correctly in the simulator

## Step 3: Pull a precompiled docker image from Docker Hub and run
Pull precompiled docker image and run at the working directory

- At the working directory which includes bathymetry_source directory with source bathymetry file inside
  ```bash
  docker pull woensugchoi/bathymetry_converter:release && docker run -it --rm -v $PWD:/home/mkbathy/workdir -w /home/mkbathy/workdir woensugchoi/bathymetry_converter:release python3 mkbathy.py
  ```
  * note : ignore `ERROR 1: PROJ: Unrecognized horizontal grid format for filename 'us_noaa_pvhpgn.tif'`. it's not our problem. it's PROJ's network database problem. It works ok with what's in the cache.

- Converted gazebo model files will be saved at a directory with `PREFIX` (defined at mkbathy.py) as its name to be called using the bathymetry plugin [bathymetry plugin tutorial](https://field-robotics-lab.github.io/dave.doc/contents/dave_env/Bathymetry-Integration/)


### Other useful tips
- To investigate the information (boundaries, max height/depth and etc) of the source bathymetry file, you may also use the docker image

  Launch the docker image's bash
  ```bash
  docker pull woensugchoi/bathymetry_converter:release && docker run -it --rm -v $PWD:/home/mkbathy/workdir -w /home/mkbathy/workdir woensugchoi/bathymetry_converter:release bash
  ```

  Get information of the source bathymetry file

  ```bash
  gdalinfo bathymetry_source/monterey_13_navd88_2012.nc
  ```

  You may add `--stats` option to see max/min depth/heights

- For XYZ datasets, it's best to transform the source bathymetry file into GeoTiff (it's also useful since you can open it with common image viewer applications)

  Launch the docker image's bash
  ```bash
  docker pull woensugchoi/bathymetry_converter:release && docker run -it --rm -v $PWD:/home/mkbathy/workdir -w /home/mkbathy/workdir woensugchoi/bathymetry_converter:release bash
  ```

  Transform the source bathymetry data in XYZ into Geotiff
  - You need to provide a EPSG code of the XYZ dataset

  ```bash
  # this is an example of XYZ dataset in UTM-4N (EPSG:32604)
  gdalwarp -s_srs 'EPSG:32604' -t_srs 'EPSG:4326' -of GTiff source.xyz source.tif
  ```
