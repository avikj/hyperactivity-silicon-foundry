`timescale 1ns/1ps
// Emitted directly from lib/silicon/inet-compiler.hypercubical (zero hand-written SV!)
module tb_metacircular;
  reg clk = 0, rst_n = 1, ena = 1;
  reg [7:0] ui_in = 8'd0, uio_in = 8'd0;
  wire [7:0] uo_out, uio_out, uio_oe;
  tt_um_hyperinet dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));
  always #5 clk = ~clk;
  task load_field(input [2:0] slot, input [1:0] field, input [7:0] data);
    begin uio_in = {2'b00, field, slot, 1'b1}; ui_in = data; @(posedge clk); #1; uio_in = 8'd0; end
  endtask
  initial begin
    #1 rst_n = 0; #2 rst_n = 1; #1;
    // --- Compiled Program 1: hx-dup-add #21 (hardware DUP sharing: 21 -> (21, 21)) ---
    load_field(3'd0, 2'd0, 8'd128);
    load_field(3'd1, 2'd0, 8'd0);
    load_field(3'd2, 2'd0, 8'd0);
    load_field(3'd3, 2'd0, 8'd0);
    load_field(3'd4, 2'd0, 8'd0);
    load_field(3'd5, 2'd0, 8'd0);
    load_field(3'd6, 2'd0, 8'd0);
    load_field(3'd7, 2'd0, 8'd0);
    load_field(3'd0, 2'd0, 8'd4);
    load_field(3'd0, 2'd3, 8'd21);
    load_field(3'd0, 2'd1, 8'd4);
    load_field(3'd1, 2'd0, 8'd2);
    load_field(3'd1, 2'd3, 8'd0);
    load_field(3'd1, 2'd1, 8'd0);
    @(posedge clk); #1;
    uio_in = {1'b1, 3'b000, 3'd0, 1'b0}; #1;
    if (uo_out !== 8'd21) $fatal(1);
    uio_in = {1'b1, 3'b000, 3'd1, 1'b0}; #1;
    if (uo_out !== 8'd21) $fatal(1);
    $display("METACIRCULAR P1 PASS: compiled DUP(21) -> (21, %0d) in 1 cycle", uo_out);
    // --- Compiled Program 2: hx-add #100 #23 -> 123 ---
    load_field(3'd0, 2'd0, 8'd128);
    load_field(3'd1, 2'd0, 8'd0);
    load_field(3'd2, 2'd0, 8'd0);
    load_field(3'd3, 2'd0, 8'd0);
    load_field(3'd4, 2'd0, 8'd0);
    load_field(3'd5, 2'd0, 8'd0);
    load_field(3'd6, 2'd0, 8'd0);
    load_field(3'd7, 2'd0, 8'd0);
    load_field(3'd0, 2'd0, 8'd4);
    load_field(3'd0, 2'd3, 8'd100);
    load_field(3'd0, 2'd1, 8'd4);
    load_field(3'd1, 2'd0, 8'd5);
    load_field(3'd1, 2'd3, 8'd0);
    load_field(3'd1, 2'd1, 8'd0);
    load_field(3'd1, 2'd2, 8'd8);
    load_field(3'd2, 2'd0, 8'd4);
    load_field(3'd2, 2'd3, 8'd23);
    load_field(3'd2, 2'd1, 8'd5);
    @(posedge clk); #1; @(posedge clk); #1;
    uio_in = {1'b1, 3'b000, 3'd2, 1'b0}; #1;
    if (uo_out !== 8'd123) $fatal(1);
    $display("METACIRCULAR P2 PASS: compiled (100 + 23) -> %0d in 2 cycles", uo_out);
    // --- Compiled Program 3: hx-par-add #17 #25 #30 #12 -> (42, 42) in 2 cycles (DUAL-LANE!) ---
    load_field(3'd0, 2'd0, 8'd128);
    load_field(3'd1, 2'd0, 8'd0);
    load_field(3'd2, 2'd0, 8'd0);
    load_field(3'd3, 2'd0, 8'd0);
    load_field(3'd4, 2'd0, 8'd0);
    load_field(3'd5, 2'd0, 8'd0);
    load_field(3'd6, 2'd0, 8'd0);
    load_field(3'd7, 2'd0, 8'd0);
    load_field(3'd0, 2'd0, 8'd4);
    load_field(3'd0, 2'd3, 8'd17);
    load_field(3'd0, 2'd1, 8'd4);
    load_field(3'd1, 2'd0, 8'd5);
    load_field(3'd1, 2'd3, 8'd0);
    load_field(3'd1, 2'd1, 8'd0);
    load_field(3'd1, 2'd2, 8'd8);
    load_field(3'd2, 2'd0, 8'd4);
    load_field(3'd2, 2'd3, 8'd25);
    load_field(3'd2, 2'd1, 8'd5);
    load_field(3'd3, 2'd0, 8'd4);
    load_field(3'd3, 2'd3, 8'd30);
    load_field(3'd3, 2'd1, 8'd16);
    load_field(3'd4, 2'd0, 8'd5);
    load_field(3'd4, 2'd3, 8'd0);
    load_field(3'd4, 2'd1, 8'd12);
    load_field(3'd4, 2'd2, 8'd20);
    load_field(3'd5, 2'd0, 8'd4);
    load_field(3'd5, 2'd3, 8'd12);
    load_field(3'd5, 2'd1, 8'd17);
    if (uo_out[6] !== 1'b1) $fatal(1);
    @(posedge clk); #1;
    if (uo_out[5:3] !== 3'd2) $fatal(1);
    @(posedge clk); #1;
    if (uo_out[5:3] !== 3'd4) $fatal(1);
    uio_in = {1'b1, 3'b000, 3'd2, 1'b0}; #1;
    if (uo_out !== 8'd42) $fatal(1);
    uio_in = {1'b1, 3'b000, 3'd5, 1'b0}; #1;
    if (uo_out !== 8'd42) $fatal(1);
    $display("METACIRCULAR P3 PASS: compiled (17+25) || (30+12) -> (42, %0d) via 4 redexes in 2 cycles (2.0 redexes/cycle!)", uo_out);
    $display("METACIRCULAR_SILICON_LOOP_COMPLETE 3/3 compiled .hypercubical programs verified on tt_um_hyperinet!");
    $finish;
  end
endmodule
