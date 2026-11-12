# WRF and WPS Installation Guide

This guide provides step-by-step instructions to compile and install WRF v4.8.0 and WPS v4.7.0 in the `/opt/WRF_GNU` directory on an Ubuntu Linux system.

## Prerequisites

Ensure your system has the required compilers and libraries installed via Ubuntu's package manager. Note that we do not install `libjasper-dev` here, as it must be compiled manually for compatibility. We also make sure `git` is installed to correctly clone the WRF source code with all of its submodules.

```bash
sudo apt update
sudo apt install -y gcc g++ gfortran build-essential csh tcsh m4 \
                    libopenmpi-dev openmpi-bin \
                    libnetcdf-dev libnetcdff-dev netcdf-bin \
                    libpng-dev zlib1g-dev git
```

## Step 1: Compile and Install Jasper

Since newer versions of Ubuntu no longer include a compatible `libjasper-dev` package, you must compile it from source to enable WPS to process GRIB2 files (like GFS data).

```bash
# Create the central installation directory
sudo mkdir -p /opt/WRF_GNU
cd /opt/WRF_GNU

# Download and extract Jasper
sudo wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
sudo tar -xf jasper-1.900.1.tar.gz

# Configure and compile into a custom grib2 directory
sudo mkdir -p /opt/WRF_GNU/grib2
cd /opt/WRF_GNU/jasper-1.900.1/
sudo ./configure --prefix=/opt/WRF_GNU/grib2
sudo make
sudo make install
```

## Step 2: Create the Environment Script

This script configures the paths and compilers needed by both the installer and the users. It points to your newly compiled Jasper library.

1. Create the file `/opt/WRF_GNU/setenv-wrf.sh`:

   ```bash
   sudo nano /opt/WRF_GNU/setenv-wrf.sh
   ```

2. Paste the following contents:

   ```bash
   #!/usr/bin/env bash
   # WRF 4.8.0 / WPS 4.7.0
   # Dependencies supplied by Ubuntu and Manual Compilation
   
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
   ```

## Step 3: Create the Compilation Script

This script automates cloning the repositories (with submodules) and compiling WRF and WPS. It is designed to be idempotent—meaning you can safely re-run it. It will skip cloning, geographic data downloading, and compiling for any steps that have already successfully completed. It also automatically applies a patch to fix an Ubuntu-specific NetCDF linking bug.

1. Create the file `/opt/WRF_GNU/compile-wrf.sh`:

   ```bash
   sudo nano /opt/WRF_GNU/compile-wrf.sh
   ```

