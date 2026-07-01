# FPGA Multi-Clock Domain Data Processing System

## Overview
This project implements a robust, multi-clock domain digital system on an Intel/Altera Cyclone IV E FPGA. The architecture is designed to safely process high-speed incoming data, buffer it, and transmit it over a slower communication interface. 

The design emphasizes advanced hardware engineering principles, including **Clock Domain Crossing (CDC)** management, **Static Timing Analysis (STA)**, and dynamic power reduction using **Clock Gating** techniques.

## System Architecture
The system bridges two distinct asynchronous clock domains using an Asynchronous FIFO, ensuring data integrity and preventing metastability.

### 1. Fast Domain (Write Domain - 100MHz)
* **FIR Filter (4-Tap):** Processes incoming digital signals at high speed.
* **Power Manager:** Implements intelligent Clock Gating. It monitors the FIFO's status and halts the fast clock tree (`clk_fast`) during idle periods to conserve dynamic power.
* **ALTCLKCTRL IP:** An Altera hardware primitive used to safely gate the global clock network without introducing clock glitches.

### 2. Slow Domain (Read Domain - 10MHz)
* **UART Transmitter:** Fetches processed data from the FIFO and serializes it for external communication.
* **Baud Generator & TX FSM:** Manages the standard UART protocol and timing based on the slower `clk_slow` clock.

### 3. Clock Domain Crossing (CDC) & Async FIFO
* **Gray Code Pointers:** Used for the FIFO's internal read/write address pointers to ensure only one bit changes per clock cycle.
* **2-Stage Flip-Flop Synchronizers:** Implemented to safely pass the Gray-coded pointers between the 100MHz and 10MHz domains, mitigating metastability risks.

## Advanced Engineering Verification
* **Gate-Level Simulation (GLS):** The system was rigorously verified post-synthesis using ModelSim to ensure hardware-accurate behavior.
* **Static Timing Analysis (STA):** Constrained using a standard `.sdc` file. Cross-domain paths were strictly defined using `set_false_path` exceptions to prove zero setup/hold violations within the synchronous domains.
* **Power Analysis:** A comparative power analysis was conducted via Quartus Power Analyzer (driven by `.vcd` toggle rates). It validates the trade-offs between the clock routing power saved by the `ALTCLKCTRL` gate and the operational overhead of the gating logic itself.

## Repository Structure
The repository is structured to maintain a clean separation between source code, testbenches, and tool-specific configuration files:

```text
├── source code/                 # RTL source files (.v) and IP modules (.qsys)
│   ├── clk_gater_ALTCLKCTRL/    # Clock Gating IP generated files
│   ├── FIR_4Tap.v               # 4-Tap FIR Filter
│   ├── async_fifo_top.v         # Asynchronous FIFO top module
│   ├── uart_top.v               # UART transmitter top module
│   └── ...                      # Additional design modules
├── testbench/                   # Verification and simulation files
│   ├── system_top_TB.v          # Main system testbench
│   └── ...                      # Module-level testbenches
├── FIFO_Toplvl.qpf              # Quartus Prime Project File
├── FIFO_Toplvl.qsf              # Quartus Settings File (Pinout & Assignments)
├── FIFO_Toplvl.clk.sdc          # Synopsys Design Constraints (Timing Analysis)
└── .gitignore                   # Ignores build artifacts (db/, output_files/, etc.)
```

## Tools & Environment
* **FPGA Family:** Intel/Altera Cyclone IV E (EP4CE115F29C7)
* **Synthesis & Implementation:** Intel Quartus Prime 20.1 Lite Edition
* **Simulation:** ModelSim - Intel FPGA Edition

## How to Run
1. Clone this repository.
2. Open the `FIFO_Toplvl.qpf` project file in Quartus Prime.
3. Run **Start Compilation** to synthesize the design and generate the Netlist.
4. For simulation, the project is configured to use NativeLink. Open ModelSim via *Tools -> Run Simulation Tool -> RTL Simulation*.