// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun Jan  1 12:00:12 2023
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/rdos/vivado/adcsig/adcsig.runs/bram_coeff_synth_1/bram_coeff_stub.v
// Design      : bram_coeff
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module bram_coeff(clka, ena, wea, addra, dina, douta, clkb, rstb, enb, web, 
  addrb, dinb, doutb, rsta_busy, rstb_busy)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[12:0],dina[31:0],douta[31:0],clkb,rstb,enb,web[0:0],addrb[10:0],dinb[127:0],doutb[127:0],rsta_busy,rstb_busy" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [12:0]addra;
  input [31:0]dina;
  output [31:0]douta;
  input clkb;
  input rstb;
  input enb;
  input [0:0]web;
  input [10:0]addrb;
  input [127:0]dinb;
  output [127:0]doutb;
  output rsta_busy;
  output rstb_busy;
endmodule
