#!/bin/bash
# ET4351 Lab 3 - Tutorial: Final Power Reports with VCD (Section 3.8 cont.)
# Loads done checkpoint, annotates VCD switching activity, reports power.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut-final-power-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 3 - Tutorial: Final Power Reports with VCD ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
cd ~/lab3
source setup.sh
cd ~/lab3/tut/pnr

echo "=== Running Innovus: Final Power with VCD annotation ==="

cat > /tmp/innovus_final_power.tcl << 'TCL'
# Load the final checkpoint
source checkpoints/et4351_done.enc

# Restore variables
source ./scripts/1.set_variable.tcl

# Power analysis with hold VCD (delay_min corner)
set_power_analysis_mode -report_missing_nets true -corner delay_min -analysis_view analysis_view_power
read_activity_file ../sim_phys/vcd/${DESIGN}.phys.hold.vcd -reset -format VCD -scope testbench/dut
propagate_activity

report_power -outfile powerReports/Final_min_VCDImport.rpt

puts ""
puts "=== Final Power Report (hold VCD) complete ==="
exit
TCL

innovus -no_gui -init /tmp/innovus_final_power.tcl

echo ""
echo "=== Checking outputs ==="
echo "--- Final Power Report (hold VCD) ---"
cat ~/lab3/tut/pnr/powerReports/Final_min_VCDImport.rpt 2>/dev/null || echo "No final power report found"
echo ""
echo "=== Final Power Reports complete ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
