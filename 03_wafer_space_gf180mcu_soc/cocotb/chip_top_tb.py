# SPDX-FileCopyrightText: 2026 Avik Jain / Hyperactive Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
import os, logging
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles
from cocotb_tools.runner import get_runner

sim = os.getenv('SIM', 'icarus')
gl = os.getenv('GL', False)
pdk_root = os.getenv('PDK_ROOT', Path(__file__).resolve().parent / '../gf180mcu')
pdk = os.getenv('PDK', 'gf180mcuD')
scl = os.getenv('SCL', 'gf180mcu_fd_sc_mcu7t5v0')
pad = os.getenv('PAD', 'gf180mcu_fd_io')
sram = os.getenv('SRAM', 'gf180mcu_fd_ip_sram')
slot = os.getenv('SLOT', '1x1')
hdl_toplevel = 'chip_top'

async def send_cmd(dut, cmd, byte):
    dut.input_PAD.value = (1 << 11) | ((cmd & 7) << 8) | (byte & 0xFF)
    await ClockCycles(dut.clk_PAD, 1)
    dut.input_PAD.value = 0
    await ClockCycles(dut.clk_PAD, 1)

async def load_u32(dut, cmd, val):
    for s in [24, 16, 8, 0]:
        await send_cmd(dut, cmd, (val >> s) & 0xFF)

@cocotb.test()
async def test_wafer_hyperactivity_soc(dut):
    dut.input_PAD.value = 0
    if gl:
        dut.VDD.value = 1
        dut.VSS.value = 0
    cocotb.start_soon(Clock(dut.clk_PAD, 40, 'ns').start())
    dut.rst_n_PAD.value = 0
    await Timer(500, 'ns')
    dut.rst_n_PAD.value = 1
    await ClockCycles(dut.clk_PAD, 4)

    # 1. RV32I ALU (bank 3): 0x12345678 + 0x01020304 = 0x1336597C
    await load_u32(dut, 1, 0x12345678)
    await load_u32(dut, 2, 0x01020304)
    await send_cmd(dut, 3, 0xC0)
    assert (int(dut.bidir_PAD.value) & 0xFFFFFFFF) == 0x1336597C

    # 2. Lossless 12b->16b BF16 Unzip + Exact BF16xBF16->FP32 (bank 1): 1.5 * 2.0 = 3.0 (0x40400000)
    await load_u32(dut, 1, 0x40000000)
    await send_cmd(dut, 4, 0x40)
    await send_cmd(dut, 3, 0x60)
    assert (int(dut.bidir_PAD.value) & 0xFFFFFFFF) == 0x40400000

    # 3. 4x Parallel HyperINet-Opt Tiles (bank 0): all 4 lanes active pair commute simultaneously!
    await load_u32(dut, 1, 0x05050505)
    await load_u32(dut, 2, 0x00000000)
    await send_cmd(dut, 3, 0x00)
    v_inet = int(dut.bidir_PAD.value) & 0xFFFFFFFF
    for lane in range(4):
        assert (((v_inet >> (lane * 8)) & 0x05) == 0x04)

    # 4. Dual Hardened 512x8 On-Chip SRAM Write & Read + 4-Lane Fiber (bank 2)
    await load_u32(dut, 1, 0x000011AB)
    await load_u32(dut, 2, 0x00002205)
    await send_cmd(dut, 5, 0xCD)
    await ClockCycles(dut.clk_PAD, 2)
    await send_cmd(dut, 6, 0x00)
    await send_cmd(dut, 3, 0x80)
    await ClockCycles(dut.clk_PAD, 2)
    v_sram = int(dut.bidir_PAD.value) & 0xFFFFFFFF
    assert ((v_sram >> 16) & 0xFFFF) == 0xCDAB

def chip_top_runner():
    proj_path = Path(__file__).resolve().parent
    sources = []
    defines = {'SLOT_' + slot.upper(): True, 'PDK_' + pdk.replace('-', '_'): True, 'SCL_' + scl: True, 'PAD_' + pad: True, 'SRAM_' + sram: True}
    includes = [proj_path / '../src/']
    if gl:
        sources.append(Path(pdk_root) / pdk / 'libs.ref' / scl / 'verilog' / f'{scl}.v')
        if scl != 'gf180mcu_as_sc_mcu7t3v3':
            sources.append(Path(pdk_root) / pdk / 'libs.ref' / scl / 'verilog' / 'primitives.v')
        sources.append(proj_path / f'../final/pnl/{hdl_toplevel}.pnl.v')
        defines.update({'FUNCTIONAL': True, 'USE_POWER_PINS': True})
    else:
        sources += [proj_path / '../src/chip_top.sv', proj_path / '../src/chip_core.sv']
    sources += [
        Path(pdk_root) / pdk / f'libs.ref/{pad}/verilog/{pad}.v',
        Path(pdk_root) / pdk / f'libs.ref/{sram}/verilog/{sram}__sram512x8m8wm1.v',
        proj_path / '../ip/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v',
        proj_path / '../ip/gf180mcu_ws_ip__marker/vh/gf180mcu_ws_ip__marker.v',
        proj_path / '../ip/gf180mcu_ws_ip__qrcode_id/vh/gf180mcu_ws_ip__qrcode_id.v',
        proj_path / '../ip/gf180mcu_ws_ip__shuttle_id/vh/gf180mcu_ws_ip__shuttle_id.v',
        proj_path / '../ip/gf180mcu_ws_ip__project_id/vh/gf180mcu_ws_ip__project_id.v',
    ]
    runner = get_runner(sim)
    runner.build(sources=sources, hdl_toplevel=hdl_toplevel, defines=defines, always=True, includes=includes, waves=True)
    runner.test(hdl_toplevel=hdl_toplevel, test_module='chip_top_tb,', waves=True)

if __name__ == '__main__':
    chip_top_runner()
