#!/bin/bash
# ET4351 Task 2: Dummy Accelerator
# Compiles dummy_accel.c and runs PicoSoC simulation with the accelerator
# Expected output: "Accelerator Output: 0x00012345"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/credentials.txt"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

echo "=== ET4351 Task 2: Dummy Accelerator ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE'
# Setup environment
cd ~/lab1
source setup.sh

# Add RISC-V compiler to PATH
export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"

# Ensure lab files exist
if [ ! -d ~/lab1 ]; then
    cp -r /data/labs/2026/labs/lab1 ~/
    echo "Lab files copied."
fi

echo "=== Step 1: Compile dummy_accel.c ==="
cd ~/lab1/task2/firmware
make clean 2>/dev/null
make dummy_accel
echo ""

echo "=== Step 2: Run QuestaSim simulation ==="
cd ~/lab1/task2/questasim
source task2.sh
echo ""

echo "=== Task 2 complete! ==="
REMOTE
