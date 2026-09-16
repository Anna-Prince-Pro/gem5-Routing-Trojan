#!/bin/bash

# Load required Python library path
export LD_LIBRARY_PATH=/home/annamaria/.pyenv/versions/3.10.13/lib:$LD_LIBRARY_PATH

# Create results folder if it does not exist
mkdir -p experiment_results

# Output CSV file
OUTPUT="experiment_results/trojan_fixed_east_51_80.csv"

# Write CSV header
echo "InjectionRate,PacketsInjected,PacketsReceived,AverageLatency" > "$OUTPUT"

# Run all 20 injection rates
for rate in \
0.02 0.04 0.06 0.08 0.10 \
0.12 0.14 0.16 0.18 0.20 \
0.22 0.24 0.26 0.28 0.30 \
0.32 0.34 0.36 0.38 0.40
do

    echo "========================================"
    echo "Running Trojan experiment: $rate"
    echo "========================================"

    build/Garnet_standalone/gem5.opt \
    configs/example/garnet_synth_traffic.py \
    --network=garnet \
    --num-cpus=64 \
    --num-dirs=64 \
    --topology=Mesh_XY \
    --mesh-rows=8 \
    --routing-algorithm=2 \
    --sim-cycles=10000000 \
    --synthetic=uniform_random \
    --vcs-per-vnet=4 \
    --injectionrate=$rate

    # Extract statistics
    injected=$(grep "packets_injected::total" m5out/stats.txt | awk '{print $2}')
    received=$(grep "packets_received::total" m5out/stats.txt | awk '{print $2}')
    latency=$(grep "average_packet_latency " m5out/stats.txt | awk '{print $2}')

    # Save results to CSV
    echo "$rate,$injected,$received,$latency" >> "$OUTPUT"

    echo "Saved: $rate,$injected,$received,$latency"

done

echo "========================================"
echo "ALL 20 TROJAN RUNS COMPLETED"
echo "Results saved in:"
echo "$OUTPUT"
echo "========================================"
