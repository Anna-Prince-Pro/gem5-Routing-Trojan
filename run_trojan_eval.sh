#!/bin/bash

# Initialize the CSV file
echo "Injection Rate,Packets Injected,Packets Received,Average Latency (Ticks),Average Latency (Cycles)" > trojan_results.csv

echo "Starting 20-point Trojan evaluation..."

for rate in $(seq -f "%.2f" 0.02 0.02 0.40); do
    echo "Running simulation for Injection Rate: $rate..."

    # Executing with your original working parameters
    ./build/Garnet_standalone/gem5.opt configs/example/garnet_synth_traffic.py \
        --network=garnet \
        --num-cpus=64 \
        --num-dirs=64 \
        --topology=Mesh_XY \
        --mesh-rows=8 \
        --routing-algorithm=1 \
        --sim-cycles=10000000 \
        --synthetic=uniform_random \
        --vcs-per-vnet=4 \
        --injectionrate=$rate

    # Extract metrics cleanly
    injected=$(grep "packets_injected::total" m5out/stats.txt | awk '{print $2}')
    received=$(grep "packets_received::total" m5out/stats.txt | awk '{print $2}')
    latency_ticks=$(grep "average_packet_network_latency" m5out/stats.txt | awk '{print $2}')

    latency_cycles=$(echo "scale=3; $latency_ticks / 1000" | bc)

    # Append to CSV
    echo "$rate,$injected,$received,$latency_ticks,$latency_cycles" >> trojan_results.csv
done

echo "Evaluation complete! Results saved to trojan_results.csv."
