#!/bin/bash
# ET4351 Lab 3 - Tutorial: Power Planning (Section 3.3)
# Loads floorplan checkpoint, adds power rings/stripes, connects power nets.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-powerplan-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Power Planning (3.3) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Power Planning ==="

cat > /tmp/innovus_powerplan.tcl << 'TCL'
# Load floorplan checkpoint
source checkpoints/et4351_fplan.enc

# Restore variables needed by pplan script (from 1.set_variable.tcl and 3.0.fplan.tcl)
source ./scripts/1.set_variable.tcl
set coregap 34.2
set sram_gap 2.000
set sram_w 36.835

# Run power planning
source ./scripts/4.pplan.tcl

puts ""
puts "=== Power Planning complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_powerplan.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Checkpoint ---"
ls -lh ~/lab3/tut/pnr/checkpoints/ 2>/dev/null || echo "No checkpoints found"
echo ""
echo "=== Power Planning complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
