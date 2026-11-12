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
