#!/bin/bash
# ET4351 Lab 3 - Tutorial: Post-Layout Simulation (Section 3.8)
# Runs setup (max) and hold (min) post-layout simulations with ModelSim.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-post-layout-sim-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Post-Layout Simulation (3.8) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/sim_phys

echo "=== Running Setup (Max) Post-Layout Simulation ==="
bash run_pnr_sim_setup_max.sh

echo ""
echo "=== Setup simulation complete ==="
echo ""

echo "--- Checking output.txt ---"
cat output.txt 2>/dev/null || echo "No output.txt found"
echo ""

echo "--- Verifying setup simulation output ---"
python3 verify.py 2>&1 || echo "Verification returned non-zero"
echo ""

echo "--- VCD files ---"
ls -lh vcd/ 2>/dev/null || echo "No VCD directory found"
echo ""

echo "=== Running Hold (Min) Post-Layout Simulation ==="
bash run_pnr_sim_hold_min.sh

echo ""
echo "=== Hold simulation complete ==="
echo ""

echo "--- Checking output.txt ---"
cat output.txt 2>/dev/null || echo "No output.txt found"
echo ""

echo "--- Verifying hold simulation output ---"
python3 verify.py 2>&1 || echo "Verification returned non-zero"
echo ""

echo "--- VCD files ---"
ls -lh vcd/ 2>/dev/null || echo "No VCD directory found"
echo ""

echo "=== Post-Layout Simulation complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
