// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Wed Dec 28 11:42:00 2022
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub C:/rdos/vivado/adcsig/adcsig.runs/multiply_synth_1/multiply_stub.v
// Design      : multiply
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "xbip_dsp48_macro_v3_0_17,Vivado 2019.2" *)
module multiply(CLK, A, B, P)
/* synthesis syn_black_box black_box_pad_pin="CLK,A[13:0],B[15:0],P[29:0]" */;
  input CLK;
  input [13:0]A;
  input [15:0]B;
  output [29:0]P;
endmodule
