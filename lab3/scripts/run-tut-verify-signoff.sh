#!/bin/bash
# ET4351 Lab 3 - Tutorial: Verification & Signoff (Section 3.7)
# Loads route checkpoint, runs DRC/LVS/antenna checks, final reports, exports.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-verify-signoff-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Verification & Signoff (3.7) ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Verification & Signoff ==="

cat > /tmp/innovus_verify_signoff.tcl << 'TCL'
# Load route checkpoint
source checkpoints/et4351_route.enc

# Restore variables
source ./scripts/1.set_variable.tcl

# Run verification (DRC, connectivity, antenna)
source ./scripts/8.verify.tcl

# Run final reports (timing, power, area, noise)
source ./scripts/9.report.tcl

# Export (Verilog netlist, SDF, GDS, final checkpoint)
source ./scripts/10.export.tcl

puts ""
puts "=== Verification & Signoff complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_verify_signoff.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Verify: Connectivity ---"
cat ~/lab3/tut/pnr/verifyReports/verifyConnectivity.rpt 2>/dev/null || echo "No connectivity report found"
echo ""
echo "--- Verify: DRC ---"
cat ~/lab3/tut/pnr/verifyReports/verify_drc.rpt 2>/dev/null || echo "No DRC report found"
echo ""
echo "--- Verify: Antenna ---"
head -50 ~/lab3/tut/pnr/verifyReports/verifyProcessAntenna.rpt 2>/dev/null || echo "No antenna report found"
echo ""
echo "--- Final Reports: Power ---"
cat ~/lab3/tut/pnr/finalReports/report_power.rpt 2>/dev/null || echo "No final power report found"
echo ""
echo "--- Final Reports: Area ---"
cat ~/lab3/tut/pnr/finalReports/report_area.rpt 2>/dev/null || echo "No final area report found"
echo ""
echo "--- Final Reports: Setup Timing Summary ---"
cat ~/lab3/tut/pnr/finalReports/report_timing/et4351.summary 2>/dev/null || echo "No final setup timing summary found"
echo ""
echo "--- Final Reports: Hold Timing Summary ---"
cat ~/lab3/tut/pnr/finalReports/report_timing_hold/et4351.summary 2>/dev/null || echo "No final hold timing summary found"
echo ""
echo "--- Exports ---"
ls -lh ~/lab3/tut/pnr/outputs/ 2>/dev/null || echo "No outputs found"
echo ""
echo "--- Final Checkpoint ---"
ls -lh ~/lab3/tut/pnr/checkpoints/et4351_done* 2>/dev/null || echo "No final checkpoint found"
echo ""
echo "=== Verification & Signoff complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
