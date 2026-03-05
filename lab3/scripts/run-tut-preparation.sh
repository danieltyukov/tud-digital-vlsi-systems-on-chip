#!/bin/bash
# ET4351 Lab 3 - Tutorial: Preparation (Section 3.1)
# Copies lab3 files, creates PnR directories, runs synthesis, and runs
# structural simulation with VCD generation for activity annotation.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-preparation-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Preparation (3.1) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
# Copy lab3 files if not already present
if [ ! -d ~/lab3 ]; then
    cp -r /data/labs/2026/labs/lab3 ~/
    echo "Lab3 files copied."
else
    echo "Lab3 files already exist."
fi

# Setup EDA environment
cd ~/lab3
source setup.sh

# Add RISC-V compiler to PATH
export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"

echo ""
echo "=== Step 1: Create PnR output directories ==="
cd ~/lab3/tut/pnr
mkdir -p initialReports timingReports verifyReports clockReports \
         powerReports densityReports finalReports extLogDir
echo "Directories created:"
ls -d */ 2>/dev/null

echo ""
echo "=== Step 2: Run synthesis ==="
cd ~/lab3/tut/synth
# Genus doesn't exit by default; append exit to the TCL script
(cat scripts/synth.tcl; echo -e "\nexit") > /tmp/synth_lab3.tcl
genus -legacy_ui -64 -f /tmp/synth_lab3.tcl || { echo "Synthesis failed"; exit 1; }

echo ""
echo "--- Checking synthesis outputs ---"
ls -lh ~/lab3/tut/synth/outputs/

echo ""
echo "=== Step 3: Generate firmware ==="
cd ~/lab3/tut/firmware
make

echo ""
echo "=== Step 4: Run structural simulation with VCD ==="
cd ~/lab3/tut/sim_struct
source run_struct_sim_vcd.sh

echo ""
echo "=== Step 5: Verify outputs ==="
echo ""
echo "--- Checking VCD file ---"
find ~/lab3/tut/sim_struct -name "*.vcd" -ls 2>/dev/null || echo "No VCD files found"

echo ""
echo "=== Preparation complete! Ready for PnR in Innovus ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
