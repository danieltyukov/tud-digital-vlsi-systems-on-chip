#!/bin/bash
# ET4351 Lab 3 Preparation - Task 2: Post-Synthesis Simulation of PicoSoC
# Runs structural (gate-level) simulation of the synthesized PicoSoC with FFT
# accelerator and verifies correctness against golden reference.
# Success: "Test Passed ^_^ Outputs and Gold are identical!!!"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/prep-task2-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 Preparation - Task 2: Post-Synthesis Simulation ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
# Verify lab3_preparation exists
if [ ! -d ~/lab3_preparation ]; then
    echo "ERROR: ~/lab3_preparation not found. Run Task 1 first."
    exit 1
fi

# Setup EDA environment
cd ~/lab3_preparation
source setup.sh

# Add RISC-V compiler to PATH
export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"

echo ""
echo "=== Step 1: Run post-synthesis (structural) simulation ==="
cd ~/lab3_preparation/task/sim_struct
source run_struct_sim.sh

echo ""
echo "=== Step 2: Verify simulation output ==="
python verify.py

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
