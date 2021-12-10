* The converter script was developed by Micahel Jakuba at WHOI and implemented to the dave project by Woensug Choi.

## Proclaimer
The Gazebo includes direct uploads of DEM data on the simulator ([Gazebo tutorial for DEM link](http://gazebosim.org/tutorials?tut=dem&cat=build_world)). However, it handles only grids and suggests downsampling to coarse resolutions. The pipeline of this converter constructs simplified triangular meshes that retain detail where it is needed. The pipeline also creates overlap and generates tiles with the special/arbitrary filenames required by the plugin. A major limitation of the bathymetry converter-plugin is the arbitrary file naming convention that has to be followed for the tiling to work.

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
└── mkbathy.sh
```

### Bathymetry source file location
Go to the working directory and make a child directory named with `bathymetry_source` and put the source bathymetry file inside.

### Download `mkbathy.sh` script and make modifications necessar
At the working directory
```bash
wget https://github.com/Field-Robotics-Lab/Bathymetry_Converter/blob/master/mkbathy.sh
```
You may want to change following parameters in the script,
- `prefix` : prefix for the model names
- `SRC`: path to source bathymetry file
- 'EPSG': target EPSG code
- `DLON`: size of the bathymetry output tiles in Longitude direction
- `DLAT`: size of the bathymetry output tiles in Latitude direction
- `OVERLON`: size of the buffer zone when transitioning between tiles in Longitude direction
- `OVERLAT`: size of the buffer zone when transitioning between tiles in Latitude direction
- `STARTLON` : starting Longitude
- `STARTLAT` : starting Latitude
- `ENDLON` : ending Longitude
- `ENDLAT` : ending Latitude



## Step 3: Pull a precompiled docker image from Docker Hub and run
Pull precompiled docker image and run at the working directory
```bash
# At the working directory which includes bathymetry_source directory with source bathymetry file inside
docker run -it --rm -v $PWD:/home/mkbathy -w /home/mkbathy woensugchoi/bathymetry_converter:release bash
chmod +x mkbathy.sh
./mkbathy.sh
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