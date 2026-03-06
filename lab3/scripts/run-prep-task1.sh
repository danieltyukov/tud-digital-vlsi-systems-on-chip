#!/bin/bash
# ET4351 Lab 3 Preparation - Task 1: Synthesize PicoSoC with FFT Accelerator
# Copies lab3_preparation files, compiles firmware, runs behavioral simulation,
# verifies FFT output, and synthesizes the full design using Cadence Genus.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/prep-task1-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 Preparation - Task 1: Synthesize PicoSoC with FFT Accelerator ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
# Copy lab3_preparation files if not already present
if [ ! -d ~/lab3_preparation ]; then
    cp -r /data/labs/2026/labs/lab3_preparation ~/
    echo "lab3_preparation files copied."
else
    echo "lab3_preparation files already exist."
fi

# Setup EDA environment
cd ~/lab3_preparation
source setup.sh

# Add RISC-V compiler to PATH
export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"

cd ~/lab3_preparation/task

echo ""
echo "=== Step 1: Compile firmware ==="
cd firmware
make
echo ""
echo "--- Firmware build output ---"
ls -lh *.hex 2>/dev/null || echo "No hex files found"
ls -lh *.elf 2>/dev/null || echo "No elf files found"

echo ""
echo "=== Step 2: Run behavioral simulation ==="
cd ../sim_behav/
source run_behav_sim.sh

echo ""
echo "=== Step 3: Verify behavioral simulation output ==="
python verify.py

echo ""
echo "=== Step 4: Synthesize PicoSoC with FFT accelerator ==="
cd ../synth
# run_synth.sh sources Genus; append exit to ensure it terminates
cat scripts/synth.tcl > /tmp/synth_prep.tcl
echo -e "\nexit" >> /tmp/synth_prep.tcl
genus -legacy_ui -64 -f /tmp/synth_prep.tcl -log genus_prep

echo ""
echo "--- Checking synthesis outputs ---"
ls -lh outputs/ 2>/dev/null || echo "No outputs directory"

echo ""
echo "--- Area Report ---"
cat reports/struct/*area* 2>/dev/null || echo "No area report found"

echo ""
echo "--- Timing Report (first 100 lines) ---"
head -100 reports/struct/*timing* 2>/dev/null || echo "No timing report found"

echo ""
echo "--- Power Report ---"
cat reports/struct/*power* 2>/dev/null || echo "No power report found"

echo ""
echo "=== Task 1 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
