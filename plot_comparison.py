import csv
import matplotlib.pyplot as plt

# 1. Exact Baseline Latency Data from the PDF (Cycles)
pdf_baseline_latencies = [
    8.914,
    8.984,
    9.389,
    14.329,
    33.994,
    57.540,
    84.703,
    113.808,
    138.661,
    184.766,
    256.055,
    340.409,
    442.236,
    529.813,
    580.918,
    636.280,
    686.249,
    700.074,
    741.289,
    771.208,
]
injection_rates = [round(0.02 * i, 2) for i in range(1, 21)]

# 2. Read your Trojan data from the CSV
my_trojan_latencies = []
with open("trojan_results.csv", "r") as file:
    reader = csv.reader(file)
    next(reader)  # Skip header
    for row in reader:
        my_trojan_latencies.append(float(row[4]))  # Column 5: Latency (Cycles)

# 3. Plot the data
plt.figure(figsize=(10, 6))
plt.plot(
    injection_rates,
    pdf_baseline_latencies,
    marker="o",
    linestyle="-",
    color="blue",
    label="PDF Baseline (XY Routing)",
)
plt.plot(
    injection_rates,
    my_trojan_latencies,
    marker="x",
    linestyle="--",
    color="red",
    label="Custom Square Loop Trojan",
)

# 4. Formatting
plt.title("Network Latency: PDF Baseline vs. Custom Square Loop Trojan")
plt.xlabel("Injection Rate (flits/node/cycle)")
plt.ylabel("Average Packet Latency (Cycles)")
plt.grid(True, linestyle=":", alpha=0.7)
plt.legend()
plt.tight_layout()

# 5. Save the graph
plt.savefig("latency_comparison.png", dpi=300)
print("Graph successfully saved as 'latency_comparison.png'")
