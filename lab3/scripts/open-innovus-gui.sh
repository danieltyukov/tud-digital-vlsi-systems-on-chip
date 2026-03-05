#!/bin/bash
# ET4351 Lab 3 - Open Cadence Innovus GUI
# Launches Innovus with X11 forwarding, loads the latest checkpoint.
# Requires X11 server running locally (XQuartz on macOS, X11 on Linux).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/../../credentials.txt"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

# Auto-detect DISPLAY if not set
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:1
    echo "DISPLAY was not set, using $DISPLAY"
fi

echo "=== ET4351 Lab 3 - Opening Cadence Innovus GUI ==="
echo "Connecting to $SERVER with X11 forwarding (DISPLAY=$DISPLAY)..."
echo ""
echo "NOTE: You need an X11 server running locally."
echo "  - Linux: should work out of the box"
echo "  - macOS: install and run XQuartz first"
echo "  - Windows: use MobaXterm (has built-in X11)"
echo ""

# Step 1: Create the TCL startup script on the remote server (non-interactive)
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'SETUP'
cat > /tmp/innovus_startup.tcl << 'TCL'
set checkpoints {
    checkpoints/et4351_route.enc
    checkpoints/et4351_cts.enc
    checkpoints/et4351_place.enc
    checkpoints/et4351_pplan.enc
    checkpoints/et4351_fplan.enc
}
set loaded 0
foreach cp $checkpoints {
    if {[file exists $cp]} {
        puts "Loading checkpoint: $cp"
        source $cp
        set loaded 1
        break
    }
}
if {!$loaded} {
    puts "No checkpoint found, loading design from scratch..."
    source ./scripts/1.set_variable.tcl
    source ./scripts/2.0.load_design.tcl
    source ./scripts/2.1.set_library_n_sdc.tcl
}
puts ""
puts "=============================================="
puts "Design loaded. You should see the layout."
puts "Type \"exit\" to quit Innovus."
puts "=============================================="
win
fit
TCL
SETUP

# Step 2: Launch Innovus interactively with X11 forwarding
echo "Starting Innovus GUI (interactive)..."
echo "Type \"exit\" in the Innovus terminal when done."
echo ""
sshpass -p "$PASSWORD" ssh -t -X -o StrictHostKeyChecking=no -o ForwardX11Trusted=yes "$USERNAME@$SERVER" \
    "cd ~/lab3 && source setup.sh && cd ~/lab3/tut/pnr && innovus -init /tmp/innovus_startup.tcl"
