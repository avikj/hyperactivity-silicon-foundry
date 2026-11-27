`timescale 1ns/1ps
module hypercore_tb;
  // 1. Exhaustive 4-NAND2 shared XOR vs behavioral ALU sum check
  logic xa, xb, y_beh, y_nand;
  alu_sum_rtl     u_alu  (.a(xa), .b(xb), .y(y_beh));
  xor4_shared_net u_xor4 (.a(xa), .b(xb), .y(y_nand));

  // 2. Exhaustive [8,4,4] SECDED single-bit heal & double-bit detect (592 cases)
  logic [3:0] msg_in, healed_msg;
  logic [7:0] err_mask, code_out;
  logic       s_heal, d_det;
  hypercore_secded84 u_ecc (
    .msg_in(msg_in), .err_mask(err_mask), .code_out(code_out),
    .healed_msg(healed_msg), .single_err_healed(s_heal), .double_err_detected(d_det)
  );

  // 3. Pipelined Branch-Squashing Hart + MMIO 2x2 Systolic Tensor-Core SoC
  logic        clk = 1'b0, rst = 1'b1;
  logic [7:0]  pc_out;
  logic        if_valid_out;
  logic [15:0] r3_out, r6_out, r7_out, dmem1_out;
  logic [31:0] c00_out, c01_out, c10_out, c11_out;
  hypercore_soc u_soc (
    .clk(clk), .rst(rst), .pc_out(pc_out), .if_valid_out(if_valid_out),
    .r3_out(r3_out), .r6_out(r6_out), .r7_out(r7_out), .dmem1_out(dmem1_out),
    .c00_out(c00_out), .c01_out(c01_out), .c10_out(c10_out), .c11_out(c11_out)
  );

  // 4. Section 4.5 GALS Cubical Interaction-Net Silicon Tile
  logic        it_valid = 1'b0, it_op_a = 1'b0, it_op_b = 1'b0;
  logic [3:0]  it_tag_a = 4'd0, it_tag_b = 4'd0;
  logic [3:0]  it_pa = 4'd0, it_na = 4'd0, it_pb = 4'd0, it_nb = 4'd0;
  logic        it_clken, it_conf;
  logic [15:0] it_ann, it_comm, it_prune, it_fp, it_gated;
  hypercore_inet_tile u_inet (
    .clk(clk), .rst(rst), .pair_valid(it_valid),
    .op_a(it_op_a), .op_b(it_op_b), .tag_a(it_tag_a), .tag_b(it_tag_b),
    .pos_a(it_pa), .neg_a(it_na), .pos_b(it_pb), .neg_b(it_nb),
    .clk_en_out(it_clken), .face_conflict_out(it_conf),
    .ann_count(it_ann), .comm_count(it_comm), .prune_count(it_prune),
    .free_ptr(it_fp), .gated_cycles(it_gated)
  );
  task automatic tick;
    begin #5 clk = 1'b1; #5 clk = 1'b0; end
  endtask

  integer m, b1, b2, cyc;
  initial begin
    // Check 1: 4-NAND2 XOR == Behavioral ALU Sum
    for (m = 0; m < 4; m = m + 1) begin
      xa = m[1]; xb = m[0]; #1;
      if (y_nand !== (xa ^ xb) || y_beh !== y_nand)      $fatal(1, "XOR4 mismatch");
    end
    // Check 2: Exhaustive [8,4,4] SECDED (16 msgs x (1 clean + 8 1-bit + 28 2-bit) = 592 cases)
    for (m = 0; m < 16; m = m + 1) begin
      msg_in = m[3:0]; err_mask = 8'd0; #1;
      if (healed_msg !== msg_in || s_heal !== 1'b0 || d_det !== 1'b0)      $fatal(1, "ECC clean fail");
      for (b1 = 0; b1 < 8; b1 = b1 + 1) begin
        err_mask = (8'd1 << b1); #1;
        if (healed_msg !== msg_in || s_heal !== 1'b1 || d_det !== 1'b0)      $fatal(1, "ECC 1bit fail");
        for (b2 = b1 + 1; b2 < 8; b2 = b2 + 1) begin
          err_mask = (8'd1 << b1) | (8'd1 << b2); #1;
          if (d_det !== 1'b1 || s_heal !== 1'b0)      $fatal(1, "ECC 2bit fail");
        end
      end
    end
    // Check 3 & 4: Synchronous reset + 12 SoC cycles & 5 GALS Cubical Inet-Tile cycles
    rst = 1'b1; tick(); rst = 1'b0;
    it_valid = 1'b0; tick();
    it_valid = 1'b1; it_op_a = 1'b0; it_tag_a = 4'd0; it_pa = 4'b0001; it_na = 4'b0000;
                     it_op_b = 1'b0; it_tag_b = 4'd0; it_pb = 4'b0000; it_nb = 4'b0000; tick();
    it_valid = 1'b1; it_op_a = 1'b0; it_tag_a = 4'd0; it_pa = 4'b0001; it_na = 4'b0000;
                     it_op_b = 1'b1; it_tag_b = 4'd1; it_pb = 4'b0000; it_nb = 4'b0000; tick();
    it_valid = 1'b1; it_op_a = 1'b0; it_tag_a = 4'd0; it_pa = 4'b0001; it_na = 4'b0000;
                     it_op_b = 1'b1; it_tag_b = 4'd1; it_pb = 4'b0000; it_nb = 4'b0001; tick();
    it_valid = 1'b0; tick();
    if (it_ann !== 16'd1 || it_comm !== 16'd1 || it_prune !== 16'd1 || it_fp !== 16'd4 || it_gated !== 16'd2)
      $fatal(1, "Inet tile mismatch");
    for (cyc = 0; cyc < 7; cyc = cyc + 1) tick();
    if (pc_out !== 8'd11 || r3_out !== 16'd15 || r6_out !== 16'd15 || r7_out !== 16'd15 || dmem1_out !== 16'd15)
      $fatal(1, "SoC hart state mismatch");
    if (c00_out !== 32'd40 || c01_out !== 32'd60 || c10_out !== 32'd60 || c11_out !== 32'd90)
      $fatal(1, "Systolic GEMM mismatch");
    $display("HYPERCORE_VERILATOR_PASS: xor4=4/4 secded=592/592 inet=(ann=%0d,comm=%0d,prune=%0d,fp=%0d,gated=%0d) soc=(pc=%0d,r3=%0d,r6=%0d,r7=%0d,dmem1=%0d,C=[[%0d,%0d],[%0d,%0d]])", it_ann, it_comm, it_prune, it_fp, it_gated, pc_out, r3_out, r6_out, r7_out, dmem1_out, c00_out, c01_out, c10_out, c11_out);
    $finish;
  end
endmodule
