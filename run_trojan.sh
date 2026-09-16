#!/bin/bash

mkdir -p experiment_results

echo "InjectionRate,PacketsInjected,PacketsReceived,AverageLatency" > experiment_results/trojan_64core_10M.csv

echo "---------------------------------------------------------------"
printf "%-10s %-12s %-12s %-20s\n" "Rate" "Injected" "Received" "AvgLatency"
echo "---------------------------------------------------------------"

for rate in 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.32 0.34 0.36 0.38 0.40
do
    echo "Running injection rate = $rate..."

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
    injected=$(grep "packets_injected::total" m5out/stats.txt | awk '{print $2}')
    received=$(grep "packets_received::total" m5out/stats.txt | awk '{print $2}')
    latency=$(grep "average_packet_latency" m5out/stats.txt | awk '{print $2}')

    printf "%-10s %-12s %-12s %-20s\n" "$rate" "$injected" "$received" "$latency"

    echo "$rate,$injected,$received,$latency" >> experiment_results/trojan_64core_10M.csv
done

echo "---------------------------------------------------------------"
echo "Results saved to experiment_results/trojan_64core_10M.csv"
