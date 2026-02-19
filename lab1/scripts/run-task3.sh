#!/bin/bash
# ET4351 Lab 1 - Task 3: FFT Algorithm
# Compiles fft.c firmware and runs PicoSoC simulation in QuestaSim
# Then verifies the FFT output with verify.py

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/task3-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Task 3: FFT Algorithm ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE'
# Copy lab files if not already present
if [ ! -d ~/lab1 ]; then
    cp -r /data/labs/2026/labs/lab1 ~/
    echo "Lab files copied."
else
    echo "Lab files already exist."
fi

# Setup EDA environment
cd ~/lab1
source setup.sh

# Add RISC-V compiler to PATH
export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"

echo ""
echo "=== Compiling fft.c firmware ==="
cd ~/lab1/task3/firmware
make clean
make
echo ""
echo "=== Compilation successful ==="

echo ""
echo "=== Running QuestaSim simulation ==="
cd ~/lab1/task3/questasim
source task3.sh

echo ""
echo "=== Verifying FFT output ==="
python verify.py

echo ""
echo "=== Task 3 complete! ==="
REMOTE

# Capture output
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "Script finished successfully."
else
    echo ""
    echo "Script finished with exit code $EXIT_CODE"
fi
