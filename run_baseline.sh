#!/bin/bash

mkdir -p experiment_results
# echo "InjectionRate,PacketsInjected,PacketsReceived,AverageLatency" > experiment_results/baseline_64core_10M.csv

for rate in 0.32 0.34 0.36 0.38 0.40
do

echo "==============================================="
echo "Running Injection Rate = $rate"
echo "==============================================="

build/Garnet_standalone/gem5.opt \
configs/example/garnet_synth_traffic.py \
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

latency=$(grep average_packet_latency m5out/stats.txt | awk '{print $2}')
inj=$(grep "packets_injected::total" m5out/stats.txt | awk '{print $2}')
recv=$(grep "packets_received::total" m5out/stats.txt | awk '{print $2}')

echo "$rate,$inj,$recv,$latency" >> experiment_results/baseline_64core_10M.csv

done

echo ""
echo "======================================"
echo "All simulations completed!"
echo "Results saved to:"
echo "experiment_results/baseline_64core.csv"
echo "======================================"
