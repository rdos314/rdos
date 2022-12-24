// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun Apr 19 17:21:29 2020
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/rdos/vivado/adc/adc.srcs/sources_1/ip/jesd204_rx_0/jesd204_rx_0_stub.v
// Design      : jesd204_rx_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "jesd204_rx,Vivado 2019.2" *)
module jesd204_rx_0(clk, reset, phy_data, phy_header, phy_charisk, 
  phy_notintable, phy_disperr, phy_block_sync, sysref, lmfc_edge, lmfc_clk, 
  event_sysref_alignment_error, event_sysref_edge, sync, phy_en_char_align, rx_data, 
  rx_valid, rx_eof, rx_sof, cfg_lanes_disable, cfg_links_disable, cfg_beats_per_multiframe, 
  cfg_octets_per_frame, cfg_lmfc_offset, cfg_sysref_disable, cfg_sysref_oneshot, 
  cfg_buffer_early_release, cfg_buffer_delay, cfg_disable_char_replacement, 
  cfg_disable_scrambler, ctrl_err_statistics_reset, ctrl_err_statistics_mask, 
  status_err_statistics_cnt, ilas_config_valid, ilas_config_addr, ilas_config_data, 
  status_ctrl_state, status_lane_cgs_state, status_lane_ifs_ready, status_lane_latency, 
  status_lane_emb_state)
/* synthesis syn_black_box black_box_pad_pin="clk,reset,phy_data[127:0],phy_header[7:0],phy_charisk[15:0],phy_notintable[15:0],phy_disperr[15:0],phy_block_sync[3:0],sysref,lmfc_edge,lmfc_clk,event_sysref_alignment_error,event_sysref_edge,sync[0:0],phy_en_char_align,rx_data[127:0],rx_valid,rx_eof[3:0],rx_sof[3:0],cfg_lanes_disable[3:0],cfg_links_disable[0:0],cfg_beats_per_multiframe[7:0],cfg_octets_per_frame[7:0],cfg_lmfc_offset[7:0],cfg_sysref_disable,cfg_sysref_oneshot,cfg_buffer_early_release,cfg_buffer_delay[7:0],cfg_disable_char_replacement,cfg_disable_scrambler,ctrl_err_statistics_reset,ctrl_err_statistics_mask[6:0],status_err_statistics_cnt[127:0],ilas_config_valid[3:0],ilas_config_addr[7:0],ilas_config_data[127:0],status_ctrl_state[1:0],status_lane_cgs_state[7:0],status_lane_ifs_ready[3:0],status_lane_latency[55:0],status_lane_emb_state[11:0]" */;
  input clk;
  input reset;
  input [127:0]phy_data;
  input [7:0]phy_header;
  input [15:0]phy_charisk;
  input [15:0]phy_notintable;
  input [15:0]phy_disperr;
  input [3:0]phy_block_sync;
  input sysref;
  output lmfc_edge;
  output lmfc_clk;
  output event_sysref_alignment_error;
  output event_sysref_edge;
  output [0:0]sync;
  output phy_en_char_align;
  output [127:0]rx_data;
  output rx_valid;
  output [3:0]rx_eof;
  output [3:0]rx_sof;
  input [3:0]cfg_lanes_disable;
  input [0:0]cfg_links_disable;
  input [7:0]cfg_beats_per_multiframe;
  input [7:0]cfg_octets_per_frame;
  input [7:0]cfg_lmfc_offset;
  input cfg_sysref_disable;
  input cfg_sysref_oneshot;
  input cfg_buffer_early_release;
  input [7:0]cfg_buffer_delay;
  input cfg_disable_char_replacement;
  input cfg_disable_scrambler;
  input ctrl_err_statistics_reset;
  input [6:0]ctrl_err_statistics_mask;
  output [127:0]status_err_statistics_cnt;
  output [3:0]ilas_config_valid;
  output [7:0]ilas_config_addr;
  output [127:0]ilas_config_data;
  output [1:0]status_ctrl_state;
  output [7:0]status_lane_cgs_state;
  output [3:0]status_lane_ifs_ready;
  output [55:0]status_lane_latency;
  output [11:0]status_lane_emb_state;
endmodule
