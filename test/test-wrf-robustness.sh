#!/bin/bash
# WRF/WPS Robustness Test: Hurricane Matthew
# This script fully automates a single-domain test run to validate the /opt installation.

set -e # Exit immediately if a command exits with a non-zero status

TEST_DIR="$HOME/wrf_robustness_test"
OPT_DIR="/opt/WRF_GNU"
WPS_DIR="$OPT_DIR/WPS-4.7.0"
WRF_MAIN="$OPT_DIR/WRF-4.8.0/main"
WRF_RUN="$OPT_DIR/WRF-4.8.0/run"

echo "===================================================="
echo "1. Initializing Workspace & Downloading Data"
echo "===================================================="
mkdir -p "$TEST_DIR/data"
cd "$TEST_DIR/data"

if [ ! -f "matthew_1deg.tar.gz" ]; then
    wget https://www2.mmm.ucar.edu/wrf/TUTORIAL_DATA/matthew_1deg.tar.gz
    tar -xvzf matthew_1deg.tar.gz
else
    echo "Matthew data already exists. Skipping download."
fi

echo "===================================================="
echo "2. Configuring and Running WPS (Preprocessing)"
echo "===================================================="
cd "$TEST_DIR"

# Link WPS executables and Vtable
ln -sf "$WPS_DIR"/*.exe .
ln -sf "$WPS_DIR/ungrib/Variable_Tables/Vtable.GFS" Vtable
"$WPS_DIR/link_grib.csh" "$TEST_DIR/data/matthew/fnl"

# Generate namelist.wps with hardcoded table paths
cat << EOF > namelist.wps
&share
 wrf_core = 'ARW',
 max_dom = 1,
 start_date = '2016-10-06_00:00:00',
 end_date   = '2016-10-08_00:00:00',
 interval_seconds = 21600,
 io_form_geogrid = 2,
/
&geogrid
 parent_id         = 1,
 parent_grid_ratio = 1,
 i_parent_start    = 1,
 j_parent_start    = 1,
 e_we              = 91,
 e_sn              = 100,
 geog_data_res     = 'default',
 dx = 27000,
 dy = 27000,
 map_proj = 'mercator',
 ref_lat   = 28.0,
 ref_lon   = -75.0,
 truelat1  = 28.0,
 truelat2  = 0,
 stand_lon = -75.0,
 geog_data_path = '$OPT_DIR/WPS_GEOG/'
 opt_geogrid_tbl_path = '$WPS_DIR/geogrid/'
/
&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/
&metgrid
 fg_name = 'FILE',
 io_form_metgrid = 2,
 opt_metgrid_tbl_path = '$WPS_DIR/metgrid/'
/
EOF

echo "Running geogrid..."
./geogrid.exe > geogrid.log 2>&1
echo "Running ungrib..."
./ungrib.exe > ungrib.log 2>&1
echo "Running metgrid..."
./metgrid.exe > metgrid.log 2>&1

echo "===================================================="
echo "3. Configuring and Running WRF"
echo "===================================================="

# Link WRF executables and exhaustive physics/radiation tables
ln -sf "$WRF_MAIN"/*.exe .
ln -sf "$WRF_RUN"/*_DATA .
ln -sf "$WRF_RUN"/*.TBL .
ln -sf "$WRF_RUN"/ozone* .
ln -sf "$WRF_RUN"/RRTMG* .
ln -sf "$WRF_RUN"/CAM* .
ln -sf "$WRF_RUN"/aerosol* .

# Generate namelist.input with CFL-safe dynamics (dt=90, w_damping=1)
cat << EOF > namelist.input
&time_control
 run_days                            = 0,
 run_hours                           = 48,
 run_minutes                         = 0,
 run_seconds                         = 0,
 start_year                          = 2016,
 start_month                         = 10,
 start_day                           = 06,
 start_hour                          = 00,
 end_year                            = 2016,
 end_month                           = 10,
 end_day                             = 08,
 end_hour                            = 00,
 interval_seconds                    = 21600,
 input_from_file                     = .true.,
 history_interval                    = 180,
 frames_per_outfile                  = 1,
 restart                             = .false.,
 restart_interval                    = 1440,
 io_form_history                     = 2,
 io_form_restart                     = 2,
 io_form_input                       = 2,
 io_form_boundary                    = 2,
/
&domains
 time_step                           = 90,
 max_dom                             = 1,
 e_we                                = 91,
 e_sn                                = 100,
 e_vert                              = 45,
 p_top_requested                     = 5000,
 num_metgrid_levels                  = 32,
 dx                                  = 27000,
 dy                                  = 27000,
 grid_id                             = 1,
 parent_id                           = 1,
 i_parent_start                      = 1,
 j_parent_start                      = 1,
 parent_grid_ratio                   = 1,
 parent_time_step_ratio              = 1,
 feedback                            = 1,
 smooth_option                       = 0
/
&physics
 mp_physics                          = 3,
 ra_lw_physics                       = 1,
 ra_sw_physics                       = 1,
 radt                                = 30,
 sf_sfclay_physics                   = 1,
 sf_surface_physics                  = 2,
 bl_pbl_physics                      = 1,
 bldt                                = 0,
 cu_physics                          = 1,
 cudt                                = 5,
 isfflx                              = 1,
 ifsnow                              = 1,
 icloud                              = 1,
 surface_input_source                = 3,
 num_soil_layers                     = 4,
 num_land_cat                        = 21,
 sf_urban_physics                    = 0,
/
&bdy_control
 spec_bdy_width                      = 5,
 spec_zone                           = 1,
 relax_zone                          = 4,
 specified                           = .true.,
/
&dynamics
 w_damping                           = 1,
 diff_opt                            = 1,
 km_opt                              = 4,
 diff_6th_opt                        = 0,
 diff_6th_factor                     = 0.12,
 base_temp                           = 290.,
 damp_opt                            = 3,
 zdamp                               = 5000.,
 dampcoef                            = 0.2,
 khdif                               = 0,
 kvdif                               = 0,
 non_hydrostatic                     = .true.,
 moist_adv_opt                       = 1,
 scalar_adv_opt                      = 1,
/
&namelist_quilt
 nio_tasks_per_group = 0,
 nio_groups = 1,
/
EOF

# Bypass Ubuntu stack limits to prevent segmentation faults
ulimit -s unlimited

echo "Running real.exe..."
./real.exe

echo "Running wrf.exe (this will take time)..."
# If running with MPI in the future, change this to: mpirun -np 2 ./wrf.exe
./wrf.exe

echo "===================================================="
echo "Test complete! Check ~/wrf_robustness_test for wrfout files."
echo "===================================================="
