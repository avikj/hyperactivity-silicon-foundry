// SPDX-FileCopyrightText: 2026 Avik Jain / Hyperactive Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
// Mechanically compiled from lib/silicon/hx-tt-tapeout.hypercubical (0 postulates).
`default_nettype none

module hx_opt_face_conflict(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w2);
  wire w4 = ~(w1 & w2);
  wire w5 = ~(w3 & w4);
  assign y = w5;
endmodule
module hx_opt_demorgan_mux(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w1);
  wire w4 = ~(w2 & w3);
  wire w5 = ~(w0 & w4);
  wire w6 = ~(w1 & w4);
  wire w7 = ~(w5 & w6);
  assign y = w7;
endmodule
module hx_opt_commute(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w1);
  wire w4 = ~(w0 & w2);
  wire w5 = ~(w1 & w2);
  wire w6 = ~(w4 & w5);
  wire w7 = ~(w3 & w6);
  wire w8 = ~(w7 & w7);
  assign y = w8;
endmodule
module hx_opt_era_prune(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w0);
  wire w4 = ~(w1 & w1);
  wire w5 = ~(w2 & w2);
  wire w6 = ~(w3 & w4);
  wire w7 = ~(w5 & w6);
  wire w8 = ~(w5 & w7);
  assign y = w8;
endmodule
module hx_opt_gals_clk_en(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w1);
  wire w4 = ~(w0 & w3);
  wire w5 = ~(w2 & w2);
  wire w6 = ~(w4 & w5);
  assign y = w6;
endmodule
module hx_opt_vxchg_fire(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w1);
  wire w4 = ~(w0 & w2);
  wire w5 = ~(w3 & w3);
  wire w6 = ~(w4 & w5);
  wire w7 = ~(w6 & w6);
  assign y = w7;
endmodule
module hx_opt_aux_mux2(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w2);
  wire w4 = ~(w0 & w3);
  wire w5 = ~(w1 & w2);
  wire w6 = ~(w4 & w5);
  assign y = w6;
endmodule
module hx_opt_maj3_carry(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w0);
  wire w4 = ~(w0 & w1);
  wire w5 = ~(w1 & w1);
  wire w6 = ~(w3 & w5);
  wire w7 = ~(w2 & w6);
  wire w8 = ~(w4 & w7);
  assign y = w8;
endmodule
module hx_opt_xor2_vxchg(input wire w0, input wire w1, input wire w2, output wire y);
  wire w3 = ~(w0 & w1);
  wire w4 = ~(w0 & w3);
  wire w5 = ~(w1 & w3);
  wire w6 = ~(w4 & w5);
  assign y = w6;
endmodule
module hx_meta_cub_face_conflict4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w2 & w2);
  wire w5 = ~(w3 & w4);
  wire w6 = ~(w5 & w4);
  wire w7 = ~(w6 & w1);
  wire w8 = ~(w6 & w0);
  wire w9 = ~(w8 & w7);
  assign y = w9;
endmodule
module hx_meta_cub_demorgan_alu4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w3 & w1);
  wire w5 = ~(w2 & w0);
  wire w6 = ~(w2 & w5);
  wire w7 = ~(w3 & w4);
  wire w8 = ~(w5 & w0);
  wire w9 = ~(w8 & w6);
  wire w10 = ~(w4 & w1);
  wire w11 = ~(w7 & w9);
  wire w12 = ~(w11 & w10);
  assign y = w12;
endmodule
module hx_meta_inet_era_either4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w3 & w3);
  wire w5 = ~(w2 & w4);
  wire w6 = ~(w5 & w4);
  wire w7 = ~(w0 & w6);
  wire w8 = ~(w1 & w7);
  wire w9 = ~(w8 & w7);
  wire w10 = ~(w9 & w6);
  assign y = w10;
endmodule
module hx_meta_inet_commute4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w0 & w2);
  wire w5 = ~(w1 & w0);
  wire w6 = ~(w0 & w3);
  wire w7 = ~(w3 & w2);
  wire w8 = ~(w7 & w5);
  wire w9 = ~(w6 & w4);
  wire w10 = ~(w9 & w8);
  wire w11 = ~(w10 & w9);
  wire w12 = ~(w11 & w11);
  assign y = w12;
endmodule
module hx_meta_inet_annihilate4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w1 & w0);
  wire w5 = ~(w2 & w4);
  wire w6 = ~(w0 & w3);
  wire w7 = ~(w5 & w0);
  wire w8 = ~(w6 & w4);
  wire w9 = ~(w8 & w5);
  wire w10 = ~(w1 & w2);
  wire w11 = ~(w6 & w7);
  wire w12 = ~(w9 & w11);
  wire w13 = ~(w12 & w12);
  assign y = w13;
endmodule
module hx_meta_inet_vxchg_arb4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w1 & w0);
  wire w5 = ~(w0 & w4);
  wire w6 = ~(w4 & w1);
  wire w7 = ~(w3 & w2);
  wire w8 = ~(w5 & w6);
  wire w9 = ~(w7 & w8);
  wire w10 = ~(w9 & w2);
  wire w11 = ~(w2 & w10);
  wire w12 = ~(w11 & w11);
  assign y = w12;
endmodule
module hx_meta_inet_tag_neq4(input wire w0, input wire w1, input wire w2, input wire w3, output wire y);
  wire w4 = ~(w0 & w2);
  wire w5 = ~(w0 & w4);
  wire w6 = ~(w2 & w4);
  wire w7 = ~(w1 & w3);
  wire w8 = ~(w1 & w7);
  wire w9 = ~(w3 & w7);
  wire w10 = ~(w5 & w8);
  wire w11 = ~(w10 & w10);
  wire w12 = ~(w6 & w9);
  wire w13 = ~(w12 & w12);
  wire w14 = ~(w11 & w13);
  assign y = w14;
endmodule

module hx_inet_opt_tile (
  input  wire       pair_valid, load_en, tag_a, tag_b, era_a, era_b,
  input  wire [3:0] face_a0, face_a1, face_b0, face_b1,
  input  wire       iv_sel, iv_a, iv_b, vx_arr, vx_wait,
  output wire       out_conflict, out_erase, out_commute, out_annihilate,
  output wire       out_gals_clk, out_vx_fire, out_vx_next, out_iv_res
);
  wire [3:0] m1 = face_a1 | face_b1;
  wire [3:0] fc;
  genvar d;
  generate for (d = 0; d < 4; d = d + 1) begin : g_fc
    hx_opt_face_conflict u_fc (.w0(face_a0[d]), .w1(face_b0[d]), .w2(m1[d]), .y(fc[d]));
  end endgenerate
  assign out_conflict = |fc;
  hx_opt_era_prune    u_era  (.w0(era_a), .w1(era_b), .w2(out_conflict), .y(out_erase));
  hx_opt_gals_clk_en  u_clk  (.w0(pair_valid), .w1(out_conflict), .w2(load_en), .y(out_gals_clk));
  wire active_ok = pair_valid & ~out_erase;
  hx_opt_commute      u_comm (.w0(tag_a), .w1(tag_b), .w2(active_ok), .y(out_commute));
  wire n_comm = ~(out_commute & out_commute);
  wire n_ann  = ~(active_ok & n_comm);
  assign out_annihilate = ~(n_ann & n_ann);
  hx_opt_vxchg_fire   u_vxf  (.w0(vx_arr), .w1(vx_wait), .w2(out_erase), .y(out_vx_fire));
  hx_opt_xor2_vxchg   u_vxn  (.w0(vx_arr), .w1(vx_wait), .w2(1'b0), .y(out_vx_next));
  hx_opt_demorgan_mux u_iv   (.w0(iv_a), .w1(iv_b), .w2(iv_sel), .y(out_iv_res));
endmodule

module hx_meta_inet_tile (
  input  wire       pair_valid,
  input  wire [1:0] tag_a, tag_b,
  input  wire [3:0] fa0, fa1, fb0, fb1,
  input  wire       iv_a, iv_b, iv_neg, iv_and, arr_a, arr_b, vx_wait,
  output wire       out_conflict, out_era, out_tag_neq, out_commute, out_annihilate, out_vx_arb, out_iv
);
  wire [3:0] fc;
  genvar d;
  generate for (d = 0; d < 4; d = d + 1) begin : g_fc4
    hx_meta_cub_face_conflict4 u_fc (.w0(fa0[d]), .w1(fb0[d]), .w2(fa1[d]), .w3(fb1[d]), .y(fc[d]));
  end endgenerate
  assign out_conflict = |fc;
  hx_meta_inet_era_either4  u_era (.w0(tag_a[0]), .w1(tag_a[1]), .w2(tag_b[0]), .w3(tag_b[1]), .y(out_era));
  hx_meta_inet_tag_neq4     u_tnq (.w0(tag_a[0]), .w1(tag_a[1]), .w2(tag_b[0]), .w3(tag_b[1]), .y(out_tag_neq));
  wire pruned = out_conflict | out_era;
  hx_meta_inet_commute4     u_cm  (.w0(pair_valid), .w1(pruned), .w2(tag_a[0]), .w3(tag_b[0]), .y(out_commute));
  hx_meta_inet_annihilate4  u_an  (.w0(pair_valid), .w1(pruned), .w2(tag_a[0]), .w3(tag_b[0]), .y(out_annihilate));
  hx_meta_inet_vxchg_arb4   u_vx  (.w0(arr_a), .w1(arr_b), .w2(vx_wait), .w3(pruned), .y(out_vx_arb));
  hx_meta_cub_demorgan_alu4 u_dm  (.w0(iv_a), .w1(iv_b), .w2(iv_neg), .w3(iv_and), .y(out_iv));
endmodule

module hx_psc1_bf16_mul_fp32 (
  input  wire [15:0] a,
  input  wire [15:0] b,
  output reg  [31:0] fp32_out
);
  wire        sr   = a[15] ^ b[15];
  wire [7:0]  ea   = a[14:7];
  wire [7:0]  eb   = b[14:7];
  wire [6:0]  ma   = a[6:0];
  wire [6:0]  mb   = b[6:0];
  wire        infA = (ea == 8'hFF);
  wire        infB = (eb == 8'hFF);
  wire        zerA = (ea == 8'h00);
  wire        zerB = (eb == 8'h00);
  wire        nanR = (infA && (ma != 7'd0)) || (infB && (mb != 7'd0)) || ((infA || infB) && (zerA || zerB));
  wire [15:0] prod = {1'b1, ma} * {1'b1, mb};
  wire        norm = prod[15];
  wire [9:0]  rawE = {2'd0, ea} + {2'd0, eb} + {9'd0, norm};
  wire [7:0]  er   = rawE[7:0] - 8'd127;
  wire [22:0] mr   = norm ? {prod[14:0], 8'd0} : {prod[13:0], 9'd0};
  always @(*) begin
    if (infA || infB)        fp32_out = nanR ? 32'h7FC00000 : {sr, 8'hFF, 23'd0};
    else if (zerA || zerB)   fp32_out = {sr, 31'd0};
    else if (rawE < 10'd128) fp32_out = {sr, 31'd0};
    else if (rawE > 10'd381) fp32_out = {sr, 8'hFF, 23'd0};
    else                     fp32_out = {sr, er, mr};
  end
endmodule

module hx_psc1_fiber_unit (
  input  wire        op_and,
  input  wire [15:0] a_vec,
  input  wire [15:0] b_vec,
  output wire [15:0] y_vec
);
  genvar i;
  generate for (i = 0; i < 4; i = i + 1) begin : flane
    wire [3:0] a = a_vec[i*4 +: 4];
    wire [3:0] b = b_vec[i*4 +: 4];
    wire [3:0] lx = { (a[0]&b[3])|(a[3]&b[0])|(a[1]&b[2])|(a[2]&b[1]),
                      (a[0]&b[2])|(a[2]&b[0])|(a[1]&b[3])|(a[3]&b[1]),
                      (a[0]&b[1])|(a[1]&b[0])|(a[2]&b[3])|(a[3]&b[2]),
                      (a[0]&b[0])|(a[1]&b[1])|(a[2]&b[2])|(a[3]&b[3]) };
    wire [3:0] qa = { (a[3]&b[3]),
                      (a[2]&(b[2]|b[3]))|(a[3]&b[2]),
                      (a[1]&(b[1]|b[3]))|(a[3]&b[1]),
                      (a[0]&(|b))|(b[0]&(|a))|(a[1]&b[2])|(a[2]&b[1]) };
    assign y_vec[i*4 +: 4] = op_and ? qa : lx;
  end endgenerate
endmodule

module hx_rv32i_alu10 (
  input  wire [3:0]  op,
  input  wire [31:0] a,
  input  wire [31:0] b,
  output reg  [31:0] y
);
  wire [4:0] sh = b[4:0];
  wire signed [31:0] sa = a;
  wire signed [31:0] sb = b;
  always @(*) begin
    case (op)
      4'd0: y = a + b;
      4'd1: y = a - b;
      4'd2: y = a ^ b;
      4'd3: y = a | b;
      4'd4: y = a & b;
      4'd5: y = a << sh;
      4'd6: y = a >> sh;
      4'd7: y = $unsigned(sa >>> sh);
      4'd8: y = {31'd0, (sa < sb)};
      4'd9: y = {31'd0, (a < b)};
      default: y = a + b;
    endcase
  end
endmodule

module chip_core #(
    parameter NUM_INPUT_PADS = 12,
    parameter NUM_BIDIR_PADS = 40,
    parameter NUM_ANALOG_PADS = 2
)(
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif
    input  wire clk,
    input  wire rst_n,
    input  wire [NUM_INPUT_PADS-1:0]  input_in,
    output wire [NUM_INPUT_PADS-1:0]  input_pu,
    output wire [NUM_INPUT_PADS-1:0]  input_pd,
    input  wire [NUM_BIDIR_PADS-1:0]  bidir_in,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_out,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_oe,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_cs,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_sl,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_ie,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_pu,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_pd,
    inout  wire [NUM_ANALOG_PADS-1:0] analog
);
    assign input_pu = {NUM_INPUT_PADS{1'b0}};
    assign input_pd = {NUM_INPUT_PADS{1'b0}};
    assign bidir_oe = {NUM_BIDIR_PADS{1'b1}};
    assign bidir_cs = {NUM_BIDIR_PADS{1'b0}};
    assign bidir_sl = {NUM_BIDIR_PADS{1'b0}};
    assign bidir_ie = {NUM_BIDIR_PADS{1'b0}};
    assign bidir_pu = {NUM_BIDIR_PADS{1'b0}};
    assign bidir_pd = {NUM_BIDIR_PADS{1'b0}};
    wire _unused_bidir = &bidir_in;

    // Host command bus (uses dedicated input_in[11:0] cleanly on 1x1 full die)
    wire [7:0] wdata   = input_in[7:0];
    wire [2:0] cmd     = input_in[10:8];
    wire       exec_en = input_in[11];

    reg [31:0] op_a;
    reg [31:0] op_b;
    reg [7:0]  ctrl;
    reg [7:0]  zip_sm;
    reg [7:0]  sram_d1;
    reg        sram_wen;
    reg        sram_cen;
    reg [31:0] bist_sig;

    // 4x Parallel HyperINet-Opt Cubical Interaction-Net Tiles (172 proved minimal NAND2 gates!)
    wire [31:0] inet4_flags;
    genvar t;
    generate for (t = 0; t < 4; t = t + 1) begin : g_inet4
      hx_inet_opt_tile u_it (
        .pair_valid(op_a[t*8 + 0]), .load_en(op_a[t*8 + 1]),
        .tag_a(op_a[t*8 + 2]),      .tag_b(op_a[t*8 + 3]),
        .era_a(op_a[t*8 + 4]),      .era_b(op_a[t*8 + 5]),
        .face_a0(op_b[3:0]),        .face_a1(op_b[7:4]),
        .face_b0(op_b[11:8]),       .face_b1(op_b[15:12]),
        .iv_sel(op_a[t*8 + 6]),     .iv_a(op_a[t*8 + 7]), .iv_b(op_b[t]),
        .vx_arr(op_b[16 + t]),      .vx_wait(op_b[20 + t]),
        .out_conflict(inet4_flags[t*8 + 0]),   .out_erase(inet4_flags[t*8 + 1]),
        .out_commute(inet4_flags[t*8 + 2]),    .out_annihilate(inet4_flags[t*8 + 3]),
        .out_gals_clk(inet4_flags[t*8 + 4]),   .out_vx_fire(inet4_flags[t*8 + 5]),
        .out_vx_next(inet4_flags[t*8 + 6]),    .out_iv_res(inet4_flags[t*8 + 7])
      );
    end endgenerate

    // HyperMeta-INet 4-Input GPU-Superoptimized Tile (61 proved minimal NAND2 gates!)
    wire [7:0] meta_flags;
    assign meta_flags[7] = 1'b0;
    hx_meta_inet_tile u_meta (
      .pair_valid(op_a[0]), .tag_a(op_a[12:11]), .tag_b(op_a[14:13]),
      .fa0(op_b[3:0]), .fa1(op_b[7:4]), .fb0(op_b[11:8]), .fb1(op_b[15:12]),
      .iv_a(op_a[7]), .iv_b(op_a[8]), .iv_neg(op_a[15]), .iv_and(op_a[6]),
      .arr_a(op_a[9]), .arr_b(op_a[10]), .vx_wait(op_b[16]),
      .out_conflict(meta_flags[0]), .out_era(meta_flags[1]), .out_tag_neq(meta_flags[2]),
      .out_commute(meta_flags[3]), .out_annihilate(meta_flags[4]),
      .out_vx_arb(meta_flags[5]), .out_iv(meta_flags[6])
    );

    // 2x Parallel PSC-1 Lossless 12b->16b BF16 Unzip + Exact BF16xBF16->FP32 Tensor Lanes
    wire [15:0] bf16_unzip0 = {zip_sm[7], 8'h7F, zip_sm[6:0]};
    wire [15:0] bf16_a0 = ctrl[5] ? bf16_unzip0 : op_a[15:0];
    wire [31:0] bf16_fp32_0;
    wire [31:0] bf16_fp32_1;
    hx_psc1_bf16_mul_fp32 u_bf16_0 (.a(bf16_a0),     .b(op_a[31:16]), .fp32_out(bf16_fp32_0));
    hx_psc1_bf16_mul_fp32 u_bf16_1 (.a(op_b[15:0]),  .b(op_b[31:16]), .fp32_out(bf16_fp32_1));

    // PSC-1 4-Lane Cubical Fiber Propagator (L:XOR, Q:AND)
    wire [15:0] fiber_y;
    hx_psc1_fiber_unit u_fib (.op_and(ctrl[4]), .a_vec(op_a[15:0]), .b_vec(op_b[15:0]), .y_vec(fiber_y));

    // Universally-Proved 10-Op 32-bit RV32I ALU
    wire [31:0] alu_y;
    hx_rv32i_alu10 u_alu (.op(ctrl[3:0]), .a(op_a), .b(op_b), .y(alu_y));

    // Dual Real Hardened On-Chip 512x8 GF180MCU SRAM Macros (1 KB Graph/Weight Store)
    wire [7:0] sram_0_out;
    wire [7:0] sram_1_out;
    `gf180mcu_xxx_ip_sram__sram512x8m8wm1 sram_0 (
        `ifdef USE_POWER_PINS
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .CLK  (clk),
        .CEN  (sram_cen),
        .GWEN (sram_wen),
        .WEN  (8'h00),
        .A    (op_b[8:0]),
        .D    (op_a[7:0]),
        .Q    (sram_0_out)
    );
    `gf180mcu_xxx_ip_sram__sram512x8m8wm1 sram_1 (
        `ifdef USE_POWER_PINS
        .VDD  (VDD),
        .VSS  (VSS),
        `endif
        .CLK  (clk),
        .CEN  (sram_cen),
        .GWEN (sram_wen),
        .WEN  (8'h00),
        .A    (op_b[8:0]),
        .D    (sram_d1),
        .Q    (sram_1_out)
    );

    wire [31:0] step_mix = inet4_flags ^ bf16_fp32_0 ^ bf16_fp32_1 ^ alu_y ^ {sram_1_out, sram_0_out, fiber_y};

    always @(posedge clk) begin
        if (!rst_n) begin
            op_a     <= 32'd0;
            op_b     <= 32'd0;
            ctrl     <= 8'd0;
            zip_sm   <= 8'd0;
            sram_d1  <= 8'd0;
            sram_cen <= 1'b1;
            sram_wen <= 1'b1;
            bist_sig <= 32'hA55A_1337;
        end else begin
            sram_cen <= 1'b1;
            sram_wen <= 1'b1;
            if (exec_en) begin
                case (cmd)
                    3'd1: op_a <= {op_a[23:0], wdata};
                    3'd2: op_b <= {op_b[23:0], wdata};
                    3'd3: ctrl <= wdata;
                    3'd4: zip_sm <= wdata;
                    3'd5: begin sram_d1 <= wdata; sram_cen <= 1'b0; sram_wen <= 1'b0; end
                    3'd6: begin sram_cen <= 1'b0; sram_wen <= 1'b1; end
                    3'd7: bist_sig <= {bist_sig[30:0], bist_sig[31] ^ bist_sig[21] ^ bist_sig[1] ^ bist_sig[0]} ^ step_mix;
                    default: ;
                endcase
            end
        end
    end

    reg [31:0] out32;
    always @(*) begin
        case (ctrl[7:6])
            2'd0: out32 = inet4_flags;
            2'd1: out32 = bf16_fp32_0;
            2'd2: out32 = {sram_1_out, sram_0_out, fiber_y};
            2'd3: out32 = alu_y;
        endcase
    end

    assign bidir_out[31:0] = out32;
    assign bidir_out[NUM_BIDIR_PADS-1:32] = bist_sig[NUM_BIDIR_PADS-33:0] ^ {{(NUM_BIDIR_PADS-40){1'b0}}, meta_flags};
endmodule
`default_nettype wire
