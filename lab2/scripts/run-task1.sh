#!/bin/bash
# ET4351 Lab 2 - Task 1: Synthesize PicoSoC
# Synthesizes the full PicoSoC with dummy accelerator using Cadence Genus
# Design: et4351 (top-level) with picorv32, picosoc, simpleuart, spimemio, accelerator
# Clock: 83.33 ns period (~12 MHz), QSPI divided by 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/task1-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Task 1: Synthesize PicoSoC ==="
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

cd ~/lab2/task/synth

echo ""
echo "=== Synthesizing PicoSoC (without clock gating) ==="
echo "Design: et4351, Clock period: 83.33 ns (~12 MHz)"
echo ""

# The synth_elb.tcl has a suspend point after reading SDC.
# Create a wrapper that avoids the suspend.
cat > /tmp/synth_task1.tcl << 'TCL'
# Task 1: Full PicoSoC synthesis without clock gating

source scripts/synth_set.tcl

puts "\n ##################################"
puts " #                                #"
puts " #    ELABORATION (PicoSoC)       #"
puts " #                                #"
puts " ##################################\n"

set INPUT_PATH "../src"
set DESIGN "et4351"

# Read all Verilog source files
read_hdl -v2001 "../src/${DESIGN}.v"
read_hdl -v2001 "../src/accelerator.v"
read_hdl -v2001 "../src/picosoc.v"
read_hdl -v2001 "../src/spimemio.v"
read_hdl -v2001 "../src/simpleuart.v"
read_hdl -v2001 "../src/picorv32.v"

set_attribute hdl_error_on_latch true /
set_attribute auto_ungroup none /

elaborate $DESIGN
timestat Elaboration

# Preserve internal nets for debug
set_attr preserve true [get_nets soc/*]
set_attr preserve true [get_nets soc/cpu/*]
set_attr preserve true [get_nets soc/simpleuart/*]
set_attr preserve true [get_nets soc/spimemio/*]
set_attr preserve true [get_nets soc/memory/*]
set_attr preserve true [get_nets soc/cpu/mem_done]

read_sdc "${INPUT_PATH}/${DESIGN}.sdc"

change_names -restricted "\[ \]" -replace_str "_"
set_attribute number_of_routing_layers 8 /designs/*

# Generic synthesis
syn_generic
timestat GENERIC

# Generate elaboration reports
set IMPL_STAGE "elb"
file mkdir ${REPORTS_PATH}/${IMPL_STAGE}
report timing -lint -verbose       > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_lint.rpt
report clocks                      > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_clocks.rpt
report clocks -generated           > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_clocksg.rpt
report port *                      > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_port.rpt

puts "\n ##################################"
puts " #                                #"
puts " #    MAPPING                     #"
puts " #                                #"
puts " ##################################\n"

set_attribute syn_map_effort low
syn_map
echo "Synthesis complete"
timestat MAPPED

# Generate mapping reports
set IMPL_STAGE "map"
file mkdir ${REPORTS_PATH}/${IMPL_STAGE}
report gates                      > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_gates.rpt
report area                       > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_area.rpt
report timing -worst 100          > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_timing.rpt

puts "\n ##################################"
puts " #                                #"
puts " #    EXPORT                      #"
puts " #                                #"
puts " ##################################\n"

set IMPL_STAGE "struct"
file mkdir ${REPORTS_PATH}/${IMPL_STAGE}

report gates                              > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_gates.rpt
report area                               > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_area.rpt
report timing -worst 100                  > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_timing.rpt
report qor                                > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_qor.rpt
check_design -all                         > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_check.rpt
report timing -lint -verbose              > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_lint.rpt
report datapath -all                      > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_datapath.rpt
report sequential -hier                   > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_sequential.rpt
report nets -cap_worst 50 -hierarchical   > ${REPORTS_PATH}/${IMPL_STAGE}/${DESIGN}_nets.rpt

change_names -verilog
write_encounter *

write_hdl ${DESIGN} > ${OUTPUTS_PATH}/${DESIGN}.struct.v
write_sdc ${DESIGN} > ${OUTPUTS_PATH}/${DESIGN}.struct.sdc
write_sdf -nonegchecks -interconn "interconnect" -delimiter "/" > ${OUTPUTS_PATH}/${DESIGN}.struct.sdf

# Print summary reports to console
puts "\n ##################################"
puts " #                                #"
puts " #    SUMMARY                     #"
puts " #                                #"
puts " ##################################\n"

puts "=== Area Report ==="
report area

puts "\n=== Timing (worst 10) ==="
report timing -worst 10

puts "\n=== Power Report ==="
report_power

exit
TCL

genus -legacy_ui -64 -f /tmp/synth_task1.tcl -log genus_task1

echo ""
echo "=============================================="
echo "=== Checking synthesis outputs ==="
echo "=============================================="

echo ""
echo "--- Generated outputs ---"
for f in outputs/et4351.struct.*; do
    if [ -f "$f" ]; then
        echo "$f: $(wc -l < "$f") lines"
    fi
done

echo ""
echo "--- Area Report ---"
cat reports/struct/et4351_area.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Timing Report (worst 10 paths) ---"
head -200 reports/struct/et4351_timing.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "=== Task 1 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
