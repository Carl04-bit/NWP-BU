# CM1 Robustness Test Automation

This guide provides a single, fully automated Bash script to validate your central `/opt/WRF_GNU` CM1 installation.

Unlike WRF, CM1 does not require external geographic data or GRIB preprocessing. This script sets up an isolated workspace, links the `cm1.exe` binary and physics tables, configures a fast 15-minute idealized supercell thunderstorm simulation, unlocks Linux stack size limits (`ulimit -s unlimited`), and runs the model to verify stability.

## The Automation Script

Create a new file named `test_cm1_robustness.sh` in your home directory and paste the following code into it:

```bash
#!/bin/bash
# CM1 v22.0 Robustness Test: Idealized Supercell Thunderstorm
# Validates the centralized /opt/WRF_GNU CM1 installation in an isolated workspace.

set -e # Exit immediately if a command exits with a non-zero status

TEST_DIR="$HOME/cm1_robustness_test"
OPT_DIR="/opt/WRF_GNU"
# Automatically locate the CM1 folder inside /opt/WRF_GNU (e.g., cm1r22.0)
CM1_DIR=$(find "$OPT_DIR" -maxdepth 1 -type d -iname "*cm1*" | head -n 1)

if [ -z "$CM1_DIR" ]; then
    echo "Error: Could not locate CM1 directory inside $OPT_DIR."
    exit 1
fi

echo "===================================================="
echo "1. Initializing CM1 Workspace from: $CM1_DIR"
echo "===================================================="
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Link the compiled CM1 executable and required radiation/lookup tables
ln -sf "$CM1_DIR/run/cm1.exe" .
ln -sf "$CM1_DIR/run/"*DATA* . 2>/dev/null || true
ln -sf "$CM1_DIR/run/"*.TBL* . 2>/dev/null || true
ln -sf "$CM1_DIR/run/RRTMG*" . 2>/dev/null || true

# Copy the default supercell configuration and sounding files
cp "$CM1_DIR/run/config_files/supercell/namelist.input" .
cp "$CM1_DIR/run/config_files/supercell/input_sounding" .

echo "===================================================="
echo "2. Configuring a Fast 15-Minute Validation Run"
echo "===================================================="
# Shorten simulation duration (timax) to 900 seconds (15 mins) for a quick test
sed -i 's/timax.*/timax = 900.0,/' namelist.input

# Set output interval (tapfrq) to 300 seconds (5 mins)
sed -i 's/tapfrq.*/tapfrq = 300.0,/' namelist.input

# Unlock Ubuntu stack size limits to prevent segmentation faults
ulimit -s unlimited

echo "===================================================="
echo "3. Executing cm1.exe"
echo "===================================================="
# If compiled with MPI, replace ./cm1.exe with: mpirun -np 4 ./cm1.exe
./cm1.exe | tee cm1.log

echo "===================================================="
echo "Test complete! Check $TEST_DIR for cm1out_*.nc files."
echo "===================================================="
```

## Running the Test

1. Make the script executable:
   ```bash
   chmod +x ~/test_cm1_robustness.sh
   ```

2. Execute the script:
   ```bash
   ~/test_cm1_robustness.sh
   ```

*(Note: If your CM1 binary was compiled with MPI support instead of OpenMP/serial, edit step 3 in the script to use `mpirun -np 4 ./cm1.exe`, and ensure `nodex * nodey = 4` in `namelist.input`.)*

## Verifying the Output

Once the simulation completes cleanly up to `900.0` seconds without segmentation faults, verify the generated NetCDF files:

```bash
cd ~/cm1_robustness_test
ls -lh cm1out_*.nc
```

You should see `cm1out_000001.nc` through `cm1out_000004.nc` generated in the test directory.
