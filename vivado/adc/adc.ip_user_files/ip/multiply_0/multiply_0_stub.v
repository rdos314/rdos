// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Tue May  5 21:00:41 2020
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub C:/rdos/vivado/adc/adc.runs/multiply_0_synth_1/multiply_0_stub.v
// Design      : multiply_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "mult_gen_v12_0_16,Vivado 2019.2" *)
module multiply_0(CLK, A, B, P)
/* synthesis syn_black_box black_box_pad_pin="CLK,A[14:0],B[13:0],P[28:0]" */;
  input CLK;
  input [14:0]A;
  input [13:0]B;
  output [28:0]P;
endmodule
