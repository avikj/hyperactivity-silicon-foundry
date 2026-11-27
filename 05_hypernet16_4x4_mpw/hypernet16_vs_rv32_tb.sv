`timescale 1ns/1ps
module hypernet16_vs_rv32_tb;
  logic clk = 0, rst = 1, start = 0;
  logic [1:0] prog_sel = 0;
  always #5 clk = ~clk;
  logic        hn_q, rv_halt;
  logic [31:0] hn_ans, rv_ans;
  logic [15:0] hn_steps, hn_stolen, hn_pruned, hn_allocs, hn_gated, rv_cyc, rv_inst;
  logic [7:0]  hn_fcells, hn_fvars;
  logic [4:0]  hn_peak;
  hypernet16_mesh_4x4 u_hn16 (
    .clk(clk), .rst(rst), .start(start), .prog_sel(prog_sel),
    .quiescent(hn_q), .root_result(hn_ans),
    .total_steps(hn_steps), .stolen_count(hn_stolen), .pruned_count(hn_pruned),
    .alloc_count(hn_allocs), .gated_tile_cycles(hn_gated),
    .total_free_cells(hn_fcells), .total_free_vars(hn_fvars), .active_tiles_peak(hn_peak)
  );
  riscv32_pipe16 u_rv32 (
    .clk(clk), .rst(rst), .start(start), .prog_sel(prog_sel),
    .halted(rv_halt), .result_out(rv_ans), .cycle_count(rv_cyc), .inst_retired(rv_inst)
  );
  integer p, hn_cyc;
  logic [31:0] exp_ans [0:3];
  initial begin
    exp_ans[0] = 32'd10;
    exp_ans[1] = 32'd12;
    exp_ans[2] = 32'd136;
    exp_ans[3] = 32'd10;
    @(posedge clk); @(posedge clk); rst = 0;
    for (p = 0; p < 4; p = p + 1) begin
      prog_sel = p[1:0]; start = 1;
      @(posedge clk); start = 0;
      hn_cyc = 0;
      while ((!hn_q || !rv_halt) && hn_cyc < 5000) begin
        @(posedge clk);
        if (!hn_q) hn_cyc = hn_cyc + 1;
      end
      $display("BENCH_%0d: ans=%0d (rv=%0d) | HyperNet16_4x4(cycles=%0d, steps=%0d, stolen=%0d, peak_tiles=%0d/16, pruned=%0d, allocs=%0d, cells=%0d/128, vars=%0d/128, gated_cyc=%0d) | RISCV32(cycles=%0d, inst=%0d)",
               p, hn_ans, rv_ans, hn_cyc, hn_steps, hn_stolen, hn_peak, hn_pruned, hn_allocs, hn_fcells, hn_fvars, hn_gated, rv_cyc, rv_inst);
      if (!hn_q || !rv_halt || hn_ans !== exp_ans[p] || rv_ans !== exp_ans[p] || hn_fcells !== 8'd128 || hn_fvars !== 8'd128) begin
        $display("FAIL on BENCH_%0d!", p);
        $fatal(1);
      end
    end
    $display("ALL_4_HYPERNET16_BENCHMARKS_PASSED");
    $finish;
  end
endmodule
