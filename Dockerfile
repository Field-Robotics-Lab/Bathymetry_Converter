# Dockerfile for bathymetry converter environment
FROM ubuntu:18.04

# Baseline
RUN apt update \
 && apt install -y --no-install-recommends \
        build-essential cmake git sudo wget curl \
        gmt gmt-dcw gmt-gshhg apcalc sqlite3 checkinstall \
        libudunits2-dev libgdal-dev libgeos-dev libproj-dev \
        lsb-release software-properties-common gnupg python3 python3-dev \
 && apt clean

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

############  Download repo and example files  #############
# Clone the bathymetry converter repositoryClone
ENV VERSION_REPO=3fdce851208c549a2cadb10e0b280e189d4edb08
RUN curl -fsSL https://github.com/Field-Robotics-Lab/Bathymetry_Converter/archive/$VERSION_REPO.tar.gz | tar xz
RUN mv Bathymetry_Converter-$VERSION_REPO Bathymetry_Converter

# download bathymetry source file
WORKDIR /Bathymetry_Converter
RUN wget -O bathymetry_source.tar.bz2 https://www.dropbox.com/s/x3acdnnpw3ej9b4/bathymetry_source.tar.bz2?dl=1 \
 && tar xvfj bathymetry_source.tar.bz2

############  Install prerequisite packages  #############
# unzip dependency files (meshlab portable; included in the repository)
WORKDIR /Bathymetry_Converter/mkbathy_dependencies
RUN  tar xvfj meshlab_linux_portable.tar.bz2

# Install proj
WORKDIR /proj
ENV VERSION_PROJ=7.1.1
RUN wget -O proj-$VERSION_PROJ.tar.gz https://www.dropbox.com/s/4rjx9vutlezt0yx/proj-7.1.1.tar.gz?dl=1 \
 && tar -xzf proj-$VERSION_PROJ.tar.gz
WORKDIR /proj/proj-$VERSION_PROJ
RUN ./configure && make -j$(nproc) && checkinstall -y -install

# Install gdal
WORKDIR /gdal
ENV VERSION_GDAL=3.1.3
RUN wget -O gdal-$VERSION_GDAL.tar.gz https://www.dropbox.com/s/uucd3qwee43bhj9/gdal-3.1.3.tar.gz?dl=1 \
 && tar -xzf gdal-$VERSION_GDAL.tar.gz
WORKDIR /gdal/gdal-$VERSION_GDAL
RUN ./configure --enable-shared --with-python=python3 --with-proj=/usr/local && make -j$(nproc) && checkinstall -y -install

# Install pdal
WORKDIR /pdal
ENV VERSION_PDAL=2.2.0
RUN wget -O PDAL-$VERSION_PDAL-src.tar.bz2 https://www.dropbox.com/s/27qt50yh86exo9c/PDAL-2.2.0-src.tar.bz2?dl=1 \
 && tar xvfj PDAL-$VERSION_PDAL-src.tar.bz2
WORKDIR /pdal/PDAL-$VERSION_PDAL-src
RUN cmake . && checkinstall -y -install

# Add meshlabserver symbolinc link at /usr/local/bin
RUN ln -s /Bathymetry_Converter/mkbathy_dependencies/meshlab_linux_portable/meshlabserver /usr/local/bin/meshlabserver

# Make user (assume host user has 1000:1000 permission)
RUN useradd -ms /bin/bash mkbathy
USER mkbathy
WORKDIR /home/mkbathy

# Add path for proj, gdal, and pdal
RUN echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib' >> /home/mkbathy/.bashrc