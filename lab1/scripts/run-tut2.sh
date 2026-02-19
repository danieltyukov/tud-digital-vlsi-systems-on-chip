#!/bin/bash
# ET4351 Tutorial 2: Simulation with QuestaSim
# Connects to server, sets up lab files, and launches QuestaSim GUI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$SCRIPT_DIR/credentials.txt"

SERVER="et4351.ewi.tudelft.nl"
USERNAME="datyukov"
PASSWORD=$(grep '^password:' "$CRED_FILE" | sed 's/^password: //')

echo "=== ET4351 Tutorial 2: Simulation with QuestaSim ==="
echo "Connecting to $SERVER as $USERNAME with X11 forwarding..."
echo ""

# Step 1: Setup lab files and create a run script on the server
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" bash << 'SETUP'
# Copy lab files if not already present
if [ ! -d ~/lab1 ]; then
    cp -r /data/labs/2026/labs/lab1 ~/
    echo "Lab files copied."
else
    echo "Lab files already exist."
fi

# Create a modified simulation script that keeps the GUI open
cat > ~/lab1/tut2/questasim/run_gui.sh << 'EOF'
#!/bin/bash
workLib=workLib
rm -rf ${workLib}
vlib ${workLib}
vmap work ${workLib}
vlog -sv ../src/design/mul.sv ../src/testbench/tb_mul.sv -timescale 1ns/1ps
vsim -voptargs=+acc -onfinish stop tb_multiplier_32bit -do tb_mul.cmd -t 100ps
EOF
chmod +x ~/lab1/tut2/questasim/run_gui.sh
SETUP

# Step 2: Launch interactive session with GUI (-t for PTY, -X for X11)
sshpass -p "$PASSWORD" ssh -t -X -o StrictHostKeyChecking=no "$USERNAME@$SERVER" \
    'cd ~/lab1 && source setup.sh && cd ~/lab1/tut2/questasim && source run_gui.sh'
