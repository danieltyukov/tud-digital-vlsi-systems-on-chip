#!/bin/bash
# ET4351 Lab 3 - Tutorial: Routing (Section 3.6)
# Loads CTS checkpoint, adds fillers, routes design, post-route optimization.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-routing-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Routing (3.6) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Routing ==="

cat > /tmp/innovus_routing.tcl << 'TCL'
# Load CTS checkpoint
source checkpoints/et4351_cts.enc

# Restore variables
source ./scripts/1.set_variable.tcl

# Run routing
source ./scripts/7.route.tcl

puts ""
puts "=== Routing complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_routing.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Checkpoint ---"
ls -lh ~/lab3/tut/pnr/checkpoints/ 2>/dev/null || echo "No checkpoints found"
echo ""
echo "--- Post-Route Hold Timing Summary ---"
cat ~/lab3/tut/pnr/timingReports/postRouteHold/et4351.summary 2>/dev/null || echo "No post-route timing summary found"
echo ""
echo "--- Post-Route Hold (hold mode) Summary ---"
cat ~/lab3/tut/pnr/timingReports/postRouteHold_hold/et4351.summary 2>/dev/null || echo "No post-route hold summary found"
echo ""
echo "=== Routing complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
