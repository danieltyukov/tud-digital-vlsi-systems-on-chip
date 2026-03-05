#!/bin/bash
# ET4351 Lab 3 - Tutorial: Floorplanning (Section 3.2)
# Runs the floorplan script in Innovus (non-GUI mode).
# Sets die size, places SRAM macros with halos, saves checkpoint.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-floorplan-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Floorplanning (3.2) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Load design + Floorplan ==="

# Create a TCL script that loads design, runs floorplan, then exits
cat > /tmp/innovus_floorplan.tcl << 'TCL'
# Load design
source ./scripts/1.set_variable.tcl
source ./scripts/2.0.load_design.tcl
source ./scripts/2.1.set_library_n_sdc.tcl

# Run floorplanning
source ./scripts/3.0.fplan.tcl

# Print floorplan check report
puts ""
puts "=== Floorplan Check Report ==="
if {[file exists verifyReports/checkFPlan.rpt]} {
    set fp [open verifyReports/checkFPlan.rpt r]
    puts [read $fp]
    close $fp
}

puts ""
puts "=== Floorplan complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_floorplan.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Checkpoint ---"
ls -lh ~/lab3/tut/pnr/checkpoints/ 2>/dev/null || echo "No checkpoints found"
echo ""
echo "--- Floorplan report ---"
cat ~/lab3/tut/pnr/verifyReports/checkFPlan.rpt 2>/dev/null || echo "No floorplan report found"
echo ""
echo "=== Floorplanning complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
