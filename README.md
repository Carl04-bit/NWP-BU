# WRF and CM1: System Prerequisites & Directory Architecture

This guide outlines the necessary system packages and the organizational structure used for deploying the Weather Research and Forecasting (WRF) model, the WRF Preprocessing System (WPS), and Cloud Model 1 (CM1) on a local Ubuntu Linux Virtual Machine.

Our deployment strategy uses a **Centralized Installation** with **Local Workspaces** to maximize storage efficiency and maintain a clean, reusable system.

---

## 1. System Prerequisites

Before compiling WRF, WPS, or CM1, the base Ubuntu system must have the correct compilers, MPI libraries, and data processing tools installed.

### System Packages (Ubuntu/Debian)
Run the following command to install all necessary dependencies via the `apt` package manager:

```bash
sudo apt update
sudo apt install -y gcc g++ gfortran build-essential csh tcsh m4 \
                    libopenmpi-dev openmpi-bin \
                    libnetcdf-dev libnetcdff-dev netcdf-bin \
                    libpng-dev zlib1g-dev git
```

### Manual Jasper Compilation (Required for WPS)
Modern Ubuntu repositories no longer package a compatible `libjasper-dev` library, which WPS requires to process GRIB2 meteorological data (like GFS). This must be compiled manually and placed in our central directory prior to running the installation scripts.

```bash
sudo mkdir -p /opt/WRF_GNU/grib2
cd /opt/WRF_GNU
sudo wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
sudo tar -xf jasper-1.900.1.tar.gz
cd jasper-1.900.1/
sudo ./configure --prefix=/opt/WRF_GNU/grib2
sudo make
sudo make install
```

---

## 2. Directory Architecture

To prevent multiple users from downloading redundant multi-gigabyte files (like geographic data or model source code), the software is split into two distinct areas: the **Centralized Hub (`/opt`)** and the **Local Workspace (`$HOME`)**.

### The Centralized Hub: `/opt/WRF_GNU`
This directory requires `sudo` privileges to modify. It houses the compiled executables, static geographic data, and shared environment scripts. **Users should never run simulations directly in this directory.**

```text
/opt/WRF_GNU/
│
├── setenv-wrf.sh        # Master environment script (loads NetCDF, MPI, Compilers)
├── compile-wrf.sh       # Automated, idempotent WRF & WPS installation script
├── compile-cm1.sh       # Automated CM1 installation script
├── patch-wrf.sh         # Patching tool
│
├── grib2/               # Manually compiled Jasper libraries
├── WPS_GEOG/            # Shared high-resolution static geographic data (~30GB)
│
├── WRF-4.8.0/           # Compiled WRF source code and executables
├── WPS-4.7.0/           # Compiled WPS source code and executables
└── cm1r22.0/            # Compiled CM1 source code and executables
```

### The Local Workspace: `$HOME/wrf_workspace`
This is where users actually configure and run their simulations. Users create folders here and use **symbolic links** (shortcuts) to point to the heavy executables and lookup tables in `/opt/WRF_GNU`. This keeps the system lightweight and ensures users have write-access to their output files.

```text
$HOME/wrf_workspace/
│
├── my_wrf_simulation/          # A user's specific WRF test case
│   ├── WPS/
│   │   ├── namelist.wps        # Copied physically (Users edit this!)
│   │   ├── geogrid.exe         # Symlink -> /opt/WRF_GNU/WPS-4.7.0/geogrid.exe
│   │   └── ...                 # Symlinks to other WPS executables & tables
│   │
│   └── WRF/
│       ├── namelist.input      # Copied physically (Users edit this!)
│       ├── wrf.exe             # Symlink -> /opt/WRF_GNU/WRF-4.8.0/run/wrf.exe
│       ├── wrfout_d01_...      # Output files generated here (Can be large!)
│       └── ...                 # Symlinks to other WRF executables & tables
│
└── my_cm1_simulation/          # A user's specific CM1 test case
    ├── namelist.input          # Copied physically (Users edit this!)
    ├── cm1.exe                 # Symlink -> /opt/WRF_GNU/cm1r22.0/run/cm1.exe
    ├── cm1out_000001.nc        # Output files generated here
    └── ...                     # Symlinks to CM1 lookup tables
```

### Summary of Workflow
1. Administrators set up `/opt/WRF_GNU` once using the provided compilation scripts.
2. Users source `/opt/WRF_GNU/setenv-wrf.sh` in their terminals.
3. Users create folders in `$HOME/wrf_workspace`, link the executables, copy the `namelist` files, and run their models.
4. User revises `opt/WRF_GNU/patch-wrf` to symlink necessary files (also as a corrective tool)

### Developer Contact

Whenever errors occur when setting up, compiling, or running executables, please contact me through email:
`carlbuenaflor09@gmail.com`
`clbuenaflor@iesm.upd.edu.ph`
