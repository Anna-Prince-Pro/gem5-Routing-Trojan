#!/bin/bash

# ============================================================
# 64-Core Garnet Experiment
# Baseline + Trojan
# inj-vnet option REMOVED
# ============================================================

GEM5=build/Garnet_standalone/gem5.opt
CONFIG=configs/example/garnet_synth_traffic.py

RESULT_DIR=experiment_results

mkdir -p $RESULT_DIR

# Injection rates
rates=(
0.02
0.04
0.06
0.08
0.10
0.12
0.14
0.16
0.18
0.20
0.22
0.24
0.26
0.28
0.30
0.32
0.34
0.36
0.38
0.40
)

# ============================================================
# BASELINE
# ============================================================

baseline_file=$RESULT_DIR/baseline_64core_no_injvnet.csv

echo "InjectionRate,PacketsInjected,PacketsReceived,AverageLatency" \
> $baseline_file

echo "============================================"
echo "RUNNING BASELINE EXPERIMENTS"
echo "============================================"

for rate in "${rates[@]}"
do
    echo ""
    echo "Running BASELINE at injection rate = $rate"

    $GEM5 $CONFIG \
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

    latency=$(grep "average_packet_latency" m5out/stats.txt | awk '{print $2}')
    injected=$(grep "packets_injected::total" m5out/stats.txt | awk '{print $2}')
    received=$(grep "packets_received::total" m5out/stats.txt | awk '{print $2}')

    echo "$rate,$injected,$received,$latency" >> $baseline_file

    echo "Baseline completed: $rate"
done

# ============================================================
# TROJAN
# ============================================================

trojan_file=$RESULT_DIR/trojan_64core_no_injvnet.csv

echo "InjectionRate,PacketsInjected,PacketsReceived,AverageLatency" \
> $trojan_file

echo ""
echo "============================================"
echo "RUNNING TROJAN EXPERIMENTS"
echo "============================================"

for rate in "${rates[@]}"
do
    echo ""
    echo "Running TROJAN at injection rate = $rate"

    $GEM5 $CONFIG \
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

    latency=$(grep "average_packet_latency" m5out/stats.txt | awk '{print $2}')
    injected=$(grep "packets_injected::total" m5out/stats.txt | awk '{print $2}')
    received=$(grep "packets_received::total" m5out/stats.txt | awk '{print $2}')

    echo "$rate,$injected,$received,$latency" >> $trojan_file

    echo "Trojan completed: $rate"
done

echo ""
echo "============================================"
echo "ALL EXPERIMENTS COMPLETED"
echo "============================================"

echo ""
echo "BASELINE RESULTS:"
cat $baseline_file

echo ""
echo "TROJAN RESULTS:"
cat $trojan_file
