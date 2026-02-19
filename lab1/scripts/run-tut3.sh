#!/bin/bash
# ET4351 Tutorial 3: Compiling RISC-V C Programs
# Compiles sum.c using RISC-V cross-compiler, step-by-step and via Makefile

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/credentials.txt"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

echo "=== ET4351 Tutorial 3: Compiling RISC-V C Programs ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE'
# Setup environment
cd ~/lab1
source setup.sh

# Add RISC-V compiler to PATH if not already there
export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"
if ! grep -q 'picorv32-utils' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="/data/picorv32-utils/riscv32imc/bin:$PATH"' >> ~/.bashrc
    echo "Added RISC-V compiler to ~/.bashrc"
fi

cd ~/lab1/tut3/firmware

echo "=== Step 1: Inspect sum.c ==="
cat sum.c
echo ""

echo "=== Step 2: Compile C to assembly (.s) ==="
riscv32-unknown-elf-gcc -S sum.c -o sum.s -march=rv32imc
echo "Generated sum.s:"
cat sum.s
echo ""

echo "=== Step 3: Assemble to object file (.o) ==="
riscv32-unknown-elf-gcc -c sum.s -o sum.o
file sum.o
echo ""

echo "=== Step 4: Link to ELF executable ==="
echo "Linkerscript:"
cat linkerscript.ld
echo ""
riscv32-unknown-elf-ld sum.o -o sum.elf -T linkerscript.ld
file sum.elf
echo ""

echo "=== Step 5: Clean up and rebuild with Makefile ==="
make clean
echo ""
echo "Running make..."
make
echo ""
file sum.elf
echo ""

echo "=== Tutorial 3 complete! ==="
REMOTE
