#!/bin/bash
# Quick start script for Go-Kart Dashboard

# Default to virtual mode for easy testing
MODE="${1:-virtual}"

if [ "$MODE" == "virtual" ]; then
    echo "Starting dashboard in VIRTUAL mode..."
    python3 main.py --virtual
elif [ "$MODE" == "hardware" ]; then
    echo "Starting dashboard with HARDWARE (CAN interface)..."
    python3 main.py --interface can0 --fullscreen
else
    echo "Usage: ./run.sh [virtual|hardware]"
    echo "  virtual  - Run with simulated CAN data (default)"
    echo "  hardware - Run with real CAN interface"
    exit 1
fi
