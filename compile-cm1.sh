#!/bin/bash
# compile-cm1.sh
# Run this script with sudo (or as root) if installing in /opt/WRF_GNU
# It relies on the environment variables defined in setenv-wrf.sh

export INSTALL_DIR="/opt/WRF_GNU"
export CM1_VERSION="22.0"
export CM1_DIR="${INSTALL_DIR}/cm1r${CM1_VERSION}"

echo "Starting CM1 Installation..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 1. Source the WRF environment (provides NETCDF and MPI paths)
# Explicitly using absolute path to avoid directory execution issues
if [ -f "${INSTALL_DIR}/setenv-wrf.sh" ]; then
    source ${INSTALL_DIR}/setenv-wrf.sh
else
    echo "Error: setenv-wrf.sh not found in $INSTALL_DIR"
    echo "Please ensure the WRF environment script is created before compiling CM1."
    exit 1
fi

# 2. Download CM1
echo "Downloading CM1 Release ${CM1_VERSION}..."
wget https://www2.mmm.ucar.edu/people/bryan/cm1/cm1r${CM1_VERSION}.tar.gz -O cm1.tar.gz
tar -xf cm1.tar.gz
rm cm1.tar.gz

# 3. Configure the Makefile
echo "Configuring the Makefile for gfortran, MPI, and NetCDF..."
cd ${CM1_DIR}/src

# Backup the original Makefile
cp Makefile Makefile.orig

# Append our required compiler and library flags to override defaults at the bottom
cat << 'EOF' >> Makefile

# --- Appended by compile-cm1.sh ---
# Compiler flags for MPI + gfortran
FC = mpif90
OPTS = -ffree-form -ffree-line-length-none -O3 -finline-functions
CPP = cpp -P -traditional -Wno-invalid-pp-token -ffreestanding
DM = -DMPI

# NetCDF output flags (Uses the NETCDF environment variable from setenv-wrf.sh)
OUTPUTINC = -I$(NETCDF)/include
OUTPUTLIB = -L$(NETCDF)/lib -lnetcdff -lnetcdf
OUTPUTOPT = -DNETCDF
# -----------------------------------
EOF

# 4. Compile CM1
echo "Compiling CM1..."
make >& compile_cm1.log

if [ -f ../run/cm1.exe ]; then
    echo "CM1 Compilation Successful!"
    echo "Executable is located in ${CM1_DIR}/run/cm1.exe"
else
    echo "CM1 Compilation Failed. Check ${CM1_DIR}/src/compile_cm1.log for errors."
    exit 1
fi
