# Dockerfile for bathymetry converter environment
FROM continuumio/miniconda3

# Install required libraries
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        git wget nano \
 && apt-get clean

RUN conda create --name mkbathy --channel conda-forge pygmt

# Make mkbathy as a default conda environment
ENV PATH /opt/conda/envs/mkbathy/bin:$PATH
ENV CONDA_DEFAULT_ENV mkbathy

# Install pymeslab
RUN pip install pymeshlab

# For pymeshlab libGL.so.1 error
RUN apt-get update\
 && apt-get install -y --no-install-recommends \
        libglu1-mesa libgl1-mesa-dev \
 && apt-get clean

# For progressbar
RUN pip install tqdm

# COPY Current repo's data
COPY . /Bathymetry_Converter

# Make user (assume host user has 1000:1000 permission)
RUN adduser --disabled-password --gecos "" mkbathy \
 && echo 'mkbathy:mkbathy' | chpasswd \
 && adduser mkbathy sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER mkbathy
