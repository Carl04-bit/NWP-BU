# Running a CM1 Simulation

This guide explains how to set up your environment, prepare your test case, and run an idealized simulation using the centralized Cloud Model 1 (CM1) installation. We will use symbolic links to save disk space and protect the core installation files.

## Step 1: Environment Setup

Just like with WRF, you must load the shared environment variables and remove memory limits to prevent segmentation faults. Run this in your terminal:

```
source /opt/WRF_GNU/setenv-wrf.sh
ulimit -s unlimited

```

## Step 2: Set Up Your Workspace via Symlinks

CM1 requires various lookup tables (e.g., for microphysics schemes) and the main executable to run. We will link these into your personal workspace and make a physical copy of the namelist so you can edit it safely.

```
# 1. Create and enter your personal workspace directory for CM1
mkdir -p $HOME/wrf_workspace/cm1_test
cd $HOME/wrf_workspace/cm1_test

# 2. Link ALL standard lookup tables and executables from the central run directory
ln -sf /opt/WRF_GNU/cm1r22.0/run/* .

# 3. Remove the linked namelist.input and replace it with a physical, writable copy
rm namelist.input
cp /opt/WRF_GNU/cm1r22.0/run/namelist.input .

```

## Step 3: Configure the Simulation (Namelist)

CM1 is driven entirely by the `namelist.input` file. Open the file in your preferred text editor (like `nano` or `vim`):

```
nano namelist.input

```

### Key Parameters to Check/Modify:

* **Grid Dimensions (`nx`, `ny`, `nz`):** Defines the number of grid points in the X, Y, and Z directions. For a 2D simulation, set `ny = 1`.

* **Grid Spacing (`dx`, `dy`, `dz`):** Defines the physical distance between grid points (usually in meters).

* **Time Step (`dtl`):** The large time step in seconds. Ensure this satisfies the Courant-Friedrichs-Lewy (CFL) condition to prevent model instability.

* **Simulation Length (`timax`):** Total integration time of the simulation in seconds.

* **Output Frequency (`tapfrq`):** How often 3D output files are written (in minutes or seconds, depending on your flags).

* **Base State / Initialization (`ibnd`, `imoist`):** Controls the initial sounding and atmospheric setup.

*Tip: The default `namelist.input` provided by CM1 is pre-configured for a supercell thunderstorm simulation. You can run it as-is to test your installation!*

## Step 4: Run the Model

Once your namelist is configured, you can execute CM1 using MPI (Message Passing Interface) to distribute the workload across multiple CPU cores.

```
# Run CM1 using 4 cores (change the number to match your VM's available CPUs)
mpirun -np 4 ./cm1.exe

```

### Monitoring the Run

As the model runs, it will print its progress to the terminal. You should see time step information, maximum vertical velocities (`wmax`), and output file generation alerts.

* **Outputs:** NetCDF output files will be generated in your current directory (typically named `cm1out_*.nc` depending on your namelist settings).

* **Errors:** If the model crashes, check the `cm1.out` or standard terminal output for clues (often related to CFL violations requiring a smaller `dtl` time step).
