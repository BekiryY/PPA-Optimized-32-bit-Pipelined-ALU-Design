## Verification & Sign-off
Functional correctness was verified using a constrained-random testbench in **Cadence Xcelium**.

* **Self-Checking Scoreboard:** Implemented a golden-model comparator to verify ALU results against reference C/SystemVerilog models in real-time.
* **100% Code Coverage:** Achieved full sign-off across all metrics:
    * **Block/Statement:** 100% (Every logic path executed).
    * **Toggle:** 100% (Every net in the 32-bit datapath transitioned 0->1 and 1->0).
    * **Functional:** Verified all instruction combinations and pipeline hazard scenarios.

## PPA Metrics (Sign-off Results)
Final metrics extracted after physical routing in **Innovus** and parasitic extraction in **Quantus**.

## Final PPA & Performance Sign-off

| Metric | Results | Description / Context |
| :--- | :--- | :--- |
| **Operating Frequency** | **1.66 GHz** | Target frequency (602.4 ps period) |
| **Peak Throughput** | **1.66 GOPS** | 1.0 Operation per Cycle |
| **Pipeline Latency** | **[X] Cycles** | Cycles from Input to Output |
| **Worst Negative Slack** | **+100 ps** | Timing margin (Reg-to-Reg) |
| **Total Power** | **[Value] mW** | Measured @ 1.66 GHz, 1.1V |
| **Energy per Op** | **[Value] pJ/Op** | Efficiency ($Power / Frequency$) |
| **Total Cell Area** | **[Value] µm²** | Standard Cell + Filler Area |
| **Gate Count** | **[Value] Gates** | NAND2 Equivalent Area |
| **Gate Density** | **[Value] kG/mm²** | Physical packing efficiency |
| **Cell Utilization** | **[Value] %** | Active cell vs. Core area ratio |
| **Clock Tree Power** | **[Value] %** | Power consumed by CTS buffers |
