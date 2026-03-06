#!/bin/bash
# ET4351 Lab 3 - Tutorial: Placement (Section 3.4)
# Loads power plan checkpoint, places standard cells, runs pre-CTS timing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-placement-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Placement (3.4) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Placement ==="

cat > /tmp/innovus_placement.tcl << 'TCL'
# Load power plan checkpoint
source checkpoints/et4351_pplan.enc

# Restore variables needed
source ./scripts/1.set_variable.tcl

# Run placement
source ./scripts/5.place.tcl

puts ""
puts "=== Placement complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_placement.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Checkpoint ---"
ls -lh ~/lab3/tut/pnr/checkpoints/ 2>/dev/null || echo "No checkpoints found"
echo ""
echo "--- Pre-CTS Timing Report ---"
cat ~/lab3/tut/pnr/timingReports/preCTS/et4351.summary 2>/dev/null || echo "No pre-CTS timing summary found"
echo ""
echo "--- Pre-CTS Power Report ---"
head -50 ~/lab3/tut/pnr/powerReports/preCTS.rpt 2>/dev/null || echo "No pre-CTS power report found"
echo ""
echo "--- Check Place Report ---"
cat ~/lab3/tut/pnr/verifyReports/checkPlace.rpt 2>/dev/null || echo "No checkPlace report found"
echo ""
echo "=== Placement complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
