// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun Feb  5 16:43:56 2023
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
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14, probe15, probe16, probe17, 
  probe18, probe19, probe20, probe21, probe22, probe23)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[3:0],probe2[15:0],probe3[1:0],probe4[15:0],probe5[47:0],probe6[47:0],probe7[20:0],probe8[47:0],probe9[47:0],probe10[20:0],probe11[15:0],probe12[15:0],probe13[15:0],probe14[15:0],probe15[15:0],probe16[15:0],probe17[0:0],probe18[0:0],probe19[47:0],probe20[127:0],probe21[127:0],probe22[127:0],probe23[127:0]" */;
  input clk;
  input [0:0]probe0;
  input [3:0]probe1;
  input [15:0]probe2;
  input [1:0]probe3;
  input [15:0]probe4;
  input [47:0]probe5;
  input [47:0]probe6;
  input [20:0]probe7;
  input [47:0]probe8;
  input [47:0]probe9;
  input [20:0]probe10;
  input [15:0]probe11;
  input [15:0]probe12;
  input [15:0]probe13;
  input [15:0]probe14;
  input [15:0]probe15;
  input [15:0]probe16;
  input [0:0]probe17;
  input [0:0]probe18;
  input [47:0]probe19;
  input [127:0]probe20;
  input [127:0]probe21;
  input [127:0]probe22;
  input [127:0]probe23;
endmodule
