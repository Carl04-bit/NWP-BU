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
