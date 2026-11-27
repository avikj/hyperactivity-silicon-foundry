`timescale 1ns/1ps
module hypernet_vs_rv32_tb;
  logic        clk = 1'b0, rst = 1'b1, start = 1'b0;
  logic [1:0]  prog_sel = 2'd0;
  logic        hn_done, rv_done;
  logic [31:0] hn_res, rv_res;
  logic [15:0] hn_steps, hn_steal, hn_prune, hn_alloc, hn_gated;
  logic [7:0]  hn_free;
  logic [15:0] rv_cyc, rv_inst;
  hypernet_mesh_4tile u_hn (
    .clk(clk), .rst(rst), .start(start), .prog_sel(prog_sel),
    .quiescent(hn_done), .root_result(hn_res), .total_steps(hn_steps),
    .stolen_count(hn_steal), .pruned_count(hn_prune), .alloc_count(hn_alloc),
    .gated_tile_cycles(hn_gated), .total_free_cells(hn_free)
  );
  riscv32_pipe u_rv (
    .clk(clk), .rst(rst), .start(start), .prog_sel(prog_sel),
    .halted(rv_done), .result_out(rv_res), .cycle_count(rv_cyc), .inst_retired(rv_inst)
  );
  task automatic tick; begin #5 clk = 1'b1; #5 clk = 1'b0; end endtask
  integer p, hn_c, guard;
  logic [31:0] exp_val;
  initial begin
    rst = 1'b1; tick(); rst = 1'b0;
    for (p = 0; p < 3; p = p + 1) begin
      prog_sel = p[1:0]; exp_val = (p == 1) ? 32'd144 : 32'd36;
      start = 1'b1; tick(); start = 1'b0;
      hn_c = 0; guard = 0;
      while ((!hn_done || !rv_done) && guard < 200) begin
        if (!hn_done) hn_c = hn_c + 1;
        tick(); guard = guard + 1;
      end
      if (!hn_done || !rv_done)      $fatal(1, "Timeout waiting for completion");
      if (hn_res !== exp_val || rv_res !== exp_val)      $fatal(1, "Normal-form value mismatch");
      if (hn_free !== 8'd32)      $fatal(1, "Freelist cell leak detected");
      if (p == 0 && hn_steal < 16'd2)      $fatal(1, "Expected multi-tile work stealing");
      if (p == 2 && hn_prune !== 16'd1)      $fatal(1, "Expected 1-cycle cubical face prune");
      $display("BENCH_PROG_%0d: ans=%0d | HyperNet_4Tile(cycles=%0d, steps=%0d, stolen=%0d, pruned=%0d, allocs=%0d, free=%0d/32, gated_tile_cyc=%0d) | RISCV32(cycles=%0d, inst=%0d)", p, hn_res, hn_c, hn_steps, hn_steal, hn_prune, hn_alloc, hn_free, hn_gated, rv_cyc, rv_inst);
    end
    $finish;
  end
endmodule
