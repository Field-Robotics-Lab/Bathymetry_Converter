# Dockerfile for bathymetry converter environment
FROM ubuntu:18.04

RUN apt update \
 && apt install -y --no-install-recommends \
        build-essential cmake git sudo wget curl \
        gmt gmt-dcw gmt-gshhg apcalc sqlite3 checkinstall \
        libudunits2-dev libgdal-dev libgeos-dev libproj-dev \
 && apt clean 

RUN curl -fsSL https://github.com/Field-Robotics-Lab/Bathymetry_Converter/archive/3fdce851208c549a2cadb10e0b280e189d4edb08.tar.gz | tar xz

WORKDIR Bathymetry_Converter
RUN wget -O bathymetry_source.tar.bz2 https://www.dropbox.com/s/x3acdnnpw3ej9b4/bathymetry_source.tar.bz2?dl=1 && \
    tar xvfj bathymetry_source.tar.bz2


