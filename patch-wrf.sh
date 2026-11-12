#!/bin/bash

# Ensure a directory was provided
if [ -z "$1" ]; then
    echo "Error: Please provide the target directory."
    echo "Usage: /opt/WRF_GNU/patch_wrf_env.sh /path/to/wrf/folder"
    exit 1
fi

# Resolve absolute path of the target directory
TARGET_DIR=$(realpath "$1")
OPT_DIR="/opt/WRF_GNU"

echo "Patching WRF environment in: $TARGET_DIR"
cd "$TARGET_DIR" || exit

# 1. Patch namelist.wps (Skip if already patched)
if [ -f "namelist.wps" ]; then
    if ! grep -q "opt_geogrid_tbl_path" namelist.wps; then
        sed -i '/geog_data_path/a \ opt_geogrid_tbl_path = "/opt/WRF_GNU/WPS-4.7.0/geogrid/"' namelist.wps
        echo " -> Geogrid table path hardcoded."
    fi
    if ! grep -q "opt_metgrid_tbl_path" namelist.wps; then
        sed -i '/fg_name/a \ opt_metgrid_tbl_path = "/opt/WRF_GNU/WPS-4.7.0/metgrid/"' namelist.wps
        echo " -> Metgrid table path hardcoded."
    fi
else
    echo " -> Warning: namelist.wps not found. Skipping WPS patch."
fi

# 2. Link exhaustive physics and radiation tables
echo " -> Linking WRF physics tables..."
ln -sf "$OPT_DIR"/WRF-4.8.0/run/CAM* .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/aerosol* .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/*_DATA .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/*.TBL .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/ozone* .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/RRTMG* .

echo "Patch complete! Reminder: Ensure 'ulimit -s unlimited' is active."