2. Paste the following contents:

   ```bash
   #!/bin/bash
   # compile-wrf.sh
   # Run this with sudo to write to /opt/WRF_GNU
   
   export WRF_HOME="/opt/WRF_GNU"
   export WRF_VERSION="4.8.0"
   export WPS_VERSION="4.7.0"
   export WRF_DIR="${WRF_HOME}/WRF-${WRF_VERSION}"
   export WPS_DIR="${WRF_HOME}/WPS-${WPS_VERSION}"
   export GEOG_DIR="${WRF_HOME}/WPS_GEOG"
   
   mkdir -p $WRF_HOME
   cd $WRF_HOME
   
   # 0. Check for necessary tools (git)
   if ! command -v git &> /dev/null; then
       echo "Error: 'git' is not installed. Please run: sudo apt install -y git"
       exit 1
   fi
   
   # 1. Source the environment
   if [ -f "${WRF_HOME}/setenv-wrf.sh" ]; then
       source ${WRF_HOME}/setenv-wrf.sh
   else
       echo "Error: setenv-wrf.sh not found in $WRF_HOME!"
       echo "Please create /opt/WRF_GNU/setenv-wrf.sh before running this script."
       exit 1
   fi
   ulimit -s unlimited
   
   # 2. Clone WRF and WPS using Git (Conditional)
   echo "Checking WRF and WPS source directories..."
   
   if [ ! -d "WRF-${WRF_VERSION}" ]; then
       echo "Cloning WRF v$WRF_VERSION..."
       git clone --branch v${WRF_VERSION} --recurse-submodules https://github.com/wrf-model/WRF.git WRF-${WRF_VERSION}
   else
       echo "WRF directory already exists. Skipping clone."
   fi
   
   if [ ! -d "WPS-${WPS_VERSION}" ]; then
       echo "Cloning WPS v$WPS_VERSION..."
       git clone --branch v${WPS_VERSION} https://github.com/wrf-model/WPS.git WPS-${WPS_VERSION}
   else
       echo "WPS directory already exists. Skipping clone."
   fi
   
   # 3. Download High-Res Geog Data (Conditional)
   echo "Checking for High Resolution GEOG data..."
   mkdir -p $GEOG_DIR
   cd $GEOG_DIR
   
   if [ -d "${GEOG_DIR}/WPS_GEOG" ] || [ -d "${GEOG_DIR}/topo_30s" ]; then
       echo "GEOG high-res data already extracted in $GEOG_DIR. Skipping download."
   elif [ -f "geog_high_res_mandatory.tar.gz" ]; then
       echo "GEOG high-res tarball found in $GEOG_DIR. Skipping download."
       echo "Extracting the archive..."
       tar -xf geog_high_res_mandatory.tar.gz
       mv WPS_GEOG/* .
       rmdir WPS_GEOG
       rm geog_high_res_mandatory.tar.gz
   else
       echo "GEOG data not found. Downloading High Resolution GEOG data..."
       wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
       tar -xf geog_high_res_mandatory.tar.gz
       mv WPS_GEOG/* .
       rmdir WPS_GEOG
       rm geog_high_res_mandatory.tar.gz
   fi
   
   # 4. Compile WRF (Conditional)
   echo "Checking WRF Compilation Status..."
   cd $WRF_DIR
   
   if [ -f main/wrf.exe ]; then
       echo "WRF is already successfully compiled (wrf.exe found). Skipping WRF compilation."
   else
       echo "Configuring and Compiling WRF..."
       ./clean -a
       # Configure WRF (Option 34 is GNU dmpar, Option 1 is for basic nesting)
       echo -e "34\n1\n" | ./configure
       ./compile em_real >& compile_wrf.log
   
       if [ -f main/wrf.exe ]; then
           echo "WRF Compilation Successful!"
       else
           echo "WRF Compilation Failed. Check $WRF_DIR/compile_wrf.log"
           exit 1
       fi
   fi
   
   # 5. Compile WPS (Conditional)
   echo "Checking WPS Compilation Status..."
   cd $WPS_DIR
   
   if [ -f geogrid.exe ] && [ -f metgrid.exe ] && [ -f ungrib.exe ]; then
       echo "WPS is already successfully compiled. Skipping WPS compilation."
   else
       echo "Configuring and Compiling WPS..."
       ./clean -a
       # Configure WPS (Option 3 is GNU dmpar)
       echo -e "3\n" | ./configure
       
       # PATCH: Fix Ubuntu split NetCDF Fortran linking error (nf_strerror_)
       sed -i 's/-lnetcdf/-lnetcdff -lnetcdf/g' configure.wps
       
       ./compile >& compile_wps.log
   
       if [ -f geogrid.exe ]; then
           echo "WPS Compilation Successful!"
       else
           echo "WPS Compilation Failed. Check $WPS_DIR/compile_wps.log"
           exit 1
       fi
   fi
   
   echo "Installation process complete in $WRF_HOME."
   ```

## Step 4: Run the Compilation

Make the scripts executable and run the installation script. **Note: Compiling WRF takes a significant amount of time depending on your system's hardware.** 

Because the script is idempotent, you can interrupt it or rerun it without destroying earlier, successfully completed stages.

```bash
sudo chmod +x /opt/WRF_GNU/setenv-wrf.sh
sudo chmod +x /opt/WRF_GNU/compile-wrf.sh
sudo /opt/WRF_GNU/compile-wrf.sh
```
