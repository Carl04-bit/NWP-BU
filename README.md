# WRF and WPS Installation Guide

This guide provides step-by-step instructions to compile and install WRF v4.8.0 and WPS v4.7.0 in the `/opt/WRF_GNU` directory on an Ubuntu Linux system.

## Prerequisites
Ensure your system has the required compilers and libraries installed via Ubuntu's package manager:
```bash
sudo apt update
sudo apt install build-essential csh gfortran m4 mpi-default-dev mpi-default-bin \
    libnetcdf-dev libnetcdff-dev libhdf5-dev netcdf-bin \
    libpng-dev libjasper-dev zlib1g-dev
```

## Step 1: Create the Environment Script
This script configures the paths and compilers needed by both the installer and the users.

1. Open your terminal and create the setup directory:
   ```bash
   sudo mkdir -p /opt/WRF_GNU
   ```
2. Create the file `/opt/WRF_GNU/setenv-wrf.sh`:
   ```bash
   sudo nano /opt/WRF_GNU/setenv-wrf.sh
   ```
3. Paste the following contents:
   ```bash
   #!/usr/bin/env bash
   # WRF 4.8.0 / WPS 4.7.0
   # Dependencies supplied by Ubuntu
   
   # Installation directories
   export WRF_HOME=/opt/WRF_GNU
   export WRF_DIR="${WRF_HOME}/WRF-4.8.0"
   export WPS_DIR="${WRF_HOME}/WPS-4.7.0"
   
   # System NetCDF libraries (Dynamic lookup)
   export NETCDF="$(nc-config --prefix)"
   
   # Jasper libraries for WPS GRIB2 support (Standard Ubuntu paths)
   export JASPERLIB="/usr/lib/x86_64-linux-gnu"
   export JASPERINC="/usr/include"
   
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
   ```

## Step 2: Create the Compilation Script
This script automates downloading, extracting, and compiling WRF, WPS, and the geographical data.

1. Create the file `/opt/WRF_GNU/compile-wrf.sh`:
   ```bash
   sudo nano /opt/WRF_GNU/compile-wrf.sh
   ```
2. Paste the following contents:
   ```bash
   #!/bin/bash
   # compile-wrf.sh
   
   export WRF_HOME="/opt/WRF_GNU"
   export WRF_VERSION="4.8.0"
   export WPS_VERSION="4.7.0"
   export WRF_DIR="${WRF_HOME}/WRF-${WRF_VERSION}"
   export WPS_DIR="${WRF_HOME}/WPS-${WPS_VERSION}"
   
   cd $WRF_HOME
   
   # 1. Source the environment
   source ./setenv-wrf.sh
   ulimit -s unlimited
   
   # 2. Download WRF and WPS
   echo "Downloading WRF v$WRF_VERSION and WPS v$WPS_VERSION..."
   wget https://github.com/wrf-model/WRF/archive/refs/tags/v${WRF_VERSION}.tar.gz -O WRF.tar.gz
   wget https://github.com/wrf-model/WPS/archive/refs/tags/v${WPS_VERSION}.tar.gz -O WPS.tar.gz
   tar -xf WRF.tar.gz
   tar -xf WPS.tar.gz
   rm *.tar.gz
   
   # 3. Download High-Res Geog Data
   echo "Downloading High Resolution GEOG data..."
   mkdir -p $WRF_HOME/WPS_GEOG
   cd $WRF_HOME/WPS_GEOG
   wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
   tar -xf geog_high_res_mandatory.tar.gz
   rm geog_high_res_mandatory.tar.gz
   
   # 4. Compile WRF
   echo "Configuring and Compiling WRF..."
   cd $WRF_DIR
   ./clean -a
   # Configure WRF (Option 34 is GNU dmpar, Option 1 is basic nesting)
   echo -e "34\n1\n" | ./configure
   ./compile em_real >& compile_wrf.log
   
   if [ -f main/wrf.exe ]; then
       echo "WRF Compilation Successful!"
   else
       echo "WRF Compilation Failed. Check $WRF_DIR/compile_wrf.log"
       exit 1
   fi
   
   # 5. Compile WPS
   echo "Configuring and Compiling WPS..."
   cd $WPS_DIR
   ./clean -a
   # Configure WPS (Option 3 is GNU dmpar)
   echo -e "3\n" | ./configure
   ./compile >& compile_wps.log
   
   if [ -f geogrid.exe ]; then
       echo "WPS Compilation Successful!"
   else
       echo "WPS Compilation Failed. Check $WPS_DIR/compile_wps.log"
       exit 1
   fi
   
   echo "Installation complete in $WRF_HOME."
   ```

## Step 3: Run the Compilation
Make the scripts executable and run the installation script. **Note: Compiling WRF takes time.**

```bash
sudo chmod +x /opt/WRF_GNU/setenv-wrf.sh
sudo chmod +x /opt/WRF_GNU/compile-wrf.sh
sudo /opt/WRF_GNU/compile-wrf.sh
```
