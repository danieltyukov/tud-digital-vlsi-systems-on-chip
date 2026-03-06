#!/bin/bash
# ET4351 Lab 3 - Tutorial: Clock Tree Synthesis (Section 3.5)
# Loads placement checkpoint, runs CTS, post-CTS hold fixing, reports.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-cts-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: CTS (3.5) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Clock Tree Synthesis ==="

cat > /tmp/innovus_cts.tcl << 'TCL'
# Load placement checkpoint
source checkpoints/et4351_place.enc

# Restore variables
source ./scripts/1.set_variable.tcl

# Run CTS
source ./scripts/6.cts.tcl

puts ""
puts "=== CTS complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_cts.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Checkpoint ---"
ls -lh ~/lab3/tut/pnr/checkpoints/ 2>/dev/null || echo "No checkpoints found"
echo ""
echo "--- Post-CTS Hold Timing Report ---"
cat ~/lab3/tut/pnr/timingReports/postCTSHold/et4351.summary 2>/dev/null || echo "No post-CTS timing summary found"
echo ""
echo "--- Clock Tree Report ---"
cat ~/lab3/tut/pnr/clockReports/CT.rpt 2>/dev/null || echo "No clock tree report found"
echo ""
echo "--- Post-CTS Power Report (first 30 lines) ---"
head -30 ~/lab3/tut/pnr/powerReports/postCTSHold.rpt 2>/dev/null || echo "No post-CTS power report found"
echo ""
echo "=== CTS complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
