#!/bin/bash

# Define the output CSV file
output_file="experiment2_trojan_results.csv"

# Write the header row
echo "Injection_Rate,Average_Latency,Average_Hops" > $output_file

echo "Starting Experiment 2 Trojan Simulations (0.02 to 0.40)..."

# Loop through injection rates from 0.02 to 0.40 with a step of 0.02 (20 runs)
for i in $(seq 0.02 0.02 0.40); do
    # Format the number to ensure bash reads it correctly
    inj_rate=$(printf "%.2f" $i)
    echo "-> Running Injection Rate: $inj_rate"

    # Execute the Garnet simulation quietly
   ./build/Garnet_standalone/gem5.opt configs/example/garnet_synth_traffic.py \
        --network=garnet \
        --num-cpus=64 \
        --num-dirs=64 \
        --topology=Mesh_XY \
        --routing-algorithm=1 \
        --mesh-rows=8 \
        --sim-cycles=1000000 \
        --synthetic=uniform \
        --injectionrate=$inj_rate > /dev/null 2>&1
    # Extract the average packet latency and average hops from the stats file
    latency=$(grep "system.ruby.network.average_packet_latency" m5out/stats.txt | awk '{print $2}')
    hops=$(grep "system.ruby.network.average_hops" m5out/stats.txt | awk '{print $2}')

    # Handle empty values just in case the network deadlocks
    if [ -z "$latency" ]; then latency="Deadlock"; fi
    if [ -z "$hops" ]; then hops="Deadlock"; fi

    # Append the results to the CSV
    echo "$inj_rate,$latency,$hops" >> $output_file
done

echo "✅ All 20 simulations complete! Data saved to $output_file"
