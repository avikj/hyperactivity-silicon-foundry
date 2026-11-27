`timescale 1ns/1ps
module hypernet_tile #(parameter [4:0] BASE_CID = 5'd0, parameter IS_BOOT = 0) (
  input  logic        clk, rst, start, active, quiescent,
  input  logic [1:0]  prog_sel,
  input  logic        steal_grant, stolen_by_succ,
  input  logic [47:0] steal_in_flit,
  output logic        can_offer, want_steal,
  output logic [47:0] offer_flit,
  input  logic        rx_redex_valid, rx_retire_valid,
  input  logic [47:0] rx_redex_flit,
  input  logic [4:0]  rx_retire_cid,
  output logic        tx_valid, set_wire_valid,
  output logic [3:0]  tx_dst, set_wire_id, set_wire_par,
  output logic [15:0] tx_val,
  output logic [4:0]  tx_cid,
  output logic [3:0]  free_sp_out,
  output logic [15:0] steps_out, pruned_out, allocs_out, gated_out
);
  logic [47:0] dq [0:5];
  logic [2:0]  dq_len;
  logic [4:0]  free_stk [0:11];
  logic [3:0]  free_sp;
  assign can_offer   = (dq_len >= 3'd2);
  assign offer_flit  = dq[0];
  assign want_steal  = (dq_len == 3'd0) && !rx_redex_valid;
  assign free_sp_out = free_sp;
  wire [2:0]  top_idx = (dq_len == 3'd0) ? 3'd0 : (dq_len - 3'd1);
  wire [47:0] cur     = dq[top_idx];
  wire [2:0]  rk      = cur[47:45];
  wire        is_mul  = cur[44];
  wire [4:0]  cid     = cur[43:39];
  wire [3:0]  dst     = cur[38:35];
  wire [1:0]  pa = cur[34:33], na = cur[32:31], pb = cur[30:29], nb = cur[28:27];
  wire [3:0]  nid     = cur[26:23];
  wire [1:0]  dep     = cur[22:21];
  wire [10:0] ahi     = cur[20:10];
  wire [9:0]  alo     = cur[9:0];
  wire        conf    = |((pa | pb) & (na | nb));
  wire        has_cur = active && !quiescent && (dq_len != 3'd0);
  wire        do_pop  = has_cur && !conf && (rk == 3'd3 || rk == 3'd4);
  wire [4:0]  ncid    = rx_retire_valid ? rx_retire_cid : free_stk[free_sp - 4'd1];
  wire [15:0] op_res  = is_mul ? ({6'd0, alo} * {5'd0, ahi}) : ({6'd0, alo} + {5'd0, ahi});
  wire [9:0]  hstep   = (dep == 2'd3) ? 10'd4 : 10'd2;
  wire [47:0] dup_c0  = {3'd1, 1'b0, cid,  dst, 8'h00, 4'd0, 2'd0, 11'd0, alo};
  wire [47:0] dup_c1  = {3'd1, 1'b0, ncid, dst, 8'h00, 4'd0, 2'd0, 11'd0, alo};
  wire [47:0] leaf_c0 = {3'd1, 1'b0, cid,  nid, 8'h00, 4'd0, 2'd0, 11'd0, alo};
  wire [47:0] leaf_c1 = {3'd1, 1'b0, ncid, nid, 8'h00, 4'd0, 2'd0, 11'd0, alo + 10'd1};
  wire [47:0] fork_c0 = {3'd4, 1'b0, cid,  nid, 8'h00, (nid * 4'd2) + 4'd1, dep - 2'd1, 11'd0, alo};
  wire [47:0] fork_c1 = {3'd4, 1'b0, ncid, nid, 8'h00, (nid * 4'd2) + 4'd2, dep - 2'd1, 11'd0, alo + hstep};
  wire [47:0] sp_c0   = (rk == 3'd3) ? dup_c0 : ((dep == 2'd1) ? leaf_c0 : fork_c0);
  wire [47:0] sp_c1   = (rk == 3'd3) ? dup_c1 : ((dep == 2'd1) ? leaf_c1 : fork_c1);
  wire [2:0]  rem     = stolen_by_succ ? (dq_len - 3'd2) : (dq_len - 3'd1);
  integer j;
  always_ff @(posedge clk) begin
    if (rst || start) begin
      tx_valid <= 1'b0; set_wire_valid <= 1'b0; tx_dst <= 4'd0; tx_val <= 16'd0; tx_cid <= 5'd0;
      set_wire_id <= 4'd0; set_wire_par <= 4'd0;
      steps_out <= 16'd0; pruned_out <= 16'd0; gated_out <= 16'd0;
      for (j = 0; j < 6; j = j + 1) dq[j] <= 48'd0;
      for (j = 0; j < 12; j = j + 1) free_stk[j] <= (j < 8) ? (BASE_CID + j[4:0]) : 5'd0;
      if (start && IS_BOOT != 0) begin
        if (prog_sel == 2'd0) begin
          free_sp <= 4'd7; allocs_out <= 16'd1; dq_len <= 3'd1;
          dq[0] <= {3'd4, 1'b0, BASE_CID + 5'd7, 4'd15, 8'h00, 4'd0, 2'd3, 11'd0, 10'd1};
        end else if (prog_sel == 2'd1) begin
          free_sp <= 4'd7; allocs_out <= 16'd1; dq_len <= 3'd1;
          dq[0] <= {3'd2, 1'b0, BASE_CID + 5'd7, 4'd8, 8'h00, 4'd0, 2'd0, 11'd3, 10'd3};
        end else begin
          free_sp <= 4'd6; allocs_out <= 16'd2; dq_len <= 3'd2;
          dq[0] <= {3'd4, 1'b0, BASE_CID + 5'd7, 4'd7, 8'b01_00_00_00, 4'd0, 2'd3, 11'd0, 10'd1};
          dq[1] <= {3'd4, 1'b0, BASE_CID + 5'd6, 4'd7, 8'b01_00_00_01, 4'd0, 2'd3, 11'd0, 10'd100};
        end
      end else begin
        free_sp <= 4'd8; allocs_out <= 16'd0; dq_len <= 3'd0;
      end
    end else if (active && !quiescent) begin
      if (do_pop && !rx_retire_valid) free_sp <= free_sp - 4'd1;
      else if (!do_pop && rx_retire_valid) begin
        free_stk[free_sp] <= rx_retire_cid; free_sp <= free_sp + 4'd1;
      end
      if (dq_len == 3'd0) begin
        tx_valid <= 1'b0; set_wire_valid <= 1'b0;
        if (rx_redex_valid) begin dq[0] <= rx_redex_flit; dq_len <= 3'd1; end
        else if (steal_grant) begin dq[0] <= steal_in_flit; dq_len <= 3'd1; end
        else gated_out <= gated_out + 16'd1;
      end else begin
        steps_out <= steps_out + 16'd1;
        if (stolen_by_succ) begin
          dq[0] <= dq[1]; dq[1] <= dq[2]; dq[2] <= dq[3]; dq[3] <= dq[4];
        end
        if (conf) begin
          pruned_out <= pruned_out + 16'd1; set_wire_valid <= 1'b0;
          tx_valid <= 1'b1; tx_dst <= dst; tx_val <= 16'd0; tx_cid <= cid;
          if (rx_redex_valid) begin dq[rem] <= rx_redex_flit; dq_len <= rem + 3'd1; end
          else dq_len <= rem;
        end else if (rk == 3'd1 || rk == 3'd2) begin
          set_wire_valid <= 1'b0;
          tx_valid <= 1'b1; tx_dst <= dst; tx_val <= (rk == 3'd1) ? {6'd0, alo} : op_res; tx_cid <= cid;
          if (rx_redex_valid) begin dq[rem] <= rx_redex_flit; dq_len <= rem + 3'd1; end
          else dq_len <= rem;
        end else begin
          tx_valid <= 1'b0; allocs_out <= allocs_out + 16'd1;
          set_wire_valid <= (rk == 3'd4); set_wire_id <= nid; set_wire_par <= dst;
          dq[rem] <= sp_c0; dq[rem + 3'd1] <= sp_c1;
          if (rx_redex_valid) begin dq[rem + 3'd2] <= rx_redex_flit; dq_len <= rem + 3'd3; end
          else dq_len <= rem + 3'd2;
        end
      end
    end
  end
endmodule

module hypernet_mesh_4tile (
  input  logic        clk, rst, start,
  input  logic [1:0]  prog_sel,
  output logic        quiescent,
  output logic [31:0] root_result,
  output logic [15:0] total_steps, stolen_count, pruned_count, alloc_count, gated_tile_cycles,
  output logic [7:0]  total_free_cells
);
  logic        active;
  logic [3:0]  offer, want, sgrant, sby;
  logic [47:0] oflit [0:3], sflit [0:3], rx_flit [0:3];
  logic [3:0]  rx_rv, rx_retv, tx_v, sw_v;
  logic [4:0]  rx_retc [0:3], tx_c [0:3];
  logic [3:0]  tx_d [0:3], sw_id [0:3], sw_par [0:3], fsp [0:3];
  logic [15:0] tx_val [0:3], stp [0:3], prn [0:3], alc [0:3], gat [0:3];
  assign sgrant[1] = offer[0] & want[1]; assign sflit[1] = oflit[0]; assign sby[0] = sgrant[1];
  assign sgrant[2] = offer[1] & want[2]; assign sflit[2] = oflit[1]; assign sby[1] = sgrant[2];
  assign sgrant[3] = offer[2] & want[3]; assign sflit[3] = oflit[2]; assign sby[2] = sgrant[3];
  assign sgrant[0] = offer[3] & want[0]; assign sflit[0] = oflit[3]; assign sby[3] = sgrant[0];
  hypernet_tile #(5'd0,  1) u_t0 (clk, rst, start, active, quiescent, prog_sel, sgrant[0], sby[0], sflit[0], offer[0], want[0], oflit[0], rx_rv[0], rx_retv[0], rx_flit[0], rx_retc[0], tx_v[0], sw_v[0], tx_d[0], sw_id[0], sw_par[0], tx_val[0], tx_c[0], fsp[0], stp[0], prn[0], alc[0], gat[0]);
  hypernet_tile #(5'd8,  0) u_t1 (clk, rst, start, active, quiescent, prog_sel, sgrant[1], sby[1], sflit[1], offer[1], want[1], oflit[1], rx_rv[1], rx_retv[1], rx_flit[1], rx_retc[1], tx_v[1], sw_v[1], tx_d[1], sw_id[1], sw_par[1], tx_val[1], tx_c[1], fsp[1], stp[1], prn[1], alc[1], gat[1]);
  hypernet_tile #(5'd16, 0) u_t2 (clk, rst, start, active, quiescent, prog_sel, sgrant[2], sby[2], sflit[2], offer[2], want[2], oflit[2], rx_rv[2], rx_retv[2], rx_flit[2], rx_retc[2], tx_v[2], sw_v[2], tx_d[2], sw_id[2], sw_par[2], tx_val[2], tx_c[2], fsp[2], stp[2], prn[2], alc[2], gat[2]);
  hypernet_tile #(5'd24, 0) u_t3 (clk, rst, start, active, quiescent, prog_sel, sgrant[3], sby[3], sflit[3], offer[3], want[3], oflit[3], rx_rv[3], rx_retv[3], rx_flit[3], rx_retc[3], tx_v[3], sw_v[3], tx_d[3], sw_id[3], sw_par[3], tx_val[3], tx_c[3], fsp[3], stp[3], prn[3], alc[3], gat[3]);
  logic        var_valid [0:9], var_op [0:9];
  logic [15:0] var_val   [0:9];
  logic [3:0]  var_par   [0:9];
  logic        v_ok_t    [0:9];
  logic [15:0] v_vl_t    [0:9];
  integer q, w;
  always_ff @(posedge clk) begin
    if (rst || start) begin
      active <= start; root_result <= 32'd0; stolen_count <= 16'd0;
      for (q = 0; q < 4; q = q + 1) begin rx_rv[q] <= 1'b0; rx_retv[q] <= 1'b0; rx_flit[q] <= 48'd0; rx_retc[q] <= 5'd0; end
      for (w = 0; w < 10; w = w + 1) begin var_valid[w] <= 1'b0; var_val[w] <= 16'd0; var_op[w] <= 1'b0; var_par[w] <= 4'd15; end
      if (start && prog_sel == 2'd1) begin var_op[1] <= 1'b0; var_par[1] <= 4'd9; var_op[2] <= 1'b1; var_par[2] <= 4'd15; end
      if (start && prog_sel == 2'd2) begin var_op[7] <= 1'b0; var_par[7] <= 4'd15; end
    end else if (active && !quiescent) begin
      stolen_count <= stolen_count + {15'd0, sgrant[0]} + {15'd0, sgrant[1]} + {15'd0, sgrant[2]} + {15'd0, sgrant[3]};
      for (q = 0; q < 4; q = q + 1) if (sw_v[q]) begin var_op[sw_id[q]] <= 1'b0; var_par[sw_id[q]] <= sw_par[q]; end
      for (w = 0; w < 10; w = w + 1) begin v_ok_t[w] = var_valid[w]; v_vl_t[w] = var_val[w]; end
      for (q = 0; q < 4; q = q + 1) begin
        rx_rv[q] <= 1'b0; rx_retv[q] <= 1'b0;
        if (tx_v[q]) begin
          if (tx_d[q] == 4'd15) begin
            root_result <= {16'd0, tx_val[q]}; rx_retv[q] <= 1'b1; rx_retc[q] <= tx_c[q];
          end else if (tx_d[q] == 4'd8 || tx_d[q] == 4'd9) begin
            rx_rv[q] <= 1'b1; rx_flit[q] <= {3'd3, 1'b0, tx_c[q], (tx_d[q] == 4'd8 ? 4'd1 : 4'd2), 8'h00, 4'd0, 2'd0, 11'd0, tx_val[q][9:0]};
          end else if (!v_ok_t[tx_d[q]]) begin
            v_ok_t[tx_d[q]] = 1'b1; v_vl_t[tx_d[q]] = tx_val[q]; rx_retv[q] <= 1'b1; rx_retc[q] <= tx_c[q];
          end else begin
            v_ok_t[tx_d[q]] = 1'b0; rx_rv[q] <= 1'b1;
            rx_flit[q] <= {3'd2, var_op[tx_d[q]], tx_c[q], var_par[tx_d[q]], 8'h00, 4'd0, 2'd0, tx_val[q][10:0], v_vl_t[tx_d[q]][9:0]};
          end
        end
      end
      for (w = 0; w < 10; w = w + 1) begin var_valid[w] <= v_ok_t[w]; var_val[w] <= v_vl_t[w]; end
    end
  end
  assign total_steps       = stp[0] + stp[1] + stp[2] + stp[3];
  assign pruned_count      = prn[0] + prn[1] + prn[2] + prn[3];
  assign alloc_count       = alc[0] + alc[1] + alc[2] + alc[3];
  assign gated_tile_cycles = gat[0] + gat[1] + gat[2] + gat[3];
  assign total_free_cells  = {4'd0, fsp[0]} + {4'd0, fsp[1]} + {4'd0, fsp[2]} + {4'd0, fsp[3]};
  assign quiescent         = active && (total_free_cells == 8'd32) && (tx_v == 4'd0) && (rx_rv == 4'd0) && (rx_retv == 4'd0);
endmodule

// 32-Bit 2-Stage RAW-Forwarding Pipelined RISC-V Benchmark Core (identical PDK comparison)
module riscv32_pipe (
  input  logic        clk, rst, start,
  input  logic [1:0]  prog_sel,
  output logic        halted,
  output logic [31:0] result_out,
  output logic [15:0] cycle_count, inst_retired
);
  // Instruction encoding: [31:28] op (0=NOP,1=ADDI,2=ADD,3=MUL,4=OR,5=AND,6=BNEZ,7=HALT),
  // [27:24] rd, [23:20] rs1, [19:16] rs2, [15:0] imm/target
  logic [7:0]  pc;
  logic        ex_valid, running;
  logic [31:0] ex_inst;
  logic [31:0] rf [0:15];
  logic [31:0] fetch_inst;
  always_comb begin
    case (pc)
      // Prog 0 (PC 0..10): sequential 8-leaf loop sum i=1..8 -> x3 = 36
      8'd0:  fetch_inst = {4'd1, 4'd1, 4'd0, 4'd0, 16'd1};  // x1 = 1
      8'd1:  fetch_inst = {4'd1, 4'd2, 4'd0, 4'd0, 16'd8};  // x2 = 8 (count)
      8'd2:  fetch_inst = {4'd1, 4'd3, 4'd0, 4'd0, 16'd0};  // x3 = 0 (acc)
      8'd3:  fetch_inst = {4'd2, 4'd3, 4'd3, 4'd1, 16'd0};  // loop: x3 = x3 + x1
      8'd4:  fetch_inst = {4'd1, 4'd1, 4'd1, 4'd0, 16'd1};  // x1 = x1 + 1
      8'd5:  fetch_inst = {4'd1, 4'd2, 4'd2, 4'd0, 16'hFFFF}; // x2 = x2 - 1
      8'd6:  fetch_inst = {4'd6, 4'd0, 4'd2, 4'd0, 16'd3};  // bnez x2 -> PC 3
      8'd7:  fetch_inst = {4'd7, 4'd0, 4'd3, 4'd0, 16'd0};  // halt(x3)
      // Prog 1 (PC 16..20): x1=3+3=6; x2=x1+x1=12; x3=x2*x2=144
      8'd16: fetch_inst = {4'd1, 4'd1, 4'd0, 4'd0, 16'd3};
      8'd17: fetch_inst = {4'd2, 4'd1, 4'd1, 4'd1, 16'd0};
      8'd18: fetch_inst = {4'd2, 4'd2, 4'd1, 4'd1, 16'd0};
      8'd19: fetch_inst = {4'd3, 4'd3, 4'd2, 4'd2, 16'd0};
      8'd20: fetch_inst = {4'd7, 4'd0, 4'd3, 4'd0, 16'd0};
      // Prog 2 (PC 32..46): software face-conflict check + live 8-leaf loop
      8'd32: fetch_inst = {4'd1, 4'd4, 4'd0, 4'd0, 16'd1};  // pa = 1
      8'd33: fetch_inst = {4'd1, 4'd5, 4'd0, 4'd0, 16'd1};  // nb = 1
      8'd34: fetch_inst = {4'd5, 4'd6, 4'd4, 4'd5, 16'd0};  // conf = pa & nb
      8'd35: fetch_inst = {4'd6, 4'd0, 4'd6, 4'd0, 16'd0};  // bnez conf -> skip dead tree to PC 0!
      default: fetch_inst = 32'd0;
    endcase
  end
  wire [3:0]  op  = ex_inst[31:28], rd = ex_inst[27:24], rs1 = ex_inst[23:20], rs2 = ex_inst[19:16];
  wire [31:0] imm = {{16{ex_inst[15]}}, ex_inst[15:0]};
  wire [31:0] v1  = (rs1 == 4'd0) ? 32'd0 : rf[rs1];
  wire [31:0] v2  = (rs2 == 4'd0) ? 32'd0 : rf[rs2];
  logic [31:0] alu_y;
  always_comb begin
    case (op)
      4'd1: alu_y = v1 + imm;
      4'd2: alu_y = v1 + v2;
      4'd3: alu_y = v1 * v2;
      4'd4: alu_y = v1 | v2;
      default: alu_y = v1 & v2;
    endcase
  end
  wire take_br = ex_valid && (op == 4'd6) && (v1 != 32'd0);
  integer k;
  always_ff @(posedge clk) begin
    if (rst) begin
      pc <= 8'd0; ex_valid <= 1'b0; ex_inst <= 32'd0; running <= 1'b0; halted <= 1'b0;
      result_out <= 32'd0; cycle_count <= 16'd0; inst_retired <= 16'd0;
      for (k = 0; k < 16; k = k + 1) rf[k] <= 32'd0;
    end else if (start) begin
      pc <= (prog_sel == 2'd0) ? 8'd0 : (prog_sel == 2'd1) ? 8'd16 : 8'd32;
      ex_valid <= 1'b0; ex_inst <= 32'd0; running <= 1'b1; halted <= 1'b0;
      result_out <= 32'd0; cycle_count <= 16'd0; inst_retired <= 16'd0;
      for (k = 0; k < 16; k = k + 1) rf[k] <= 32'd0;
    end else if (running && !halted) begin
      cycle_count <= cycle_count + 16'd1;
      if (ex_valid) begin
        inst_retired <= inst_retired + 16'd1;
        if (op >= 4'd1 && op <= 4'd5 && rd != 4'd0) rf[rd] <= alu_y;
        if (op == 4'd7) begin halted <= 1'b1; running <= 1'b0; result_out <= v1; end
      end
      if (take_br) begin
        pc <= ex_inst[7:0]; ex_valid <= 1'b0; ex_inst <= 32'd0;
      end else begin
        ex_valid <= 1'b1; ex_inst <= fetch_inst; pc <= pc + 8'd1;
      end
    end
  end
endmodule

