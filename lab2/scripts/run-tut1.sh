#!/bin/bash
# ET4351 Lab 2 - Tutorial 1: Synthesis with Cadence Genus
# Synthesizes a 4-bit integer multiplier using Cadence Genus
# Steps: setup PDK paths, elaborate, map, export netlist + reports

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"
OUTPUT_DIR="$SCRIPT_DIR/../output/tut1-output"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

mkdir -p "$OUTPUT_DIR"

echo "=== ET4351 Lab 2 - Tutorial 1: Synthesis with Cadence Genus ==="
echo "Connecting to $SERVER as $USERNAME..."
echo ""

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'REMOTE' 2>&1 | tee "$OUTPUT_DIR/output.txt"
# Copy lab2 files if not already present
if [ ! -d ~/lab2 ]; then
    cp -r /data/labs/2025/labs/lab2 ~/
    echo "Lab2 files copied."
else
    echo "Lab2 files already exist."
fi

# Setup EDA environment
cd ~/lab2
source setup.sh

echo ""
echo "=== Step 1: Inspecting SDC constraints file ==="
echo "--- Contents of mul.sdc ---"
cat ~/lab2/tut/src/mul.sdc
echo ""
echo "--- End of mul.sdc ---"

echo ""
echo "=== Step 2: Running Cadence Genus synthesis (without clock gating) ==="
cd ~/lab2/tut/synth

# Run Genus with the full synthesis script (synth.tcl)
# This script calls: synth_set.tcl, synth_elb.tcl, synth_map.tcl, synth_exp.tcl
# The script suspends after reading SDC; we pipe "resume" then "exit" with a delay
(echo "resume"; sleep 120; echo "exit") | genus -legacy_ui -64 -f scripts/synth.tcl -log genus_tut1

echo ""
echo "=== Step 3: Checking synthesis outputs ==="
echo ""

# Display area report (check multiple possible paths)
AREA_RPT=$(find reports/ -name "*area*" -type f 2>/dev/null | head -1)
if [ -n "$AREA_RPT" ]; then
    echo "--- Area Report ($AREA_RPT) ---"
    cat "$AREA_RPT"
    echo "--- End Area Report ---"
else
    echo "WARNING: Area report not found"
    echo "Available reports:"
    find reports/ -type f 2>/dev/null
fi

echo ""

# Display timing report (check multiple possible paths)
TIMING_RPT=$(find reports/ -name "*timing*" -type f 2>/dev/null | head -1)
if [ -n "$TIMING_RPT" ]; then
    echo "--- Timing Report ($TIMING_RPT) ---"
    cat "$TIMING_RPT"
    echo "--- End Timing Report ---"
else
    echo "WARNING: Timing report not found"
    echo "Available reports:"
    find reports/ -type f 2>/dev/null
fi

echo ""

# Check that netlist was generated
if [ -f outputs/mul.struct.v ]; then
    echo "Netlist generated: outputs/mul.struct.v"
    echo "Lines: $(wc -l < outputs/mul.struct.v)"
else
    echo "WARNING: Netlist not found"
fi

if [ -f outputs/mul.struct.sdc ]; then
    echo "SDC generated: outputs/mul.struct.sdc"
else
    echo "WARNING: SDC output not found"
fi

if [ -f outputs/mul.struct.sdf ]; then
    echo "SDF generated: outputs/mul.struct.sdf"
    echo "Lines: $(wc -l < outputs/mul.struct.sdf)"
else
    echo "WARNING: SDF output not found"
fi

echo ""
echo "=== Tutorial 1 complete! ==="
REMOTE

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "Output saved to $OUTPUT_DIR/output.txt"
else
    echo "Script finished with exit code $EXIT_CODE"
fi
