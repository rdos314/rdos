// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Feb  4 16:38:35 2023
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub C:/rdos/vivado/filter/adc.runs/ila_2_synth_1/ila_2_stub.v
// Design      : ila_2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2019.2" *)
module ila_2(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[15:0],probe3[15:0],probe4[15:0],probe5[15:0],probe6[31:0],probe7[31:0],probe8[43:0],probe9[43:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [15:0]probe2;
  input [15:0]probe3;
  input [15:0]probe4;
  input [15:0]probe5;
  input [31:0]probe6;
  input [31:0]probe7;
  input [43:0]probe8;
  input [43:0]probe9;
endmodule
