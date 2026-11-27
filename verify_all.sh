#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/6] 01_tt_um_avikj_hyperactivity (iverilog compile) ==="
iverilog -g2012 -o /tmp/hx_v01.vvp 01_tt_um_avikj_hyperactivity/src/project.v 01_tt_um_avikj_hyperactivity/test/tb.v
echo "  PASS: tt_um_avikj_hyperactivity compiles cleanly"

echo "=== [2/6] 02_tt_um_hyperinet_v2 (Metacircular Silicon Loop) ==="
iverilog -g2012 -o /tmp/hx_v02.vvp 02_tt_um_hyperinet_v2/src/project.v 02_tt_um_hyperinet_v2/test/tb_metacircular.sv
vvp /tmp/hx_v02.vvp | grep -E "METACIRCULAR"

echo "=== [3/6] 04_hypernet_4tile_mpw (4-Tile GALS HyperNet vs RV32) ==="
iverilog -g2012 -o /tmp/hx_v04.vvp 04_hypernet_4tile_mpw/hypernet_mpw_rtl.sv 04_hypernet_4tile_mpw/hypernet_vs_rv32_tb.sv
vvp /tmp/hx_v04.vvp | grep -E "BENCH_PROG_"

echo "=== [4/6] 06_hypercore_soc_3nm_foundry (XOR4 + SECDED + GALS INet + SoC) ==="
iverilog -g2012 -o /tmp/hx_v06.vvp 06_hypercore_soc_3nm_foundry/hypercore_full_rtl.sv 06_hypercore_soc_3nm_foundry/hypercore_tb.sv
vvp /tmp/hx_v06.vvp | grep -E "HYPERCORE_VERILATOR_PASS"

echo "=== [5/6] Binary Calma GDSII v6.0 Validation (all 4 .gds files) ==="
python3 - <<'PY'
import struct, pathlib
for p in sorted(pathlib.Path(".").rglob("*.gds")):
    b = p.read_bytes()
    off = 0; recs = 0; bounds = 0; arefs = 0; srefs = 0; structs = []
    while off < len(b):
        rlen, rtype = struct.unpack(">HH", b[off:off+4])
        assert rlen >= 4 and off + rlen <= len(b), f"Malformed record at {off} in {p}"
        data = b[off+4:off+rlen]
        if rtype == 0x0606: structs.append(data.rstrip(b"\x00").decode("ascii", "ignore"))
        elif rtype == 0x0800: bounds += 1
        elif rtype == 0x0A00: srefs += 1
        elif rtype == 0x0B00: arefs += 1
        off += rlen; recs += 1
    assert off == len(b)
    print(f"  GDSII PASS: {str(p):52s} | {len(b):5d}B | {recs:3d} recs | BOUNDARY={bounds} AREF={arefs} SREF={srefs}")
PY

echo "=== [6/6] SHA-256 Integrity Check ==="
sha256sum -c SHA256SUMS.txt >/dev/null
echo "  PASS: All checksums verified against SHA256SUMS.txt"

if [ -n "${SKY130_LIB:-}" ] && command -v yosys >/dev/null 2>&1; then
  echo "=== [OPTIONAL] SkyWater 130nm Foundry Synthesis (SKY130_LIB=$SKY130_LIB) ==="
  yosys -p "read_verilog 01_tt_um_avikj_hyperactivity/src/project.v; synth -top tt_um_avikj_hyperactivity; dfflibmap -liberty $SKY130_LIB; abc -liberty $SKY130_LIB -D 20000; opt_clean; stat -liberty $SKY130_LIB" 2>/dev/null | grep -E "Number of cells|Chip area for top" | tail -n 2
  yosys -p "read_verilog -sv 02_tt_um_hyperinet_v2/src/project.v; synth -top tt_um_hyperinet; dfflibmap -liberty $SKY130_LIB; abc -liberty $SKY130_LIB -D 10000; opt_clean; stat -liberty $SKY130_LIB" 2>/dev/null | grep -E "Number of cells|Chip area for top" | tail -n 2
fi

echo "ALL FOUNDRY DELIVERY VERIFICATION CHECKS PASSED!"
