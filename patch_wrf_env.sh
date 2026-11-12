sudo tee /opt/WRF_GNU/patch_wrf_env.sh > /dev/null << 'EOF'
#!/bin/bash

# Ensure a directory was provided
if [ -z "$1" ]; then
    echo "Error: Please provide the target directory."
    echo "Usage: patch_wrf /path/to/wrf/folder"
    exit 1
fi

# Resolve absolute path of the target directory
TARGET_DIR=$(realpath "$1")
OPT_DIR="/opt/WRF_GNU"

echo "Patching WRF environment in: $TARGET_DIR"
cd "$TARGET_DIR" || exit

# 1. Patch namelist.wps
if [ -f "namelist.wps" ]; then
    # Redirect geog_data_path to local /opt installation
    sed -i "s|geog_data_path.*|geog_data_path = '$OPT_DIR/WPS_GEOG/WPS_GEOG/',|" namelist.wps
    echo " -> Geography data path set to $OPT_DIR/WPS_GEOG/."

    # Hardcode Geogrid table path
    if ! grep -q "opt_geogrid_tbl_path" namelist.wps; then
        sed -i "/geog_data_path/a \ opt_geogrid_tbl_path = '$OPT_DIR/WPS-4.7.0/geogrid/'," namelist.wps
        echo " -> Geogrid table path hardcoded."
    fi

    # Hardcode Metgrid table path
    if ! grep -q "opt_metgrid_tbl_path" namelist.wps; then
        sed -i "/fg_name/a \ opt_metgrid_tbl_path = '$OPT_DIR/WPS-4.7.0/metgrid/'," namelist.wps
        echo " -> Metgrid table path hardcoded."
    fi
else
    echo " -> Warning: namelist.wps not found. Skipping WPS patch."
fi

# 2. Link exhaustive physics and radiation tables
echo " -> Linking exhaustive WRF physics tables..."
ln -sf "$OPT_DIR"/WRF-4.8.0/run/CAM* .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/aerosol* .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/*_DATA .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/*.TBL .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/ozone* .
ln -sf "$OPT_DIR"/WRF-4.8.0/run/RRTMG* .

echo "Patch complete! Reminder: Ensure 'ulimit -s unlimited' is active."
EOF
