# Centralized CM1 Environment Patch Setup (`patch_cm1`)

Placing the patch script directly in the `/opt/WRF_GNU` folder centralizes your administration tools alongside the core CM1 installation. Because `/opt` is a system-protected directory, you must use `sudo` to create and configure the file, after which any standard user can execute it on their local simulation folders without admin rights.

## 1. Create the Script in `/opt`

Create the centralized patch script directly inside your installation directory:

```bash
sudo nano /opt/WRF_GNU/patch_cm1_env.sh
```

## 2. Paste the Patching Logic

Paste the following script into the editor. It dynamically locates your CM1 build inside `/opt/WRF_GNU`, resolves the target workspace path, symlinks the `cm1.exe` binary along with all required radiation and lookup tables, and verifies whether `namelist.input` and `input_sounding` are present.

```bash
#!/bin/bash

# Ensure a directory was provided
if [ -z "$1" ]; then
    echo "Error: Please provide the target directory."
    echo "Usage: patch_cm1 /path/to/cm1/folder"
    exit 1
fi

# Resolve absolute path of the target directory
TARGET_DIR=$(realpath "$1")
OPT_DIR="/opt/WRF_GNU"
CM1_DIR=$(find "$OPT_DIR" -maxdepth 1 -type d -iname "*cm1*" | head -n 1)

if [ -z "$CM1_DIR" ]; then
    echo "Error: Could not locate CM1 directory inside $OPT_DIR."
    exit 1
fi

echo "Patching CM1 environment in: $TARGET_DIR"
echo "Source installation: $CM1_DIR"
cd "$TARGET_DIR" || exit

# Link CM1 executable and required radiation/lookup tables
echo " -> Linking cm1.exe and physics/radiation tables..."
ln -sf "$CM1_DIR/run/cm1.exe" .
ln -sf "$CM1_DIR/run/"*DATA* . 2>/dev/null || true
ln -sf "$CM1_DIR/run/"*.TBL* . 2>/dev/null || true
ln -sf "$CM1_DIR/run/RRTMG*" . 2>/dev/null || true

# Check for namelist.input and input_sounding
if [ ! -f "namelist.input" ]; then
    echo " -> Note: namelist.input not found. Copy one from $CM1_DIR/run/config_files/<case>/"
fi

if [ ! -f "input_sounding" ]; then
    echo " -> Note: input_sounding not found (required for idealized cases)."
fi

echo "Patch complete! Reminder: Ensure 'ulimit -s unlimited' is active."
```

Press `Ctrl+O`, hit `Enter` to save, and `Ctrl+X` to exit `nano`.

## 3. Make the Script Executable

Grant global read and execute permissions so standard user accounts can run the script:

```bash
sudo chmod a+rx /opt/WRF_GNU/patch_cm1_env.sh
```

## 4. Create a System-Wide Command Alias

Link the script to `/usr/local/bin` so you can run `patch_cm1` as a standard Linux command from anywhere on the machine:

```bash
sudo ln -sf /opt/WRF_GNU/patch_cm1_env.sh /usr/local/bin/patch_cm1
```

*Verification:* Run `which patch_cm1`. The terminal should return `/usr/local/bin/patch_cm1`.

## 5. Usage Workflow

Whenever you spin up a new CM1 simulation folder, copy your desired idealized case configuration files and run `patch_cm1`:

```bash
mkdir -p ~/cm1_workspace/my_case
cp /opt/WRF_GNU/cm1r22.0/run/config_files/supercell/* ~/cm1_workspace/my_case/
patch_cm1 ~/cm1_workspace/my_case
```

*(Note: Ensure `ulimit -s unlimited` is active in your terminal session before executing `./cm1.exe` or `mpirun -np 4 ./cm1.exe`.)*
