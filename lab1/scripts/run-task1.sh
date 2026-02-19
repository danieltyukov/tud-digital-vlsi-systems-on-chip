#!/bin/bash
# ET4351 Lab 1 - Task 1: Hello World
# Compiles hello.c firmware and runs PicoSoC simulation in QuestaSim
# Expected output: "Hello, World!" via UART, with latency in clock cycles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/task1-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Task 1: Hello World ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
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
echo "=== Compiling hello.c firmware ==="
cd ~/lab1/task1/firmware
make clean
make hello
echo ""
echo "=== Compilation successful ==="

echo ""
echo "=== Running QuestaSim simulation ==="
cd ~/lab1/task1/questasim
source task1.sh

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
