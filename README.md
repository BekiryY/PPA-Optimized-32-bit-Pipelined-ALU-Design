## Verification & Sign-off
Functional correctness was verified using a constrained-random testbench in **Cadence Xcelium**.

* **Self-Checking Scoreboard:** Implemented a golden-model comparator to verify ALU results against reference C/SystemVerilog models in real-time.
* **100% Code Coverage:** Achieved full sign-off across all metrics:
    * **Block/Statement:** 100% (Every logic path executed).
    * **Toggle:** 100% (Every net in the 32-bit datapath transitioned 0->1 and 1->0).
    * **Functional:** Verified all instruction combinations and pipeline hazard scenarios.

## PPA Metrics (Sign-off Results)
Final metrics extracted after physical routing in **Innovus** and parasitic extraction in **Quantus**.

| Metric | Results |
| :--- | :--- |
| **Operating Frequency** | 1.66 GHz (Max: 2.1 GHz) |
| **Worst Negative Slack (WNS)** | +100 ps (Reg-to-Reg) |
| **Total Power** | [Insert Value] mW |
| **Cell Area** | [Insert Value] µm² |
| **Gate Count** | [Insert Value] Gates (NAND2 Equivalent) |
| **Utilization** | [Insert Value]% |
