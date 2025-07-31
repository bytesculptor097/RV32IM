# RV32IM CPU Core in Verilog

**A custom-built, lightweight, and fully synthesizable RISC-V RV32IM-compatible CPU written in Verilog**

## Description

This project is a clean-room implementation of a **32-bit RISC-V (RV32IM) CPU** designed and implemented from scratch in Verilog HDL. It supports the standard integer (I) and multiplication/division (M) extensions. My objective with this CPU core is to provide a clear, modifiable design for both educational and experimental purposes:
- **Instruction Set**: Supports all **RV32I** (base integer) and **RV32M** (multiply/divide) instructions.
- **Approach**: Designed for readability, modularity, and simplicity—making it perfect for teaching, experiments, or as a reference for your own designs.
- **Motivation**: I wanted a CPU core that is easy to understand, customize, and integrate into larger SoC or FPGA projects, while adhering rigorously to the RISC-V open standard.
---
## Features

- **Fully compliant** with the RV32IM instruction set (RISC-V User Level ISA v2.1)
- **Synthesizable Verilog 2001**
- **Optional hazards forwarding** and basic single-cycled
- **Testbench provided** for basic functional verification
- **Simple memory-mapped I/O** for easy SoC integration
- Well-documented code with line-level comments
---
## Table of Contents

