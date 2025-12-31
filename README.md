# PPA-Optimized 32-bit Pipelined ALU Design

This repository documents the complete **RTL-to-GDSII** implementation of a high-frequency, 32-bit Arithmetic Logic Unit (ALU). Designed to simulate a high-performance processor core execution unit, this project targets aggressive PPA (Performance, Power, Area) metrics using a 45nm technology node.

The design achieves a verified **Turbo Mode frequency of 1.66 GHz** (sub-nanosecond timing) while supporting a dynamic **Low Power Mode** for energy efficiency.

!Layout view of final view(documents/screenshots/ALU_main_gpdk045.png)


## Design Flow & Methodology
The project follows an industry-standard ASIC pre-sign-off flow, moving from micro-architectural definition to physical layout hardening.

### 1. Architecture & RTL Design
The architecture was built for speed & throughput while saving power at the same time. A **7-stage pipeline** was implemented to break down critical paths (specifically in the multiplier and adder), allowing for a high clock frequency of 1.66 GHz. The RTL is written in **SystemVerilog**, utilizing parameterized modules for flexibility.

### 2. Functional Verification & Coverage Tests
Before synthesis, the logic was rigorously verified using **Cadence Xcelium & Vivado 2025.2**.
* **Constrained-Random Verification:** Developed a testbench to inject random instructions and data to cover corner cases.
* **Self-Checking Scoreboard:** Implemented a real-time "Golden Model" comparator to validate ALU outputs against a reference C-model.
* **100% Sign-off Coverage:** Achieved 100% in Toggle, Block, and Functional coverage metrics.


### 3. Synthesis & Physical Implementation
The design was synthesized using **Cadence Genus** to map RTL to the target technology library, optimizing for a positive slack margin. The netlist was then transferred to **Cadence Innovus** for the physical implementation phase, which included:
* **Floorplanning:** Core sizing and pin placement to minimize I/O delays.
* **Placement & Routing:** Congestion-aware cell placement and timing-driven routing.
* **Clock Tree Synthesis (CTS):** Balancing the clock skew across the pipeline registers to maintain setup/hold timing at 1.66 GHz.

---

## Final PPA & Performance Metrics (Pre-Sign-off)
The following metrics were extracted after physical routing (Innovus) and RC extraction (Quantus).

| Metric | Results | Description / Context |
| :--- | :--- | :--- |
| **Operating Frequency** | **1.66 GHz** | Turbo Mode Target (602.4 ps period) |
| **Peak Throughput** | **1.66 GOPS** | 1.0 Operation per Cycle | 
| **Pipeline Latency** | **7-1-0 Cycles** | Variable latency (Mul-Logic-Bypass) |
| **Worst Negative Slack** | **+27 ps** | Timing margin (Setup) |
| **Worst Negative Slack** | **+7 ps** | Timing margin (Hold)|
| **Total Power (Turbo)** | **51.94 mW** | @ 1.66 GHz, 1.2V (High Performance) |
| **Total Power (Low)** | **3.30 mW** | @ 180 MHz, 1.0V (Power Saving) |
| **Power Density (Turbo)**| **100 W/cm²** | High thermal density due to frequency/voltage |
| **Power Density (Low)** | **6.35 W/cm²** | Reduced density in power-saving mode |
| **Energy per Op** | **31.29 pJ/Op** | Efficiency ($51.94mW / 1.66GHz$) |
| **Total Cell Area** | **52,900 µm²** | Standard Cell + Filler Area |
| **Gate Count** | **10,496 Gates** | NAND2 Equivalent Area |
| **Est. Transistors** | **~84,000** | Estimated count (High flip-flop density) |
| **Gate Density** | **198.4 kG/mm²** | Physical packing efficiency |
| **Cell Utilization** | **%74.7** | Final utilization of floorplan area|
| **Clock Tree Power** | **%9.61** | this amount of power is used by CT* |
