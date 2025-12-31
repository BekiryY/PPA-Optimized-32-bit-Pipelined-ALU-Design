# PPA-Optimized 32-bit Pipelined ALU Design

A high-performance, **PPA (Performance, Power, Area) optimized** Arithmetic Logic Unit (ALU) designed for a 32-bit processor core. This project demonstrates the complete **RTL-to-GDS sign-off flow** on a complex, pipelined unit, achieving a verified operating frequency of **2.0 GHz** (500 ps period).

## Key Features & Achievements

* **Ultra-High Frequency:** Achieved timing closure with a positive slack of 45 ps, demonstrating a critical path delay of $\approx 455\,\text{ps}$ (sub-nanosecond performance).
* **Advanced Pipelining:** Features a multi-stage **pipelined multiplier** for high throughput (1 GMACS) and a separate **pipelined adder** unit. 
* **Power Optimization:** RTL structured to implement **power gating** for unused blocks to minimize static/leakage power, and incorporates design hooks for **low-power operational modes**.
* **Area Efficiency:** Implements flag-based comparison logic ($A == B$, $A > B$, etc.) by efficiently reusing the main adder/subtractor hardware, saving silicon area.

## Tool Flow (RTL-to-GDS)

| Stage | Tool | Purpose |
| :--- | :--- | :--- |
| **RTL Simulation** | Vivado / Cadence Xcelium | Functional verification before synthesis. |
| **Synthesis & Gate-Level Sim** | Cadence Genus | Logic translation and optimization for timing/area. |
| **Layout & CTS** | Cadence Innovus | Placement, Routing, and Clock Tree Synthesis. |
| **Final Timing Closure** | Cadence Quantus | Full RC Parasitic Extraction and Sign-off. |


