## Verification & Sign-off
Functional correctness was verified using a constrained-random testbench in **Cadence Xcelium**.

* **Self-Checking Scoreboard:** Implemented a golden-model comparator to verify ALU results against reference C/SystemVerilog models in real-time.
* **100% Code Coverage:** Achieved full sign-off across all metrics:
    * **Block/Statement:** 100% (Every logic path executed).
    * **Toggle:** 100% (Every net in the 32-bit datapath transitioned 0->1 and 1->0).
    * **Functional:** Verified all instruction combinations and pipeline hazard scenarios.

## PPA Metrics (Sign-off Results)
Final metrics extracted after physical routing in **Innovus** and parasitic extraction in **Quantus**.

## Final PPA & Performance PRE-Sign-off

| Metric | Results | Description / Context |
| :--- | :--- | :--- |
| **Operating Frequency** | **1.66 GHz** | Target frequency (602.4 ps period) |
| **Peak Throughput** | **1.66 GOPS** | 1.0 Operation per Cycle |
| **Pipeline Latency** | **7-1-0 Cycles** | Cycles from Input to Output (depends on operation) |
| **Worst Negative Slack** | **+100 ps** | Timing margin (Reg-to-Reg) |
| **Total Power** | **51.94 mW** | Measured @Turbo @1.66 GHz, 1.2V |
| **Total Power** | **3.3 mW** | Measured @LowPower 180 MHz, 1.0V |
| **Power Density** | **100 W/cm²** | Measured @Turbo 1.66GHz, 1.2V |
| **Power Density** | **6.35 W/cm²** | Measured @LowPower 180 MHz, 1.0V |
| **Energy per Op** | **31.1pJ** | Efficiency (51.94mW / 1.66GHz) |
| **Total Cell Area** | **52900 µm²** | Standard Cell + Filler Area |
| **Gate Count** | **10496 Gates** | NAND2 Equivalent Area |
| **Transistor Count** | **84000** | Transistor count (estimation *8) |
| **Gate Density** | **198412 kG/mm²** | Physical packing efficiency |
| **Cell Utilization** | **unknown %** | Active cell vs. Core area ratio |
| **Clock Tree Power** | **unknown %** | Power consumed by CTS buffers |
