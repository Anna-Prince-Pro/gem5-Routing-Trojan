#!/bin/bash

set -e

GEM5="./build/Garnet_standalone/gem5.opt"
CONFIG="configs/example/garnet_synth_traffic.py"
OUTCSV="trojan_results.csv"

echo "InjectionRate,APL_Ticks,Trojan_Packets_Received,Trojan_Packets_Injected" > "$OUTCSV"

for i in $(seq 2 2 40); do
    rate=$(awk -v i="$i" 'BEGIN {printf "%.2f", i/100}')
    outdir="trojan_rate_${rate}"

    echo "========================================"
    echo "Running Trojan at injection rate $rate"
    echo "Output directory: $outdir"
    echo "========================================"

    "$GEM5" -d "$outdir" "$CONFIG" \
        --network=garnet \
        --num-cpus=64 \
        --num-dirs=64 \
        --topology=Mesh_XY \
        --mesh-rows=8 \
        --routing-algorithm=1 \
        --sim-cycles=10000000 \
        --synthetic=uniform_random \
        --vcs-per-vnet=4 \
        --injectionrate="$rate"

    stats="$outdir/stats.txt"

    if [ ! -f "$stats" ]; then
        echo "ERROR: Missing $stats"
        exit 1
    fi

    apl=$(awk '$1=="system.ruby.network.average_packet_latency" {v=$2} END {print v}' "$stats")
    received=$(awk '$1=="system.ruby.network.packets_received::total" {v=$2} END {print v}' "$stats")
    injected=$(awk '$1=="system.ruby.network.packets_injected::total" {v=$2} END {print v}' "$stats")

    if [ -z "$apl" ] || [ -z "$received" ] || [ -z "$injected" ]; then
        echo "ERROR: Could not extract all statistics for rate $rate"
        exit 1
    fi

    echo "$rate,$apl,$received,$injected" >> "$OUTCSV"
    echo "APL ticks: $apl | Received: $received | Injected: $injected"
done

echo
echo "ALL RUNS COMPLETED"
echo "Results saved in $OUTCSV"
cat "$OUTCSV"
