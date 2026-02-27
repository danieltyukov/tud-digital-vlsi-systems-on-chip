#!/bin/bash
# ET4351 Lab 2 - Task 2: Post-Synthesis Simulation of PicoSoC
# Runs the post-synthesis (structural) simulation of PicoSoC
# Expected output: "Hello, World!" via UART on the terminal

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/task2-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Task 2: Post-Synthesis Simulation of PicoSoC ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
# Ensure lab2 files exist
if [ ! -d ~/lab2 ]; then
    cp -r /data/labs/2025/labs/lab2 ~/
    echo "Lab2 files copied."
else
    echo "Lab2 files already exist."
fi

# Setup EDA environment
cd ~/lab2
source setup.sh

# Verify synthesis outputs exist from Task 1
echo "=== Checking Task 1 synthesis outputs ==="
if [ -f ~/lab2/task/synth/outputs/et4351.struct.v ] && \
   [ -f ~/lab2/task/synth/outputs/et4351.struct.sdc ] && \
   [ -f ~/lab2/task/synth/outputs/et4351.struct.sdf ]; then
    echo "Synthesis outputs found:"
    ls -lh ~/lab2/task/synth/outputs/et4351.struct.*
else
    echo "ERROR: Synthesis outputs not found! Run Task 1 first."
    exit 1
fi

########################################
# Post-synthesis structural simulation
########################################
echo ""
echo "=============================================="
echo "=== Running Post-Synthesis Simulation ==="
echo "=============================================="
cd ~/lab2/task/sim_struct

echo ""
echo "--- tb_et4351.sh contents ---"
cat tb_et4351.sh
echo "--- end ---"

echo ""
echo "=== Starting simulation (this may take a while for PicoSoC) ==="
source tb_et4351.sh

echo ""
echo "=== Task 2 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
