#!/usr/bin/env bash
# WRF 4.8.0 / WPS 4.7.0
# Dependencies supplied by Ubuntu

# Installation directories
export WRF_HOME=/opt/WRF_GNU
export WRF_DIR="${WRF_HOME}/WRF-4.8.0"
export WPS_DIR="${WRF_HOME}/WPS-4.7.0"

# System NetCDF libraries (Dynamic lookup)
export NETCDF="$(nc-config --prefix)"

# Jasper libraries for WPS GRIB2 support (Custom Compilation)
export JASPERLIB="/opt/WRF_GNU/grib2/lib"
export JASPERINC="/opt/WRF_GNU/grib2/include"

# WRF Specific Environment Variables
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export WRF_EM_CORE=1

# Compilers (GNU)
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran

# Display configured environment
echo "WRF environment loaded:"
echo "  WRF_DIR: $WRF_DIR"
echo "  WPS_DIR: $WPS_DIR"
echo "  NETCDF:  $NETCDF"
