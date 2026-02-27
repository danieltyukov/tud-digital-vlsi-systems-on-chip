#!/bin/bash
# ET4351 Lab 2 - Report Questions Data Collection
# Q2.2: Re-synthesize PicoSoC with 1 ns clock (1 GHz)
# Q2.3: Re-synthesize PicoSoC with clock gating enabled, compare power

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/report-questions-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Report Questions Data Collection ==="
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

########################################
# Q2.2: Synthesize with 1 ns clock
########################################
echo ""
echo "=============================================="
echo "=== Q2.2: Synthesis with 1 ns clock (1 GHz) ==="
echo "=============================================="

cd ~/lab2/task/synth

# Backup original SDC
cp ../src/et4351.sdc ../src/et4351.sdc.bak

# Show original clock period
echo ""
echo "--- Original SDC clock setting ---"
grep CLK_PERIOD ../src/et4351.sdc

# Modify SDC: change clock period to 1 ns = 1000 ps
sed -i 's/set CLK_PERIOD .*/set CLK_PERIOD 1.0/' ../src/et4351.sdc

echo "--- Modified SDC clock setting ---"
grep CLK_PERIOD ../src/et4351.sdc

cat > /tmp/synth_q22.tcl << 'TCL'
# Q2.2: PicoSoC synthesis with 1 ns (1 GHz) clock

source scripts/synth_set.tcl

set INPUT_PATH "../src"
set DESIGN "et4351"

read_hdl -v2001 "../src/${DESIGN}.v"
read_hdl -v2001 "../src/accelerator.v"
read_hdl -v2001 "../src/picosoc.v"
read_hdl -v2001 "../src/spimemio.v"
read_hdl -v2001 "../src/simpleuart.v"
read_hdl -v2001 "../src/picorv32.v"

set_attribute hdl_error_on_latch true /
set_attribute auto_ungroup none /

elaborate $DESIGN

set_attr preserve true [get_nets soc/*]
set_attr preserve true [get_nets soc/cpu/*]
set_attr preserve true [get_nets soc/simpleuart/*]
set_attr preserve true [get_nets soc/spimemio/*]
set_attr preserve true [get_nets soc/memory/*]
set_attr preserve true [get_nets soc/cpu/mem_done]

read_sdc "${INPUT_PATH}/${DESIGN}.sdc"

change_names -restricted "\[ \]" -replace_str "_"
set_attribute number_of_routing_layers 8 /designs/*

syn_generic
syn_map

puts "\n=== Q2.2 AREA REPORT (1 GHz) ==="
report area

puts "\n=== Q2.2 TIMING REPORT (1 GHz, worst 10) ==="
report timing -worst 10

puts "\n=== Q2.2 POWER REPORT (1 GHz) ==="
report_power

puts "\n=== Q2.2 GATES REPORT (1 GHz) ==="
report gates

exit
TCL

genus -legacy_ui -64 -f /tmp/synth_q22.tcl -log genus_q22

# Restore original SDC
cp ../src/et4351.sdc.bak ../src/et4351.sdc
echo ""
echo "--- SDC restored to original ---"
grep CLK_PERIOD ../src/et4351.sdc

########################################
# Q2.3: Synthesize with clock gating
########################################
echo ""
echo "=============================================="
echo "=== Q2.3: Synthesis WITH Clock Gating ==="
echo "=============================================="

cd ~/lab2/task/synth

cat > /tmp/synth_q23.tcl << 'TCL'
# Q2.3: PicoSoC synthesis WITH clock gating

source scripts/synth_set.tcl

set INPUT_PATH "../src"
set DESIGN "et4351"

# Enable clock gating BEFORE elaboration
set_attribute lp_insert_clock_gating true /

read_hdl -v2001 "../src/${DESIGN}.v"
read_hdl -v2001 "../src/accelerator.v"
read_hdl -v2001 "../src/picosoc.v"
read_hdl -v2001 "../src/spimemio.v"
read_hdl -v2001 "../src/simpleuart.v"
read_hdl -v2001 "../src/picorv32.v"

set_attribute hdl_error_on_latch true /
set_attribute auto_ungroup none /

elaborate $DESIGN

# CG control attributes AFTER elaboration
set_attribute lp_clock_gating_control_point precontrol /des*/*
set_attribute lp_clock_gating_style latch /des*/*
set_attribute lp_insert_discrete_clock_gating_logic true

set_attr preserve true [get_nets soc/*]
set_attr preserve true [get_nets soc/cpu/*]
set_attr preserve true [get_nets soc/simpleuart/*]
set_attr preserve true [get_nets soc/spimemio/*]
set_attr preserve true [get_nets soc/memory/*]
set_attr preserve true [get_nets soc/cpu/mem_done]

read_sdc "${INPUT_PATH}/${DESIGN}.sdc"

change_names -restricted "\[ \]" -replace_str "_"
set_attribute number_of_routing_layers 8 /designs/*

syn_generic
syn_map

puts "\n=== Q2.3 AREA REPORT (with CG) ==="
report area

puts "\n=== Q2.3 TIMING REPORT (with CG, worst 10) ==="
report timing -worst 10

puts "\n=== Q2.3 POWER REPORT (with CG) ==="
report_power

puts "\n=== Q2.3 CLOCK GATING REPORT ==="
report clock_gating

puts "\n=== Q2.3 GATES REPORT (with CG) ==="
report gates

exit
TCL

genus -legacy_ui -64 -f /tmp/synth_q23.tcl -log genus_q23

echo ""
echo "=== Report Questions Data Collection Complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
