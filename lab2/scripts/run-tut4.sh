#!/bin/bash
# ET4351 Lab 2 - Tutorial 4: Post-Synthesis Simulation & Power Estimation
# Steps:
#   1. Run behavioral simulation (sim_behav) as reference
#   2. Run post-synthesis structural simulation (sim_struct)
#   3. Run post-synthesis simulation with VCD generation (sim_struct/vcd)
#   4. Run synthesis with clock gating, annotate VCD, get power estimation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut4-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Tutorial 4: Post-Synthesis Simulation & Power Estimation ==="
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
# Step 1: Behavioral simulation
########################################
echo ""
echo "=============================================="
echo "=== Step 1: Behavioral Simulation (reference) ==="
echo "=============================================="
cd ~/lab2/tut/sim_behav
source tb_mul.sh

########################################
# Step 2: Post-synthesis structural simulation
########################################
echo ""
echo "=============================================="
echo "=== Step 2: Post-Synthesis Structural Simulation ==="
echo "=============================================="
cd ~/lab2/tut/sim_struct
source tb_mul.sh

########################################
# Step 3: Post-synthesis simulation with VCD
########################################
echo ""
echo "=============================================="
echo "=== Step 3: Post-Synthesis Simulation with VCD ==="
echo "=============================================="
cd ~/lab2/tut/sim_struct/vcd
mkdir -p vcd
source tb_mul_vcd.sh

echo ""
echo "--- Checking VCD file ---"
if [ -f vcd/mul.struct.vcd ]; then
    echo "VCD generated: vcd/mul.struct.vcd"
    ls -lh vcd/mul.struct.vcd
    echo "First 20 lines:"
    head -20 vcd/mul.struct.vcd
else
    echo "WARNING: VCD file not found"
    echo "Looking for VCD files:"
    find . -name "*.vcd" -type f 2>/dev/null
fi

########################################
# Step 4: Synthesis with CG + VCD power estimation
########################################
echo ""
echo "=============================================="
echo "=== Step 4: Synthesis with CG + Power Estimation ==="
echo "=============================================="
cd ~/lab2/tut/synth

cat > /tmp/synth_tut4_power.tcl << 'TCL'
# Tutorial 4: Synthesis with CG + VCD-annotated power estimation

source scripts/synth_set.tcl

set INPUT_PATH "../src"
set DESIGN "mul"

# Enable clock gating
set_attribute lp_insert_clock_gating true /

read_hdl -sv "${INPUT_PATH}/${DESIGN}.sv"
set_attr hdl_error_on_latch true /
set_attr auto_ungroup none /
elaborate $DESIGN
read_sdc "${INPUT_PATH}/${DESIGN}.sdc"

# CG options after elaboration
set_attribute lp_clock_gating_control_point precontrol /des*/*
set_attribute lp_clock_gating_style latch /des*/*
set_attribute lp_insert_discrete_clock_gating_logic true

syn_generic
syn_map

puts "\n ##################################"
puts " #                                #"
puts " #    POWER ESTIMATION (VCD)      #"
puts " #                                #"
puts " ##################################\n"

file mkdir reports/power

# Power WITHOUT VCD annotation (default toggle rate)
puts "\n=== Power Report (default toggle rate, with CG) ==="
report_power
report_power > reports/power/mul_power_default_cg.rpt

# Read VCD and annotate
puts "\n=== Reading VCD file ==="
read_vcd ../sim_struct/vcd/mul.struct.vcd

# Power WITH VCD annotation
puts "\n=== Power Report (VCD-annotated, with CG) ==="
report_power
report_power > reports/power/mul_power_vcd_cg.rpt

exit
TCL

genus -legacy_ui -64 -f /tmp/synth_tut4_power.tcl -log genus_tut4_power

echo ""
echo "=============================================="
echo "=== Step 5: Results Summary ==="
echo "=============================================="

echo ""
echo "--- Power (default toggle, with CG) ---"
cat ~/lab2/tut/synth/reports/power/mul_power_default_cg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "--- Power (VCD-annotated, with CG) ---"
cat ~/lab2/tut/synth/reports/power/mul_power_vcd_cg.rpt 2>/dev/null || echo "NOT FOUND"

echo ""
echo "=== Tutorial 4 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