- [Getting Started](#getting-started)
- [CPU Architecture](#cpu-architecture)
- [Project Structure](#project-structure)
- [Usage and Simulation](#usage-and-simulation)
- [Operations](#operations)
- [FPGA Implementation](#fpga-implementation)
- [Planned Improvements](#planned-improvements)
- [License](#license)
- [Contact](#contact)
---
## Getting Started

1. **Clone the repository:**
   ```
   git clone https://github.com/bytesculptor097/RV32IM
   cd src
   ```
2. **Requirements:**
   - Verilog simulator (e.g., Icarus Verilog, ModelSim, or Verilator)
   - GTKWave (optional, for waveform visualization)

 
---
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
---
## Project Structure

- `/rtl` — Core Verilog source files ( ALU, regfile, etc.)
- `/testbench` — Testbenches and basic memory models
- `/docs` — Architecture diagrams
- `/fpga` — Implementation of the CPU on VSDSquadronFM
---
## Usage and Simulation

1. Type the command in you terminal:- (make sure to change the directory to src/rtl folder and ensure to download iverilog in your cmd or text editor) 

```
iverilog -o cpu.vvp alu_control.v alu.v core.v cu.v data_mem.v decode.v imem.v pc.v reg_file.v tb_core.v
```
2. Please change the the instuction memory of the CPU like this:-
```verilog
module ram (
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] din,
    output reg [31:0] dout
);
    reg [31:0] mem [0:1023]; // 4KB RAM

    always @(posedge clk) begin
        if (we)
            mem[addr[11:2]] <= din;
        dout <= mem[addr[11:2]];
    end


    initial begin
     mem[0] = 32'h022082b3;  // <------ Change this code for different operations
    end

endmodule


```

and,

```verilog
module regfile (
    input wire clk,
    input wire reg_write,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] wd,
    output wire [31:0] rs1_val,
    output wire [31:0] rs2_val,
    output wire [31:0] x3_debug,
    output wire [31:0] x5_debug
);

    reg [31:0] regs [0:31];


    // Read logic
    assign rs1_val = regs[rs1];
    assign rs2_val = regs[rs2];

    // Write logic
    always @(posedge clk) begin
        if (reg_write && rd != 5'd0) begin
            regs[rd] <= wd;
            $display("WRITE: x%0d <= %h at time %0t", rd, wd, $time);
        end
    end

    // Debug outputs
    assign x3_debug = regs[3];
    assign x5_debug = regs[5];

 initial begin
    regs[1] = 32'd15; // Change this value for the register source 1    
    regs[2] = 32'd4;  // Change this value for the register source 2
 end

    always @(posedge clk) begin
    $display("x3 = %h, x5 = %h", regs[3], regs[5]);
    end

initial begin
 $display("rs1value = %h", rs1_val);
 $display("rs2value = %h", rs2_val);
end


endmodule
```
---
## Operations
Use the following table's hex code for changing the operation in the instruction memory:-

| Mnemonic | Format | Example Operands     | 32-bit Hex Code | Description                            |
|----------|--------|----------------------|------------------|----------------------------------------|
| add      | R-type | add x5, x1, x2       | 0x002081b3       | x5 = x1 + x2                            |
| sub      | R-type | sub x5, x1, x2       | 0x402081b3       | x5 = x1 - x2                            |
| and      | R-type | and x5, x1, x2       | 0x002071b3       | x5 = x1 & x2                            |
| or       | R-type | or x5, x1, x2        | 0x002061b3       | x5 = x1 | x2                            |
| xor      | R-type | xor x5, x1, x2       | 0x002051b3       | x5 = x1 ^ x2                            |
| sll      | R-type | sll x5, x1, x2       | 0x002011b3       | x5 = x1 << x2                           |
| srl      | R-type | srl x5, x1, x2       | 0x002051b3       | x5 = x1 >> x2 (logical)                 |
| sra      | R-type | sra x5, x1, x2       | 0x402051b3       | x5 = x1 >> x2 (arithmetic)              |
| slt      | R-type | slt x5, x1, x2       | 0x002021b3       | x5 = (x1 < x2) ? 1 : 0                  |
| sltu     | R-type | sltu x5, x1, x2      | 0x002031b3       | x5 = (x1 < x2 unsigned) ? 1 : 0         |
| addi     | I-type | addi x5, x1, 10      | 0x00a08093       | x5 = x1 + 10                            |
| andi     | I-type | andi x5, x1, 10      | 0x00a0f093       | x5 = x1 & 10                            |
| ori      | I-type | ori x5, x1, 10       | 0x00a0e093       | x5 = x1 | 10                            |
| xori     | I-type | xori x5, x1, 10      | 0x00a0c093       | x5 = x1 ^ 10                            |
| lw       | I-type | lw x5, 0(x1)         | 0x0000a283       | x5 = MEM[x1 + 0]                        |
| sw       | S-type | sw x2, 0(x1)         | 0x0020a023       | MEM[x1 + 0] = x2                        |
| beq      | B-type | beq x1, x2, +4       | 0x00208663       | if (x1 == x2) PC += 4                   |
| bne      | B-type | bne x1, x2, +4       | 0x00209663       | if (x1 != x2) PC += 4                   |
| jal      | J-type | jal x5, +4           | 0x0040006f       | x5 = PC+4; PC += 4                      |
| jalr     | I-type | jalr x5, 0(x1)       | 0x00008067       | x5 = PC+4; PC = x1                      |
| lui      | U-type | lui x5, 0x12345      | 0x123450b7       | x5 = 0x12345000                         |
| auipc    | U-type | auipc x5, 0x12345    | 0x12345097       | x5 = PC + 0x12345000                    |
| mul      | R-type | mul x5, x1, x2       | 0x022081b3       | x5 = x1 * x2                            |
| mulh     | R-type | mulh x5, x1, x2      | 0x022091b3       | x5 = high(x1 * x2 signed)               |
| mulhsu   | R-type | mulhsu x5, x1, x2    | 0x0220a1b3       | x5 = high(x1 signed * x2 unsigned)      |
| mulhu    | R-type | mulhu x5, x1, x2     | 0x0220b1b3       | x5 = high(x1 * x2 unsigned)             |
| div      | R-type | div x5, x1, x2       | 0x0220c1b3       | x5 = x1 / x2 (signed)                   |
| divu     | R-type | divu x5, x1, x2      | 0x0220d1b3       | x5 = x1 / x2 (unsigned)                 |
| rem      | R-type | rem x5, x1, x2       | 0x0220e1b3       | x5 = x1 % x2 (signed)                   |
| remu     | R-type | remu x5, x1, x2      | 0x0220f1b3       | x5 = x1 % x2 (unsigned)                 |

---
## FPGA Implementation
We will implement this core on [VSDSquadronFM](https://www.vlsisystemdesign.com/vsdsquadronfm/), follow the steps for implementation:-

1. Follow the environment setup instructions in [this](https://github.com/bytesculptor097/VSDSquadron_FM) repository of mine.
2. Then open the `fpga` directory present inside the src using the terminal, by:-
```bash
cd  git/cloned/path/of/this/repository/src/fpga
```
3. Then type:-
```bash
make build
```
4. Then make sure to connect the VSDSquadronFM board, and then:-
```bash
sudo make flash
```
---
## Planned Improvements

- Support for additional RISC-V extensions (such as Zicsr, atomics)
- Add pipeline stages
- More complete set of simulation/verification tests

---
## License

This project is licensed under the MIT License. See [`LICENSE`](./LICENSE) for details.
---


