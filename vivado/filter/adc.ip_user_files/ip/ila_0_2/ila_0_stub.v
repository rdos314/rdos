// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun Jan 22 12:33:08 2023
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub C:/rdos/vivado/filter/adc.runs/ila_0_synth_1/ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2019.2" *)
module ila_0(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[47:0],probe3[127:0],probe4[127:0],probe5[127:0],probe6[127:0],probe7[127:0],probe8[127:0],probe9[127:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [47:0]probe2;
  input [127:0]probe3;
  input [127:0]probe4;
  input [127:0]probe5;
  input [127:0]probe6;
  input [127:0]probe7;
  input [127:0]probe8;
  input [127:0]probe9;
endmodule
