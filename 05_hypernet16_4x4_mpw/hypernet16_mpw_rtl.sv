`timescale 1ns/1ps
module hypernet16_tile #(parameter [3:0] TILE_ID = 4'd0) (
  input  logic        clk, rst, start, active, quiescent,
  input  logic [1:0]  prog_sel,
  input  logic        steal_grant, stolen_by_succ,
  input  logic [51:0] steal_in_flit,
  output logic        can_offer, want_steal,
  output logic [51:0] offer_flit,
  input  logic        net_tx_valid,
  input  logic [6:0]  net_tx_vid,
  input  logic [15:0] net_tx_val,
  input  logic [6:0]  net_tx_src_cid,
  input  logic        net_ret_valid,
  input  logic [6:0]  net_ret_cid,
  input  logic        tx_ack, ret_ack,
  output logic        out_tx_valid,
  output logic [3:0]  out_tx_home,
  output logic [6:0]  out_tx_vid,
  output logic [15:0] out_tx_val,
  output logic [6:0]  out_tx_cid,
  output logic        out_ret_valid,
  output logic [3:0]  out_ret_home,
  output logic [6:0]  out_ret_cid,
  output logic        root_hit,
  output logic [15:0] root_val,
  output logic [3:0]  free_cells_out,
  output logic [3:0]  free_vars_out,
  output logic        busy_out,
  output logic [15:0] steps_out, pruned_out, allocs_out, gated_out
);
  logic [51:0] dq [0:7];
  logic [3:0]  dq_len;
  logic [15:0] cell_sram [0:1];
  logic [6:0]  free_stk  [0:7];
  logic [3:0]  free_sp;
  logic        var_valid [0:7];
  logic        var_op    [0:7];
  logic [15:0] var_val   [0:7];
  logic [7:0]  var_par   [0:7];
  logic [2:0]  vfree_stk [0:7];
  logic [3:0]  vfree_sp;
  logic [51:0] rx_q [0:3];
  logic [2:0]  rx_q_len;
  wire tx_busy  = out_tx_valid  && !tx_ack;
  wire ret_busy = out_ret_valid && !ret_ack;
  assign can_offer      = (dq_len >= 4'd2);
  assign offer_flit     = dq[0];
  assign want_steal     = (dq_len == 4'd0) && (rx_q_len == 3'd0) && !net_tx_valid;
  assign free_cells_out = free_sp;
  assign free_vars_out  = vfree_sp;
  assign busy_out       = (dq_len != 4'd0) || (rx_q_len != 3'd0) || out_tx_valid || out_ret_valid || root_hit;
  wire [2:0]  top_idx = (dq_len == 4'd0) ? 3'd0 : (dq_len[2:0] - 3'd1);
  wire [51:0] cur     = dq[top_idx];
  wire [2:0]  rk      = cur[51:49];
  wire        is_mul  = cur[48];
  wire [6:0]  cid     = cur[47:41];
  wire [7:0]  dst     = cur[40:33];
  wire [1:0]  pa = cur[32:31], na = cur[30:29], pb = cur[28:27], nb = cur[26:25];
  wire        conf    = |((pa | pb) & (na | nb));
  wire [10:0] ahi     = cur[20:10];
  wire [9:0]  alo     = cur[9:0];
  wire [2:0]  t_dep   = cur[22:20];
  wire        cptr    = cur[20];
  wire [2:0]  nq_r    = cur[22:20];
  wire [4:0]  nq_cols = cur[19:15];
  wire [4:0]  nq_dl   = cur[14:10];
  wire [4:0]  nq_dr   = cur[9:5];
  wire [4:0]  nq_mask = cur[4:0];
  wire [4:0]  nq_avail = 5'b11111 & ~(nq_cols | nq_dl | nq_dr) & nq_mask;
  wire [4:0]  nq_lsb   = nq_avail & (~nq_avail + 5'd1);
  wire [4:0]  nq_rem_m = nq_avail ^ nq_lsb;
  wire        nq_zero  = (nq_avail == 5'd0);
  wire        nq_done  = !nq_zero && (nq_r == 3'd4);
  wire        nq_one   = !nq_zero && !nq_done && (nq_rem_m == 5'd0);
  wire        nq_fork  = !nq_zero && !nq_done && (nq_rem_m != 5'd0);
  wire        step_emits_tx = (dq_len != 4'd0) && (conf || rk == 3'd1 || rk == 3'd2 || rk == 3'd6 || (rk == 3'd5 && (nq_zero || nq_done)));
  wire        rx_emits_ret  = net_tx_valid && !var_valid[net_tx_vid[6:4]] && (net_tx_src_cid[3:0] != TILE_ID);
  wire        can_step_dq   = (dq_len != 4'd0) && !(step_emits_tx && ((!dst[7] && tx_busy) || (dst[7] && cid[3:0] != TILE_ID && (ret_busy || rx_emits_ret))))
                              && !((rk == 3'd3 || rk == 3'd4 || (rk == 3'd5 && nq_fork)) && !conf && ((free_sp == 4'd0 && !net_ret_valid) || vfree_sp == 4'd0 || dq_len >= 4'd7));
  wire        do_split    = active && !quiescent && can_step_dq && !conf && (rk == 3'd3 || rk == 3'd4 || (rk == 3'd5 && nq_fork));
  wire [6:0]  popped_cid  = net_ret_valid ? net_ret_cid : free_stk[free_sp - 4'd1];
  wire [2:0]  popped_vidx = vfree_stk[vfree_sp - 4'd1];
  wire [7:0]  minted_vid  = {1'b0, popped_vidx, TILE_ID};
  wire [15:0] cls_word = cell_sram[cptr];
  wire [15:0] cls_res  = cls_word[15] ? ({6'd0, alo} * {1'b0, cls_word[14:0]}) : ({6'd0, alo} + {1'b0, cls_word[14:0]});
  wire [15:0] alu_res  = is_mul ? ({6'd0, alo} * {5'd0, ahi}) : ({6'd0, alo} + {5'd0, ahi});
  wire [9:0]  t_step   = (t_dep == 3'd4) ? 10'd8 : ((t_dep == 3'd3) ? 10'd4 : 10'd2);
  wire [51:0] dup_c0  = {3'd6, 1'b0, cid,        minted_vid, 8'h00, 4'd0, cptr, 10'd0, alo};
  wire [51:0] dup_c1  = {3'd1, 1'b1, popped_cid, minted_vid, 8'h00, 15'd0, {9'd0, cptr}};
  wire [51:0] tl_c0   = {3'd1, 1'b0, cid,        minted_vid, 8'h00, 15'd0, alo};
  wire [51:0] tl_c1   = {3'd1, 1'b0, popped_cid, minted_vid, 8'h00, 15'd0, alo + 10'd1};
  wire [51:0] tf_c0   = {3'd4, 1'b0, cid,        minted_vid, 8'h00, 2'd0, t_dep - 3'd1, 10'd0, alo};
  wire [51:0] tf_c1   = {3'd4, 1'b0, popped_cid, minted_vid, 8'h00, 2'd0, t_dep - 3'd1, 10'd0, alo + t_step};
  wire [4:0]  nq_nc   = nq_cols | nq_lsb;
  wire [4:0]  nq_ndl  = (nq_dl | nq_lsb) << 1;
  wire [4:0]  nq_ndr  = (nq_dr | nq_lsb) >> 1;
  wire [51:0] nq_single_next = {3'd5, 1'b0, cid, dst, 8'h00, 2'd0, nq_r + 3'd1, nq_nc, nq_ndl, nq_ndr, 5'b11111};
  wire [51:0] nq_c0   = {3'd5, 1'b0, cid,        minted_vid, 8'h00, 2'd0, nq_r,        nq_cols, nq_dl,  nq_dr,  nq_rem_m};
  wire [51:0] nq_c1   = {3'd5, 1'b0, popped_cid, minted_vid, 8'h00, 2'd0, nq_r + 3'd1, nq_nc,   nq_ndl, nq_ndr, 5'b11111};
  wire [51:0] sp_c0   = (rk == 3'd3) ? dup_c0 : ((rk == 3'd5) ? nq_c0 : ((t_dep == 3'd1) ? tl_c0 : tf_c0));
  wire [51:0] sp_c1   = (rk == 3'd3) ? dup_c1 : ((rk == 3'd5) ? nq_c1 : ((t_dep == 3'd1) ? tl_c1 : tf_c1));
  wire [3:0]  rem     = stolen_by_succ ? (dq_len - 4'd2) : (dq_len - 4'd1);
  integer j;
  always_ff @(posedge clk) begin
    if (rst || start) begin
      out_tx_valid <= 1'b0; out_tx_home <= 4'd0; out_tx_vid <= 7'd0; out_tx_val <= 16'd0; out_tx_cid <= 7'd0;
      out_ret_valid <= 1'b0; out_ret_home <= 4'd0; out_ret_cid <= 7'd0;
      root_hit <= 1'b0; root_val <= 16'd0;
      steps_out <= 16'd0; pruned_out <= 16'd0; allocs_out <= 16'd0; gated_out <= 16'd0;
      rx_q_len <= 3'd0;
      for (j = 0; j < 4; j = j + 1) rx_q[j] <= 52'd0;
      cell_sram[0] <= {1'b1, 15'd2}; cell_sram[1] <= 16'd0;
      for (j = 0; j < 8; j = j + 1) begin
        dq[j] <= 52'd0;
        free_stk[j]  <= {j[2:0], TILE_ID};
        var_valid[j] <= 1'b0; var_op[j] <= 1'b0; var_val[j] <= 16'd0; var_par[j] <= 8'h80;
        vfree_stk[j] <= j[2:0];
      end
      vfree_sp <= 4'd8;
      if (start && TILE_ID == 4'd0) begin
        if (prog_sel == 2'd0) begin
          free_sp <= 4'd7; allocs_out <= 16'd1; dq_len <= 4'd1;
          dq[0] <= {3'd5, 1'b0, {3'd7, TILE_ID}, 8'h80, 8'h00, 2'd0, 3'd0, 5'd0, 5'd0, 5'd0, 5'b11111};
        end else if (prog_sel == 2'd1) begin
          free_sp <= 4'd7; allocs_out <= 16'd1; dq_len <= 4'd1;
          dq[0] <= {3'd3, 1'b0, {3'd7, TILE_ID}, 8'h80, 8'h00, 4'd0, 1'b0, 10'd0, 10'd3};
        end else if (prog_sel == 2'd2) begin
          free_sp <= 4'd7; allocs_out <= 16'd1; dq_len <= 4'd1;
          dq[0] <= {3'd4, 1'b0, {3'd7, TILE_ID}, 8'h80, 8'h00, 2'd0, 3'd4, 10'd0, 10'd1};
        end else begin
          free_sp <= 4'd6; allocs_out <= 16'd2; dq_len <= 4'd2; vfree_sp <= 4'd7;
          var_par[3'd7] <= 8'h80; var_op[3'd7] <= 1'b0;
          dq[0] <= {3'd5, 1'b0, {3'd7, TILE_ID}, {1'b0, 3'd7, TILE_ID}, 8'b01_00_00_00, 2'd0, 3'd0, 5'd0, 5'd0, 5'd0, 5'b11111};
          dq[1] <= {3'd5, 1'b0, {3'd6, TILE_ID}, {1'b0, 3'd7, TILE_ID}, 8'b01_00_00_01, 2'd0, 3'd0, 5'd0, 5'd0, 5'd0, 5'b11111};
        end
      end else begin
        free_sp <= 4'd8; dq_len <= 4'd0;
      end
    end else if (active && !quiescent) begin : step_blk
      reg [3:0]  nfsp, nvsp;
      reg [2:0]  nrx;
      reg        spawn_rx, pop_rx;
      reg [51:0] spawn_flit;
      if (tx_ack)  out_tx_valid  <= 1'b0;
      if (ret_ack) out_ret_valid <= 1'b0;
      root_hit <= 1'b0;
      nfsp = free_sp; nvsp = vfree_sp; nrx = rx_q_len;
      spawn_rx = 1'b0; spawn_flit = 52'd0;
      if (!do_split && net_ret_valid) begin
        free_stk[nfsp[2:0]] <= net_ret_cid; nfsp = nfsp + 4'd1;
      end else if (do_split && !net_ret_valid) begin
        nfsp = nfsp - 4'd1;
      end
      if (do_split) nvsp = nvsp - 4'd1;
      if (net_tx_valid) begin : vxchg_blk
        reg [2:0] vslot;
        vslot = net_tx_vid[6:4];
        if (!var_valid[vslot]) begin
          var_valid[vslot] <= 1'b1; var_val[vslot] <= net_tx_val;
          if (net_tx_src_cid[3:0] == TILE_ID) begin
            free_stk[nfsp[2:0]] <= net_tx_src_cid; nfsp = nfsp + 4'd1;
          end else begin
            out_ret_valid <= 1'b1; out_ret_home <= net_tx_src_cid[3:0]; out_ret_cid <= net_tx_src_cid;
          end
        end else begin
          var_valid[vslot] <= 1'b0;
          vfree_stk[nvsp[2:0]] <= vslot; nvsp = nvsp + 4'd1;
          spawn_rx = 1'b1;
          if (var_op[vslot]) begin : cls_chain
            reg [15:0] arg_v; reg cp_id;
            arg_v = net_tx_val[15] ? var_val[vslot] : net_tx_val;
            cp_id = net_tx_val[15] ? net_tx_val[0]   : var_val[vslot][0];
            spawn_flit = {3'd6, 1'b0, net_tx_src_cid, var_par[vslot], 8'h00, 4'd0, cp_id, 10'd0, arg_v[9:0]};
          end else begin
            spawn_flit = {3'd2, 1'b0, net_tx_src_cid, var_par[vslot], 8'h00, 4'd0, net_tx_val[10:0], var_val[vslot][9:0]};
          end
        end
      end
      pop_rx = (rx_q_len != 3'd0) && (dq_len <= 4'd5);
      if (dq_len == 4'd0) begin
        if (rx_q_len != 3'd0) begin
          dq[0] <= rx_q[0]; dq_len <= 4'd1;
          rx_q[0] <= rx_q[1]; rx_q[1] <= rx_q[2]; rx_q[2] <= rx_q[3];
          nrx = nrx - 3'd1;
        end else if (spawn_rx) begin
          dq[0] <= spawn_flit; dq_len <= 4'd1; spawn_rx = 1'b0;
        end else if (steal_grant) begin
          dq[0] <= steal_in_flit; dq_len <= 4'd1;
        end else begin
          gated_out <= gated_out + 16'd1;
        end
      end else if (!can_step_dq) begin
        if (stolen_by_succ) begin
          for (j = 0; j < 7; j = j + 1) dq[j] <= dq[j + 1];
          dq_len <= dq_len - 4'd1;
        end
      end else begin
        steps_out <= steps_out + 16'd1;
        if (stolen_by_succ) begin
          for (j = 0; j < 6; j = j + 1) dq[j] <= dq[j + 1];
        end
        if (conf) begin
          pruned_out <= pruned_out + 16'd1;
          if (dst[7]) begin
            root_hit <= 1'b1; root_val <= 16'd0;
            if (cid[3:0] == TILE_ID) begin free_stk[nfsp[2:0]] <= cid; nfsp = nfsp + 4'd1; end
            else begin out_ret_valid <= 1'b1; out_ret_home <= cid[3:0]; out_ret_cid <= cid; end
          end else begin
            out_tx_valid <= 1'b1; out_tx_home <= dst[3:0]; out_tx_vid <= dst[6:0]; out_tx_val <= 16'd0; out_tx_cid <= cid;
          end
          if (pop_rx) begin
            dq[rem[2:0]] <= rx_q[0]; dq_len <= rem + 4'd1;
            rx_q[0] <= rx_q[1]; rx_q[1] <= rx_q[2]; rx_q[2] <= rx_q[3]; nrx = nrx - 3'd1;
          end else dq_len <= rem;
        end else if (rk == 3'd1 || rk == 3'd2 || rk == 3'd6 || (rk == 3'd5 && (nq_zero || nq_done))) begin : emit_blk
          reg [15:0] res_v;
          if (rk == 3'd1)      res_v = {is_mul, 5'd0, alo};
          else if (rk == 3'd2) res_v = alu_res;
          else if (rk == 3'd6) res_v = cls_res;
          else                 res_v = nq_done ? 16'd1 : 16'd0;
          if (dst[7]) begin
            root_hit <= 1'b1; root_val <= res_v;
            if (cid[3:0] == TILE_ID) begin free_stk[nfsp[2:0]] <= cid; nfsp = nfsp + 4'd1; end
            else begin out_ret_valid <= 1'b1; out_ret_home <= cid[3:0]; out_ret_cid <= cid; end
          end else begin
            out_tx_valid <= 1'b1; out_tx_home <= dst[3:0]; out_tx_vid <= dst[6:0]; out_tx_val <= res_v; out_tx_cid <= cid;
          end
          if (pop_rx) begin
            dq[rem[2:0]] <= rx_q[0]; dq_len <= rem + 4'd1;
            rx_q[0] <= rx_q[1]; rx_q[1] <= rx_q[2]; rx_q[2] <= rx_q[3]; nrx = nrx - 3'd1;
          end else dq_len <= rem;
        end else if (rk == 3'd5 && nq_one) begin
          dq[rem[2:0]] <= nq_single_next;
          if (pop_rx) begin
            dq[rem[2:0] + 3'd1] <= rx_q[0]; dq_len <= rem + 4'd2;
            rx_q[0] <= rx_q[1]; rx_q[1] <= rx_q[2]; rx_q[2] <= rx_q[3]; nrx = nrx - 3'd1;
          end else dq_len <= rem + 4'd1;
        end else begin
          allocs_out <= allocs_out + 16'd1;
          var_valid[popped_vidx] <= 1'b0;
          var_op[popped_vidx]    <= (rk == 3'd3);
          var_par[popped_vidx]   <= dst;
          dq[rem[2:0]]           <= sp_c0;
          dq[rem[2:0] + 3'd1]    <= sp_c1;
          if (pop_rx) begin
            dq[rem[2:0] + 3'd2] <= rx_q[0]; dq_len <= rem + 4'd3;
            rx_q[0] <= rx_q[1]; rx_q[1] <= rx_q[2]; rx_q[2] <= rx_q[3]; nrx = nrx - 3'd1;
          end else dq_len <= rem + 4'd2;
        end
      end
      if (spawn_rx) begin
        rx_q[nrx[1:0]] <= spawn_flit; nrx = nrx + 3'd1;
      end
      free_sp <= nfsp; vfree_sp <= nvsp; rx_q_len <= nrx;
    end
  end
endmodule
module hypernet16_mesh_4x4 (
  input  logic        clk, rst, start,
  input  logic [1:0]  prog_sel,
  output logic        quiescent,
  output logic [31:0] root_result,
  output logic [15:0] total_steps, stolen_count, pruned_count, alloc_count, gated_tile_cycles,
  output logic [7:0]  total_free_cells,
  output logic [7:0]  total_free_vars,
  output logic [4:0]  active_tiles_peak
);
  logic        active;
  logic [15:0] offer, want, sgrant, sby;
  logic [51:0] oflit [0:15], sflit [0:15];
  logic [15:0] ntx_v, nret_v, otx_v, oret_v, tx_ack, ret_ack, r_hit, busy_t;
  logic [6:0]  ntx_vid [0:15], otx_vid [0:15], ntx_cid [0:15], otx_cid [0:15], nret_cid [0:15], oret_cid [0:15];
  logic [15:0] ntx_val [0:15], otx_val [0:15], r_val [0:15];
  logic [3:0]  otx_home [0:15], oret_home [0:15], fcells [0:15], fvars [0:15];
  logic [15:0] stp [0:15], prn [0:15], alc [0:15], gat [0:15];
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi = gi + 1) begin : g_tiles
      localparam int PRED = (gi + 15) % 16;
      localparam int SUCC = (gi + 1)  % 16;
      assign sgrant[gi] = offer[PRED] & want[gi];
      assign sflit[gi]  = oflit[PRED];
      assign sby[gi]    = offer[gi] & want[SUCC];
      hypernet16_tile #(gi[3:0]) u_tile (
        .clk(clk), .rst(rst), .start(start), .active(active), .quiescent(quiescent), .prog_sel(prog_sel),
        .steal_grant(sgrant[gi]), .stolen_by_succ(sby[gi]), .steal_in_flit(sflit[gi]),
        .can_offer(offer[gi]), .want_steal(want[gi]), .offer_flit(oflit[gi]),
        .net_tx_valid(ntx_v[gi]), .net_tx_vid(ntx_vid[gi]), .net_tx_val(ntx_val[gi]), .net_tx_src_cid(ntx_cid[gi]),
        .net_ret_valid(nret_v[gi]), .net_ret_cid(nret_cid[gi]),
        .tx_ack(tx_ack[gi]), .ret_ack(ret_ack[gi]),
        .out_tx_valid(otx_v[gi]), .out_tx_home(otx_home[gi]), .out_tx_vid(otx_vid[gi]), .out_tx_val(otx_val[gi]), .out_tx_cid(otx_cid[gi]),
        .out_ret_valid(oret_v[gi]), .out_ret_home(oret_home[gi]), .out_ret_cid(oret_cid[gi]),
        .root_hit(r_hit[gi]), .root_val(r_val[gi]),
        .free_cells_out(fcells[gi]), .free_vars_out(fvars[gi]), .busy_out(busy_t[gi]),
        .steps_out(stp[gi]), .pruned_out(prn[gi]), .allocs_out(alc[gi]), .gated_out(gat[gi])
      );
    end
  endgenerate
  integer s, d;
  always_comb begin
    for (d = 0; d < 16; d = d + 1) begin
      ntx_v[d] = 1'b0; ntx_vid[d] = 7'd0; ntx_val[d] = 16'd0; ntx_cid[d] = 7'd0;
      nret_v[d] = 1'b0; nret_cid[d] = 7'd0; tx_ack[d] = 1'b0; ret_ack[d] = 1'b0;
    end
    for (s = 0; s < 16; s = s + 1) begin
      if (otx_v[s] && !ntx_v[otx_home[s]] && !oret_v[otx_home[s]]) begin
        ntx_v[otx_home[s]] = 1'b1; ntx_vid[otx_home[s]] = otx_vid[s];
        ntx_val[otx_home[s]] = otx_val[s]; ntx_cid[otx_home[s]] = otx_cid[s];
        tx_ack[s] = 1'b1;
      end
      if (oret_v[s] && !nret_v[oret_home[s]]) begin
        nret_v[oret_home[s]] = 1'b1; nret_cid[oret_home[s]] = oret_cid[s];
        ret_ack[s] = 1'b1;
      end
    end
  end
  logic [4:0] cur_busy_cnt;
  integer m;
  always_comb begin
    total_steps = 16'd0; pruned_count = 16'd0; alloc_count = 16'd0; gated_tile_cycles = 16'd0;
    total_free_cells = 8'd0; total_free_vars = 8'd0; cur_busy_cnt = 5'd0;
    for (m = 0; m < 16; m = m + 1) begin
      total_steps       = total_steps + stp[m];
      pruned_count      = pruned_count + prn[m];
      alloc_count       = alloc_count + alc[m];
      gated_tile_cycles = gated_tile_cycles + gat[m];
      total_free_cells  = total_free_cells + {4'd0, fcells[m]};
      total_free_vars   = total_free_vars  + {4'd0, fvars[m]};
      cur_busy_cnt      = cur_busy_cnt     + {4'd0, (stp[m] != 16'd0)};
    end
  end
  integer k;
  always_ff @(posedge clk) begin
    if (rst || start) begin
      active <= start; root_result <= 32'd0; stolen_count <= 16'd0; active_tiles_peak <= 5'd0;
    end else if (active && !quiescent) begin : mesh_cnt
      reg [15:0] st_inc;
      st_inc = 16'd0;
      for (k = 0; k < 16; k = k + 1) begin
        st_inc = st_inc + {15'd0, sgrant[k]};
        if (r_hit[k]) root_result <= {16'd0, r_val[k]};
      end
      stolen_count <= stolen_count + st_inc;
      if (cur_busy_cnt > active_tiles_peak) active_tiles_peak <= cur_busy_cnt;
    end
  end
  assign quiescent = active && (total_free_cells == 8'd128) && (total_free_vars == 8'd128) && (busy_t == 16'd0);
endmodule
module riscv32_pipe16 (
  input  logic        clk, rst, start,
  input  logic [1:0]  prog_sel,
  output logic        halted,
  output logic [31:0] result_out,
  output logic [15:0] cycle_count, inst_retired
);
  logic [7:0]  pc;
  logic        ex_valid, running;
  logic [31:0] ex_inst;
  logic [31:0] rf [0:15];
  logic [31:0] dmem [0:7];
  logic [31:0] fetch_inst;
  always_comb begin
    case (pc)
      8'd0:  fetch_inst = {4'd1,  4'd9,  4'd0, 4'd0, 16'd31};
      8'd1:  fetch_inst = {4'd1,  4'd11, 4'd0, 4'd0, 16'd4};
      8'd2:  fetch_inst = {4'd1,  4'd5,  4'd0, 4'd0, 16'd31};
      8'd3:  fetch_inst = {4'd13, 4'd0,  4'd5, 4'd0, 16'd20};
      8'd4:  fetch_inst = {4'd3,  4'd10, 4'd0, 4'd5, 16'd0};
      8'd5:  fetch_inst = {4'd5,  4'd6,  4'd5, 4'd10, 16'd0};
      8'd6:  fetch_inst = {4'd7,  4'd5,  4'd5, 4'd6, 16'd0};
      8'd7:  fetch_inst = {4'd3,  4'd10, 4'd1, 4'd11, 16'd0};
      8'd8:  fetch_inst = {4'd13, 4'd0,  4'd10, 4'd0, 16'd18};
      8'd9:  fetch_inst = {4'd8,  4'd12, 4'd2, 4'd0, 16'd20};
      8'd10: fetch_inst = {4'd8,  4'd13, 4'd3, 4'd0, 16'd10};
      8'd11: fetch_inst = {4'd6,  4'd12, 4'd12, 4'd13, 16'd0};
      8'd12: fetch_inst = {4'd8,  4'd13, 4'd4, 4'd0, 16'd5};
      8'd13: fetch_inst = {4'd6,  4'd12, 4'd12, 4'd13, 16'd0};
      8'd14: fetch_inst = {4'd6,  4'd12, 4'd12, 4'd5, 16'd0};
      8'd15: fetch_inst = {4'd12, 4'd0,  4'd1, 4'd12, 16'd0};
      8'd16: fetch_inst = {4'd6,  4'd2,  4'd2, 4'd6, 16'd0};
      8'd17: fetch_inst = {4'd13, 4'd0,  4'd0, 4'd0, 16'd28};
      8'd18: fetch_inst = {4'd1,  4'd8,  4'd8, 4'd0, 16'd1};
      8'd19: fetch_inst = {4'd13, 4'd0,  4'd0, 4'd0, 16'd3};
      8'd20: fetch_inst = {4'd13, 4'd0,  4'd1, 4'd0, 16'd27};
      8'd21: fetch_inst = {4'd1,  4'd1,  4'd1, 4'd0, 16'hFFFF};
      8'd22: fetch_inst = {4'd11, 4'd12, 4'd1, 4'd0, 16'd0};
      8'd23: fetch_inst = {4'd10, 4'd5,  4'd12, 4'd0, 16'd31};
      8'd24: fetch_inst = {4'd9,  4'd4,  4'd12, 4'd0, 16'd5};
      8'd25: fetch_inst = {4'd10, 4'd4,  4'd4,  4'd0, 16'd31};
      8'd26: fetch_inst = {4'd13, 4'd0,  4'd0, 4'd0, 16'd35};
      8'd27: fetch_inst = {4'd15, 4'd0,  4'd8, 4'd0, 16'd0};
      8'd28: fetch_inst = {4'd6,  4'd3,  4'd3, 4'd6, 16'd0};
      8'd29: fetch_inst = {4'd8,  4'd3,  4'd3, 4'd0, 16'd1};
      8'd30: fetch_inst = {4'd6,  4'd4,  4'd4, 4'd6, 16'd0};
      8'd31: fetch_inst = {4'd9,  4'd4,  4'd4, 4'd0, 16'd1};
      8'd32: fetch_inst = {4'd1,  4'd1,  4'd1, 4'd0, 16'd1};
      8'd33: fetch_inst = {4'd6,  4'd10, 4'd2, 4'd3, 16'd0};
      8'd34: fetch_inst = {4'd13, 4'd0,  4'd0, 4'd0, 16'd39};
      8'd35: fetch_inst = {4'd9,  4'd3,  4'd12, 4'd0, 16'd10};
      8'd36: fetch_inst = {4'd10, 4'd3,  4'd3,  4'd0, 16'd31};
      8'd37: fetch_inst = {4'd9,  4'd2,  4'd12, 4'd0, 16'd20};
      8'd38: fetch_inst = {4'd13, 4'd0,  4'd0,  4'd0, 16'd3};
      8'd39: fetch_inst = {4'd6,  4'd10, 4'd10, 4'd4, 16'd0};
      8'd40: fetch_inst = {4'd7,  4'd5,  4'd9,  4'd10, 16'd0};
      8'd41: fetch_inst = {4'd10, 4'd5,  4'd5,  4'd0, 16'd31};
      8'd42: fetch_inst = {4'd13, 4'd0,  4'd0,  4'd0, 16'd3};
      8'd48: fetch_inst = {4'd1,  4'd1, 4'd0, 4'd0, 16'd3};
      8'd49: fetch_inst = {4'd1,  4'd2, 4'd0, 4'd0, 16'd2};
      8'd50: fetch_inst = {4'd4,  4'd1, 4'd1, 4'd2, 16'd0};
      8'd51: fetch_inst = {4'd4,  4'd1, 4'd1, 4'd2, 16'd0};
      8'd52: fetch_inst = {4'd15, 4'd0, 4'd1, 4'd0, 16'd0};
      8'd64: fetch_inst = {4'd1,  4'd1, 4'd0, 4'd0, 16'd1};
      8'd65: fetch_inst = {4'd1,  4'd2, 4'd0, 4'd0, 16'd16};
      8'd66: fetch_inst = {4'd2,  4'd3, 4'd3, 4'd1, 16'd0};
      8'd67: fetch_inst = {4'd1,  4'd1, 4'd1, 4'd0, 16'd1};
      8'd68: fetch_inst = {4'd1,  4'd2, 4'd2, 4'd0, 16'hFFFF};
      8'd69: fetch_inst = {4'd14, 4'd0, 4'd2, 4'd0, 16'd66};
      8'd70: fetch_inst = {4'd15, 4'd0, 4'd3, 4'd0, 16'd0};
      8'd80: fetch_inst = {4'd1,  4'd14, 4'd0,  4'd0,  16'd1};
      8'd81: fetch_inst = {4'd1,  4'd15, 4'd0,  4'd0,  16'd1};
      8'd82: fetch_inst = {4'd5,  4'd14, 4'd14, 4'd15, 16'd0};
      8'd83: fetch_inst = {4'd14, 4'd0,  4'd14, 4'd0,  16'd0};
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
      4'd1:  alu_y = v1 + imm;
      4'd2:  alu_y = v1 + v2;
      4'd3:  alu_y = v1 - v2;
      4'd4:  alu_y = v1 * v2;
      4'd5:  alu_y = v1 & v2;
      4'd6:  alu_y = v1 | v2;
      4'd7:  alu_y = v1 ^ v2;
      4'd8:  alu_y = v1 << ex_inst[4:0];
      4'd9:  alu_y = v1 >> ex_inst[4:0];
      4'd10: alu_y = v1 & {16'd0, ex_inst[15:0]};
      4'd11: alu_y = dmem[v1[2:0]];
      default: alu_y = 32'd0;
    endcase
  end
  wire take_br = ex_valid && ((op == 4'd13 && v1 == 32'd0) || (op == 4'd14 && v1 != 32'd0));
  integer k;
  always_ff @(posedge clk) begin
    if (rst || start) begin
      pc <= (prog_sel == 2'd0) ? 8'd0 : (prog_sel == 2'd1) ? 8'd48 : (prog_sel == 2'd2) ? 8'd64 : 8'd80;
      ex_valid <= 1'b0; ex_inst <= 32'd0; running <= start && !rst; halted <= 1'b0;
      result_out <= 32'd0; cycle_count <= 16'd0; inst_retired <= 16'd0;
      for (k = 0; k < 16; k = k + 1) rf[k] <= 32'd0;
      for (k = 0; k < 8; k = k + 1) dmem[k] <= 32'd0;
    end else if (running && !halted) begin
      cycle_count <= cycle_count + 16'd1;
      if (ex_valid) begin
        inst_retired <= inst_retired + 16'd1;
        if (op >= 4'd1 && op <= 4'd11 && rd != 4'd0) rf[rd] <= alu_y;
        if (op == 4'd12) dmem[v1[2:0]] <= v2;
        if (op == 4'd15) begin halted <= 1'b1; running <= 1'b0; result_out <= v1; end
      end
      if (take_br) begin
        pc <= ex_inst[7:0]; ex_valid <= 1'b0; ex_inst <= 32'd0;
      end else begin
        ex_valid <= 1'b1; ex_inst <= fetch_inst; pc <= pc + 8'd1;
      end
    end
  end
endmodule
