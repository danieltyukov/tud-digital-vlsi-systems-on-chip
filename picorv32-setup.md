# PicoRV32 Setup Guide

PicoRV32 is a size-optimized RISC-V CPU core (RV32IMC) for use as an auxiliary processor in FPGA/ASIC designs.

## Installation

Repository cloned to `~/picorv32/`.

### Installed packages

```bash
sudo apt-get install -y iverilog gcc-riscv64-unknown-elf
```

- **Icarus Verilog 12.0** — Verilog simulation
- **riscv64-unknown-elf-gcc 13.2.0** — RISC-V cross-compiler and binutils

## Running Tests

```bash
cd ~/picorv32

# Quick test (no toolchain needed)
make test_ez

# Full test suite (firmware, IRQ, MUL/DIV)
make test TOOLCHAIN_PREFIX=riscv64-unknown-elf-
```

## Usage

### Core file

`~/picorv32/picorv32.v` — copy this single file into any project.

### Module variants

| Module | Bus Interface |
|---|---|
| `picorv32` | Simple native memory interface |
| `picorv32_axi` | AXI4-Lite |
| `picorv32_wb` | Wishbone |

### Minimal instantiation (native interface)

```verilog
picorv32 #(
    .ENABLE_MUL(1),
    .ENABLE_DIV(1),
    .ENABLE_IRQ(0),
    .COMPRESSED_ISA(0),
    .STACKADDR(32'h0002_0000)
) cpu (
    .clk       (clk),
    .resetn    (resetn),
    .mem_valid (mem_valid),
    .mem_instr (mem_instr),
    .mem_ready (mem_ready),
    .mem_addr  (mem_addr),
    .mem_wdata (mem_wdata),
    .mem_wstrb (mem_wstrb),
    .mem_rdata (mem_rdata)
);
```

### Compiling firmware

```bash
# Compile C code to RV32IM binary
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib \
    -T ~/picorv32/firmware/riscv.ld -o firmware.elf firmware.c start.S

# Convert to hex for Verilog $readmemh
riscv64-unknown-elf-objcopy -O verilog firmware.elf firmware.hex
```

### Reference designs

- `~/picorv32/picosoc/` — complete SoC with SPI flash, UART, GPIO
- `~/picorv32/firmware/` — test firmware with C code, IRQ handling, custom instructions (public domain)
- `~/picorv32/testbench_ez.v` — simplest testbench to see the CPU run
