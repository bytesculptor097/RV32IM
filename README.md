# RV32IM CPU Core in Verilog

**A custom-built, lightweight, and fully synthesizable RISC-V RV32IM-compatible CPU written in Verilog**

## Description

This project is a clean-room implementation of a **32-bit RISC-V (RV32IM) CPU** designed and implemented from scratch in Verilog HDL. It supports the standard integer (I) and multiplication/division (M) extensions. My objective with this CPU core is to provide a clear, modifiable design for both educational and experimental purposes:
- **Instruction Set**: Supports all **RV32I** (base integer) and **RV32M** (multiply/divide) instructions.
- **Approach**: Designed for readability, modularity, and simplicity—making it perfect for teaching, experiments, or as a reference for your own designs.
- **Motivation**: I wanted a CPU core that is easy to understand, customize, and integrate into larger SoC or FPGA projects, while adhering rigorously to the RISC-V open standard.

## Features

- **Fully compliant** with the RV32IM instruction set (RISC-V User Level ISA v2.1)
- **Synthesizable Verilog 2001**
- **Optional hazards forwarding** and basic single-cycled
- **Testbench provided** for basic functional verification
- **Simple memory-mapped I/O** for easy SoC integration
- Well-documented code with line-level comments

## Table of Contents

- [Getting Started](#getting-started)
- [CPU Architecture](#cpu-architecture)
- [Usage and Simulation](#usage-and-simulation)
- [Project Structure](#project-structure)
- [Planned Improvements](#planned-improvements)
- [License](#license)
- [Contact](#contact)

## Getting Started

1. **Clone the repository:**
   ```
   git clone https://github.com/bytesculptor097/RV32IM
   cd src
   ```
2. **Requirements:**
   - Verilog simulator (e.g., Icarus Verilog, ModelSim, or Verilator)
   - GTKWave (optional, for waveform visualization)

 

## CPU Architecture

- **Single-cycled**: Single-cycled CPU
- **Instruction Support**: All RV32I and RV32M instructions
- **Key modules**:
   - `core.v` : The top level module
   - `pc.v` : Program Counter handler
   - `imem.v` : Instruction memory
   - `decode.v`: Instruction decoder
   - `cu.v` : The control Unit
   - `reg_file.v` : With 32 registers (x0 - x31)
   - `alu.v` and `alu_control.v: ALU and branch resolution
   - `dat_mem.v`: Data memory interface


## Usage and Simulation

1. Type the command in you terminal:- (make sure to change the directory to src/rtl folder and ensure to download iverilog in your cmd or text editor) 

```
iverilog -o cpu.vvp alu_control.v alu.v core.v cu.v data_mem.v decode.v imem.v pc.v reg_file.v tb_core.v
```
2. The module currently does `sw` operation.
 
## Project Structure

- `/rtl` — Core Verilog source files ( ALU, regfile, etc.)
- `/testbench` — Testbenches and basic memory models
- `/docs` — Architecture diagrams 

## Planned Improvements

- Support for additional RISC-V extensions (such as Zicsr, atomics)
- Add pipeline stages
- More complete set of simulation/verification tests

# Currently working on building an Assembler for RISC-V Assembly
## License

This project is licensed under the MIT License. See [`LICENSE`](./LICENSE) for details.

