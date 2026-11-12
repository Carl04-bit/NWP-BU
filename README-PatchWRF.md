# Centralized WRF Environment Patch Setup (`patch_wrf`)

`patch_wrf` is intended to be used as a corrective tool to patch certain errors when running WRF. Revise as needed when errors occur. Use this shell script as a corrective tool, rather than revising the other shell scripts.

Placing the patch script directly in the `/opt/WRF_GNU` folder centralizes your administration tools alongside the actual software. Because `/opt` is a system-protected directory, you must use `sudo` to create and configure the file, after which any standard user can execute it on their local simulation folders without admin rights.

## 1. Create the Script in `/opt`

Create or overwrite the centralized patch script directly inside your WRF installation directory:

```bash
sudo nano /opt/WRF_GNU/patch_wrf_env.sh
```

## 2. Paste the Patching Logic

Paste the following updated script into the editor. It uses `realpath` to ensure it always targets the correct directory, redirects `geog_data_path` to your local `/opt` installation, hardcodes WPS table paths, and links all required WRF physics files.

```bash
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
    sed -i "s|geog_data_path.*|geog_data_path = '$OPT_DIR/WPS_GEOG/',|" namelist.wps
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
```

Press `Ctrl+O`, hit `Enter` to save, and `Ctrl+X` to exit `nano`.

## 3. Make the Script Executable

Grant global read and execute permissions so standard user accounts can run the script:

```bash
sudo chmod a+rx /opt/WRF_GNU/patch_wrf_env.sh
```

## 4. Create a System-Wide Command Alias

Link the script to `/usr/local/bin` so you can run `patch_wrf` as a standard Linux command from anywhere on the machine:

```bash
sudo ln -sf /opt/WRF_GNU/patch_wrf_env.sh /usr/local/bin/patch_wrf
```

*Verification:* Run `which patch_wrf`. The terminal should return `/usr/local/bin/patch_wrf`.

## 5. Usage

Whenever you generate a new simulation workspace, apply all environment fixes immediately by running:

```bash
patch_wrf ~/path/to/your/simulation_folder
```
