# Hyperactivity Silicon — Foundry Delivery Bundle

**Foundry-ready, non-von-Neumann & Tiny Tapeout supercomputer silicon designs emitted directly from [Hyperactivity](https://github.com/avikj/hyperactivity) (`.hypercubical`) at commit `e211d839c`.**

Every Verilog/SystemVerilog netlist, Tiny Tapeout submission manifest (`info.yaml`, `yaml_version: 6`), IEEE Liberty 7nm NLDM standard-cell library (`.lib`), testbench, and binary Calma GDSII v6.0 layout stream (`.gds`) in this repository was mechanically emitted from zero-postulate `.hypercubical` specifications and independently verified with external semiconductor EDA tools (**Icarus Verilog**, **Yosys**, **UC Berkeley `ABC`**, **Verilator**, **KLayout**, and the physical **SkyWater 130nm `sky130_fd_sc_hd`** foundry standard-cell library).

- **Technical Treatise:** [https://hyperactivity.ai/silicon](https://hyperactivity.ai/silicon) · [https://hyperactivity.ai/chip-design](https://hyperactivity.ai/chip-design)
- **Source Compiler & Proofs:** [https://github.com/avikj/hyperactivity](https://github.com/avikj/hyperactivity)

---

## 1. Quick-Start Verification (1 Command)

Any engineer with `iverilog`, `vvp`, and `python3` installed can reproduce every simulation, binary Calma GDSII v6.0 stream check, and SHA-256 integrity check in under 10 seconds:

```bash
git clone https://github.com/avikj/hyperactivity-silicon-foundry.git
cd hyperactivity-silicon-foundry
./verify_all.sh
```

If you also have `yosys` and the open-source SkyWater 130nm Liberty file (`sky130_fd_sc_hd__tt_025C_1v80.lib`), pass `SKY130_LIB=/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib ./verify_all.sh` to reproduce the exact SkyWater 130nm foundry standard-cell synthesis and die-area figures below.

---

## 2. Package Overview (6 Complete Supercomputer Silicon Designs)

| # | Directory | Target Process / Shuttle | Architecture | Verification & Real Foundry Metrics |
|---|---|---|---|---|
| **01** | [`01_tt_um_avikj_hyperactivity/`](./01_tt_um_avikj_hyperactivity) | **Tiny Tapeout SkyWater Sky130A** (`TTSKY26d/e`) & **GF180MCU** (`1×2` tile) | 4-Engine Hyperactivity Supercomputer ASIC (`tt_um_avikj_hyperactivity`) lowering 16 minimal NAND2 blocks + PSC-1 + RV32I | `iverilog` PASS · **Sky130:** `2,120` cells, **`16,026.62 µm²`** (`50.1%` of `1×2` tile) · Complete `info.yaml` (`v6`), `docs/info.md`, `test/tb.v`, `test/test.py` (cocotb RTL+GL) |
| **02** | [`02_tt_um_hyperinet_v2/`](./02_tt_um_hyperinet_v2) | **Tiny Tapeout SkyWater Sky130A** (`2×2` tile) | **HyperINet v2** (`tt_um_hyperinet`): Zero-PC, zero-ISA dual-lane parallel Lafont Interaction-Net processor + fused 8-bit `NUM`/`ADD` + runtime graph loader | `iverilog` + `vvp` **PASS (`3/3` compiled `.hypercubical` programs, `2.0` redexes/cycle)** · **Sky130:** `11,247` cells, `211` FFs, `0` latches, **`65,738.05 µm²`** · Complete `info.yaml` (`v6`) |
| **03** | [`03_wafer_space_gf180mcu_soc/`](./03_wafer_space_gf180mcu_soc) | **wafer.space GF180MCU MPW** (Full `20 mm²` / Quarter `5 mm²`, ~1,000 dies) | Full-die multi-core supercomputer SoC (`4× INet` + `2× BF16` + `RV32I` + dual hardened GF180MCU `512×8` SRAM macros) | Complete `src/chip_core.sv` (`16.3 KB`) + `cocotb/chip_top_tb.py` (`4.2 KB`) wired to GF180MCU PDK SRAM macros |
| **04** | [`04_hypernet_4tile_mpw/`](./04_hypernet_4tile_mpw) | **7nm NLDM CMOS MPW** (`5.2 × 5.2 µm` hierarchical `AREF 2×2`) | Self-hosting 4-tile GALS **HyperNet** mesh (zero MESI cache coherence, zero GC, 1-cycle cubical dead-subgraph pruning) vs. pipelined `riscv32_pipe` | `iverilog` + `vvp` **ALL 3 BENCHMARKS PASS** (`19` vs `44` cyc on 8-leaf tree; `23` vs `49` cyc on cubical pruned tree; `32/32` cells recovered) · **GDSII v6.0 PASS** (`1,328 B`, `101` records) · Includes `hypercore_cmos7nm.lib` |
| **05** | [`05_hypernet16_4x4_mpw/`](./05_hypernet16_4x4_mpw) | **7nm NLDM CMOS MPW** (hierarchical `AREF 4×4` die) | 16-tile (`4×4`) universal cubical **HyperNet-16** supercomputer (`CON`/`DUP`/`ERA` + `ClauseVec 4` + Work-Stealing NoC) | **GDSII v6.0 PASS** (`5,386 B`, `421` records, `9` hierarchical cell/tile structs, `BOUNDARY=71`, `AREF=2`, `SREF=6`) · Verilator SystemVerilog RTL & RV32 comparison testbench |
| **06** | [`06_hypercore_soc_3nm_foundry/`](./06_hypercore_soc_3nm_foundry) | **3nm GAA Standard-Cell & 5-Layer SoC** | Core SoC (`hypercore_soc`: pipelined Hart + MMIO + `2×2` systolic MAC), `[8,4,4]` SECDED ECC, GALS INet tile, and strictly optimal 4-`NAND2` XOR cell | `iverilog` + `vvp` **`HYPERCORE_VERILATOR_PASS`** (`xor4=4/4`, `secded=592/592`, `soc pc=11 C=[[40,60],[60,90]]`) · **Both GDSII v6.0 files PASS** (`376 B` & `890 B`) |

---

## 3. Detailed Engineering Notes per Package

### Package 01 — `tt_um_avikj_hyperactivity` (Tiny Tapeout Sky130A / GF180MCU, `1×2` Tile)
- **Origin:** `lib/silicon/hx-tt-tapeout.hypercubical` (`2,391 passed, 0 failed`).
- **Contents:**
  - `src/project.v` (`14,845 B`) — Synthesizable Verilog-2001/SystemVerilog top module `tt_um_avikj_hyperactivity` with standard Tiny Tapeout pinout (`ui_in[7:0]`, `uo_out[7:0]`, `uio_in[7:0]`, `uio_out[7:0]`, `uio_oe[7:0]`, `ena`, `clk`, `rst_n`).
  - `info.yaml` (`958 B`) — Official Tiny Tapeout `yaml_version: 6` submission manifest (`1×2` tile).
  - `docs/info.md` (`1,519 B`) — Human-readable datasheet & pinout specification.
  - `test/tb.v` & `test/test.py` — Self-checking cocotb RTL & gate-level (GL) test harness.
- **SkyWater 130nm Foundry Synthesis (`sky130_fd_sc_hd__tt_025C_1v80.lib`):** `2,120` standard cells, **`16,026.62 µm²`** (`50.1%` utilization of a `1×2` Tiny Tapeout tile).

### Package 02 — `tt_um_hyperinet` (HyperINet v2: Non-von-Neumann Dual-Lane Processor, `2×2` Tile)
- **Origin:** `lib/silicon/inet-fabric.hypercubical` + `lib/silicon/inet-compiler.hypercubical` (`1,624 passed, 0 failed`).
- **Why this architecture matters:** Eliminates the von Neumann bottleneck completely—**no program counter, no instruction cache, no branch predictor, no global register file**. Computation is local 1-cycle Lafont graph rewriting (`CON`, `DUP`, `ERA`) fused with native 8-bit arithmetic (`NUM`, `ADD`, `ADD1`). A combinational dual-lane scanner fires **two disjoint active pairs on the exact same clock edge (`dual_fire = 1`)**.
- **Metacircular Silicon Loop (`test/tb_metacircular.sv`):** Emitted directly by the `.hypercubical` wire-graph compiler (`compile-hexpr`), streaming 3 compiled functional programs over Tiny Tapeout's `ui_in`/`uio_in` pins and verifying physical pin readouts on `uo_out`:
  1. `DUP(21)` → `(21, 21)` in **1 cycle**
  2. `100 + 23` → `123` in **2 cycles**
  3. `(17 + 25) || (30 + 12)` → `(42, 42)` via **4 redexes in 2 clock cycles (`2.0` redexes/cycle)**
- **SkyWater 130nm Foundry Synthesis:** `11,247` standard cells, `211` flip-flops, `0` latches, **`65,738.05 µm²`**.

### Package 03 — `wafer.space` GF180MCU Dual-SRAM Full-Die Supercomputer SoC
- **Origin:** `lib/silicon/hx-wafer-soc.hypercubical` (`2,398 passed, 0 failed`).
- **Contents:** `src/chip_core.sv` (`16,318 B`) and `cocotb/chip_top_tb.py` (`4,244 B`), scaling the verified interaction-net, BF16, and RV32I engines to a full-die GF180MCU MPW with dual hardened `512×8` SRAM macros (`gf180mcu_xxx_ip_sram__sram512x8m8wm1`).

### Packages 04 & 05 — 4-Tile `HyperNet` & 16-Tile `HyperNet-16` GALS MPW Packages
- **Origin:** `lib/silicon/hypernet.hypercubical` & `lib/silicon/hypernet16.hypercubical` (`1,724 passed, 0 failed`).
- **Contents:**
  - `04_hypernet_4tile_mpw/`: `hypercore_cmos7nm.lib` (IEEE Liberty 7nm NLDM PDK), `hypernet_mpw_rtl.sv`, `hypernet_vs_rv32_tb.sv`, and hierarchical `AREF 2×2` binary Calma GDSII v6.0 `hypernet_4tile_soc.gds` (`1,328 B`, `101` records).
  - `05_hypernet16_4x4_mpw/`: `hypernet16_mpw_rtl.sv`, `hypernet16_vs_rv32_tb.sv`, and hierarchical `AREF 4×4` binary Calma GDSII v6.0 `hypernet16_4x4_soc.gds` (`5,386 B`, `421` records, `9` structs). *(Note: `hypernet16_mpw_rtl.sv` uses SystemVerilog `always_comb` constructs requiring Verilator for simulation.)*

### Package 06 — `HyperCore` Core SoC & 5-Layer 3nm GDSII Bundle
- **Origin:** `lib/silicon/export.hypercubical` (`1,724 passed, 0 failed`).
- **Contents:** `hypercore_full_rtl.sv`, `hypercore_tb.sv`, `xor4_gaa3nm.gds` (`376 B`, strictly optimal 4-`NAND2` XOR cell), and `hypercore_soc_5layer.gds` (`890 B`, 5-layer SoC layout). Passes all self-checking assertions in `iverilog` (`xor4=4/4`, `secded=592/592`, `inet=(ann=1,comm=1,prune=1,fp=4)`, `soc C=[[40,60],[60,90]]`).

---

## 4. Cryptographic Integrity & Provenance

Every file in this repository is checksummed in [`SHA256SUMS.txt`](./SHA256SUMS.txt) and directly reproducible from `avikj/hyperactivity` commit `e211d839c` (`./build/cubical`).

For commercial silicon IP licensing, custom ASIC/FPGA co-design, or foundry MPW collaboration: **root@hyperactivity.ai** · [https://hyperactivity.ai/silicon](https://hyperactivity.ai/silicon)
