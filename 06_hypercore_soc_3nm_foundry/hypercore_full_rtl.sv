`timescale 1ns/1ps
module alu_sum_rtl (input logic a, input logic b, output logic y);
  assign y = (~(~((1'b0 | a) ^ b)));
endmodule

module xor4_shared_net (input logic a, input logic b, output logic y);
  wire w0;
  assign w0 = ~(a & b);
  wire w1;
  assign w1 = ~(a & w0);
  wire w2;
  assign w2 = ~(w0 & b);
  assign y = ~(w1 & w2);
endmodule

module hypercore_rom (input logic [7:0] pc, output logic [31:0] inst);
  always_comb begin
    case (pc)
      8'h00: inst = 32'h10612000;
      8'h01: inst = 32'h11762000;
      8'h02: inst = 32'h30570000;
      8'h03: inst = 32'h20350000;
      8'h04: inst = 32'h30470000;
      8'h05: inst = 32'h40100007;
      8'h06: inst = 32'h00000000;
      8'h07: inst = 32'h12676000;
      8'h08: inst = 32'h30460000;
      8'h09: inst = 32'h00000000;
      default: inst = 32'h00000000;
    endcase
  end
endmodule

module systolic_mac_2x2 (
  input  logic        clk, rst, kick,
  input  logic [15:0] a0, a1, b0, b1,
  output logic [31:0] c00, c01, c10, c11
);
  always_ff @(posedge clk) begin
    if (rst) begin
      c00 <= 32'd0; c01 <= 32'd0; c10 <= 32'd0; c11 <= 32'd0;
    end else if (kick) begin
      c00 <= c00 + (a0 * b0);
      c01 <= c01 + (a0 * b1);
      c10 <= c10 + (a1 * b0);
      c11 <= c11 + (a1 * b1);
    end
  end
endmodule

module hypercore_soc (
  input  logic        clk, rst,
  output logic [7:0]  pc_out,
  output logic        if_valid_out,
  output logic [15:0] r3_out, r6_out, r7_out, dmem1_out,
  output logic [31:0] c00_out, c01_out, c10_out, c11_out
);
  logic [7:0]  pc, if_pc;
  logic        if_valid;
  logic [31:0] if_inst;
  logic [15:0] rf [0:7];
  logic [15:0] dmem [0:15];
  logic [7:0]  fetch_pc;
  logic [31:0] rom_inst;
  hypercore_rom u_rom (.pc(fetch_pc), .inst(rom_inst));
  logic [3:0]  op, alu_op, f_rd, f_rs1, f_rs2;
  logic [7:0]  target_pc;
  assign op        = if_inst[31:28];
  assign alu_op    = if_inst[27:24];
  assign f_rd      = if_inst[23:20];
  assign f_rs1     = if_inst[19:16];
  assign f_rs2     = if_inst[15:12];
  assign target_pc = if_inst[7:0];
  logic [15:0] v_rs1, v_rs2, v_rd_addr, alu_res;
  assign v_rs1     = rf[f_rs1[2:0]];
  assign v_rs2     = rf[f_rs2[2:0]];
  assign v_rd_addr = rf[f_rd[2:0]];
  always_comb begin
    case (alu_op)
      4'd0: alu_res = v_rs1 + v_rs2;
      4'd1: alu_res = v_rs1 * v_rs2;
      4'd2: alu_res = (v_rs1 >= v_rs2) ? v_rs1 : v_rs2;
      default: alu_res = (v_rs1 <= v_rs2) ? v_rs1 : v_rs2;
    endcase
  end
  logic [7:0] next_pc, spec_next_pc;
  logic       branch_taken, is_store, is_mmio, tensor_kick;
  assign branch_taken = if_valid && (op == 4'd4) && (v_rd_addr != 16'd0);
  assign next_pc      = branch_taken ? target_pc : (pc + 8'd1);
  assign spec_next_pc = if_pc + 8'd1;
  assign fetch_pc     = if_valid ? spec_next_pc : pc;
  assign is_store     = if_valid && (op == 4'd3);
  assign is_mmio      = (v_rd_addr >= 16'd16);
  assign tensor_kick  = is_store && is_mmio;
  systolic_mac_2x2 u_tensor (
    .clk(clk), .rst(rst), .kick(tensor_kick),
    .a0(rf[1]), .a1(rf[2]), .b0(rf[6]), .b1(rf[7]),
    .c00(c00_out), .c01(c01_out), .c10(c10_out), .c11(c11_out)
  );
  integer i;
  always_ff @(posedge clk) begin
    if (rst) begin
      pc <= 8'd0; if_valid <= 1'b0; if_pc <= 8'd0; if_inst <= 32'd0;
      for (i = 0; i < 8; i = i + 1) rf[i] <= 16'd0;
      for (i = 0; i < 16; i = i + 1) dmem[i] <= 16'd0;
      rf[1] <= 16'd2; rf[2] <= 16'd3; rf[4] <= 16'd16; rf[5] <= 16'd1;
    end else if (!if_valid) begin
      if_valid <= 1'b1; if_pc <= pc; if_inst <= rom_inst;
    end else begin
      pc <= next_pc;
      if (op == 4'd1) rf[f_rd[2:0]] <= alu_res;
      else if (op == 4'd2) rf[f_rd[2:0]] <= dmem[v_rs1[3:0]];
      else if (op == 4'd3 && !is_mmio) dmem[v_rd_addr[3:0]] <= v_rs1;
      if (next_pc == spec_next_pc) begin
        if_valid <= 1'b1; if_pc <= spec_next_pc; if_inst <= rom_inst;
      end else begin
        if_valid <= 1'b0; if_pc <= 8'd0; if_inst <= 32'd0;
      end
    end
  end
  assign pc_out       = pc;
  assign if_valid_out = if_valid;
  assign r3_out       = rf[3];
  assign r6_out       = rf[6];
  assign r7_out       = rf[7];
  assign dmem1_out    = dmem[1];
endmodule

// [8, 4, 4] Extended Hamming SECDED Cosmic-Ray Self-Healing Codec (lib/silicon/ecc.hypercubical)
module hypercore_secded84 (
  input  logic [3:0] msg_in,
  input  logic [7:0] err_mask,
  output logic [7:0] code_out,
  output logic [3:0] healed_msg,
  output logic       single_err_healed,
  output logic       double_err_detected
);
  logic d0, d1, d2, d3, p0, p1, p2, p_all;
  assign d0    = msg_in[0];
  assign d1    = msg_in[1];
  assign d2    = msg_in[2];
  assign d3    = msg_in[3];
  assign p0    = d0 ^ d1 ^ d3;
  assign p1    = d0 ^ d2 ^ d3;
  assign p2    = d1 ^ d2 ^ d3;
  assign p_all = p0 ^ p1 ^ d0 ^ p2 ^ d1 ^ d2 ^ d3;
  assign code_out = {d3, d2, d1, p2, d0, p1, p0, p_all};
  logic [7:0] rx, corr_mask, corr;
  logic       s0, s1, s2, sp;
  logic [2:0] syn;
  assign rx        = code_out ^ err_mask;
  assign s0        = rx[1] ^ rx[3] ^ rx[5] ^ rx[7];
  assign s1        = rx[2] ^ rx[3] ^ rx[6] ^ rx[7];
  assign s2        = rx[4] ^ rx[5] ^ rx[6] ^ rx[7];
  assign sp        = ^rx;
  assign syn       = {s2, s1, s0};
  assign corr_mask = (!sp) ? 8'd0 : (8'd1 << syn);
  assign corr      = rx ^ corr_mask;
  assign healed_msg          = {corr[7], corr[6], corr[5], corr[3]};
  assign single_err_healed   = sp;
  assign double_err_detected = (!sp) & (|syn);
endmodule

// O(1)-Depth Section 4.5 Cubical Face Clause Meet & Conflict Unit (lib/silicon/inet.hypercubical)
module hypercore_dnf_unit (
  input  logic [3:0] pos_a,
  input  logic [3:0] neg_a,
  input  logic [3:0] pos_b,
  input  logic [3:0] neg_b,
  output logic [3:0] pos_out,
  output logic [3:0] neg_out,
  output logic       conflict
);
  assign pos_out  = pos_a | pos_b;
  assign neg_out  = neg_a | neg_b;
  assign conflict = |(pos_out & neg_out);
endmodule

// Section 4.5 GALS Cubical Interaction-Net Silicon Tile (lib/silicon/inet.hypercubical + export.hypercubical)
module hypercore_inet_tile (
  input  logic        clk, rst, pair_valid,
  input  logic        op_a, op_b,
  input  logic [3:0]  tag_a, tag_b,
  input  logic [3:0]  pos_a, neg_a, pos_b, neg_b,
  output logic        clk_en_out, face_conflict_out,
  output logic [15:0] ann_count, comm_count, prune_count, free_ptr, gated_cycles
);
  logic [3:0] pos_m, neg_m;
  logic       conflict;
  hypercore_dnf_unit u_dnf (
    .pos_a(pos_a), .neg_a(neg_a), .pos_b(pos_b), .neg_b(neg_b),
    .pos_out(pos_m), .neg_out(neg_m), .conflict(conflict)
  );
  assign clk_en_out        = pair_valid;
  assign face_conflict_out = conflict;
  always_ff @(posedge clk) begin
    if (rst) begin
      ann_count <= 16'd0; comm_count <= 16'd0; prune_count <= 16'd0;
      free_ptr  <= 16'd0; gated_cycles <= 16'd0;
    end else if (!pair_valid) begin
      gated_cycles <= gated_cycles + 16'd1;
    end else if (conflict) begin
      prune_count <= prune_count + 16'd1;
    end else if ((op_a == op_b) && (tag_a == tag_b)) begin
      ann_count <= ann_count + 16'd1;
    end else begin
      comm_count <= comm_count + 16'd1;
      free_ptr   <= free_ptr + 16'd4;
    end
  end
endmodule

