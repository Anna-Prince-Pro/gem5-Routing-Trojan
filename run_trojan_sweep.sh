#!/bin/bash
cd ~/gem5 || exit

echo "InjectionRate,AvgLatency,AcceptedPackets" > trojan_sweep_results.csv

for rate in $(seq 0.01 0.01 0.20); do
    echo "=== Running injection rate: $rate ==="

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

    if [ -f "m5out/stats.txt" ]; then
        # Use more robust matching for gem5 stats
        latency=$(grep "network_stat::packet_latency" m5out/stats.txt | awk '{print $2}')
        packets=$(grep "network_stat::accepted_packets" m5out/stats.txt | awk '{print $2}')

        # Fallback if empty
        [ -z "$latency" ] && latency=$(grep "packet_latency" m5out/stats.txt | head -n 1 | awk '{print $2}')
        [ -z "$packets" ] && packets=$(grep "accepted_packets" m5out/stats.txt | head -n 1 | awk '{print $2}')

        echo "Extracted -> Latency: $latency | Packets: $packets"
        echo "$rate,$latency,$packets" >> trojan_sweep_results.csv
    else
        echo "ERROR: m5out/stats.txt not found!"
    fi
done

echo "Sweep complete! Results saved to trojan_sweep_results.csv"
