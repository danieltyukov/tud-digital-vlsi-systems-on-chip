#!/bin/bash
# ET4351 Lab 2 - Tutorial 2: Static Timing Analysis
# Runs synthesis on the 4-bit multiplier, then extracts timing reports
# for all 4 timing path types:
#   t_a2d  (Path 1): Input ports     -> Register data pins
#   t_ck2d (Path 2): Register clocks -> Register data pins
#   t_ck2z (Path 3): Register clocks -> Output ports
#   t_a2z  (Path 4): Input ports     -> Output ports

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut2-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Tutorial 2: Static Timing Analysis ==="
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
echo "=== Running Cadence Genus synthesis + STA timing reports ==="

# Create a custom TCL script that runs synthesis then extracts all 4 timing paths
cat > scripts/synth_tut2.tcl << 'TCL'
# Tutorial 2: Synthesis + Static Timing Analysis
# Source the sub-scripts directly (avoiding suspend)

# Step 1: Setup PDK paths
source scripts/synth_set.tcl

# Step 2: Elaboration (inline, no suspend)
puts "\n ##################################"
puts " #                                #"
puts " #    ELABORATION                 #"
puts " #                                #"
puts " ##################################\n"

set INPUT_PATH "../src"
set DESIGN "mul"

read_hdl -sv "${INPUT_PATH}/${DESIGN}.sv"
set_attr hdl_error_on_latch true /
set_attr auto_ungroup none /
elaborate $DESIGN
read_sdc "${INPUT_PATH}/${DESIGN}.sdc"

# Step 3: Generic synthesis
syn_generic

# Step 4: Technology mapping
puts "\n ##################################"
puts " #                                #"
puts " #    MAPPING                     #"
puts " #                                #"
puts " ##################################\n"

syn_map

puts "Synthesis complete"

# Step 5: Generate all timing reports
puts "\n ##################################"
puts " #                                #"
puts " #    STATIC TIMING ANALYSIS      #"
puts " #                                #"
puts " ##################################\n"

file mkdir reports/sta

# Overall worst 10 paths
puts "=== Overall Worst 10 Timing Paths ==="
report timing -worst 10

# Path Type 1: t_a2d - Input ports to register data pins
puts "\n=== Path Type 1: t_a2d (Input -> Register) ==="
report timing -worst 10 -from [all_inputs] -to [all_registers -data_pins]
report timing -worst 10 -from [all_inputs] -to [all_registers -data_pins] > reports/sta/mul_timing_a2d.rpt

# Path Type 2: t_ck2d - Register clocks to register data pins
puts "\n=== Path Type 2: t_ck2d (Register -> Register) ==="
report timing -worst 10 -from [all_registers -clock_pins] -to [all_registers -data_pins]
report timing -worst 10 -from [all_registers -clock_pins] -to [all_registers -data_pins] > reports/sta/mul_timing_ck2d.rpt

# Path Type 3: t_ck2z - Register clocks to output ports
puts "\n=== Path Type 3: t_ck2z (Register -> Output) ==="
report timing -worst 10 -from [all_registers -clock_pins] -to [all_outputs]
report timing -worst 10 -from [all_registers -clock_pins] -to [all_outputs] > reports/sta/mul_timing_ck2z.rpt

# Path Type 4: t_a2z - Input ports to output ports
puts "\n=== Path Type 4: t_a2z (Input -> Output) ==="
report timing -worst 10 -from [all_inputs] -to [all_outputs]
report timing -worst 10 -from [all_inputs] -to [all_outputs] > reports/sta/mul_timing_a2z.rpt

# Area report for reference
puts "\n=== Area Report ==="
report area
report area > reports/sta/mul_area.rpt

puts "\n=== STA Reports Complete ==="

exit
TCL

# Run Genus with our custom script (no suspend points)
genus -legacy_ui -64 -f scripts/synth_tut2.tcl -log genus_tut2

echo ""
echo "=== Checking generated STA reports ==="
echo ""
for rpt in reports/sta/*.rpt; do
    if [ -f "$rpt" ]; then
        echo "--- $rpt ---"
        cat "$rpt"
        echo ""
    fi
done

echo ""
echo "=== Tutorial 2 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
