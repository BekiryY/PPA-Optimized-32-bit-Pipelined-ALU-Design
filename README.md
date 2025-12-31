## Verification & Sign-off
Functional correctness was verified using a constrained-random testbench in **Cadence Xcelium**.

* **Self-Checking Scoreboard:** Implemented a golden-model comparator to verify ALU results against reference C/SystemVerilog models in real-time.
* **100% Code Coverage:** Achieved full sign-off across all metrics:
    * **Block/Statement:** 100% (Every logic path executed).
    * **Toggle:** 100% (Every net in the 32-bit datapath transitioned 0->1 and 1->0).
    * **Functional:** Verified all instruction combinations and pipeline hazard scenarios.

## PPA Metrics (Sign-off Results)
Final metrics extracted after physical routing in **Innovus** and parasitic extraction in **Quantus**.

Metric,Results,Description / Context
Operating Frequency,1.66 GHz (Max: 2.1 GHz),Target frequency achieved with sign-off margins.
Throughput,1.66 GOPS,1 Operation per Cycle (1660 Million Ops/sec).
Latency,[X] Cycles,Cycle count from input sampling to valid output.
Worst Negative Slack,+100 ps,Timing margin after RC parasitic extraction.
Total Power,[Value] mW,"Measured at 1.66 GHz, 1.1V (Turbo Mode)."
Energy per Operation,[Value] pJ/Op,Calculated as Total Power/Frequency.
Total Cell Area,[Value] µm²,Total silicon footprint (Standard Cells + Macros).
Gate Count,[Value] Gates,NAND2 equivalent (Area / Area of 1 NAND2 gate).
Gate Density,[Value] kG/mm²,Measure of physical packing efficiency in Innovus.
Cell Utilization,[Value] %,Percentage of the core area occupied by active cells.
Clock Tree Power,[Value] %,Percentage of total power consumed by the clock net.
