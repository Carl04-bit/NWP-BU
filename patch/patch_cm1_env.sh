sudo tee /opt/WRF_GNU/patch_cm1_env.sh > /dev/null << 'EOF'
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
EOF
