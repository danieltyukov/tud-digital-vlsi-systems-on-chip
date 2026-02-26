#!/bin/bash
# ET4351 Lab 2 - Tutorial 3: Clock Gating & Power Estimation
# Synthesizes the 4-bit multiplier WITH clock gating using synth_cg.tcl
# Then extracts clock gating report and compares area/timing with Tutorial 1 (no CG)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut3-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Tutorial 3: Clock Gating & Power Estimation ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
# Ensure lab2 files exist
if [ ! -d ~/lab2 ]; then
    cp -r /data/labs/2025/labs/lab2 ~/
    echo "Lab2 files copied."
else
    echo "Lab2 files already exist."
fi

# Setup EDA environment
cd ~/lab2
source setup.sh

cd ~/lab2/tut/synth

echo ""
echo "=== Step 1: Synthesis WITH Clock Gating ==="

# Create a custom TCL script that does CG synthesis without suspend
cat > scripts/synth_tut3_cg.tcl << 'TCL'
# Tutorial 3: Synthesis with Clock Gating + Reports
# Based on synth_cg.tcl but without suspend points

# Step 1: Setup PDK paths
source scripts/synth_set.tcl

# Step 2: Elaboration with clock gating attributes
puts "\n ##################################"
puts " #                                #"
puts " #    ELABORATION (Clock Gating)  #"
puts " #                                #"
puts " ##################################\n"

set INPUT_PATH "../src"
set DESIGN "mul"

# Enable CG BEFORE elaboration (root-level attribute)
set_attribute lp_insert_clock_gating true /

read_hdl -sv "${INPUT_PATH}/${DESIGN}.sv"
set_attr hdl_error_on_latch true /
set_attr auto_ungroup none /
elaborate $DESIGN
read_sdc "${INPUT_PATH}/${DESIGN}.sdc"

# CG options AFTER elaboration (design-level attributes)
set_attribute lp_clock_gating_control_point precontrol /des*/*
set_attribute lp_clock_gating_style latch /des*/*
set_attribute lp_insert_discrete_clock_gating_logic true

# Step 3: Generic synthesis
syn_generic

# Step 4: Technology mapping
puts "\n ##################################"
puts " #                                #"
puts " #    MAPPING (Clock Gating)      #"
puts " #                                #"
puts " ##################################\n"

syn_map

puts "Synthesis with Clock Gating complete"

# Step 5: Reports
puts "\n ##################################"
puts " #                                #"
puts " #    REPORTS                     #"
puts " #                                #"
puts " ##################################\n"

file mkdir reports/cg

# Clock gating report
puts "=== Clock Gating Report ==="
report_clock_gating
report_clock_gating > reports/cg/mul_clock_gating.rpt

# Area report
puts "\n=== Area Report (with CG) ==="
report area
report area > reports/cg/mul_area_cg.rpt

# Timing report
puts "\n=== Timing Report (with CG) ==="
report timing -worst 10
report timing -worst 10 > reports/cg/mul_timing_cg.rpt

# Gate report
puts "\n=== Gates Report (with CG) ==="
report gates
report gates > reports/cg/mul_gates_cg.rpt

# Power report (without activity annotation - default toggle rate)
puts "\n=== Power Report (with CG, no activity annotation) ==="
report_power
report_power > reports/cg/mul_power_cg.rpt

# Export netlist for post-synthesis simulation
puts "\n ##################################"
puts " #                                #"
puts " #    EXPORT (Clock Gating)       #"
puts " #                                #"
puts " ##################################\n"

change_names -verilog
write_hdl ${DESIGN} > ${OUTPUTS_PATH}/${DESIGN}.cg.struct.v
write_sdc ${DESIGN} > ${OUTPUTS_PATH}/${DESIGN}.cg.struct.sdc
write_sdf -nonegchecks -interconn "interconnect" -delimiter "/" > ${OUTPUTS_PATH}/${DESIGN}.cg.struct.sdf

puts "\n=== Clock Gating Synthesis Complete ==="
exit
TCL

# Run CG synthesis
genus -legacy_ui -64 -f scripts/synth_tut3_cg.tcl -log genus_tut3_cg

echo ""
echo "=============================================="
echo "=== Step 2: Synthesis WITHOUT Clock Gating ==="
echo "=============================================="

# Now run synthesis WITHOUT clock gating for comparison
cat > scripts/synth_tut3_nocg.tcl << 'TCL'
# Synthesis WITHOUT clock gating for comparison

source scripts/synth_set.tcl

# Explicitly DISABLE clock gating
set_attribute lp_insert_clock_gating false /

set INPUT_PATH "../src"
set DESIGN "mul"

read_hdl -sv "${INPUT_PATH}/${DESIGN}.sv"
set_attr hdl_error_on_latch true /
set_attr auto_ungroup none /
elaborate $DESIGN
read_sdc "${INPUT_PATH}/${DESIGN}.sdc"
syn_generic
syn_map

file mkdir reports/nocg

puts "\n=== Area Report (no CG) ==="
report area
report area > reports/nocg/mul_area_nocg.rpt

puts "\n=== Timing Report (no CG) ==="
report timing -worst 10
report timing -worst 10 > reports/nocg/mul_timing_nocg.rpt

puts "\n=== Gates Report (no CG) ==="
report gates
report gates > reports/nocg/mul_gates_nocg.rpt

puts "\n=== Power Report (no CG, no activity annotation) ==="
report_power
report_power > reports/nocg/mul_power_nocg.rpt

puts "\n=== Clock Gating Report (no CG - should show 0%) ==="
report_clock_gating
report_clock_gating > reports/nocg/mul_clock_gating_nocg.rpt

puts "\n=== No-CG Synthesis Complete ==="
exit
TCL

genus -legacy_ui -64 -f scripts/synth_tut3_nocg.tcl -log genus_tut3_nocg

echo ""
echo "=============================================="
echo "=== Step 3: Comparison Summary ==="
echo "=============================================="

echo ""
echo "--- Clock Gating Report (WITH CG) ---"
cat reports/cg/mul_clock_gating.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Clock Gating Report (WITHOUT CG) ---"
cat reports/nocg/mul_clock_gating_nocg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Area (WITH CG) ---"
cat reports/cg/mul_area_cg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Area (WITHOUT CG) ---"
cat reports/nocg/mul_area_nocg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Power (WITH CG) ---"
cat reports/cg/mul_power_cg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Power (WITHOUT CG) ---"
cat reports/nocg/mul_power_nocg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Timing Worst Slack (WITH CG) ---"
grep "Timing slack" reports/cg/mul_timing_cg.rpt 2>/dev/null | head -1 || echo "NOT FOUND"

echo ""
echo "--- Timing Worst Slack (WITHOUT CG) ---"
grep "Timing slack" reports/nocg/mul_timing_nocg.rpt 2>/dev/null | head -1 || echo "NOT FOUND"

echo ""
echo "=== Tutorial 3 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
