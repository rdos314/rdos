// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun Apr 19 17:21:29 2020
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               C:/rdos/vivado/adc/adc.srcs/sources_1/ip/jesd204_rx_0/jesd204_rx_0_sim_netlist.v
// Design      : jesd204_rx_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "jesd204_rx_0,jesd204_rx,{}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) (* IP_DEFINITION_SOURCE = "package_project" *) 
(* X_CORE_INFO = "jesd204_rx,Vivado 2019.2" *) 
(* NotValidForBitStream *)
module jesd204_rx_0
   (clk,
    reset,
    phy_data,
    phy_header,
    phy_charisk,
    phy_notintable,
    phy_disperr,
    phy_block_sync,
    sysref,
    lmfc_edge,
    lmfc_clk,
    event_sysref_alignment_error,
    event_sysref_edge,
    sync,
    phy_en_char_align,
    rx_data,
    rx_valid,
    rx_eof,
    rx_sof,
    cfg_lanes_disable,
    cfg_links_disable,
    cfg_beats_per_multiframe,
    cfg_octets_per_frame,
    cfg_lmfc_offset,
    cfg_sysref_disable,
    cfg_sysref_oneshot,
    cfg_buffer_early_release,
    cfg_buffer_delay,
    cfg_disable_char_replacement,
    cfg_disable_scrambler,
    ctrl_err_statistics_reset,
    ctrl_err_statistics_mask,
    status_err_statistics_cnt,
    ilas_config_valid,
    ilas_config_addr,
    ilas_config_data,
    status_ctrl_state,
    status_lane_cgs_state,
    status_lane_ifs_ready,
    status_lane_latency,
    status_lane_emb_state);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_clock CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_clock, ASSOCIATED_BUSIF rx_cfg:rx_ilas_config:rx_event:rx_status:rx_data, ASSOCIATED_RESET reset, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0" *) input clk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_reset RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rx_cfg_rx_ilas_config_rx_event_rx_status_rx_data_signal_reset, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *) input reset;
  (* X_INTERFACE_INFO = "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxdata [31:0] [31:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxdata [31:0] [63:32], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxdata [31:0] [95:64], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxdata [31:0] [127:96]" *) input [127:0]phy_data;
  (* X_INTERFACE_INFO = "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxheader [1:0] [1:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxheader [1:0] [3:2], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxheader [1:0] [5:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxheader [1:0] [7:6]" *) input [7:0]phy_header;
  (* X_INTERFACE_INFO = "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxcharisk [3:0] [3:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxcharisk [3:0] [7:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxcharisk [3:0] [11:8], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxcharisk [3:0] [15:12]" *) input [15:0]phy_charisk;
  (* X_INTERFACE_INFO = "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxnotintable [3:0] [3:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxnotintable [3:0] [7:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxnotintable [3:0] [11:8], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxnotintable [3:0] [15:12]" *) input [15:0]phy_notintable;
  (* X_INTERFACE_INFO = "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxdisperr [3:0] [3:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxdisperr [3:0] [7:4], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxdisperr [3:0] [11:8], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxdisperr [3:0] [15:12]" *) input [15:0]phy_disperr;
  (* X_INTERFACE_INFO = "xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy0 rxblock_sync [0:0] [0:0], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy1 rxblock_sync [0:0] [1:1], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy2 rxblock_sync [0:0] [2:2], xilinx.com:display_jesd204:jesd204_rx_bus:1.0 rx_phy3 rxblock_sync [0:0] [3:3]" *) input [3:0]phy_block_sync;
  input sysref;
  output lmfc_edge;
  output lmfc_clk;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_event:1.0 rx_event sysref_alignment_error" *) output event_sysref_alignment_error;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_event:1.0 rx_event sysref_edge" *) output event_sysref_edge;
  output [0:0]sync;
  output phy_en_char_align;
  output [127:0]rx_data;
  output rx_valid;
  output [3:0]rx_eof;
  output [3:0]rx_sof;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg lanes_disable" *) input [3:0]cfg_lanes_disable;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg links_disable" *) input [0:0]cfg_links_disable;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg beats_per_multiframe" *) input [7:0]cfg_beats_per_multiframe;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg octets_per_frame" *) input [7:0]cfg_octets_per_frame;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg lmfc_offset" *) input [7:0]cfg_lmfc_offset;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg sysref_disable" *) input cfg_sysref_disable;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg sysref_oneshot" *) input cfg_sysref_oneshot;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg buffer_early_release" *) input cfg_buffer_early_release;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg buffer_delay" *) input [7:0]cfg_buffer_delay;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg disable_char_replacement" *) input cfg_disable_char_replacement;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg disable_scrambler" *) input cfg_disable_scrambler;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg err_statistics_reset" *) input ctrl_err_statistics_reset;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_cfg:1.0 rx_cfg err_statistics_mask" *) input [6:0]ctrl_err_statistics_mask;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_status:1.0 rx_status err_statistics_cnt" *) output [127:0]status_err_statistics_cnt;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_ilas_config:1.0 rx_ilas_config valid" *) output [3:0]ilas_config_valid;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_ilas_config:1.0 rx_ilas_config addr" *) output [7:0]ilas_config_addr;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_ilas_config:1.0 rx_ilas_config data" *) output [127:0]ilas_config_data;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_status:1.0 rx_status ctrl_state" *) output [1:0]status_ctrl_state;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_cgs_state" *) output [7:0]status_lane_cgs_state;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_ifs_ready" *) output [3:0]status_lane_ifs_ready;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_latency" *) output [55:0]status_lane_latency;
  (* X_INTERFACE_INFO = "analog.com:interface:jesd204_rx_status:1.0 rx_status lane_emb_state" *) output [11:0]status_lane_emb_state;

  wire [7:0]cfg_beats_per_multiframe;
  wire [7:0]cfg_buffer_delay;
  wire cfg_buffer_early_release;
  wire cfg_disable_char_replacement;
  wire cfg_disable_scrambler;
  wire [3:0]cfg_lanes_disable;
  wire [0:0]cfg_links_disable;
  wire [7:0]cfg_lmfc_offset;
  wire [7:0]cfg_octets_per_frame;
  wire cfg_sysref_disable;
  wire cfg_sysref_oneshot;
  wire clk;
  wire [6:0]ctrl_err_statistics_mask;
  wire ctrl_err_statistics_reset;
  wire event_sysref_alignment_error;
  wire event_sysref_edge;
  wire [7:0]ilas_config_addr;
  wire [127:0]ilas_config_data;
  wire [3:0]ilas_config_valid;
  wire lmfc_clk;
  wire lmfc_edge;
  wire [3:0]phy_block_sync;
  wire [15:0]phy_charisk;
  wire [127:0]phy_data;
  wire [15:0]phy_disperr;
  wire phy_en_char_align;
  wire [7:0]phy_header;
  wire [15:0]phy_notintable;
  wire reset;
  wire [127:0]rx_data;
  wire [3:0]rx_eof;
  wire [3:0]rx_sof;
  wire rx_valid;
  wire [1:0]status_ctrl_state;
  wire [127:0]status_err_statistics_cnt;
  wire [7:0]status_lane_cgs_state;
  wire [11:0]status_lane_emb_state;
  wire [3:0]status_lane_ifs_ready;
  wire [55:0]status_lane_latency;
  wire [0:0]sync;
  wire sysref;

  (* ALIGN_MUX_REGISTERED = "0" *) 
  (* CHAR_INFO_REGISTERED = "0" *) 
  (* CW = "16" *) 
  (* DATA_PATH_WIDTH = "4" *) 
  (* DW = "128" *) 
  (* ELASTIC_BUFFER_SIZE = "128" *) 
  (* HW = "8" *) 
  (* LINK_MODE = "1" *) 
  (* LMFC_COUNTER_WIDTH = "7" *) 
  (* MAX_BEATS_PER_MULTIFRAME = "128" *) 
  (* MAX_OCTETS_PER_FRAME = "16" *) 
  (* MAX_OCTETS_PER_MULTIFRAME = "512" *) 
  (* NUM_INPUT_PIPELINE = "1" *) 
  (* NUM_LANES = "4" *) 
  (* NUM_LINKS = "1" *) 
  (* SCRAMBLER_REGISTERED = "0" *) 
  jesd204_rx_0_jesd204_rx inst
       (.cfg_beats_per_multiframe(cfg_beats_per_multiframe),
        .cfg_buffer_delay(cfg_buffer_delay),
        .cfg_buffer_early_release(cfg_buffer_early_release),
        .cfg_disable_char_replacement(cfg_disable_char_replacement),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cfg_lanes_disable(cfg_lanes_disable),
        .cfg_links_disable(cfg_links_disable),
        .cfg_lmfc_offset(cfg_lmfc_offset),
        .cfg_octets_per_frame(cfg_octets_per_frame),
        .cfg_sysref_disable(cfg_sysref_disable),
        .cfg_sysref_oneshot(cfg_sysref_oneshot),
        .clk(clk),
        .ctrl_err_statistics_mask(ctrl_err_statistics_mask),
        .ctrl_err_statistics_reset(ctrl_err_statistics_reset),
        .event_sysref_alignment_error(event_sysref_alignment_error),
        .event_sysref_edge(event_sysref_edge),
        .ilas_config_addr(ilas_config_addr),
        .ilas_config_data(ilas_config_data),
        .ilas_config_valid(ilas_config_valid),
        .lmfc_clk(lmfc_clk),
        .lmfc_edge(lmfc_edge),
        .phy_block_sync(phy_block_sync),
        .phy_charisk(phy_charisk),
        .phy_data(phy_data),
        .phy_disperr(phy_disperr),
        .phy_en_char_align(phy_en_char_align),
        .phy_header(phy_header),
        .phy_notintable(phy_notintable),
        .reset(reset),
        .rx_data(rx_data),
        .rx_eof(rx_eof),
        .rx_sof(rx_sof),
        .rx_valid(rx_valid),
        .status_ctrl_state(status_ctrl_state),
        .status_err_statistics_cnt(status_err_statistics_cnt),
        .status_lane_cgs_state(status_lane_cgs_state),
        .status_lane_emb_state(status_lane_emb_state),
        .status_lane_ifs_ready(status_lane_ifs_ready),
        .status_lane_latency(status_lane_latency),
        .sync(sync),
        .sysref(sysref));
endmodule

(* ORIG_REF_NAME = "align_mux" *) 
module jesd204_rx_0_align_mux
   (data_scrambled_s,
    data_aligned_s,
    Q,
    \in_charisk_d1_reg[3]_0 ,
    SS,
    ilas_config_valid_reg,
    ifs_ready_reg,
    WEBWE,
    cfg_disable_scrambler,
    \ilas_config_data_reg[5] ,
    \ilas_config_data_reg[5]_0 ,
    D,
    \in_data_d1_reg[31]_0 ,
    mem_reg,
    state,
    \in_charisk_d1_reg[3]_1 ,
    \wr_addr_reg[0] ,
    ilas_config_valid_reg_0,
    ilas_config_valid_reg_1,
    state_reg,
    clk);
  output [17:0]data_scrambled_s;
  output [23:0]data_aligned_s;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3]_0 ;
  output [0:0]SS;
  output ilas_config_valid_reg;
  output ifs_ready_reg;
  output [0:0]WEBWE;
  input cfg_disable_scrambler;
  input \ilas_config_data_reg[5] ;
  input \ilas_config_data_reg[5]_0 ;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31]_0 ;
  input [0:0]mem_reg;
  input state;
  input [3:0]\in_charisk_d1_reg[3]_1 ;
  input \wr_addr_reg[0] ;
  input ilas_config_valid_reg_0;
  input ilas_config_valid_reg_1;
  input state_reg;
  input clk;

  wire [7:0]D;
  wire [7:0]Q;
  wire [0:0]SS;
  wire [0:0]WEBWE;
  wire cfg_disable_scrambler;
  wire [1:1]charisk28_aligned_s;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [17:0]data_scrambled_s;
  wire ifs_ready_reg;
  wire \ilas_config_data_reg[5] ;
  wire \ilas_config_data_reg[5]_0 ;
  wire ilas_config_valid_i_3__2_n_0;
  wire ilas_config_valid_i_5__2_n_0;
  wire ilas_config_valid_reg;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire [2:0]in_charisk_d1;
  wire [0:0]\in_charisk_d1_reg[3]_0 ;
  wire [3:0]\in_charisk_d1_reg[3]_1 ;
  wire [23:0]in_data_d1;
  wire [31:0]\in_data_d1_reg[31]_0 ;
  wire [0:0]mem_reg;
  wire state;
  wire \state[14]_i_3__1_n_0 ;
  wire state_reg;
  wire \wr_addr_reg[0] ;

  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[0]_i_1__2 
       (.I0(in_data_d1[16]),
        .I1(Q[0]),
        .I2(in_data_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[8]),
        .O(data_aligned_s[0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[10]_i_1__2 
       (.I0(Q[2]),
        .I1(\in_data_d1_reg[31]_0 [2]),
        .I2(in_data_d1[10]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[18]),
        .O(data_aligned_s[10]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[11]_i_1__2 
       (.I0(Q[3]),
        .I1(\in_data_d1_reg[31]_0 [3]),
        .I2(in_data_d1[11]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[19]),
        .O(data_aligned_s[11]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[12]_i_1__2 
       (.I0(Q[4]),
        .I1(\in_data_d1_reg[31]_0 [4]),
        .I2(in_data_d1[12]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[20]),
        .O(data_aligned_s[12]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[13]_i_1__2 
       (.I0(Q[5]),
        .I1(\in_data_d1_reg[31]_0 [5]),
        .I2(in_data_d1[13]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[21]),
        .O(data_aligned_s[13]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[14]_i_1__2 
       (.I0(Q[6]),
        .I1(\in_data_d1_reg[31]_0 [6]),
        .I2(in_data_d1[14]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[22]),
        .O(data_aligned_s[14]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[15]_i_1__2 
       (.I0(Q[7]),
        .I1(\in_data_d1_reg[31]_0 [7]),
        .I2(in_data_d1[15]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[23]),
        .O(data_aligned_s[15]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[16]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [0]),
        .I1(\in_data_d1_reg[31]_0 [8]),
        .I2(in_data_d1[16]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[0]),
        .O(data_aligned_s[16]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[17]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [1]),
        .I1(\in_data_d1_reg[31]_0 [9]),
        .I2(in_data_d1[17]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[1]),
        .O(data_aligned_s[17]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[18]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [2]),
        .I1(\in_data_d1_reg[31]_0 [10]),
        .I2(in_data_d1[18]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[2]),
        .O(data_aligned_s[18]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[19]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [3]),
        .I1(\in_data_d1_reg[31]_0 [11]),
        .I2(in_data_d1[19]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[3]),
        .O(data_aligned_s[19]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[1]_i_1__2 
       (.I0(in_data_d1[17]),
        .I1(Q[1]),
        .I2(in_data_d1[1]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[9]),
        .O(data_aligned_s[1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[20]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [4]),
        .I1(\in_data_d1_reg[31]_0 [12]),
        .I2(in_data_d1[20]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[4]),
        .O(data_aligned_s[20]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[21]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [5]),
        .I1(\in_data_d1_reg[31]_0 [13]),
        .I2(in_data_d1[21]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[5]),
        .O(data_aligned_s[21]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[22]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [6]),
        .I1(\in_data_d1_reg[31]_0 [14]),
        .I2(in_data_d1[22]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[6]),
        .O(data_aligned_s[22]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[23]_i_1__2 
       (.I0(\in_data_d1_reg[31]_0 [7]),
        .I1(\in_data_d1_reg[31]_0 [15]),
        .I2(in_data_d1[23]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[7]),
        .O(data_aligned_s[23]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[2]_i_1__2 
       (.I0(in_data_d1[18]),
        .I1(Q[2]),
        .I2(in_data_d1[2]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[10]),
        .O(data_aligned_s[2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[3]_i_1__2 
       (.I0(in_data_d1[19]),
        .I1(Q[3]),
        .I2(in_data_d1[3]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[11]),
        .O(data_aligned_s[3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[4]_i_1__2 
       (.I0(in_data_d1[20]),
        .I1(Q[4]),
        .I2(in_data_d1[4]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[12]),
        .O(data_aligned_s[4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[5]_i_1__2 
       (.I0(in_data_d1[21]),
        .I1(Q[5]),
        .I2(in_data_d1[5]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[13]),
        .O(data_aligned_s[5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[6]_i_1__2 
       (.I0(in_data_d1[22]),
        .I1(Q[6]),
        .I2(in_data_d1[6]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[14]),
        .O(data_aligned_s[6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[7]_i_1__2 
       (.I0(in_data_d1[23]),
        .I1(Q[7]),
        .I2(in_data_d1[7]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[15]),
        .O(data_aligned_s[7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[8]_i_1__2 
       (.I0(Q[0]),
        .I1(\in_data_d1_reg[31]_0 [0]),
        .I2(in_data_d1[8]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[16]),
        .O(data_aligned_s[8]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[9]_i_1__2 
       (.I0(Q[1]),
        .I1(\in_data_d1_reg[31]_0 [1]),
        .I2(in_data_d1[9]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[17]),
        .O(data_aligned_s[9]));
  LUT6 #(
    .INIT(64'hFE22022200000000)) 
    ilas_config_valid_i_1__2
       (.I0(ilas_config_valid_reg_0),
        .I1(ilas_config_valid_reg_1),
        .I2(ilas_config_valid_i_3__2_n_0),
        .I3(charisk28_aligned_s),
        .I4(ilas_config_valid_i_5__2_n_0),
        .I5(state_reg),
        .O(ilas_config_valid_reg));
  (* SOFT_HLUTNM = "soft_lutpair69" *) 
  LUT4 #(
    .INIT(16'h0400)) 
    ilas_config_valid_i_3__2
       (.I0(data_aligned_s[14]),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[13]),
        .I3(state),
        .O(ilas_config_valid_i_3__2_n_0));
  LUT6 #(
    .INIT(64'hFFAACCF000AACCF0)) 
    ilas_config_valid_i_4__2
       (.I0(\in_charisk_d1_reg[3]_0 ),
        .I1(in_charisk_d1[2]),
        .I2(in_charisk_d1[1]),
        .I3(\ilas_config_data_reg[5]_0 ),
        .I4(\ilas_config_data_reg[5] ),
        .I5(\in_charisk_d1_reg[3]_1 [0]),
        .O(charisk28_aligned_s));
  (* SOFT_HLUTNM = "soft_lutpair69" *) 
  LUT3 #(
    .INIT(8'h10)) 
    ilas_config_valid_i_5__2
       (.I0(data_aligned_s[13]),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .O(ilas_config_valid_i_5__2_n_0));
  FDRE \in_charisk_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [0]),
        .Q(in_charisk_d1[0]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [1]),
        .Q(in_charisk_d1[1]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [2]),
        .Q(in_charisk_d1[2]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [3]),
        .Q(\in_charisk_d1_reg[3]_0 ),
        .R(1'b0));
  FDRE \in_data_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [0]),
        .Q(in_data_d1[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [10]),
        .Q(in_data_d1[10]),
        .R(1'b0));
  FDRE \in_data_d1_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [11]),
        .Q(in_data_d1[11]),
        .R(1'b0));
  FDRE \in_data_d1_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [12]),
        .Q(in_data_d1[12]),
        .R(1'b0));
  FDRE \in_data_d1_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [13]),
        .Q(in_data_d1[13]),
        .R(1'b0));
  FDRE \in_data_d1_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [14]),
        .Q(in_data_d1[14]),
        .R(1'b0));
  FDRE \in_data_d1_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [15]),
        .Q(in_data_d1[15]),
        .R(1'b0));
  FDRE \in_data_d1_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [16]),
        .Q(in_data_d1[16]),
        .R(1'b0));
  FDRE \in_data_d1_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [17]),
        .Q(in_data_d1[17]),
        .R(1'b0));
  FDRE \in_data_d1_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [18]),
        .Q(in_data_d1[18]),
        .R(1'b0));
  FDRE \in_data_d1_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [19]),
        .Q(in_data_d1[19]),
        .R(1'b0));
  FDRE \in_data_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [1]),
        .Q(in_data_d1[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [20]),
        .Q(in_data_d1[20]),
        .R(1'b0));
  FDRE \in_data_d1_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [21]),
        .Q(in_data_d1[21]),
        .R(1'b0));
  FDRE \in_data_d1_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [22]),
        .Q(in_data_d1[22]),
        .R(1'b0));
  FDRE \in_data_d1_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [23]),
        .Q(in_data_d1[23]),
        .R(1'b0));
  FDRE \in_data_d1_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [24]),
        .Q(Q[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [25]),
        .Q(Q[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [26]),
        .Q(Q[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [27]),
        .Q(Q[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [28]),
        .Q(Q[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [29]),
        .Q(Q[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [2]),
        .Q(in_data_d1[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [30]),
        .Q(Q[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [31]),
        .Q(Q[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [3]),
        .Q(in_data_d1[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [4]),
        .Q(in_data_d1[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [5]),
        .Q(in_data_d1[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [6]),
        .Q(in_data_d1[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [7]),
        .Q(in_data_d1[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [8]),
        .Q(in_data_d1[8]),
        .R(1'b0));
  FDRE \in_data_d1_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [9]),
        .Q(in_data_d1[9]),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_18__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[14]),
        .I3(D[7]),
        .O(data_scrambled_s[17]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_19__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[12]),
        .I3(D[6]),
        .O(data_scrambled_s[16]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_20__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[12]),
        .I2(data_aligned_s[11]),
        .I3(D[5]),
        .O(data_scrambled_s[15]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_21__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[11]),
        .I2(data_aligned_s[10]),
        .I3(D[4]),
        .O(data_scrambled_s[14]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_22__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[10]),
        .I2(data_aligned_s[9]),
        .I3(D[3]),
        .O(data_scrambled_s[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_23__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[9]),
        .I2(data_aligned_s[8]),
        .I3(D[2]),
        .O(data_scrambled_s[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_24__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[8]),
        .I3(D[1]),
        .O(data_scrambled_s[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_25__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[22]),
        .I3(D[0]),
        .O(data_scrambled_s[10]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_26__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[5]),
        .I2(data_aligned_s[23]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_27__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[5]),
        .I3(data_aligned_s[22]),
        .O(data_scrambled_s[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_28__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[3]),
        .I3(data_aligned_s[21]),
        .O(data_scrambled_s[7]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_29__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[3]),
        .I2(data_aligned_s[2]),
        .I3(data_aligned_s[20]),
        .O(data_scrambled_s[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_30__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[2]),
        .I2(data_aligned_s[1]),
        .I3(data_aligned_s[19]),
        .O(data_scrambled_s[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_31__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[1]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[18]),
        .O(data_scrambled_s[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_32__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[17]),
        .O(data_scrambled_s[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_33__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .I3(data_aligned_s[16]),
        .O(data_scrambled_s[2]));
  LUT1 #(
    .INIT(2'h1)) 
    mem_reg_i_34
       (.I0(SS),
        .O(WEBWE));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_8__2
       (.I0(cfg_disable_scrambler),
        .I1(mem_reg),
        .I2(data_aligned_s[9]),
        .I3(data_aligned_s[7]),
        .O(data_scrambled_s[1]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_9__2
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[7]),
        .I2(data_aligned_s[8]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[0]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAAAEA)) 
    \state[14]_i_1__2 
       (.I0(\wr_addr_reg[0] ),
        .I1(state),
        .I2(\state[14]_i_3__1_n_0 ),
        .I3(data_aligned_s[5]),
        .I4(data_aligned_s[6]),
        .I5(data_aligned_s[7]),
        .O(SS));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \state[14]_i_3__1 
       (.I0(in_charisk_d1[2]),
        .I1(\in_charisk_d1_reg[3]_0 ),
        .I2(in_charisk_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_charisk_d1[1]),
        .O(\state[14]_i_3__1_n_0 ));
  LUT2 #(
    .INIT(4'hB)) 
    state_i_1__1
       (.I0(SS),
        .I1(state_reg),
        .O(ifs_ready_reg));
endmodule

(* ORIG_REF_NAME = "align_mux" *) 
module jesd204_rx_0_align_mux_13
   (data_scrambled_s,
    data_aligned_s,
    Q,
    \in_charisk_d1_reg[3]_0 ,
    SR,
    ilas_config_valid_reg,
    buffer_release_opportunity_reg,
    state_reg,
    WEBWE,
    cfg_disable_scrambler,
    \ilas_config_data_reg[5] ,
    \ilas_config_data_reg[5]_0 ,
    D,
    \in_data_d1_reg[31]_0 ,
    mem_reg,
    state,
    \in_charisk_d1_reg[3]_1 ,
    cfg_lanes_disable,
    p_7_out,
    state_reg_0,
    prev_was_last,
    ilas_config_valid_reg_0,
    ilas_config_valid_reg_1,
    buffer_release_n_reg,
    buffer_release_opportunity,
    buffer_release_n,
    clk);
  output [17:0]data_scrambled_s;
  output [23:0]data_aligned_s;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3]_0 ;
  output [0:0]SR;
  output ilas_config_valid_reg;
  output buffer_release_opportunity_reg;
  output state_reg;
  output [0:0]WEBWE;
  input cfg_disable_scrambler;
  input \ilas_config_data_reg[5] ;
  input \ilas_config_data_reg[5]_0 ;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31]_0 ;
  input [0:0]mem_reg;
  input state;
  input [3:0]\in_charisk_d1_reg[3]_1 ;
  input [1:0]cfg_lanes_disable;
  input p_7_out;
  input state_reg_0;
  input prev_was_last;
  input ilas_config_valid_reg_0;
  input ilas_config_valid_reg_1;
  input buffer_release_n_reg;
  input buffer_release_opportunity;
  input buffer_release_n;
  input clk;

  wire [7:0]D;
  wire [7:0]Q;
  wire [0:0]SR;
  wire [0:0]WEBWE;
  wire buffer_release_n;
  wire buffer_release_n_i_2_n_0;
  wire buffer_release_n_reg;
  wire buffer_release_opportunity;
  wire buffer_release_opportunity_reg;
  wire cfg_disable_scrambler;
  wire [1:0]cfg_lanes_disable;
  wire [1:0]charisk28_aligned_s;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [17:0]data_scrambled_s;
  wire \ilas_config_data_reg[5] ;
  wire \ilas_config_data_reg[5]_0 ;
  wire ilas_config_valid_i_3_n_0;
  wire ilas_config_valid_i_5_n_0;
  wire ilas_config_valid_reg;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire [2:0]in_charisk_d1;
  wire [0:0]\in_charisk_d1_reg[3]_0 ;
  wire [3:0]\in_charisk_d1_reg[3]_1 ;
  wire [23:0]in_data_d1;
  wire [31:0]\in_data_d1_reg[31]_0 ;
  wire [0:0]mem_reg;
  wire mem_reg_i_34__0_n_0;
  wire p_7_out;
  wire prev_was_last;
  wire state;
  wire state_reg;
  wire state_reg_0;

  LUT4 #(
    .INIT(16'hEFE0)) 
    buffer_release_n_i_1
       (.I0(buffer_release_n_i_2_n_0),
        .I1(buffer_release_n_reg),
        .I2(buffer_release_opportunity),
        .I3(buffer_release_n),
        .O(buffer_release_opportunity_reg));
  (* SOFT_HLUTNM = "soft_lutpair32" *) 
  LUT5 #(
    .INIT(32'h08FF0808)) 
    buffer_release_n_i_2
       (.I0(mem_reg_i_34__0_n_0),
        .I1(state),
        .I2(cfg_lanes_disable[0]),
        .I3(cfg_lanes_disable[1]),
        .I4(p_7_out),
        .O(buffer_release_n_i_2_n_0));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[0]_i_1 
       (.I0(in_data_d1[16]),
        .I1(Q[0]),
        .I2(in_data_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[8]),
        .O(data_aligned_s[0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[10]_i_1 
       (.I0(Q[2]),
        .I1(\in_data_d1_reg[31]_0 [2]),
        .I2(in_data_d1[10]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[18]),
        .O(data_aligned_s[10]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[11]_i_1 
       (.I0(Q[3]),
        .I1(\in_data_d1_reg[31]_0 [3]),
        .I2(in_data_d1[11]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[19]),
        .O(data_aligned_s[11]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[12]_i_1 
       (.I0(Q[4]),
        .I1(\in_data_d1_reg[31]_0 [4]),
        .I2(in_data_d1[12]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[20]),
        .O(data_aligned_s[12]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[13]_i_1 
       (.I0(Q[5]),
        .I1(\in_data_d1_reg[31]_0 [5]),
        .I2(in_data_d1[13]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[21]),
        .O(data_aligned_s[13]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[14]_i_1 
       (.I0(Q[6]),
        .I1(\in_data_d1_reg[31]_0 [6]),
        .I2(in_data_d1[14]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[22]),
        .O(data_aligned_s[14]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[15]_i_1 
       (.I0(Q[7]),
        .I1(\in_data_d1_reg[31]_0 [7]),
        .I2(in_data_d1[15]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[23]),
        .O(data_aligned_s[15]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[16]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [0]),
        .I1(\in_data_d1_reg[31]_0 [8]),
        .I2(in_data_d1[16]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[0]),
        .O(data_aligned_s[16]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[17]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [1]),
        .I1(\in_data_d1_reg[31]_0 [9]),
        .I2(in_data_d1[17]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[1]),
        .O(data_aligned_s[17]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[18]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [2]),
        .I1(\in_data_d1_reg[31]_0 [10]),
        .I2(in_data_d1[18]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[2]),
        .O(data_aligned_s[18]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[19]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [3]),
        .I1(\in_data_d1_reg[31]_0 [11]),
        .I2(in_data_d1[19]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[3]),
        .O(data_aligned_s[19]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[1]_i_1 
       (.I0(in_data_d1[17]),
        .I1(Q[1]),
        .I2(in_data_d1[1]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[9]),
        .O(data_aligned_s[1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[20]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [4]),
        .I1(\in_data_d1_reg[31]_0 [12]),
        .I2(in_data_d1[20]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[4]),
        .O(data_aligned_s[20]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[21]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [5]),
        .I1(\in_data_d1_reg[31]_0 [13]),
        .I2(in_data_d1[21]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[5]),
        .O(data_aligned_s[21]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[22]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [6]),
        .I1(\in_data_d1_reg[31]_0 [14]),
        .I2(in_data_d1[22]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[6]),
        .O(data_aligned_s[22]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[23]_i_1 
       (.I0(\in_data_d1_reg[31]_0 [7]),
        .I1(\in_data_d1_reg[31]_0 [15]),
        .I2(in_data_d1[23]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[7]),
        .O(data_aligned_s[23]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[2]_i_1 
       (.I0(in_data_d1[18]),
        .I1(Q[2]),
        .I2(in_data_d1[2]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[10]),
        .O(data_aligned_s[2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[3]_i_1 
       (.I0(in_data_d1[19]),
        .I1(Q[3]),
        .I2(in_data_d1[3]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[11]),
        .O(data_aligned_s[3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[4]_i_1 
       (.I0(in_data_d1[20]),
        .I1(Q[4]),
        .I2(in_data_d1[4]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[12]),
        .O(data_aligned_s[4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[5]_i_1 
       (.I0(in_data_d1[21]),
        .I1(Q[5]),
        .I2(in_data_d1[5]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[13]),
        .O(data_aligned_s[5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[6]_i_1 
       (.I0(in_data_d1[22]),
        .I1(Q[6]),
        .I2(in_data_d1[6]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[14]),
        .O(data_aligned_s[6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[7]_i_1 
       (.I0(in_data_d1[23]),
        .I1(Q[7]),
        .I2(in_data_d1[7]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[15]),
        .O(data_aligned_s[7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[8]_i_1 
       (.I0(Q[0]),
        .I1(\in_data_d1_reg[31]_0 [0]),
        .I2(in_data_d1[8]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[16]),
        .O(data_aligned_s[8]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[9]_i_1 
       (.I0(Q[1]),
        .I1(\in_data_d1_reg[31]_0 [1]),
        .I2(in_data_d1[9]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[17]),
        .O(data_aligned_s[9]));
  LUT6 #(
    .INIT(64'hFE22022200000000)) 
    ilas_config_valid_i_1
       (.I0(ilas_config_valid_reg_0),
        .I1(ilas_config_valid_reg_1),
        .I2(ilas_config_valid_i_3_n_0),
        .I3(charisk28_aligned_s[1]),
        .I4(ilas_config_valid_i_5_n_0),
        .I5(state_reg_0),
        .O(ilas_config_valid_reg));
  (* SOFT_HLUTNM = "soft_lutpair33" *) 
  LUT4 #(
    .INIT(16'h0400)) 
    ilas_config_valid_i_3
       (.I0(data_aligned_s[14]),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[13]),
        .I3(state),
        .O(ilas_config_valid_i_3_n_0));
  LUT6 #(
    .INIT(64'hFFAACCF000AACCF0)) 
    ilas_config_valid_i_4
       (.I0(\in_charisk_d1_reg[3]_0 ),
        .I1(in_charisk_d1[2]),
        .I2(in_charisk_d1[1]),
        .I3(\ilas_config_data_reg[5]_0 ),
        .I4(\ilas_config_data_reg[5] ),
        .I5(\in_charisk_d1_reg[3]_1 [0]),
        .O(charisk28_aligned_s[1]));
  (* SOFT_HLUTNM = "soft_lutpair33" *) 
  LUT3 #(
    .INIT(8'h10)) 
    ilas_config_valid_i_5
       (.I0(data_aligned_s[13]),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .O(ilas_config_valid_i_5_n_0));
  FDRE \in_charisk_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [0]),
        .Q(in_charisk_d1[0]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [1]),
        .Q(in_charisk_d1[1]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [2]),
        .Q(in_charisk_d1[2]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [3]),
        .Q(\in_charisk_d1_reg[3]_0 ),
        .R(1'b0));
  FDRE \in_data_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [0]),
        .Q(in_data_d1[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [10]),
        .Q(in_data_d1[10]),
        .R(1'b0));
  FDRE \in_data_d1_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [11]),
        .Q(in_data_d1[11]),
        .R(1'b0));
  FDRE \in_data_d1_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [12]),
        .Q(in_data_d1[12]),
        .R(1'b0));
  FDRE \in_data_d1_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [13]),
        .Q(in_data_d1[13]),
        .R(1'b0));
  FDRE \in_data_d1_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [14]),
        .Q(in_data_d1[14]),
        .R(1'b0));
  FDRE \in_data_d1_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [15]),
        .Q(in_data_d1[15]),
        .R(1'b0));
  FDRE \in_data_d1_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [16]),
        .Q(in_data_d1[16]),
        .R(1'b0));
  FDRE \in_data_d1_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [17]),
        .Q(in_data_d1[17]),
        .R(1'b0));
  FDRE \in_data_d1_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [18]),
        .Q(in_data_d1[18]),
        .R(1'b0));
  FDRE \in_data_d1_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [19]),
        .Q(in_data_d1[19]),
        .R(1'b0));
  FDRE \in_data_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [1]),
        .Q(in_data_d1[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [20]),
        .Q(in_data_d1[20]),
        .R(1'b0));
  FDRE \in_data_d1_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [21]),
        .Q(in_data_d1[21]),
        .R(1'b0));
  FDRE \in_data_d1_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [22]),
        .Q(in_data_d1[22]),
        .R(1'b0));
  FDRE \in_data_d1_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [23]),
        .Q(in_data_d1[23]),
        .R(1'b0));
  FDRE \in_data_d1_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [24]),
        .Q(Q[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [25]),
        .Q(Q[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [26]),
        .Q(Q[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [27]),
        .Q(Q[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [28]),
        .Q(Q[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [29]),
        .Q(Q[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [2]),
        .Q(in_data_d1[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [30]),
        .Q(Q[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [31]),
        .Q(Q[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [3]),
        .Q(in_data_d1[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [4]),
        .Q(in_data_d1[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [5]),
        .Q(in_data_d1[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [6]),
        .Q(in_data_d1[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [7]),
        .Q(in_data_d1[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [8]),
        .Q(in_data_d1[8]),
        .R(1'b0));
  FDRE \in_data_d1_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [9]),
        .Q(in_data_d1[9]),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_17
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[14]),
        .I3(D[7]),
        .O(data_scrambled_s[17]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_18
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[12]),
        .I3(D[6]),
        .O(data_scrambled_s[16]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_19
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[12]),
        .I2(data_aligned_s[11]),
        .I3(D[5]),
        .O(data_scrambled_s[15]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_20
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[11]),
        .I2(data_aligned_s[10]),
        .I3(D[4]),
        .O(data_scrambled_s[14]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_21
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[10]),
        .I2(data_aligned_s[9]),
        .I3(D[3]),
        .O(data_scrambled_s[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_22
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[9]),
        .I2(data_aligned_s[8]),
        .I3(D[2]),
        .O(data_scrambled_s[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_23
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[8]),
        .I3(D[1]),
        .O(data_scrambled_s[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_24
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[22]),
        .I3(D[0]),
        .O(data_scrambled_s[10]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_25
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[5]),
        .I2(data_aligned_s[23]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_26
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[5]),
        .I3(data_aligned_s[22]),
        .O(data_scrambled_s[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_27
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[3]),
        .I3(data_aligned_s[21]),
        .O(data_scrambled_s[7]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_28
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[3]),
        .I2(data_aligned_s[2]),
        .I3(data_aligned_s[20]),
        .O(data_scrambled_s[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_29
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[2]),
        .I2(data_aligned_s[1]),
        .I3(data_aligned_s[19]),
        .O(data_scrambled_s[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_30
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[1]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[18]),
        .O(data_scrambled_s[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_31
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[17]),
        .O(data_scrambled_s[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_32
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .I3(data_aligned_s[16]),
        .O(data_scrambled_s[2]));
  LUT2 #(
    .INIT(4'h7)) 
    mem_reg_i_33__2
       (.I0(mem_reg_i_34__0_n_0),
        .I1(state),
        .O(WEBWE));
  LUT6 #(
    .INIT(64'h55555575FFFFFFFF)) 
    mem_reg_i_34__0
       (.I0(state_reg_0),
        .I1(data_aligned_s[6]),
        .I2(charisk28_aligned_s[0]),
        .I3(data_aligned_s[5]),
        .I4(data_aligned_s[7]),
        .I5(prev_was_last),
        .O(mem_reg_i_34__0_n_0));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    mem_reg_i_35
       (.I0(in_charisk_d1[2]),
        .I1(\in_charisk_d1_reg[3]_0 ),
        .I2(in_charisk_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_charisk_d1[1]),
        .O(charisk28_aligned_s[0]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_7
       (.I0(cfg_disable_scrambler),
        .I1(mem_reg),
        .I2(data_aligned_s[9]),
        .I3(data_aligned_s[7]),
        .O(data_scrambled_s[1]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_8
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[7]),
        .I2(data_aligned_s[8]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[0]));
  (* SOFT_HLUTNM = "soft_lutpair32" *) 
  LUT2 #(
    .INIT(4'h8)) 
    \state[14]_i_1 
       (.I0(mem_reg_i_34__0_n_0),
        .I1(state),
        .O(SR));
  LUT3 #(
    .INIT(8'h8F)) 
    state_i_1__2
       (.I0(mem_reg_i_34__0_n_0),
        .I1(state),
        .I2(state_reg_0),
        .O(state_reg));
endmodule

(* ORIG_REF_NAME = "align_mux" *) 
module jesd204_rx_0_align_mux_3
   (\cfg_lanes_disable[2] ,
    p_17_out,
    data_scrambled_s,
    data_aligned_s,
    Q,
    \in_charisk_d1_reg[3]_0 ,
    ilas_config_valid_reg,
    ifs_ready_reg,
    WEBWE,
    cfg_lanes_disable,
    p_27_out,
    cfg_disable_scrambler,
    \ilas_config_data_reg[5] ,
    \ilas_config_data_reg[5]_0 ,
    D,
    \in_data_d1_reg[31]_0 ,
    mem_reg,
    state,
    \in_charisk_d1_reg[3]_1 ,
    \wr_addr_reg[6] ,
    ilas_config_valid_reg_0,
    ilas_config_valid_reg_1,
    state_reg,
    clk);
  output \cfg_lanes_disable[2] ;
  output p_17_out;
  output [17:0]data_scrambled_s;
  output [23:0]data_aligned_s;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3]_0 ;
  output ilas_config_valid_reg;
  output ifs_ready_reg;
  output [0:0]WEBWE;
  input [1:0]cfg_lanes_disable;
  input p_27_out;
  input cfg_disable_scrambler;
  input \ilas_config_data_reg[5] ;
  input \ilas_config_data_reg[5]_0 ;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31]_0 ;
  input [0:0]mem_reg;
  input state;
  input [3:0]\in_charisk_d1_reg[3]_1 ;
  input \wr_addr_reg[6] ;
  input ilas_config_valid_reg_0;
  input ilas_config_valid_reg_1;
  input state_reg;
  input clk;

  wire [7:0]D;
  wire [7:0]Q;
  wire [0:0]WEBWE;
  wire cfg_disable_scrambler;
  wire [1:0]cfg_lanes_disable;
  wire \cfg_lanes_disable[2] ;
  wire [1:1]charisk28_aligned_s;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [17:0]data_scrambled_s;
  wire ifs_ready_reg;
  wire \ilas_config_data_reg[5] ;
  wire \ilas_config_data_reg[5]_0 ;
  wire ilas_config_valid_i_3__1_n_0;
  wire ilas_config_valid_i_5__1_n_0;
  wire ilas_config_valid_reg;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire [2:0]in_charisk_d1;
  wire [0:0]\in_charisk_d1_reg[3]_0 ;
  wire [3:0]\in_charisk_d1_reg[3]_1 ;
  wire [23:0]in_data_d1;
  wire [31:0]\in_data_d1_reg[31]_0 ;
  wire [0:0]mem_reg;
  wire p_17_out;
  wire p_27_out;
  wire state;
  wire \state[14]_i_3__0_n_0 ;
  wire state_reg;
  wire \wr_addr_reg[6] ;

  (* SOFT_HLUTNM = "soft_lutpair57" *) 
  LUT4 #(
    .INIT(16'h4F44)) 
    buffer_release_n_i_3
       (.I0(cfg_lanes_disable[1]),
        .I1(p_17_out),
        .I2(cfg_lanes_disable[0]),
        .I3(p_27_out),
        .O(\cfg_lanes_disable[2] ));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[0]_i_1__1 
       (.I0(in_data_d1[16]),
        .I1(Q[0]),
        .I2(in_data_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[8]),
        .O(data_aligned_s[0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[10]_i_1__1 
       (.I0(Q[2]),
        .I1(\in_data_d1_reg[31]_0 [2]),
        .I2(in_data_d1[10]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[18]),
        .O(data_aligned_s[10]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[11]_i_1__1 
       (.I0(Q[3]),
        .I1(\in_data_d1_reg[31]_0 [3]),
        .I2(in_data_d1[11]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[19]),
        .O(data_aligned_s[11]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[12]_i_1__1 
       (.I0(Q[4]),
        .I1(\in_data_d1_reg[31]_0 [4]),
        .I2(in_data_d1[12]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[20]),
        .O(data_aligned_s[12]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[13]_i_1__1 
       (.I0(Q[5]),
        .I1(\in_data_d1_reg[31]_0 [5]),
        .I2(in_data_d1[13]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[21]),
        .O(data_aligned_s[13]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[14]_i_1__1 
       (.I0(Q[6]),
        .I1(\in_data_d1_reg[31]_0 [6]),
        .I2(in_data_d1[14]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[22]),
        .O(data_aligned_s[14]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[15]_i_1__1 
       (.I0(Q[7]),
        .I1(\in_data_d1_reg[31]_0 [7]),
        .I2(in_data_d1[15]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[23]),
        .O(data_aligned_s[15]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[16]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [0]),
        .I1(\in_data_d1_reg[31]_0 [8]),
        .I2(in_data_d1[16]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[0]),
        .O(data_aligned_s[16]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[17]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [1]),
        .I1(\in_data_d1_reg[31]_0 [9]),
        .I2(in_data_d1[17]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[1]),
        .O(data_aligned_s[17]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[18]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [2]),
        .I1(\in_data_d1_reg[31]_0 [10]),
        .I2(in_data_d1[18]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[2]),
        .O(data_aligned_s[18]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[19]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [3]),
        .I1(\in_data_d1_reg[31]_0 [11]),
        .I2(in_data_d1[19]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[3]),
        .O(data_aligned_s[19]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[1]_i_1__1 
       (.I0(in_data_d1[17]),
        .I1(Q[1]),
        .I2(in_data_d1[1]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[9]),
        .O(data_aligned_s[1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[20]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [4]),
        .I1(\in_data_d1_reg[31]_0 [12]),
        .I2(in_data_d1[20]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[4]),
        .O(data_aligned_s[20]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[21]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [5]),
        .I1(\in_data_d1_reg[31]_0 [13]),
        .I2(in_data_d1[21]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[5]),
        .O(data_aligned_s[21]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[22]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [6]),
        .I1(\in_data_d1_reg[31]_0 [14]),
        .I2(in_data_d1[22]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[6]),
        .O(data_aligned_s[22]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[23]_i_1__1 
       (.I0(\in_data_d1_reg[31]_0 [7]),
        .I1(\in_data_d1_reg[31]_0 [15]),
        .I2(in_data_d1[23]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[7]),
        .O(data_aligned_s[23]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[2]_i_1__1 
       (.I0(in_data_d1[18]),
        .I1(Q[2]),
        .I2(in_data_d1[2]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[10]),
        .O(data_aligned_s[2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[3]_i_1__1 
       (.I0(in_data_d1[19]),
        .I1(Q[3]),
        .I2(in_data_d1[3]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[11]),
        .O(data_aligned_s[3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[4]_i_1__1 
       (.I0(in_data_d1[20]),
        .I1(Q[4]),
        .I2(in_data_d1[4]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[12]),
        .O(data_aligned_s[4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[5]_i_1__1 
       (.I0(in_data_d1[21]),
        .I1(Q[5]),
        .I2(in_data_d1[5]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[13]),
        .O(data_aligned_s[5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[6]_i_1__1 
       (.I0(in_data_d1[22]),
        .I1(Q[6]),
        .I2(in_data_d1[6]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[14]),
        .O(data_aligned_s[6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[7]_i_1__1 
       (.I0(in_data_d1[23]),
        .I1(Q[7]),
        .I2(in_data_d1[7]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[15]),
        .O(data_aligned_s[7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[8]_i_1__1 
       (.I0(Q[0]),
        .I1(\in_data_d1_reg[31]_0 [0]),
        .I2(in_data_d1[8]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[16]),
        .O(data_aligned_s[8]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[9]_i_1__1 
       (.I0(Q[1]),
        .I1(\in_data_d1_reg[31]_0 [1]),
        .I2(in_data_d1[9]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[17]),
        .O(data_aligned_s[9]));
  LUT6 #(
    .INIT(64'hFE22022200000000)) 
    ilas_config_valid_i_1__1
       (.I0(ilas_config_valid_reg_0),
        .I1(ilas_config_valid_reg_1),
        .I2(ilas_config_valid_i_3__1_n_0),
        .I3(charisk28_aligned_s),
        .I4(ilas_config_valid_i_5__1_n_0),
        .I5(state_reg),
        .O(ilas_config_valid_reg));
  (* SOFT_HLUTNM = "soft_lutpair56" *) 
  LUT4 #(
    .INIT(16'h0400)) 
    ilas_config_valid_i_3__1
       (.I0(data_aligned_s[14]),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[13]),
        .I3(state),
        .O(ilas_config_valid_i_3__1_n_0));
  LUT6 #(
    .INIT(64'hFFAACCF000AACCF0)) 
    ilas_config_valid_i_4__1
       (.I0(\in_charisk_d1_reg[3]_0 ),
        .I1(in_charisk_d1[2]),
        .I2(in_charisk_d1[1]),
        .I3(\ilas_config_data_reg[5]_0 ),
        .I4(\ilas_config_data_reg[5] ),
        .I5(\in_charisk_d1_reg[3]_1 [0]),
        .O(charisk28_aligned_s));
  (* SOFT_HLUTNM = "soft_lutpair56" *) 
  LUT3 #(
    .INIT(8'h10)) 
    ilas_config_valid_i_5__1
       (.I0(data_aligned_s[13]),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .O(ilas_config_valid_i_5__1_n_0));
  FDRE \in_charisk_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [0]),
        .Q(in_charisk_d1[0]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [1]),
        .Q(in_charisk_d1[1]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [2]),
        .Q(in_charisk_d1[2]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [3]),
        .Q(\in_charisk_d1_reg[3]_0 ),
        .R(1'b0));
  FDRE \in_data_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [0]),
        .Q(in_data_d1[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [10]),
        .Q(in_data_d1[10]),
        .R(1'b0));
  FDRE \in_data_d1_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [11]),
        .Q(in_data_d1[11]),
        .R(1'b0));
  FDRE \in_data_d1_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [12]),
        .Q(in_data_d1[12]),
        .R(1'b0));
  FDRE \in_data_d1_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [13]),
        .Q(in_data_d1[13]),
        .R(1'b0));
  FDRE \in_data_d1_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [14]),
        .Q(in_data_d1[14]),
        .R(1'b0));
  FDRE \in_data_d1_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [15]),
        .Q(in_data_d1[15]),
        .R(1'b0));
  FDRE \in_data_d1_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [16]),
        .Q(in_data_d1[16]),
        .R(1'b0));
  FDRE \in_data_d1_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [17]),
        .Q(in_data_d1[17]),
        .R(1'b0));
  FDRE \in_data_d1_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [18]),
        .Q(in_data_d1[18]),
        .R(1'b0));
  FDRE \in_data_d1_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [19]),
        .Q(in_data_d1[19]),
        .R(1'b0));
  FDRE \in_data_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [1]),
        .Q(in_data_d1[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [20]),
        .Q(in_data_d1[20]),
        .R(1'b0));
  FDRE \in_data_d1_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [21]),
        .Q(in_data_d1[21]),
        .R(1'b0));
  FDRE \in_data_d1_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [22]),
        .Q(in_data_d1[22]),
        .R(1'b0));
  FDRE \in_data_d1_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [23]),
        .Q(in_data_d1[23]),
        .R(1'b0));
  FDRE \in_data_d1_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [24]),
        .Q(Q[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [25]),
        .Q(Q[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [26]),
        .Q(Q[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [27]),
        .Q(Q[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [28]),
        .Q(Q[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [29]),
        .Q(Q[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [2]),
        .Q(in_data_d1[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [30]),
        .Q(Q[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [31]),
        .Q(Q[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [3]),
        .Q(in_data_d1[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [4]),
        .Q(in_data_d1[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [5]),
        .Q(in_data_d1[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [6]),
        .Q(in_data_d1[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [7]),
        .Q(in_data_d1[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [8]),
        .Q(in_data_d1[8]),
        .R(1'b0));
  FDRE \in_data_d1_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [9]),
        .Q(in_data_d1[9]),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_17__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[14]),
        .I3(D[7]),
        .O(data_scrambled_s[17]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_18__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[12]),
        .I3(D[6]),
        .O(data_scrambled_s[16]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_19__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[12]),
        .I2(data_aligned_s[11]),
        .I3(D[5]),
        .O(data_scrambled_s[15]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_20__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[11]),
        .I2(data_aligned_s[10]),
        .I3(D[4]),
        .O(data_scrambled_s[14]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_21__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[10]),
        .I2(data_aligned_s[9]),
        .I3(D[3]),
        .O(data_scrambled_s[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_22__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[9]),
        .I2(data_aligned_s[8]),
        .I3(D[2]),
        .O(data_scrambled_s[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_23__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[8]),
        .I3(D[1]),
        .O(data_scrambled_s[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_24__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[22]),
        .I3(D[0]),
        .O(data_scrambled_s[10]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_25__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[5]),
        .I2(data_aligned_s[23]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_26__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[5]),
        .I3(data_aligned_s[22]),
        .O(data_scrambled_s[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_27__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[3]),
        .I3(data_aligned_s[21]),
        .O(data_scrambled_s[7]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_28__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[3]),
        .I2(data_aligned_s[2]),
        .I3(data_aligned_s[20]),
        .O(data_scrambled_s[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_29__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[2]),
        .I2(data_aligned_s[1]),
        .I3(data_aligned_s[19]),
        .O(data_scrambled_s[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_30__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[1]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[18]),
        .O(data_scrambled_s[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_31__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[17]),
        .O(data_scrambled_s[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_32__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .I3(data_aligned_s[16]),
        .O(data_scrambled_s[2]));
  LUT1 #(
    .INIT(2'h1)) 
    mem_reg_i_33__0
       (.I0(p_17_out),
        .O(WEBWE));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_7__1
       (.I0(cfg_disable_scrambler),
        .I1(mem_reg),
        .I2(data_aligned_s[9]),
        .I3(data_aligned_s[7]),
        .O(data_scrambled_s[1]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_8__1
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[7]),
        .I2(data_aligned_s[8]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[0]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAAAEA)) 
    \state[14]_i_1__1 
       (.I0(\wr_addr_reg[6] ),
        .I1(state),
        .I2(\state[14]_i_3__0_n_0 ),
        .I3(data_aligned_s[5]),
        .I4(data_aligned_s[6]),
        .I5(data_aligned_s[7]),
        .O(p_17_out));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \state[14]_i_3__0 
       (.I0(in_charisk_d1[2]),
        .I1(\in_charisk_d1_reg[3]_0 ),
        .I2(in_charisk_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_charisk_d1[1]),
        .O(\state[14]_i_3__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair57" *) 
  LUT2 #(
    .INIT(4'hB)) 
    state_i_1__0
       (.I0(p_17_out),
        .I1(state_reg),
        .O(ifs_ready_reg));
endmodule

(* ORIG_REF_NAME = "align_mux" *) 
module jesd204_rx_0_align_mux_8
   (data_scrambled_s,
    data_aligned_s,
    Q,
    \in_charisk_d1_reg[3]_0 ,
    SS,
    ilas_config_valid_reg,
    ifs_ready_reg,
    WEBWE,
    cfg_disable_scrambler,
    \ilas_config_data_reg[5] ,
    \ilas_config_data_reg[5]_0 ,
    D,
    \in_data_d1_reg[31]_0 ,
    mem_reg,
    state,
    \in_charisk_d1_reg[3]_1 ,
    \wr_addr_reg[0] ,
    ilas_config_valid_reg_0,
    ilas_config_valid_reg_1,
    state_reg,
    clk);
  output [17:0]data_scrambled_s;
  output [23:0]data_aligned_s;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3]_0 ;
  output [0:0]SS;
  output ilas_config_valid_reg;
  output ifs_ready_reg;
  output [0:0]WEBWE;
  input cfg_disable_scrambler;
  input \ilas_config_data_reg[5] ;
  input \ilas_config_data_reg[5]_0 ;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31]_0 ;
  input [0:0]mem_reg;
  input state;
  input [3:0]\in_charisk_d1_reg[3]_1 ;
  input \wr_addr_reg[0] ;
  input ilas_config_valid_reg_0;
  input ilas_config_valid_reg_1;
  input state_reg;
  input clk;

  wire [7:0]D;
  wire [7:0]Q;
  wire [0:0]SS;
  wire [0:0]WEBWE;
  wire cfg_disable_scrambler;
  wire [1:1]charisk28_aligned_s;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [17:0]data_scrambled_s;
  wire ifs_ready_reg;
  wire \ilas_config_data_reg[5] ;
  wire \ilas_config_data_reg[5]_0 ;
  wire ilas_config_valid_i_3__0_n_0;
  wire ilas_config_valid_i_5__0_n_0;
  wire ilas_config_valid_reg;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire [2:0]in_charisk_d1;
  wire [0:0]\in_charisk_d1_reg[3]_0 ;
  wire [3:0]\in_charisk_d1_reg[3]_1 ;
  wire [23:0]in_data_d1;
  wire [31:0]\in_data_d1_reg[31]_0 ;
  wire [0:0]mem_reg;
  wire state;
  wire \state[14]_i_3_n_0 ;
  wire state_reg;
  wire \wr_addr_reg[0] ;

  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[0]_i_1__0 
       (.I0(in_data_d1[16]),
        .I1(Q[0]),
        .I2(in_data_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[8]),
        .O(data_aligned_s[0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[10]_i_1__0 
       (.I0(Q[2]),
        .I1(\in_data_d1_reg[31]_0 [2]),
        .I2(in_data_d1[10]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[18]),
        .O(data_aligned_s[10]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[11]_i_1__0 
       (.I0(Q[3]),
        .I1(\in_data_d1_reg[31]_0 [3]),
        .I2(in_data_d1[11]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[19]),
        .O(data_aligned_s[11]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[12]_i_1__0 
       (.I0(Q[4]),
        .I1(\in_data_d1_reg[31]_0 [4]),
        .I2(in_data_d1[12]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[20]),
        .O(data_aligned_s[12]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[13]_i_1__0 
       (.I0(Q[5]),
        .I1(\in_data_d1_reg[31]_0 [5]),
        .I2(in_data_d1[13]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[21]),
        .O(data_aligned_s[13]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[14]_i_1__0 
       (.I0(Q[6]),
        .I1(\in_data_d1_reg[31]_0 [6]),
        .I2(in_data_d1[14]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[22]),
        .O(data_aligned_s[14]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[15]_i_1__0 
       (.I0(Q[7]),
        .I1(\in_data_d1_reg[31]_0 [7]),
        .I2(in_data_d1[15]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[23]),
        .O(data_aligned_s[15]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[16]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [0]),
        .I1(\in_data_d1_reg[31]_0 [8]),
        .I2(in_data_d1[16]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[0]),
        .O(data_aligned_s[16]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[17]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [1]),
        .I1(\in_data_d1_reg[31]_0 [9]),
        .I2(in_data_d1[17]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[1]),
        .O(data_aligned_s[17]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[18]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [2]),
        .I1(\in_data_d1_reg[31]_0 [10]),
        .I2(in_data_d1[18]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[2]),
        .O(data_aligned_s[18]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[19]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [3]),
        .I1(\in_data_d1_reg[31]_0 [11]),
        .I2(in_data_d1[19]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[3]),
        .O(data_aligned_s[19]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[1]_i_1__0 
       (.I0(in_data_d1[17]),
        .I1(Q[1]),
        .I2(in_data_d1[1]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[9]),
        .O(data_aligned_s[1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[20]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [4]),
        .I1(\in_data_d1_reg[31]_0 [12]),
        .I2(in_data_d1[20]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[4]),
        .O(data_aligned_s[20]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[21]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [5]),
        .I1(\in_data_d1_reg[31]_0 [13]),
        .I2(in_data_d1[21]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[5]),
        .O(data_aligned_s[21]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[22]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [6]),
        .I1(\in_data_d1_reg[31]_0 [14]),
        .I2(in_data_d1[22]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[6]),
        .O(data_aligned_s[22]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[23]_i_1__0 
       (.I0(\in_data_d1_reg[31]_0 [7]),
        .I1(\in_data_d1_reg[31]_0 [15]),
        .I2(in_data_d1[23]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(Q[7]),
        .O(data_aligned_s[23]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[2]_i_1__0 
       (.I0(in_data_d1[18]),
        .I1(Q[2]),
        .I2(in_data_d1[2]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[10]),
        .O(data_aligned_s[2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[3]_i_1__0 
       (.I0(in_data_d1[19]),
        .I1(Q[3]),
        .I2(in_data_d1[3]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[11]),
        .O(data_aligned_s[3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[4]_i_1__0 
       (.I0(in_data_d1[20]),
        .I1(Q[4]),
        .I2(in_data_d1[4]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[12]),
        .O(data_aligned_s[4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[5]_i_1__0 
       (.I0(in_data_d1[21]),
        .I1(Q[5]),
        .I2(in_data_d1[5]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[13]),
        .O(data_aligned_s[5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[6]_i_1__0 
       (.I0(in_data_d1[22]),
        .I1(Q[6]),
        .I2(in_data_d1[6]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[14]),
        .O(data_aligned_s[6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[7]_i_1__0 
       (.I0(in_data_d1[23]),
        .I1(Q[7]),
        .I2(in_data_d1[7]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[15]),
        .O(data_aligned_s[7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[8]_i_1__0 
       (.I0(Q[0]),
        .I1(\in_data_d1_reg[31]_0 [0]),
        .I2(in_data_d1[8]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[16]),
        .O(data_aligned_s[8]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[9]_i_1__0 
       (.I0(Q[1]),
        .I1(\in_data_d1_reg[31]_0 [1]),
        .I2(in_data_d1[9]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_data_d1[17]),
        .O(data_aligned_s[9]));
  LUT6 #(
    .INIT(64'hFE22022200000000)) 
    ilas_config_valid_i_1__0
       (.I0(ilas_config_valid_reg_0),
        .I1(ilas_config_valid_reg_1),
        .I2(ilas_config_valid_i_3__0_n_0),
        .I3(charisk28_aligned_s),
        .I4(ilas_config_valid_i_5__0_n_0),
        .I5(state_reg),
        .O(ilas_config_valid_reg));
  (* SOFT_HLUTNM = "soft_lutpair44" *) 
  LUT4 #(
    .INIT(16'h0400)) 
    ilas_config_valid_i_3__0
       (.I0(data_aligned_s[14]),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[13]),
        .I3(state),
        .O(ilas_config_valid_i_3__0_n_0));
  LUT6 #(
    .INIT(64'hFFAACCF000AACCF0)) 
    ilas_config_valid_i_4__0
       (.I0(\in_charisk_d1_reg[3]_0 ),
        .I1(in_charisk_d1[2]),
        .I2(in_charisk_d1[1]),
        .I3(\ilas_config_data_reg[5]_0 ),
        .I4(\ilas_config_data_reg[5] ),
        .I5(\in_charisk_d1_reg[3]_1 [0]),
        .O(charisk28_aligned_s));
  (* SOFT_HLUTNM = "soft_lutpair44" *) 
  LUT3 #(
    .INIT(8'h10)) 
    ilas_config_valid_i_5__0
       (.I0(data_aligned_s[13]),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .O(ilas_config_valid_i_5__0_n_0));
  FDRE \in_charisk_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [0]),
        .Q(in_charisk_d1[0]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [1]),
        .Q(in_charisk_d1[1]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [2]),
        .Q(in_charisk_d1[2]),
        .R(1'b0));
  FDRE \in_charisk_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_charisk_d1_reg[3]_1 [3]),
        .Q(\in_charisk_d1_reg[3]_0 ),
        .R(1'b0));
  FDRE \in_data_d1_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [0]),
        .Q(in_data_d1[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [10]),
        .Q(in_data_d1[10]),
        .R(1'b0));
  FDRE \in_data_d1_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [11]),
        .Q(in_data_d1[11]),
        .R(1'b0));
  FDRE \in_data_d1_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [12]),
        .Q(in_data_d1[12]),
        .R(1'b0));
  FDRE \in_data_d1_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [13]),
        .Q(in_data_d1[13]),
        .R(1'b0));
  FDRE \in_data_d1_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [14]),
        .Q(in_data_d1[14]),
        .R(1'b0));
  FDRE \in_data_d1_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [15]),
        .Q(in_data_d1[15]),
        .R(1'b0));
  FDRE \in_data_d1_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [16]),
        .Q(in_data_d1[16]),
        .R(1'b0));
  FDRE \in_data_d1_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [17]),
        .Q(in_data_d1[17]),
        .R(1'b0));
  FDRE \in_data_d1_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [18]),
        .Q(in_data_d1[18]),
        .R(1'b0));
  FDRE \in_data_d1_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [19]),
        .Q(in_data_d1[19]),
        .R(1'b0));
  FDRE \in_data_d1_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [1]),
        .Q(in_data_d1[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [20]),
        .Q(in_data_d1[20]),
        .R(1'b0));
  FDRE \in_data_d1_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [21]),
        .Q(in_data_d1[21]),
        .R(1'b0));
  FDRE \in_data_d1_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [22]),
        .Q(in_data_d1[22]),
        .R(1'b0));
  FDRE \in_data_d1_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [23]),
        .Q(in_data_d1[23]),
        .R(1'b0));
  FDRE \in_data_d1_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [24]),
        .Q(Q[0]),
        .R(1'b0));
  FDRE \in_data_d1_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [25]),
        .Q(Q[1]),
        .R(1'b0));
  FDRE \in_data_d1_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [26]),
        .Q(Q[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [27]),
        .Q(Q[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [28]),
        .Q(Q[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [29]),
        .Q(Q[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [2]),
        .Q(in_data_d1[2]),
        .R(1'b0));
  FDRE \in_data_d1_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [30]),
        .Q(Q[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [31]),
        .Q(Q[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [3]),
        .Q(in_data_d1[3]),
        .R(1'b0));
  FDRE \in_data_d1_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [4]),
        .Q(in_data_d1[4]),
        .R(1'b0));
  FDRE \in_data_d1_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [5]),
        .Q(in_data_d1[5]),
        .R(1'b0));
  FDRE \in_data_d1_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [6]),
        .Q(in_data_d1[6]),
        .R(1'b0));
  FDRE \in_data_d1_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [7]),
        .Q(in_data_d1[7]),
        .R(1'b0));
  FDRE \in_data_d1_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [8]),
        .Q(in_data_d1[8]),
        .R(1'b0));
  FDRE \in_data_d1_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_data_d1_reg[31]_0 [9]),
        .Q(in_data_d1[9]),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_17__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[14]),
        .I3(D[7]),
        .O(data_scrambled_s[17]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_18__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[13]),
        .I2(data_aligned_s[12]),
        .I3(D[6]),
        .O(data_scrambled_s[16]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_19__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[12]),
        .I2(data_aligned_s[11]),
        .I3(D[5]),
        .O(data_scrambled_s[15]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_20__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[11]),
        .I2(data_aligned_s[10]),
        .I3(D[4]),
        .O(data_scrambled_s[14]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_21__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[10]),
        .I2(data_aligned_s[9]),
        .I3(D[3]),
        .O(data_scrambled_s[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_22__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[9]),
        .I2(data_aligned_s[8]),
        .I3(D[2]),
        .O(data_scrambled_s[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_23__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[8]),
        .I3(D[1]),
        .O(data_scrambled_s[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_24__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[23]),
        .I2(data_aligned_s[22]),
        .I3(D[0]),
        .O(data_scrambled_s[10]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_25__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[5]),
        .I2(data_aligned_s[23]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_26__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[5]),
        .I3(data_aligned_s[22]),
        .O(data_scrambled_s[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_27__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[4]),
        .I2(data_aligned_s[3]),
        .I3(data_aligned_s[21]),
        .O(data_scrambled_s[7]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_28__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[3]),
        .I2(data_aligned_s[2]),
        .I3(data_aligned_s[20]),
        .O(data_scrambled_s[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_29__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[2]),
        .I2(data_aligned_s[1]),
        .I3(data_aligned_s[19]),
        .O(data_scrambled_s[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_30__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[1]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[18]),
        .O(data_scrambled_s[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_31__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[15]),
        .I2(data_aligned_s[0]),
        .I3(data_aligned_s[17]),
        .O(data_scrambled_s[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_32__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[14]),
        .I2(data_aligned_s[15]),
        .I3(data_aligned_s[16]),
        .O(data_scrambled_s[2]));
  LUT1 #(
    .INIT(2'h1)) 
    mem_reg_i_33
       (.I0(SS),
        .O(WEBWE));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_7__0
       (.I0(cfg_disable_scrambler),
        .I1(mem_reg),
        .I2(data_aligned_s[9]),
        .I3(data_aligned_s[7]),
        .O(data_scrambled_s[1]));
  LUT4 #(
    .INIT(16'hE1B4)) 
    mem_reg_i_8__0
       (.I0(cfg_disable_scrambler),
        .I1(data_aligned_s[7]),
        .I2(data_aligned_s[8]),
        .I3(data_aligned_s[6]),
        .O(data_scrambled_s[0]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAAAEA)) 
    \state[14]_i_1__0 
       (.I0(\wr_addr_reg[0] ),
        .I1(state),
        .I2(\state[14]_i_3_n_0 ),
        .I3(data_aligned_s[5]),
        .I4(data_aligned_s[6]),
        .I5(data_aligned_s[7]),
        .O(SS));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \state[14]_i_3 
       (.I0(in_charisk_d1[2]),
        .I1(\in_charisk_d1_reg[3]_0 ),
        .I2(in_charisk_d1[0]),
        .I3(\ilas_config_data_reg[5] ),
        .I4(\ilas_config_data_reg[5]_0 ),
        .I5(in_charisk_d1[1]),
        .O(\state[14]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'hB)) 
    state_i_1
       (.I0(SS),
        .I1(state_reg),
        .O(ifs_ready_reg));
endmodule

(* ORIG_REF_NAME = "elastic_buffer" *) 
module jesd204_rx_0_elastic_buffer
   (rx_data,
    buffer_release_n_reg,
    buffer_release_n,
    clk,
    data_scrambled_s,
    WEBWE,
    SR);
  output [31:0]rx_data;
  output buffer_release_n_reg;
  input buffer_release_n;
  input clk;
  input [31:0]data_scrambled_s;
  input [0:0]WEBWE;
  input [0:0]SR;

  wire [0:0]SR;
  wire [0:0]WEBWE;
  wire buffer_release_n;
  wire buffer_release_n_reg;
  wire clk;
  wire [31:0]data_scrambled_s;
  wire [6:0]p_0_in;
  wire [6:0]rd_addr;
  wire \rd_addr[0]_i_1_n_0 ;
  wire \rd_addr[1]_i_1_n_0 ;
  wire \rd_addr[2]_i_1_n_0 ;
  wire \rd_addr[3]_i_1_n_0 ;
  wire \rd_addr[4]_i_1_n_0 ;
  wire \rd_addr[5]_i_1_n_0 ;
  wire \rd_addr[6]_i_1_n_0 ;
  wire \rd_addr[6]_i_2_n_0 ;
  wire [31:0]rx_data;
  wire \wr_addr[6]_i_2__2_n_0 ;
  wire [6:0]wr_addr_reg;
  wire [1:0]NLW_mem_reg_DOPADOP_UNCONNECTED;
  wire [1:0]NLW_mem_reg_DOPBDOP_UNCONNECTED;

  (* \MEM.PORTA.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* \MEM.PORTB.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "4096" *) 
  (* RTL_RAM_NAME = "mode_8b10b.gen_lane[3].i_lane/i_elastic_buffer/mem" *) 
  (* bram_addr_begin = "0" *) 
  (* bram_addr_end = "511" *) 
  (* bram_slice_begin = "0" *) 
  (* bram_slice_end = "31" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "511" *) 
  (* ram_offset = "384" *) 
  (* ram_slice_begin = "0" *) 
  (* ram_slice_end = "31" *) 
  RAMB18E1 #(
    .DOA_REG(1),
    .DOB_REG(1),
    .INIT_A(18'h00000),
    .INIT_B(18'h00000),
    .RAM_MODE("SDP"),
    .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
    .READ_WIDTH_A(36),
    .READ_WIDTH_B(0),
    .RSTREG_PRIORITY_A("RSTREG"),
    .RSTREG_PRIORITY_B("RSTREG"),
    .SIM_COLLISION_CHECK("ALL"),
    .SIM_DEVICE("7SERIES"),
    .SRVAL_A(18'h00000),
    .SRVAL_B(18'h00000),
    .WRITE_MODE_A("READ_FIRST"),
    .WRITE_MODE_B("READ_FIRST"),
    .WRITE_WIDTH_A(0),
    .WRITE_WIDTH_B(36)) 
    mem_reg
       (.ADDRARDADDR({1'b1,1'b1,rd_addr,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .ADDRBWRADDR({1'b1,1'b1,wr_addr_reg,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),
        .DIADI(data_scrambled_s[15:0]),
        .DIBDI(data_scrambled_s[31:16]),
        .DIPADIP({1'b1,1'b1}),
        .DIPBDIP({1'b1,1'b1}),
        .DOADO(rx_data[15:0]),
        .DOBDO(rx_data[31:16]),
        .DOPADOP(NLW_mem_reg_DOPADOP_UNCONNECTED[1:0]),
        .DOPBDOP(NLW_mem_reg_DOPBDOP_UNCONNECTED[1:0]),
        .ENARDEN(buffer_release_n_reg),
        .ENBWREN(1'b1),
        .REGCEAREGCE(1'b1),
        .REGCEB(1'b0),
        .RSTRAMARSTRAM(1'b0),
        .RSTRAMB(1'b0),
        .RSTREGARSTREG(1'b0),
        .RSTREGB(1'b0),
        .WEA({1'b0,1'b0}),
        .WEBWE({WEBWE,WEBWE,WEBWE,WEBWE}));
  LUT1 #(
    .INIT(2'h1)) 
    mem_reg_i_1__2
       (.I0(buffer_release_n),
        .O(buffer_release_n_reg));
  (* SOFT_HLUTNM = "soft_lutpair77" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \rd_addr[0]_i_1 
       (.I0(rd_addr[0]),
        .O(\rd_addr[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair77" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr[1]_i_1 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .O(\rd_addr[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair75" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \rd_addr[2]_i_1 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .I2(rd_addr[2]),
        .O(\rd_addr[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair75" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \rd_addr[3]_i_1 
       (.I0(rd_addr[1]),
        .I1(rd_addr[0]),
        .I2(rd_addr[2]),
        .I3(rd_addr[3]),
        .O(\rd_addr[3]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair73" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \rd_addr[4]_i_1 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[4]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \rd_addr[5]_i_1 
       (.I0(rd_addr[4]),
        .I1(rd_addr[3]),
        .I2(rd_addr[1]),
        .I3(rd_addr[0]),
        .I4(rd_addr[2]),
        .I5(rd_addr[5]),
        .O(\rd_addr[5]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'hD2)) 
    \rd_addr[6]_i_1 
       (.I0(rd_addr[5]),
        .I1(\rd_addr[6]_i_2_n_0 ),
        .I2(rd_addr[6]),
        .O(\rd_addr[6]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair73" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \rd_addr[6]_i_2 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[6]_i_2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[0]_i_1_n_0 ),
        .Q(rd_addr[0]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[1]_i_1_n_0 ),
        .Q(rd_addr[1]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[2]_i_1_n_0 ),
        .Q(rd_addr[2]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[3]_i_1_n_0 ),
        .Q(rd_addr[3]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[4]_i_1_n_0 ),
        .Q(rd_addr[4]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[5]_i_1_n_0 ),
        .Q(rd_addr[5]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[6]_i_1_n_0 ),
        .Q(rd_addr[6]),
        .R(buffer_release_n));
  (* SOFT_HLUTNM = "soft_lutpair76" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \wr_addr[0]_i_1__2 
       (.I0(wr_addr_reg[0]),
        .O(p_0_in[0]));
  (* SOFT_HLUTNM = "soft_lutpair76" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr[1]_i_1__2 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .O(p_0_in[1]));
  (* SOFT_HLUTNM = "soft_lutpair74" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \wr_addr[2]_i_1__2 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .I2(wr_addr_reg[2]),
        .O(p_0_in[2]));
  (* SOFT_HLUTNM = "soft_lutpair74" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \wr_addr[3]_i_1__2 
       (.I0(wr_addr_reg[1]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[2]),
        .I3(wr_addr_reg[3]),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair72" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \wr_addr[4]_i_1__2 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(p_0_in[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \wr_addr[5]_i_1__2 
       (.I0(wr_addr_reg[4]),
        .I1(wr_addr_reg[3]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[0]),
        .I4(wr_addr_reg[2]),
        .I5(wr_addr_reg[5]),
        .O(p_0_in[5]));
  LUT3 #(
    .INIT(8'hD2)) 
    \wr_addr[6]_i_1__2 
       (.I0(wr_addr_reg[5]),
        .I1(\wr_addr[6]_i_2__2_n_0 ),
        .I2(wr_addr_reg[6]),
        .O(p_0_in[6]));
  (* SOFT_HLUTNM = "soft_lutpair72" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \wr_addr[6]_i_2__2 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(\wr_addr[6]_i_2__2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[0]),
        .Q(wr_addr_reg[0]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[1]),
        .Q(wr_addr_reg[1]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[2]),
        .Q(wr_addr_reg[2]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[3]),
        .Q(wr_addr_reg[3]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[4]),
        .Q(wr_addr_reg[4]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[5]),
        .Q(wr_addr_reg[5]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[6]),
        .Q(wr_addr_reg[6]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "elastic_buffer" *) 
module jesd204_rx_0_elastic_buffer_11
   (rx_data,
    buffer_release_n,
    clk,
    mem_reg_0,
    data_scrambled_s,
    WEBWE,
    SR);
  output [31:0]rx_data;
  input buffer_release_n;
  input clk;
  input mem_reg_0;
  input [31:0]data_scrambled_s;
  input [0:0]WEBWE;
  input [0:0]SR;

  wire [0:0]SR;
  wire [0:0]WEBWE;
  wire buffer_release_n;
  wire clk;
  wire [31:0]data_scrambled_s;
  wire mem_reg_0;
  wire [6:0]p_0_in;
  wire [6:0]rd_addr;
  wire \rd_addr[0]_i_1__1_n_0 ;
  wire \rd_addr[1]_i_1__1_n_0 ;
  wire \rd_addr[2]_i_1__1_n_0 ;
  wire \rd_addr[3]_i_1__1_n_0 ;
  wire \rd_addr[4]_i_1__1_n_0 ;
  wire \rd_addr[5]_i_1__1_n_0 ;
  wire \rd_addr[6]_i_1__1_n_0 ;
  wire \rd_addr[6]_i_2__1_n_0 ;
  wire [31:0]rx_data;
  wire \wr_addr[6]_i_2__0_n_0 ;
  wire [6:0]wr_addr_reg;
  wire [1:0]NLW_mem_reg_DOPADOP_UNCONNECTED;
  wire [1:0]NLW_mem_reg_DOPBDOP_UNCONNECTED;

  (* \MEM.PORTA.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* \MEM.PORTB.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "4096" *) 
  (* RTL_RAM_NAME = "mode_8b10b.gen_lane[1].i_lane/i_elastic_buffer/mem" *) 
  (* bram_addr_begin = "0" *) 
  (* bram_addr_end = "511" *) 
  (* bram_slice_begin = "0" *) 
  (* bram_slice_end = "31" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "511" *) 
  (* ram_offset = "384" *) 
  (* ram_slice_begin = "0" *) 
  (* ram_slice_end = "31" *) 
  RAMB18E1 #(
    .DOA_REG(1),
    .DOB_REG(1),
    .INIT_A(18'h00000),
    .INIT_B(18'h00000),
    .RAM_MODE("SDP"),
    .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
    .READ_WIDTH_A(36),
    .READ_WIDTH_B(0),
    .RSTREG_PRIORITY_A("RSTREG"),
    .RSTREG_PRIORITY_B("RSTREG"),
    .SIM_COLLISION_CHECK("ALL"),
    .SIM_DEVICE("7SERIES"),
    .SRVAL_A(18'h00000),
    .SRVAL_B(18'h00000),
    .WRITE_MODE_A("READ_FIRST"),
    .WRITE_MODE_B("READ_FIRST"),
    .WRITE_WIDTH_A(0),
    .WRITE_WIDTH_B(36)) 
    mem_reg
       (.ADDRARDADDR({1'b1,1'b1,rd_addr,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .ADDRBWRADDR({1'b1,1'b1,wr_addr_reg,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),
        .DIADI(data_scrambled_s[15:0]),
        .DIBDI(data_scrambled_s[31:16]),
        .DIPADIP({1'b1,1'b1}),
        .DIPBDIP({1'b1,1'b1}),
        .DOADO(rx_data[15:0]),
        .DOBDO(rx_data[31:16]),
        .DOPADOP(NLW_mem_reg_DOPADOP_UNCONNECTED[1:0]),
        .DOPBDOP(NLW_mem_reg_DOPBDOP_UNCONNECTED[1:0]),
        .ENARDEN(mem_reg_0),
        .ENBWREN(1'b1),
        .REGCEAREGCE(1'b1),
        .REGCEB(1'b0),
        .RSTRAMARSTRAM(1'b0),
        .RSTRAMB(1'b0),
        .RSTREGARSTREG(1'b0),
        .RSTREGB(1'b0),
        .WEA({1'b0,1'b0}),
        .WEBWE({WEBWE,WEBWE,WEBWE,WEBWE}));
  (* SOFT_HLUTNM = "soft_lutpair52" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \rd_addr[0]_i_1__1 
       (.I0(rd_addr[0]),
        .O(\rd_addr[0]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair52" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr[1]_i_1__1 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .O(\rd_addr[1]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair50" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \rd_addr[2]_i_1__1 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .I2(rd_addr[2]),
        .O(\rd_addr[2]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair50" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \rd_addr[3]_i_1__1 
       (.I0(rd_addr[1]),
        .I1(rd_addr[0]),
        .I2(rd_addr[2]),
        .I3(rd_addr[3]),
        .O(\rd_addr[3]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair48" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \rd_addr[4]_i_1__1 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[4]_i_1__1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \rd_addr[5]_i_1__1 
       (.I0(rd_addr[4]),
        .I1(rd_addr[3]),
        .I2(rd_addr[1]),
        .I3(rd_addr[0]),
        .I4(rd_addr[2]),
        .I5(rd_addr[5]),
        .O(\rd_addr[5]_i_1__1_n_0 ));
  LUT3 #(
    .INIT(8'hD2)) 
    \rd_addr[6]_i_1__1 
       (.I0(rd_addr[5]),
        .I1(\rd_addr[6]_i_2__1_n_0 ),
        .I2(rd_addr[6]),
        .O(\rd_addr[6]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair48" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \rd_addr[6]_i_2__1 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[6]_i_2__1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[0]_i_1__1_n_0 ),
        .Q(rd_addr[0]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[1]_i_1__1_n_0 ),
        .Q(rd_addr[1]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[2]_i_1__1_n_0 ),
        .Q(rd_addr[2]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[3]_i_1__1_n_0 ),
        .Q(rd_addr[3]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[4]_i_1__1_n_0 ),
        .Q(rd_addr[4]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[5]_i_1__1_n_0 ),
        .Q(rd_addr[5]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[6]_i_1__1_n_0 ),
        .Q(rd_addr[6]),
        .R(buffer_release_n));
  (* SOFT_HLUTNM = "soft_lutpair51" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \wr_addr[0]_i_1__0 
       (.I0(wr_addr_reg[0]),
        .O(p_0_in[0]));
  (* SOFT_HLUTNM = "soft_lutpair51" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr[1]_i_1__0 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .O(p_0_in[1]));
  (* SOFT_HLUTNM = "soft_lutpair49" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \wr_addr[2]_i_1__0 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .I2(wr_addr_reg[2]),
        .O(p_0_in[2]));
  (* SOFT_HLUTNM = "soft_lutpair49" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \wr_addr[3]_i_1__0 
       (.I0(wr_addr_reg[1]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[2]),
        .I3(wr_addr_reg[3]),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair47" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \wr_addr[4]_i_1__0 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(p_0_in[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \wr_addr[5]_i_1__0 
       (.I0(wr_addr_reg[4]),
        .I1(wr_addr_reg[3]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[0]),
        .I4(wr_addr_reg[2]),
        .I5(wr_addr_reg[5]),
        .O(p_0_in[5]));
  LUT3 #(
    .INIT(8'hD2)) 
    \wr_addr[6]_i_1__0 
       (.I0(wr_addr_reg[5]),
        .I1(\wr_addr[6]_i_2__0_n_0 ),
        .I2(wr_addr_reg[6]),
        .O(p_0_in[6]));
  (* SOFT_HLUTNM = "soft_lutpair47" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \wr_addr[6]_i_2__0 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(\wr_addr[6]_i_2__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[0]),
        .Q(wr_addr_reg[0]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[1]),
        .Q(wr_addr_reg[1]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[2]),
        .Q(wr_addr_reg[2]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[3]),
        .Q(wr_addr_reg[3]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[4]),
        .Q(wr_addr_reg[4]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[5]),
        .Q(wr_addr_reg[5]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[6]),
        .Q(wr_addr_reg[6]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "elastic_buffer" *) 
module jesd204_rx_0_elastic_buffer_16
   (rx_data,
    clk,
    mem_reg_0,
    data_scrambled_s,
    WEBWE,
    buffer_release_n,
    SR);
  output [31:0]rx_data;
  input clk;
  input mem_reg_0;
  input [31:0]data_scrambled_s;
  input [0:0]WEBWE;
  input buffer_release_n;
  input [0:0]SR;

  wire [0:0]SR;
  wire [0:0]WEBWE;
  wire buffer_release_n;
  wire clk;
  wire [31:0]data_scrambled_s;
  wire mem_reg_0;
  wire [6:0]p_0_in;
  wire [6:0]rd_addr;
  wire \rd_addr[0]_i_1__2_n_0 ;
  wire \rd_addr[1]_i_1__2_n_0 ;
  wire \rd_addr[2]_i_1__2_n_0 ;
  wire \rd_addr[3]_i_1__2_n_0 ;
  wire \rd_addr[4]_i_1__2_n_0 ;
  wire \rd_addr[5]_i_1__2_n_0 ;
  wire \rd_addr[6]_i_1__2_n_0 ;
  wire \rd_addr[6]_i_2__2_n_0 ;
  wire [31:0]rx_data;
  wire \wr_addr[6]_i_2_n_0 ;
  wire [6:0]wr_addr_reg;
  wire [1:0]NLW_mem_reg_DOPADOP_UNCONNECTED;
  wire [1:0]NLW_mem_reg_DOPBDOP_UNCONNECTED;

  (* \MEM.PORTA.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* \MEM.PORTB.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "4096" *) 
  (* RTL_RAM_NAME = "mode_8b10b.gen_lane[0].i_lane/i_elastic_buffer/mem" *) 
  (* bram_addr_begin = "0" *) 
  (* bram_addr_end = "511" *) 
  (* bram_slice_begin = "0" *) 
  (* bram_slice_end = "31" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "511" *) 
  (* ram_offset = "384" *) 
  (* ram_slice_begin = "0" *) 
  (* ram_slice_end = "31" *) 
  RAMB18E1 #(
    .DOA_REG(1),
    .DOB_REG(1),
    .INIT_A(18'h00000),
    .INIT_B(18'h00000),
    .RAM_MODE("SDP"),
    .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
    .READ_WIDTH_A(36),
    .READ_WIDTH_B(0),
    .RSTREG_PRIORITY_A("RSTREG"),
    .RSTREG_PRIORITY_B("RSTREG"),
    .SIM_COLLISION_CHECK("ALL"),
    .SIM_DEVICE("7SERIES"),
    .SRVAL_A(18'h00000),
    .SRVAL_B(18'h00000),
    .WRITE_MODE_A("READ_FIRST"),
    .WRITE_MODE_B("READ_FIRST"),
    .WRITE_WIDTH_A(0),
    .WRITE_WIDTH_B(36)) 
    mem_reg
       (.ADDRARDADDR({1'b1,1'b1,rd_addr,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .ADDRBWRADDR({1'b1,1'b1,wr_addr_reg,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),
        .DIADI(data_scrambled_s[15:0]),
        .DIBDI(data_scrambled_s[31:16]),
        .DIPADIP({1'b1,1'b1}),
        .DIPBDIP({1'b1,1'b1}),
        .DOADO(rx_data[15:0]),
        .DOBDO(rx_data[31:16]),
        .DOPADOP(NLW_mem_reg_DOPADOP_UNCONNECTED[1:0]),
        .DOPBDOP(NLW_mem_reg_DOPBDOP_UNCONNECTED[1:0]),
        .ENARDEN(mem_reg_0),
        .ENBWREN(1'b1),
        .REGCEAREGCE(1'b1),
        .REGCEB(1'b0),
        .RSTRAMARSTRAM(1'b0),
        .RSTRAMB(1'b0),
        .RSTREGARSTREG(1'b0),
        .RSTREGB(1'b0),
        .WEA({1'b0,1'b0}),
        .WEBWE({WEBWE,WEBWE,WEBWE,WEBWE}));
  (* SOFT_HLUTNM = "soft_lutpair41" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \rd_addr[0]_i_1__2 
       (.I0(rd_addr[0]),
        .O(\rd_addr[0]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair41" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr[1]_i_1__2 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .O(\rd_addr[1]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair39" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \rd_addr[2]_i_1__2 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .I2(rd_addr[2]),
        .O(\rd_addr[2]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair39" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \rd_addr[3]_i_1__2 
       (.I0(rd_addr[1]),
        .I1(rd_addr[0]),
        .I2(rd_addr[2]),
        .I3(rd_addr[3]),
        .O(\rd_addr[3]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair37" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \rd_addr[4]_i_1__2 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[4]_i_1__2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \rd_addr[5]_i_1__2 
       (.I0(rd_addr[4]),
        .I1(rd_addr[3]),
        .I2(rd_addr[1]),
        .I3(rd_addr[0]),
        .I4(rd_addr[2]),
        .I5(rd_addr[5]),
        .O(\rd_addr[5]_i_1__2_n_0 ));
  LUT3 #(
    .INIT(8'hD2)) 
    \rd_addr[6]_i_1__2 
       (.I0(rd_addr[5]),
        .I1(\rd_addr[6]_i_2__2_n_0 ),
        .I2(rd_addr[6]),
        .O(\rd_addr[6]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair37" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \rd_addr[6]_i_2__2 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[6]_i_2__2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[0]_i_1__2_n_0 ),
        .Q(rd_addr[0]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[1]_i_1__2_n_0 ),
        .Q(rd_addr[1]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[2]_i_1__2_n_0 ),
        .Q(rd_addr[2]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[3]_i_1__2_n_0 ),
        .Q(rd_addr[3]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[4]_i_1__2_n_0 ),
        .Q(rd_addr[4]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[5]_i_1__2_n_0 ),
        .Q(rd_addr[5]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[6]_i_1__2_n_0 ),
        .Q(rd_addr[6]),
        .R(buffer_release_n));
  (* SOFT_HLUTNM = "soft_lutpair40" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \wr_addr[0]_i_1 
       (.I0(wr_addr_reg[0]),
        .O(p_0_in[0]));
  (* SOFT_HLUTNM = "soft_lutpair40" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr[1]_i_1 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .O(p_0_in[1]));
  (* SOFT_HLUTNM = "soft_lutpair38" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \wr_addr[2]_i_1 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .I2(wr_addr_reg[2]),
        .O(p_0_in[2]));
  (* SOFT_HLUTNM = "soft_lutpair38" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \wr_addr[3]_i_1 
       (.I0(wr_addr_reg[1]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[2]),
        .I3(wr_addr_reg[3]),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair36" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \wr_addr[4]_i_1 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(p_0_in[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \wr_addr[5]_i_1 
       (.I0(wr_addr_reg[4]),
        .I1(wr_addr_reg[3]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[0]),
        .I4(wr_addr_reg[2]),
        .I5(wr_addr_reg[5]),
        .O(p_0_in[5]));
  LUT3 #(
    .INIT(8'hD2)) 
    \wr_addr[6]_i_1 
       (.I0(wr_addr_reg[5]),
        .I1(\wr_addr[6]_i_2_n_0 ),
        .I2(wr_addr_reg[6]),
        .O(p_0_in[6]));
  (* SOFT_HLUTNM = "soft_lutpair36" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \wr_addr[6]_i_2 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(\wr_addr[6]_i_2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[0]),
        .Q(wr_addr_reg[0]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[1]),
        .Q(wr_addr_reg[1]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[2]),
        .Q(wr_addr_reg[2]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[3]),
        .Q(wr_addr_reg[3]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[4]),
        .Q(wr_addr_reg[4]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[5]),
        .Q(wr_addr_reg[5]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[6]),
        .Q(wr_addr_reg[6]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "elastic_buffer" *) 
module jesd204_rx_0_elastic_buffer_6
   (rx_data,
    buffer_release_n,
    clk,
    mem_reg_0,
    data_scrambled_s,
    WEBWE,
    SR);
  output [31:0]rx_data;
  input buffer_release_n;
  input clk;
  input mem_reg_0;
  input [31:0]data_scrambled_s;
  input [0:0]WEBWE;
  input [0:0]SR;

  wire [0:0]SR;
  wire [0:0]WEBWE;
  wire buffer_release_n;
  wire clk;
  wire [31:0]data_scrambled_s;
  wire mem_reg_0;
  wire [6:0]p_0_in;
  wire [6:0]rd_addr;
  wire \rd_addr[0]_i_1__0_n_0 ;
  wire \rd_addr[1]_i_1__0_n_0 ;
  wire \rd_addr[2]_i_1__0_n_0 ;
  wire \rd_addr[3]_i_1__0_n_0 ;
  wire \rd_addr[4]_i_1__0_n_0 ;
  wire \rd_addr[5]_i_1__0_n_0 ;
  wire \rd_addr[6]_i_1__0_n_0 ;
  wire \rd_addr[6]_i_2__0_n_0 ;
  wire [31:0]rx_data;
  wire \wr_addr[6]_i_2__1_n_0 ;
  wire [6:0]wr_addr_reg;
  wire [1:0]NLW_mem_reg_DOPADOP_UNCONNECTED;
  wire [1:0]NLW_mem_reg_DOPBDOP_UNCONNECTED;

  (* \MEM.PORTA.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* \MEM.PORTB.DATA_BIT_LAYOUT  = "p0_d32" *) 
  (* METHODOLOGY_DRC_VIOS = "" *) 
  (* RTL_RAM_BITS = "4096" *) 
  (* RTL_RAM_NAME = "mode_8b10b.gen_lane[2].i_lane/i_elastic_buffer/mem" *) 
  (* bram_addr_begin = "0" *) 
  (* bram_addr_end = "511" *) 
  (* bram_slice_begin = "0" *) 
  (* bram_slice_end = "31" *) 
  (* ram_addr_begin = "0" *) 
  (* ram_addr_end = "511" *) 
  (* ram_offset = "384" *) 
  (* ram_slice_begin = "0" *) 
  (* ram_slice_end = "31" *) 
  RAMB18E1 #(
    .DOA_REG(1),
    .DOB_REG(1),
    .INIT_A(18'h00000),
    .INIT_B(18'h00000),
    .RAM_MODE("SDP"),
    .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
    .READ_WIDTH_A(36),
    .READ_WIDTH_B(0),
    .RSTREG_PRIORITY_A("RSTREG"),
    .RSTREG_PRIORITY_B("RSTREG"),
    .SIM_COLLISION_CHECK("ALL"),
    .SIM_DEVICE("7SERIES"),
    .SRVAL_A(18'h00000),
    .SRVAL_B(18'h00000),
    .WRITE_MODE_A("READ_FIRST"),
    .WRITE_MODE_B("READ_FIRST"),
    .WRITE_WIDTH_A(0),
    .WRITE_WIDTH_B(36)) 
    mem_reg
       (.ADDRARDADDR({1'b1,1'b1,rd_addr,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .ADDRBWRADDR({1'b1,1'b1,wr_addr_reg,1'b1,1'b1,1'b1,1'b1,1'b1}),
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),
        .DIADI(data_scrambled_s[15:0]),
        .DIBDI(data_scrambled_s[31:16]),
        .DIPADIP({1'b1,1'b1}),
        .DIPBDIP({1'b1,1'b1}),
        .DOADO(rx_data[15:0]),
        .DOBDO(rx_data[31:16]),
        .DOPADOP(NLW_mem_reg_DOPADOP_UNCONNECTED[1:0]),
        .DOPBDOP(NLW_mem_reg_DOPBDOP_UNCONNECTED[1:0]),
        .ENARDEN(mem_reg_0),
        .ENBWREN(1'b1),
        .REGCEAREGCE(1'b1),
        .REGCEB(1'b0),
        .RSTRAMARSTRAM(1'b0),
        .RSTRAMB(1'b0),
        .RSTREGARSTREG(1'b0),
        .RSTREGB(1'b0),
        .WEA({1'b0,1'b0}),
        .WEBWE({WEBWE,WEBWE,WEBWE,WEBWE}));
  (* SOFT_HLUTNM = "soft_lutpair65" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \rd_addr[0]_i_1__0 
       (.I0(rd_addr[0]),
        .O(\rd_addr[0]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair65" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \rd_addr[1]_i_1__0 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .O(\rd_addr[1]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair63" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \rd_addr[2]_i_1__0 
       (.I0(rd_addr[0]),
        .I1(rd_addr[1]),
        .I2(rd_addr[2]),
        .O(\rd_addr[2]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair63" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \rd_addr[3]_i_1__0 
       (.I0(rd_addr[1]),
        .I1(rd_addr[0]),
        .I2(rd_addr[2]),
        .I3(rd_addr[3]),
        .O(\rd_addr[3]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair61" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \rd_addr[4]_i_1__0 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[4]_i_1__0_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \rd_addr[5]_i_1__0 
       (.I0(rd_addr[4]),
        .I1(rd_addr[3]),
        .I2(rd_addr[1]),
        .I3(rd_addr[0]),
        .I4(rd_addr[2]),
        .I5(rd_addr[5]),
        .O(\rd_addr[5]_i_1__0_n_0 ));
  LUT3 #(
    .INIT(8'hD2)) 
    \rd_addr[6]_i_1__0 
       (.I0(rd_addr[5]),
        .I1(\rd_addr[6]_i_2__0_n_0 ),
        .I2(rd_addr[6]),
        .O(\rd_addr[6]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair61" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \rd_addr[6]_i_2__0 
       (.I0(rd_addr[2]),
        .I1(rd_addr[0]),
        .I2(rd_addr[1]),
        .I3(rd_addr[3]),
        .I4(rd_addr[4]),
        .O(\rd_addr[6]_i_2__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[0]_i_1__0_n_0 ),
        .Q(rd_addr[0]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[1]_i_1__0_n_0 ),
        .Q(rd_addr[1]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[2]_i_1__0_n_0 ),
        .Q(rd_addr[2]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[3]_i_1__0_n_0 ),
        .Q(rd_addr[3]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[4]_i_1__0_n_0 ),
        .Q(rd_addr[4]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[5]_i_1__0_n_0 ),
        .Q(rd_addr[5]),
        .R(buffer_release_n));
  FDRE #(
    .INIT(1'b0)) 
    \rd_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\rd_addr[6]_i_1__0_n_0 ),
        .Q(rd_addr[6]),
        .R(buffer_release_n));
  (* SOFT_HLUTNM = "soft_lutpair64" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \wr_addr[0]_i_1__1 
       (.I0(wr_addr_reg[0]),
        .O(p_0_in[0]));
  (* SOFT_HLUTNM = "soft_lutpair64" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \wr_addr[1]_i_1__1 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .O(p_0_in[1]));
  (* SOFT_HLUTNM = "soft_lutpair62" *) 
  LUT3 #(
    .INIT(8'h78)) 
    \wr_addr[2]_i_1__1 
       (.I0(wr_addr_reg[0]),
        .I1(wr_addr_reg[1]),
        .I2(wr_addr_reg[2]),
        .O(p_0_in[2]));
  (* SOFT_HLUTNM = "soft_lutpair62" *) 
  LUT4 #(
    .INIT(16'h7F80)) 
    \wr_addr[3]_i_1__1 
       (.I0(wr_addr_reg[1]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[2]),
        .I3(wr_addr_reg[3]),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair60" *) 
  LUT5 #(
    .INIT(32'h7FFF8000)) 
    \wr_addr[4]_i_1__1 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(p_0_in[4]));
  LUT6 #(
    .INIT(64'h7FFFFFFF80000000)) 
    \wr_addr[5]_i_1__1 
       (.I0(wr_addr_reg[4]),
        .I1(wr_addr_reg[3]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[0]),
        .I4(wr_addr_reg[2]),
        .I5(wr_addr_reg[5]),
        .O(p_0_in[5]));
  LUT3 #(
    .INIT(8'hD2)) 
    \wr_addr[6]_i_1__1 
       (.I0(wr_addr_reg[5]),
        .I1(\wr_addr[6]_i_2__1_n_0 ),
        .I2(wr_addr_reg[6]),
        .O(p_0_in[6]));
  (* SOFT_HLUTNM = "soft_lutpair60" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \wr_addr[6]_i_2__1 
       (.I0(wr_addr_reg[2]),
        .I1(wr_addr_reg[0]),
        .I2(wr_addr_reg[1]),
        .I3(wr_addr_reg[3]),
        .I4(wr_addr_reg[4]),
        .O(\wr_addr[6]_i_2__1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[0]),
        .Q(wr_addr_reg[0]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[1]),
        .Q(wr_addr_reg[1]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[2]),
        .Q(wr_addr_reg[2]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[3]),
        .Q(wr_addr_reg[3]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[4]),
        .Q(wr_addr_reg[4]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[5]),
        .Q(wr_addr_reg[5]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \wr_addr_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[6]),
        .Q(wr_addr_reg[6]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "jesd204_eof_generator" *) 
module jesd204_rx_0_jesd204_eof_generator
   (rx_sof,
    rx_eof,
    eof_reset,
    clk,
    cfg_octets_per_frame);
  output [2:0]rx_sof;
  output [0:0]rx_eof;
  input eof_reset;
  input clk;
  input [3:0]cfg_octets_per_frame;

  wire [1:0]beat_counter;
  wire \beat_counter[0]_i_1_n_0 ;
  wire \beat_counter[1]_i_1_n_0 ;
  wire [3:0]cfg_octets_per_frame;
  wire clk;
  wire \eof[1]_i_1_n_0 ;
  wire \eof[2]_i_1_n_0 ;
  wire eof_reset;
  wire [3:3]p_0_in;
  wire [0:0]rx_eof;
  wire [2:0]rx_sof;
  wire \sof[0]_i_1_n_0 ;

  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'h00004554)) 
    \beat_counter[0]_i_1 
       (.I0(beat_counter[0]),
        .I1(cfg_octets_per_frame[2]),
        .I2(beat_counter[1]),
        .I3(cfg_octets_per_frame[3]),
        .I4(eof_reset),
        .O(\beat_counter[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'h00004A52)) 
    \beat_counter[1]_i_1 
       (.I0(beat_counter[0]),
        .I1(cfg_octets_per_frame[2]),
        .I2(beat_counter[1]),
        .I3(cfg_octets_per_frame[3]),
        .I4(eof_reset),
        .O(\beat_counter[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT4 #(
    .INIT(16'h9009)) 
    beat_counter_eof
       (.I0(beat_counter[0]),
        .I1(cfg_octets_per_frame[2]),
        .I2(beat_counter[1]),
        .I3(cfg_octets_per_frame[3]),
        .O(p_0_in));
  FDRE #(
    .INIT(1'b0)) 
    \beat_counter_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_counter[0]_i_1_n_0 ),
        .Q(beat_counter[0]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \beat_counter_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_counter[1]_i_1_n_0 ),
        .Q(beat_counter[1]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT3 #(
    .INIT(8'h01)) 
    \eof[1]_i_1 
       (.I0(cfg_octets_per_frame[2]),
        .I1(cfg_octets_per_frame[3]),
        .I2(cfg_octets_per_frame[1]),
        .O(\eof[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT3 #(
    .INIT(8'h01)) 
    \eof[2]_i_1 
       (.I0(cfg_octets_per_frame[2]),
        .I1(cfg_octets_per_frame[3]),
        .I2(cfg_octets_per_frame[0]),
        .O(\eof[2]_i_1_n_0 ));
  FDRE \eof_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\eof[1]_i_1_n_0 ),
        .Q(rx_sof[1]),
        .R(eof_reset));
  FDRE \eof_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\eof[2]_i_1_n_0 ),
        .Q(rx_sof[2]),
        .R(eof_reset));
  FDRE \eof_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in),
        .Q(rx_eof),
        .R(eof_reset));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT2 #(
    .INIT(4'h1)) 
    \sof[0]_i_1 
       (.I0(beat_counter[1]),
        .I1(beat_counter[0]),
        .O(\sof[0]_i_1_n_0 ));
  FDRE \sof_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\sof[0]_i_1_n_0 ),
        .Q(rx_sof[0]),
        .R(eof_reset));
endmodule

(* ORIG_REF_NAME = "jesd204_ilas_monitor" *) 
module jesd204_rx_0_jesd204_ilas_monitor
   (ilas_config_valid_reg_0,
    state,
    prev_was_last_reg_0,
    \ilas_config_addr_reg[1]_0 ,
    ilas_config_addr,
    ilas_config_data,
    prev_was_last0,
    clk,
    ilas_config_valid_reg_1,
    state_reg_0,
    \wr_addr_reg[0] ,
    D);
  output ilas_config_valid_reg_0;
  output state;
  output prev_was_last_reg_0;
  output \ilas_config_addr_reg[1]_0 ;
  output [1:0]ilas_config_addr;
  output [31:0]ilas_config_data;
  input prev_was_last0;
  input clk;
  input ilas_config_valid_reg_1;
  input state_reg_0;
  input \wr_addr_reg[0] ;
  input [31:0]D;

  wire [31:0]D;
  wire clk;
  wire [1:0]ilas_config_addr;
  wire \ilas_config_addr[0]_i_1__2_n_0 ;
  wire \ilas_config_addr[1]_i_1__2_n_0 ;
  wire \ilas_config_addr_reg[1]_0 ;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire prev_was_last;
  wire prev_was_last0;
  wire prev_was_last_reg_0;
  wire state;
  wire state_reg_0;
  wire \wr_addr_reg[0] ;

  (* SOFT_HLUTNM = "soft_lutpair79" *) 
  LUT2 #(
    .INIT(4'h4)) 
    \ilas_config_addr[0]_i_1__2 
       (.I0(ilas_config_addr[0]),
        .I1(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[0]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair79" *) 
  LUT3 #(
    .INIT(8'h60)) 
    \ilas_config_addr[1]_i_1__2 
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[1]_i_1__2_n_0 ));
  FDRE \ilas_config_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[0]_i_1__2_n_0 ),
        .Q(ilas_config_addr[0]),
        .R(1'b0));
  FDRE \ilas_config_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[1]_i_1__2_n_0 ),
        .Q(ilas_config_addr[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[0]),
        .Q(ilas_config_data[0]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[10]),
        .Q(ilas_config_data[10]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[11]),
        .Q(ilas_config_data[11]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[12]),
        .Q(ilas_config_data[12]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[13]),
        .Q(ilas_config_data[13]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(ilas_config_data[14]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(ilas_config_data[15]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(ilas_config_data[16]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(ilas_config_data[17]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(ilas_config_data[18]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(ilas_config_data[19]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[1]),
        .Q(ilas_config_data[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(ilas_config_data[20]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(ilas_config_data[21]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(ilas_config_data[22]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(ilas_config_data[23]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(ilas_config_data[24]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(ilas_config_data[25]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(ilas_config_data[26]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(ilas_config_data[27]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(ilas_config_data[28]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(D[29]),
        .Q(ilas_config_data[29]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[2]),
        .Q(ilas_config_data[2]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(D[30]),
        .Q(ilas_config_data[30]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(D[31]),
        .Q(ilas_config_data[31]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[3]),
        .Q(ilas_config_data[3]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[4]),
        .Q(ilas_config_data[4]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[5]),
        .Q(ilas_config_data[5]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[6]),
        .Q(ilas_config_data[6]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[7]),
        .Q(ilas_config_data[7]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[8]),
        .Q(ilas_config_data[8]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[9]),
        .Q(ilas_config_data[9]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair78" *) 
  LUT3 #(
    .INIT(8'h80)) 
    ilas_config_valid_i_2__2
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(state),
        .O(\ilas_config_addr_reg[1]_0 ));
  FDRE ilas_config_valid_reg
       (.C(clk),
        .CE(1'b1),
        .D(ilas_config_valid_reg_1),
        .Q(ilas_config_valid_reg_0),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    prev_was_last_reg
       (.C(clk),
        .CE(1'b1),
        .D(prev_was_last0),
        .Q(prev_was_last),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair78" *) 
  LUT3 #(
    .INIT(8'h70)) 
    \state[14]_i_2__1 
       (.I0(prev_was_last),
        .I1(\wr_addr_reg[0] ),
        .I2(state),
        .O(prev_was_last_reg_0));
  FDRE #(
    .INIT(1'b1)) 
    state_reg
       (.C(clk),
        .CE(1'b1),
        .D(state_reg_0),
        .Q(state),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_ilas_monitor" *) 
module jesd204_rx_0_jesd204_ilas_monitor_12
   (ilas_config_valid_reg_0,
    state,
    prev_was_last_reg_0,
    \ilas_config_addr_reg[1]_0 ,
    ilas_config_addr,
    ilas_config_data,
    prev_was_last0,
    clk,
    ilas_config_valid_reg_1,
    state_reg_0,
    \wr_addr_reg[0] ,
    D);
  output ilas_config_valid_reg_0;
  output state;
  output prev_was_last_reg_0;
  output \ilas_config_addr_reg[1]_0 ;
  output [1:0]ilas_config_addr;
  output [31:0]ilas_config_data;
  input prev_was_last0;
  input clk;
  input ilas_config_valid_reg_1;
  input state_reg_0;
  input \wr_addr_reg[0] ;
  input [31:0]D;

  wire [31:0]D;
  wire clk;
  wire [1:0]ilas_config_addr;
  wire \ilas_config_addr[0]_i_1__0_n_0 ;
  wire \ilas_config_addr[1]_i_1__0_n_0 ;
  wire \ilas_config_addr_reg[1]_0 ;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire prev_was_last;
  wire prev_was_last0;
  wire prev_was_last_reg_0;
  wire state;
  wire state_reg_0;
  wire \wr_addr_reg[0] ;

  (* SOFT_HLUTNM = "soft_lutpair54" *) 
  LUT2 #(
    .INIT(4'h4)) 
    \ilas_config_addr[0]_i_1__0 
       (.I0(ilas_config_addr[0]),
        .I1(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[0]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair54" *) 
  LUT3 #(
    .INIT(8'h60)) 
    \ilas_config_addr[1]_i_1__0 
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[1]_i_1__0_n_0 ));
  FDRE \ilas_config_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[0]_i_1__0_n_0 ),
        .Q(ilas_config_addr[0]),
        .R(1'b0));
  FDRE \ilas_config_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[1]_i_1__0_n_0 ),
        .Q(ilas_config_addr[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[0]),
        .Q(ilas_config_data[0]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[10]),
        .Q(ilas_config_data[10]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[11]),
        .Q(ilas_config_data[11]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[12]),
        .Q(ilas_config_data[12]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[13]),
        .Q(ilas_config_data[13]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(ilas_config_data[14]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(ilas_config_data[15]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(ilas_config_data[16]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(ilas_config_data[17]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(ilas_config_data[18]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(ilas_config_data[19]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[1]),
        .Q(ilas_config_data[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(ilas_config_data[20]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(ilas_config_data[21]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(ilas_config_data[22]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(ilas_config_data[23]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(ilas_config_data[24]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(ilas_config_data[25]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(ilas_config_data[26]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(ilas_config_data[27]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(ilas_config_data[28]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(D[29]),
        .Q(ilas_config_data[29]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[2]),
        .Q(ilas_config_data[2]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(D[30]),
        .Q(ilas_config_data[30]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(D[31]),
        .Q(ilas_config_data[31]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[3]),
        .Q(ilas_config_data[3]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[4]),
        .Q(ilas_config_data[4]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[5]),
        .Q(ilas_config_data[5]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[6]),
        .Q(ilas_config_data[6]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[7]),
        .Q(ilas_config_data[7]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[8]),
        .Q(ilas_config_data[8]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[9]),
        .Q(ilas_config_data[9]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair53" *) 
  LUT3 #(
    .INIT(8'h80)) 
    ilas_config_valid_i_2__0
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(state),
        .O(\ilas_config_addr_reg[1]_0 ));
  FDRE ilas_config_valid_reg
       (.C(clk),
        .CE(1'b1),
        .D(ilas_config_valid_reg_1),
        .Q(ilas_config_valid_reg_0),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    prev_was_last_reg
       (.C(clk),
        .CE(1'b1),
        .D(prev_was_last0),
        .Q(prev_was_last),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair53" *) 
  LUT3 #(
    .INIT(8'h70)) 
    \state[14]_i_2 
       (.I0(prev_was_last),
        .I1(\wr_addr_reg[0] ),
        .I2(state),
        .O(prev_was_last_reg_0));
  FDRE #(
    .INIT(1'b1)) 
    state_reg
       (.C(clk),
        .CE(1'b1),
        .D(state_reg_0),
        .Q(state),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_ilas_monitor" *) 
module jesd204_rx_0_jesd204_ilas_monitor_17
   (prev_was_last,
    ilas_config_valid_reg_0,
    state,
    \ilas_config_addr_reg[1]_0 ,
    ilas_config_addr,
    ilas_config_data,
    prev_was_last0,
    clk,
    ilas_config_valid_reg_1,
    state_reg_0,
    D);
  output prev_was_last;
  output ilas_config_valid_reg_0;
  output state;
  output \ilas_config_addr_reg[1]_0 ;
  output [1:0]ilas_config_addr;
  output [31:0]ilas_config_data;
  input prev_was_last0;
  input clk;
  input ilas_config_valid_reg_1;
  input state_reg_0;
  input [31:0]D;

  wire [31:0]D;
  wire clk;
  wire [1:0]ilas_config_addr;
  wire \ilas_config_addr[0]_i_1_n_0 ;
  wire \ilas_config_addr[1]_i_1_n_0 ;
  wire \ilas_config_addr_reg[1]_0 ;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire prev_was_last;
  wire prev_was_last0;
  wire state;
  wire state_reg_0;

  LUT2 #(
    .INIT(4'h4)) 
    \ilas_config_addr[0]_i_1 
       (.I0(ilas_config_addr[0]),
        .I1(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair42" *) 
  LUT3 #(
    .INIT(8'h60)) 
    \ilas_config_addr[1]_i_1 
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[1]_i_1_n_0 ));
  FDRE \ilas_config_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[0]_i_1_n_0 ),
        .Q(ilas_config_addr[0]),
        .R(1'b0));
  FDRE \ilas_config_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[1]_i_1_n_0 ),
        .Q(ilas_config_addr[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[0]),
        .Q(ilas_config_data[0]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[10]),
        .Q(ilas_config_data[10]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[11]),
        .Q(ilas_config_data[11]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[12]),
        .Q(ilas_config_data[12]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[13]),
        .Q(ilas_config_data[13]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(ilas_config_data[14]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(ilas_config_data[15]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(ilas_config_data[16]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(ilas_config_data[17]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(ilas_config_data[18]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(ilas_config_data[19]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[1]),
        .Q(ilas_config_data[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(ilas_config_data[20]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(ilas_config_data[21]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(ilas_config_data[22]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(ilas_config_data[23]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(ilas_config_data[24]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(ilas_config_data[25]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(ilas_config_data[26]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(ilas_config_data[27]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(ilas_config_data[28]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(D[29]),
        .Q(ilas_config_data[29]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[2]),
        .Q(ilas_config_data[2]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(D[30]),
        .Q(ilas_config_data[30]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(D[31]),
        .Q(ilas_config_data[31]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[3]),
        .Q(ilas_config_data[3]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[4]),
        .Q(ilas_config_data[4]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[5]),
        .Q(ilas_config_data[5]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[6]),
        .Q(ilas_config_data[6]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[7]),
        .Q(ilas_config_data[7]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[8]),
        .Q(ilas_config_data[8]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[9]),
        .Q(ilas_config_data[9]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair42" *) 
  LUT3 #(
    .INIT(8'h80)) 
    ilas_config_valid_i_2
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(state),
        .O(\ilas_config_addr_reg[1]_0 ));
  FDRE ilas_config_valid_reg
       (.C(clk),
        .CE(1'b1),
        .D(ilas_config_valid_reg_1),
        .Q(ilas_config_valid_reg_0),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    prev_was_last_reg
       (.C(clk),
        .CE(1'b1),
        .D(prev_was_last0),
        .Q(prev_was_last),
        .R(1'b0));
  FDRE #(
    .INIT(1'b1)) 
    state_reg
       (.C(clk),
        .CE(1'b1),
        .D(state_reg_0),
        .Q(state),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_ilas_monitor" *) 
module jesd204_rx_0_jesd204_ilas_monitor_7
   (ilas_config_valid_reg_0,
    state,
    prev_was_last_reg_0,
    \ilas_config_addr_reg[1]_0 ,
    ilas_config_addr,
    ilas_config_data,
    prev_was_last0,
    clk,
    ilas_config_valid_reg_1,
    state_reg_0,
    \wr_addr_reg[6] ,
    D);
  output ilas_config_valid_reg_0;
  output state;
  output prev_was_last_reg_0;
  output \ilas_config_addr_reg[1]_0 ;
  output [1:0]ilas_config_addr;
  output [31:0]ilas_config_data;
  input prev_was_last0;
  input clk;
  input ilas_config_valid_reg_1;
  input state_reg_0;
  input \wr_addr_reg[6] ;
  input [31:0]D;

  wire [31:0]D;
  wire clk;
  wire [1:0]ilas_config_addr;
  wire \ilas_config_addr[0]_i_1__1_n_0 ;
  wire \ilas_config_addr[1]_i_1__1_n_0 ;
  wire \ilas_config_addr_reg[1]_0 ;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg_0;
  wire ilas_config_valid_reg_1;
  wire prev_was_last;
  wire prev_was_last0;
  wire prev_was_last_reg_0;
  wire state;
  wire state_reg_0;
  wire \wr_addr_reg[6] ;

  (* SOFT_HLUTNM = "soft_lutpair67" *) 
  LUT2 #(
    .INIT(4'h4)) 
    \ilas_config_addr[0]_i_1__1 
       (.I0(ilas_config_addr[0]),
        .I1(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[0]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair67" *) 
  LUT3 #(
    .INIT(8'h60)) 
    \ilas_config_addr[1]_i_1__1 
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(ilas_config_valid_reg_0),
        .O(\ilas_config_addr[1]_i_1__1_n_0 ));
  FDRE \ilas_config_addr_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[0]_i_1__1_n_0 ),
        .Q(ilas_config_addr[0]),
        .R(1'b0));
  FDRE \ilas_config_addr_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\ilas_config_addr[1]_i_1__1_n_0 ),
        .Q(ilas_config_addr[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[0]),
        .Q(ilas_config_data[0]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[10]),
        .Q(ilas_config_data[10]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[11]),
        .Q(ilas_config_data[11]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[12]),
        .Q(ilas_config_data[12]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[13]),
        .Q(ilas_config_data[13]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(ilas_config_data[14]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(ilas_config_data[15]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(ilas_config_data[16]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(ilas_config_data[17]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(ilas_config_data[18]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(ilas_config_data[19]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[1]),
        .Q(ilas_config_data[1]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(ilas_config_data[20]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(ilas_config_data[21]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(ilas_config_data[22]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(ilas_config_data[23]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(ilas_config_data[24]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(ilas_config_data[25]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(ilas_config_data[26]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(ilas_config_data[27]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(ilas_config_data[28]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(D[29]),
        .Q(ilas_config_data[29]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[2]),
        .Q(ilas_config_data[2]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(D[30]),
        .Q(ilas_config_data[30]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(D[31]),
        .Q(ilas_config_data[31]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[3]),
        .Q(ilas_config_data[3]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[4]),
        .Q(ilas_config_data[4]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[5]),
        .Q(ilas_config_data[5]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[6]),
        .Q(ilas_config_data[6]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[7]),
        .Q(ilas_config_data[7]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[8]),
        .Q(ilas_config_data[8]),
        .R(1'b0));
  FDRE \ilas_config_data_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[9]),
        .Q(ilas_config_data[9]),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair66" *) 
  LUT3 #(
    .INIT(8'h80)) 
    ilas_config_valid_i_2__1
       (.I0(ilas_config_addr[1]),
        .I1(ilas_config_addr[0]),
        .I2(state),
        .O(\ilas_config_addr_reg[1]_0 ));
  FDRE ilas_config_valid_reg
       (.C(clk),
        .CE(1'b1),
        .D(ilas_config_valid_reg_1),
        .Q(ilas_config_valid_reg_0),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    prev_was_last_reg
       (.C(clk),
        .CE(1'b1),
        .D(prev_was_last0),
        .Q(prev_was_last),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair66" *) 
  LUT3 #(
    .INIT(8'h70)) 
    \state[14]_i_2__0 
       (.I0(prev_was_last),
        .I1(\wr_addr_reg[6] ),
        .I2(state),
        .O(prev_was_last_reg_0));
  FDRE #(
    .INIT(1'b1)) 
    state_reg
       (.C(clk),
        .CE(1'b1),
        .D(state_reg_0),
        .Q(state),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_lane_latency_monitor" *) 
module jesd204_rx_0_jesd204_lane_latency_monitor
   (status_lane_ifs_ready,
    status_lane_latency,
    latency_monitor_reset,
    E,
    clk,
    \gen_lane[1].lane_latency_mem_reg[1][11]_0 ,
    \gen_lane[2].lane_latency_mem_reg[2][11]_0 ,
    \gen_lane[3].lane_latency_mem_reg[3][11]_0 );
  output [3:0]status_lane_ifs_ready;
  output [47:0]status_lane_latency;
  input latency_monitor_reset;
  input [0:0]E;
  input clk;
  input [0:0]\gen_lane[1].lane_latency_mem_reg[1][11]_0 ;
  input [0:0]\gen_lane[2].lane_latency_mem_reg[2][11]_0 ;
  input [0:0]\gen_lane[3].lane_latency_mem_reg[3][11]_0 ;

  wire [0:0]E;
  wire \beat_counter[0]_i_3_n_0 ;
  wire \beat_counter[0]_i_4_n_0 ;
  wire \beat_counter[0]_i_5_n_0 ;
  wire [11:0]beat_counter_reg;
  wire \beat_counter_reg[0]_i_2_n_0 ;
  wire \beat_counter_reg[0]_i_2_n_1 ;
  wire \beat_counter_reg[0]_i_2_n_2 ;
  wire \beat_counter_reg[0]_i_2_n_3 ;
  wire \beat_counter_reg[0]_i_2_n_4 ;
  wire \beat_counter_reg[0]_i_2_n_5 ;
  wire \beat_counter_reg[0]_i_2_n_6 ;
  wire \beat_counter_reg[0]_i_2_n_7 ;
  wire \beat_counter_reg[4]_i_1_n_0 ;
  wire \beat_counter_reg[4]_i_1_n_1 ;
  wire \beat_counter_reg[4]_i_1_n_2 ;
  wire \beat_counter_reg[4]_i_1_n_3 ;
  wire \beat_counter_reg[4]_i_1_n_4 ;
  wire \beat_counter_reg[4]_i_1_n_5 ;
  wire \beat_counter_reg[4]_i_1_n_6 ;
  wire \beat_counter_reg[4]_i_1_n_7 ;
  wire \beat_counter_reg[8]_i_1_n_1 ;
  wire \beat_counter_reg[8]_i_1_n_2 ;
  wire \beat_counter_reg[8]_i_1_n_3 ;
  wire \beat_counter_reg[8]_i_1_n_4 ;
  wire \beat_counter_reg[8]_i_1_n_5 ;
  wire \beat_counter_reg[8]_i_1_n_6 ;
  wire \beat_counter_reg[8]_i_1_n_7 ;
  wire clk;
  wire [0:0]\gen_lane[1].lane_latency_mem_reg[1][11]_0 ;
  wire [0:0]\gen_lane[2].lane_latency_mem_reg[2][11]_0 ;
  wire [0:0]\gen_lane[3].lane_latency_mem_reg[3][11]_0 ;
  wire latency_monitor_reset;
  wire sel;
  wire [3:0]status_lane_ifs_ready;
  wire [47:0]status_lane_latency;
  wire [3:3]\NLW_beat_counter_reg[8]_i_1_CO_UNCONNECTED ;

  LUT6 #(
    .INIT(64'hFFFFFFFFBFFFFFFF)) 
    \beat_counter[0]_i_1 
       (.I0(\beat_counter[0]_i_3_n_0 ),
        .I1(beat_counter_reg[11]),
        .I2(beat_counter_reg[9]),
        .I3(beat_counter_reg[0]),
        .I4(beat_counter_reg[2]),
        .I5(\beat_counter[0]_i_4_n_0 ),
        .O(sel));
  LUT4 #(
    .INIT(16'h7FFF)) 
    \beat_counter[0]_i_3 
       (.I0(beat_counter_reg[5]),
        .I1(beat_counter_reg[1]),
        .I2(beat_counter_reg[4]),
        .I3(beat_counter_reg[3]),
        .O(\beat_counter[0]_i_3_n_0 ));
  LUT4 #(
    .INIT(16'h7FFF)) 
    \beat_counter[0]_i_4 
       (.I0(beat_counter_reg[6]),
        .I1(beat_counter_reg[8]),
        .I2(beat_counter_reg[10]),
        .I3(beat_counter_reg[7]),
        .O(\beat_counter[0]_i_4_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \beat_counter[0]_i_5 
       (.I0(beat_counter_reg[0]),
        .O(\beat_counter[0]_i_5_n_0 ));
  FDRE \beat_counter_reg[0] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[0]_i_2_n_7 ),
        .Q(beat_counter_reg[0]),
        .R(latency_monitor_reset));
  CARRY4 \beat_counter_reg[0]_i_2 
       (.CI(1'b0),
        .CO({\beat_counter_reg[0]_i_2_n_0 ,\beat_counter_reg[0]_i_2_n_1 ,\beat_counter_reg[0]_i_2_n_2 ,\beat_counter_reg[0]_i_2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b1}),
        .O({\beat_counter_reg[0]_i_2_n_4 ,\beat_counter_reg[0]_i_2_n_5 ,\beat_counter_reg[0]_i_2_n_6 ,\beat_counter_reg[0]_i_2_n_7 }),
        .S({beat_counter_reg[3:1],\beat_counter[0]_i_5_n_0 }));
  FDRE \beat_counter_reg[10] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[8]_i_1_n_5 ),
        .Q(beat_counter_reg[10]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[11] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[8]_i_1_n_4 ),
        .Q(beat_counter_reg[11]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[1] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[0]_i_2_n_6 ),
        .Q(beat_counter_reg[1]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[2] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[0]_i_2_n_5 ),
        .Q(beat_counter_reg[2]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[3] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[0]_i_2_n_4 ),
        .Q(beat_counter_reg[3]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[4] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[4]_i_1_n_7 ),
        .Q(beat_counter_reg[4]),
        .R(latency_monitor_reset));
  CARRY4 \beat_counter_reg[4]_i_1 
       (.CI(\beat_counter_reg[0]_i_2_n_0 ),
        .CO({\beat_counter_reg[4]_i_1_n_0 ,\beat_counter_reg[4]_i_1_n_1 ,\beat_counter_reg[4]_i_1_n_2 ,\beat_counter_reg[4]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\beat_counter_reg[4]_i_1_n_4 ,\beat_counter_reg[4]_i_1_n_5 ,\beat_counter_reg[4]_i_1_n_6 ,\beat_counter_reg[4]_i_1_n_7 }),
        .S(beat_counter_reg[7:4]));
  FDRE \beat_counter_reg[5] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[4]_i_1_n_6 ),
        .Q(beat_counter_reg[5]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[6] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[4]_i_1_n_5 ),
        .Q(beat_counter_reg[6]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[7] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[4]_i_1_n_4 ),
        .Q(beat_counter_reg[7]),
        .R(latency_monitor_reset));
  FDRE \beat_counter_reg[8] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[8]_i_1_n_7 ),
        .Q(beat_counter_reg[8]),
        .R(latency_monitor_reset));
  CARRY4 \beat_counter_reg[8]_i_1 
       (.CI(\beat_counter_reg[4]_i_1_n_0 ),
        .CO({\NLW_beat_counter_reg[8]_i_1_CO_UNCONNECTED [3],\beat_counter_reg[8]_i_1_n_1 ,\beat_counter_reg[8]_i_1_n_2 ,\beat_counter_reg[8]_i_1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\beat_counter_reg[8]_i_1_n_4 ,\beat_counter_reg[8]_i_1_n_5 ,\beat_counter_reg[8]_i_1_n_6 ,\beat_counter_reg[8]_i_1_n_7 }),
        .S(beat_counter_reg[11:8]));
  FDRE \beat_counter_reg[9] 
       (.C(clk),
        .CE(sel),
        .D(\beat_counter_reg[8]_i_1_n_6 ),
        .Q(beat_counter_reg[9]),
        .R(latency_monitor_reset));
  FDRE #(
    .INIT(1'b0)) 
    \gen_lane[0].lane_captured_reg[0] 
       (.C(clk),
        .CE(E),
        .D(1'b1),
        .Q(status_lane_ifs_ready[0]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][0] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[0]),
        .Q(status_lane_latency[0]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][10] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[10]),
        .Q(status_lane_latency[10]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][11] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[11]),
        .Q(status_lane_latency[11]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][1] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[1]),
        .Q(status_lane_latency[1]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][2] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[2]),
        .Q(status_lane_latency[2]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][3] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[3]),
        .Q(status_lane_latency[3]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][4] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[4]),
        .Q(status_lane_latency[4]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][5] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[5]),
        .Q(status_lane_latency[5]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][6] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[6]),
        .Q(status_lane_latency[6]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][7] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[7]),
        .Q(status_lane_latency[7]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][8] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[8]),
        .Q(status_lane_latency[8]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[0].lane_latency_mem_reg[0][9] 
       (.C(clk),
        .CE(E),
        .D(beat_counter_reg[9]),
        .Q(status_lane_latency[9]),
        .R(latency_monitor_reset));
  FDRE #(
    .INIT(1'b0)) 
    \gen_lane[1].lane_captured_reg[1] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(1'b1),
        .Q(status_lane_ifs_ready[1]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][0] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[0]),
        .Q(status_lane_latency[12]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][10] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[10]),
        .Q(status_lane_latency[22]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][11] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[11]),
        .Q(status_lane_latency[23]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][1] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[1]),
        .Q(status_lane_latency[13]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][2] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[2]),
        .Q(status_lane_latency[14]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][3] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[3]),
        .Q(status_lane_latency[15]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][4] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[4]),
        .Q(status_lane_latency[16]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][5] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[5]),
        .Q(status_lane_latency[17]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][6] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[6]),
        .Q(status_lane_latency[18]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][7] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[7]),
        .Q(status_lane_latency[19]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][8] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[8]),
        .Q(status_lane_latency[20]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[1].lane_latency_mem_reg[1][9] 
       (.C(clk),
        .CE(\gen_lane[1].lane_latency_mem_reg[1][11]_0 ),
        .D(beat_counter_reg[9]),
        .Q(status_lane_latency[21]),
        .R(latency_monitor_reset));
  FDRE #(
    .INIT(1'b0)) 
    \gen_lane[2].lane_captured_reg[2] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(1'b1),
        .Q(status_lane_ifs_ready[2]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][0] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[0]),
        .Q(status_lane_latency[24]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][10] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[10]),
        .Q(status_lane_latency[34]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][11] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[11]),
        .Q(status_lane_latency[35]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][1] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[1]),
        .Q(status_lane_latency[25]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][2] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[2]),
        .Q(status_lane_latency[26]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][3] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[3]),
        .Q(status_lane_latency[27]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][4] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[4]),
        .Q(status_lane_latency[28]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][5] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[5]),
        .Q(status_lane_latency[29]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][6] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[6]),
        .Q(status_lane_latency[30]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][7] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[7]),
        .Q(status_lane_latency[31]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][8] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[8]),
        .Q(status_lane_latency[32]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[2].lane_latency_mem_reg[2][9] 
       (.C(clk),
        .CE(\gen_lane[2].lane_latency_mem_reg[2][11]_0 ),
        .D(beat_counter_reg[9]),
        .Q(status_lane_latency[33]),
        .R(latency_monitor_reset));
  FDRE #(
    .INIT(1'b0)) 
    \gen_lane[3].lane_captured_reg[3] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(1'b1),
        .Q(status_lane_ifs_ready[3]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][0] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[0]),
        .Q(status_lane_latency[36]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][10] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[10]),
        .Q(status_lane_latency[46]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][11] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[11]),
        .Q(status_lane_latency[47]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][1] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[1]),
        .Q(status_lane_latency[37]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][2] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[2]),
        .Q(status_lane_latency[38]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][3] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[3]),
        .Q(status_lane_latency[39]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][4] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[4]),
        .Q(status_lane_latency[40]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][5] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[5]),
        .Q(status_lane_latency[41]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][6] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[6]),
        .Q(status_lane_latency[42]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][7] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[7]),
        .Q(status_lane_latency[43]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][8] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[8]),
        .Q(status_lane_latency[44]),
        .R(latency_monitor_reset));
  FDRE \gen_lane[3].lane_latency_mem_reg[3][9] 
       (.C(clk),
        .CE(\gen_lane[3].lane_latency_mem_reg[3][11]_0 ),
        .D(beat_counter_reg[9]),
        .Q(status_lane_latency[45]),
        .R(latency_monitor_reset));
endmodule

(* ORIG_REF_NAME = "jesd204_lmfc" *) 
module jesd204_rx_0_jesd204_lmfc
   (sysref_edge_reg_0,
    lmfc_edge_reg_0,
    lmfc_clk,
    event_sysref_alignment_error,
    cfg_buffer_early_release_0,
    sysref,
    clk,
    reset,
    cfg_buffer_early_release,
    cfg_sysref_disable,
    cfg_lmfc_offset,
    cfg_sysref_oneshot,
    cfg_beats_per_multiframe,
    cfg_buffer_delay);
  output sysref_edge_reg_0;
  output lmfc_edge_reg_0;
  output lmfc_clk;
  output event_sysref_alignment_error;
  output cfg_buffer_early_release_0;
  input sysref;
  input clk;
  input reset;
  input cfg_buffer_early_release;
  input cfg_sysref_disable;
  input [7:0]cfg_lmfc_offset;
  input cfg_sysref_oneshot;
  input [7:0]cfg_beats_per_multiframe;
  input [7:0]cfg_buffer_delay;

  wire buffer_release_opportunity_i_2_n_0;
  wire buffer_release_opportunity_i_3_n_0;
  wire buffer_release_opportunity_i_4_n_0;
  wire [7:0]cfg_beats_per_multiframe;
  wire [7:0]cfg_buffer_delay;
  wire cfg_buffer_early_release;
  wire cfg_buffer_early_release_0;
  wire [7:0]cfg_lmfc_offset;
  wire cfg_sysref_disable;
  wire cfg_sysref_oneshot;
  wire clk;
  wire event_sysref_alignment_error;
  wire lmfc_active;
  wire lmfc_active_i_1_n_0;
  wire lmfc_clk;
  wire lmfc_clk_p1;
  wire lmfc_clk_p10__14;
  wire lmfc_clk_p1_i_1_n_0;
  wire lmfc_clk_p1_i_3_n_0;
  wire lmfc_clk_p1_i_4_n_0;
  wire [7:0]lmfc_counter;
  wire lmfc_counter1__1;
  wire \lmfc_counter[5]_i_2_n_0 ;
  wire \lmfc_counter[7]_i_2_n_0 ;
  wire \lmfc_counter[7]_i_5_n_0 ;
  wire \lmfc_counter[7]_i_6_n_0 ;
  wire lmfc_counter_next1;
  wire [4:3]lmfc_counter_next__7;
  wire lmfc_edge0;
  wire lmfc_edge_i_2_n_0;
  wire lmfc_edge_reg_0;
  wire [7:0]p_0_in;
  wire reset;
  wire sysref;
  wire sysref_alignment_error0;
  wire sysref_alignment_error_i_2_n_0;
  wire sysref_alignment_error_i_3_n_0;
  wire sysref_alignment_error_i_4_n_0;
  wire sysref_alignment_error_i_5_n_0;
  wire sysref_alignment_error_i_6_n_0;
  wire sysref_alignment_error_i_7_n_0;
  wire sysref_alignment_error_i_8_n_0;
  wire sysref_alignment_error_i_9_n_0;
  wire sysref_captured;
  wire sysref_captured_i_1_n_0;
  wire sysref_d1;
  wire sysref_d2;
  wire sysref_d3;
  wire sysref_edge0;
  wire sysref_edge_reg_0;
  wire sysref_r;

  LUT4 #(
    .INIT(16'hFF08)) 
    buffer_release_opportunity_i_1
       (.I0(buffer_release_opportunity_i_2_n_0),
        .I1(buffer_release_opportunity_i_3_n_0),
        .I2(buffer_release_opportunity_i_4_n_0),
        .I3(cfg_buffer_early_release),
        .O(cfg_buffer_early_release_0));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    buffer_release_opportunity_i_2
       (.I0(lmfc_counter[0]),
        .I1(cfg_buffer_delay[0]),
        .I2(cfg_buffer_delay[2]),
        .I3(lmfc_counter[2]),
        .I4(cfg_buffer_delay[1]),
        .I5(lmfc_counter[1]),
        .O(buffer_release_opportunity_i_2_n_0));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    buffer_release_opportunity_i_3
       (.I0(lmfc_counter[3]),
        .I1(cfg_buffer_delay[3]),
        .I2(cfg_buffer_delay[5]),
        .I3(lmfc_counter[5]),
        .I4(cfg_buffer_delay[4]),
        .I5(lmfc_counter[4]),
        .O(buffer_release_opportunity_i_3_n_0));
  LUT4 #(
    .INIT(16'h6FF6)) 
    buffer_release_opportunity_i_4
       (.I0(lmfc_counter[6]),
        .I1(cfg_buffer_delay[6]),
        .I2(lmfc_counter[7]),
        .I3(cfg_buffer_delay[7]),
        .O(buffer_release_opportunity_i_4_n_0));
  LUT6 #(
    .INIT(64'hBBBBBBBB8BBB8888)) 
    lmfc_active_i_1
       (.I0(cfg_sysref_disable),
        .I1(reset),
        .I2(cfg_sysref_oneshot),
        .I3(sysref_captured),
        .I4(sysref_edge_reg_0),
        .I5(lmfc_active),
        .O(lmfc_active_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    lmfc_active_reg
       (.C(clk),
        .CE(1'b1),
        .D(lmfc_active_i_1_n_0),
        .Q(lmfc_active),
        .R(1'b0));
  LUT4 #(
    .INIT(16'hF7A0)) 
    lmfc_clk_p1_i_1
       (.I0(lmfc_active),
        .I1(lmfc_clk_p10__14),
        .I2(lmfc_counter_next1),
        .I3(lmfc_clk_p1),
        .O(lmfc_clk_p1_i_1_n_0));
  LUT5 #(
    .INIT(32'h09000000)) 
    lmfc_clk_p1_i_2
       (.I0(cfg_beats_per_multiframe[7]),
        .I1(lmfc_counter[6]),
        .I2(lmfc_counter[7]),
        .I3(lmfc_clk_p1_i_3_n_0),
        .I4(lmfc_clk_p1_i_4_n_0),
        .O(lmfc_clk_p10__14));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    lmfc_clk_p1_i_3
       (.I0(lmfc_counter[3]),
        .I1(cfg_beats_per_multiframe[4]),
        .I2(cfg_beats_per_multiframe[6]),
        .I3(lmfc_counter[5]),
        .I4(cfg_beats_per_multiframe[5]),
        .I5(lmfc_counter[4]),
        .O(lmfc_clk_p1_i_3_n_0));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    lmfc_clk_p1_i_4
       (.I0(lmfc_counter[0]),
        .I1(cfg_beats_per_multiframe[1]),
        .I2(cfg_beats_per_multiframe[3]),
        .I3(lmfc_counter[2]),
        .I4(cfg_beats_per_multiframe[2]),
        .I5(lmfc_counter[1]),
        .O(lmfc_clk_p1_i_4_n_0));
  FDRE #(
    .INIT(1'b1)) 
    lmfc_clk_p1_reg
       (.C(clk),
        .CE(1'b1),
        .D(lmfc_clk_p1_i_1_n_0),
        .Q(lmfc_clk_p1),
        .R(reset));
  FDRE lmfc_clk_reg
       (.C(clk),
        .CE(1'b1),
        .D(lmfc_clk_p1),
        .Q(lmfc_clk),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h0303AA03AA03AA03)) 
    \lmfc_counter[0]_i_1 
       (.I0(cfg_lmfc_offset[0]),
        .I1(lmfc_counter[0]),
        .I2(lmfc_counter_next1),
        .I3(sysref_edge_reg_0),
        .I4(sysref_captured),
        .I5(cfg_sysref_oneshot),
        .O(p_0_in[0]));
  (* SOFT_HLUTNM = "soft_lutpair27" *) 
  LUT5 #(
    .INIT(32'hAAAA003C)) 
    \lmfc_counter[1]_i_1 
       (.I0(cfg_lmfc_offset[1]),
        .I1(lmfc_counter[1]),
        .I2(lmfc_counter[0]),
        .I3(lmfc_counter_next1),
        .I4(lmfc_counter1__1),
        .O(p_0_in[1]));
  LUT6 #(
    .INIT(64'hAAAAAAAA00003CCC)) 
    \lmfc_counter[2]_i_1 
       (.I0(cfg_lmfc_offset[2]),
        .I1(lmfc_counter[2]),
        .I2(lmfc_counter[1]),
        .I3(lmfc_counter[0]),
        .I4(lmfc_counter_next1),
        .I5(lmfc_counter1__1),
        .O(p_0_in[2]));
  (* SOFT_HLUTNM = "soft_lutpair30" *) 
  LUT5 #(
    .INIT(32'hCCACACAC)) 
    \lmfc_counter[3]_i_1 
       (.I0(cfg_lmfc_offset[3]),
        .I1(lmfc_counter_next__7[3]),
        .I2(sysref_edge_reg_0),
        .I3(sysref_captured),
        .I4(cfg_sysref_oneshot),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair29" *) 
  LUT5 #(
    .INIT(32'h00006AAA)) 
    \lmfc_counter[3]_i_2 
       (.I0(lmfc_counter[3]),
        .I1(lmfc_counter[2]),
        .I2(lmfc_counter[0]),
        .I3(lmfc_counter[1]),
        .I4(lmfc_counter_next1),
        .O(lmfc_counter_next__7[3]));
  (* SOFT_HLUTNM = "soft_lutpair31" *) 
  LUT5 #(
    .INIT(32'hCCACACAC)) 
    \lmfc_counter[4]_i_1 
       (.I0(cfg_lmfc_offset[4]),
        .I1(lmfc_counter_next__7[4]),
        .I2(sysref_edge_reg_0),
        .I3(sysref_captured),
        .I4(cfg_sysref_oneshot),
        .O(p_0_in[4]));
  LUT6 #(
    .INIT(64'h000000006AAAAAAA)) 
    \lmfc_counter[4]_i_2 
       (.I0(lmfc_counter[4]),
        .I1(lmfc_counter[3]),
        .I2(lmfc_counter[1]),
        .I3(lmfc_counter[0]),
        .I4(lmfc_counter[2]),
        .I5(lmfc_counter_next1),
        .O(lmfc_counter_next__7[4]));
  LUT5 #(
    .INIT(32'hAAAA003C)) 
    \lmfc_counter[5]_i_1 
       (.I0(cfg_lmfc_offset[5]),
        .I1(lmfc_counter[5]),
        .I2(\lmfc_counter[5]_i_2_n_0 ),
        .I3(lmfc_counter_next1),
        .I4(lmfc_counter1__1),
        .O(p_0_in[5]));
  (* SOFT_HLUTNM = "soft_lutpair28" *) 
  LUT5 #(
    .INIT(32'h80000000)) 
    \lmfc_counter[5]_i_2 
       (.I0(lmfc_counter[4]),
        .I1(lmfc_counter[2]),
        .I2(lmfc_counter[0]),
        .I3(lmfc_counter[1]),
        .I4(lmfc_counter[3]),
        .O(\lmfc_counter[5]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hAAAA003C)) 
    \lmfc_counter[6]_i_1 
       (.I0(cfg_lmfc_offset[6]),
        .I1(lmfc_counter[6]),
        .I2(\lmfc_counter[7]_i_2_n_0 ),
        .I3(lmfc_counter_next1),
        .I4(lmfc_counter1__1),
        .O(p_0_in[6]));
  LUT6 #(
    .INIT(64'hAAAAAAAA00003CCC)) 
    \lmfc_counter[7]_i_1 
       (.I0(cfg_lmfc_offset[7]),
        .I1(lmfc_counter[7]),
        .I2(lmfc_counter[6]),
        .I3(\lmfc_counter[7]_i_2_n_0 ),
        .I4(lmfc_counter_next1),
        .I5(lmfc_counter1__1),
        .O(p_0_in[7]));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \lmfc_counter[7]_i_2 
       (.I0(lmfc_counter[5]),
        .I1(lmfc_counter[3]),
        .I2(lmfc_counter[1]),
        .I3(lmfc_counter[0]),
        .I4(lmfc_counter[2]),
        .I5(lmfc_counter[4]),
        .O(\lmfc_counter[7]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h9009000000000000)) 
    \lmfc_counter[7]_i_3 
       (.I0(cfg_beats_per_multiframe[7]),
        .I1(lmfc_counter[7]),
        .I2(cfg_beats_per_multiframe[6]),
        .I3(lmfc_counter[6]),
        .I4(\lmfc_counter[7]_i_5_n_0 ),
        .I5(\lmfc_counter[7]_i_6_n_0 ),
        .O(lmfc_counter_next1));
  (* SOFT_HLUTNM = "soft_lutpair30" *) 
  LUT3 #(
    .INIT(8'h2A)) 
    \lmfc_counter[7]_i_4 
       (.I0(sysref_edge_reg_0),
        .I1(sysref_captured),
        .I2(cfg_sysref_oneshot),
        .O(lmfc_counter1__1));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    \lmfc_counter[7]_i_5 
       (.I0(lmfc_counter[3]),
        .I1(cfg_beats_per_multiframe[3]),
        .I2(cfg_beats_per_multiframe[5]),
        .I3(lmfc_counter[5]),
        .I4(cfg_beats_per_multiframe[4]),
        .I5(lmfc_counter[4]),
        .O(\lmfc_counter[7]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    \lmfc_counter[7]_i_6 
       (.I0(lmfc_counter[0]),
        .I1(cfg_beats_per_multiframe[0]),
        .I2(cfg_beats_per_multiframe[2]),
        .I3(lmfc_counter[2]),
        .I4(cfg_beats_per_multiframe[1]),
        .I5(lmfc_counter[1]),
        .O(\lmfc_counter[7]_i_6_n_0 ));
  FDSE \lmfc_counter_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[0]),
        .Q(lmfc_counter[0]),
        .S(reset));
  FDRE \lmfc_counter_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[1]),
        .Q(lmfc_counter[1]),
        .R(reset));
  FDRE \lmfc_counter_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[2]),
        .Q(lmfc_counter[2]),
        .R(reset));
  FDRE \lmfc_counter_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[3]),
        .Q(lmfc_counter[3]),
        .R(reset));
  FDRE \lmfc_counter_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[4]),
        .Q(lmfc_counter[4]),
        .R(reset));
  FDRE \lmfc_counter_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[5]),
        .Q(lmfc_counter[5]),
        .R(reset));
  FDRE \lmfc_counter_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[6]),
        .Q(lmfc_counter[6]),
        .R(reset));
  FDRE \lmfc_counter_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(p_0_in[7]),
        .Q(lmfc_counter[7]),
        .R(reset));
  LUT6 #(
    .INIT(64'h0000000100000000)) 
    lmfc_edge_i_1
       (.I0(lmfc_edge_i_2_n_0),
        .I1(lmfc_counter[7]),
        .I2(lmfc_counter[6]),
        .I3(lmfc_counter[4]),
        .I4(lmfc_counter[5]),
        .I5(lmfc_active),
        .O(lmfc_edge0));
  (* SOFT_HLUTNM = "soft_lutpair28" *) 
  LUT4 #(
    .INIT(16'hFFFE)) 
    lmfc_edge_i_2
       (.I0(lmfc_counter[2]),
        .I1(lmfc_counter[3]),
        .I2(lmfc_counter[0]),
        .I3(lmfc_counter[1]),
        .O(lmfc_edge_i_2_n_0));
  FDRE lmfc_edge_reg
       (.C(clk),
        .CE(1'b1),
        .D(lmfc_edge0),
        .Q(lmfc_edge_reg_0),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h8888888888888880)) 
    sysref_alignment_error_i_1
       (.I0(sysref_edge_reg_0),
        .I1(lmfc_active),
        .I2(sysref_alignment_error_i_2_n_0),
        .I3(sysref_alignment_error_i_3_n_0),
        .I4(sysref_alignment_error_i_4_n_0),
        .I5(sysref_alignment_error_i_5_n_0),
        .O(sysref_alignment_error0));
  LUT6 #(
    .INIT(64'hFFFFE77BAAAABDDE)) 
    sysref_alignment_error_i_2
       (.I0(cfg_lmfc_offset[6]),
        .I1(lmfc_counter[7]),
        .I2(lmfc_counter[6]),
        .I3(\lmfc_counter[7]_i_2_n_0 ),
        .I4(lmfc_counter_next1),
        .I5(cfg_lmfc_offset[7]),
        .O(sysref_alignment_error_i_2_n_0));
  LUT6 #(
    .INIT(64'hA99999999AAAAAAA)) 
    sysref_alignment_error_i_3
       (.I0(cfg_lmfc_offset[3]),
        .I1(lmfc_counter_next1),
        .I2(lmfc_counter[1]),
        .I3(lmfc_counter[0]),
        .I4(lmfc_counter[2]),
        .I5(lmfc_counter[3]),
        .O(sysref_alignment_error_i_3_n_0));
  LUT6 #(
    .INIT(64'hFFFFE77BAAAABDDE)) 
    sysref_alignment_error_i_4
       (.I0(cfg_lmfc_offset[4]),
        .I1(lmfc_counter[5]),
        .I2(lmfc_counter[4]),
        .I3(sysref_alignment_error_i_6_n_0),
        .I4(lmfc_counter_next1),
        .I5(cfg_lmfc_offset[5]),
        .O(sysref_alignment_error_i_4_n_0));
  LUT6 #(
    .INIT(64'hFEFEFEDFFEEFFEFD)) 
    sysref_alignment_error_i_5
       (.I0(cfg_lmfc_offset[0]),
        .I1(sysref_alignment_error_i_7_n_0),
        .I2(cfg_lmfc_offset[1]),
        .I3(lmfc_counter_next1),
        .I4(lmfc_counter[0]),
        .I5(lmfc_counter[1]),
        .O(sysref_alignment_error_i_5_n_0));
  (* SOFT_HLUTNM = "soft_lutpair29" *) 
  LUT4 #(
    .INIT(16'h8000)) 
    sysref_alignment_error_i_6
       (.I0(lmfc_counter[3]),
        .I1(lmfc_counter[1]),
        .I2(lmfc_counter[0]),
        .I3(lmfc_counter[2]),
        .O(sysref_alignment_error_i_6_n_0));
  LUT6 #(
    .INIT(64'hAAAA65556555AAAA)) 
    sysref_alignment_error_i_7
       (.I0(cfg_lmfc_offset[2]),
        .I1(sysref_alignment_error_i_8_n_0),
        .I2(\lmfc_counter[7]_i_5_n_0 ),
        .I3(\lmfc_counter[7]_i_6_n_0 ),
        .I4(sysref_alignment_error_i_9_n_0),
        .I5(lmfc_counter[2]),
        .O(sysref_alignment_error_i_7_n_0));
  LUT4 #(
    .INIT(16'h6FF6)) 
    sysref_alignment_error_i_8
       (.I0(lmfc_counter[6]),
        .I1(cfg_beats_per_multiframe[6]),
        .I2(lmfc_counter[7]),
        .I3(cfg_beats_per_multiframe[7]),
        .O(sysref_alignment_error_i_8_n_0));
  (* SOFT_HLUTNM = "soft_lutpair27" *) 
  LUT2 #(
    .INIT(4'h8)) 
    sysref_alignment_error_i_9
       (.I0(lmfc_counter[1]),
        .I1(lmfc_counter[0]),
        .O(sysref_alignment_error_i_9_n_0));
  FDRE sysref_alignment_error_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref_alignment_error0),
        .Q(event_sysref_alignment_error),
        .R(reset));
  (* SOFT_HLUTNM = "soft_lutpair31" *) 
  LUT2 #(
    .INIT(4'hE)) 
    sysref_captured_i_1
       (.I0(sysref_edge_reg_0),
        .I1(sysref_captured),
        .O(sysref_captured_i_1_n_0));
  FDRE sysref_captured_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref_captured_i_1_n_0),
        .Q(sysref_captured),
        .R(reset));
  (* ASYNC_REG *) 
  FDRE #(
    .INIT(1'b0)) 
    sysref_d1_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref_r),
        .Q(sysref_d1),
        .R(1'b0));
  (* ASYNC_REG *) 
  FDRE #(
    .INIT(1'b0)) 
    sysref_d2_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref_d1),
        .Q(sysref_d2),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    sysref_d3_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref_d2),
        .Q(sysref_d3),
        .R(1'b0));
  LUT3 #(
    .INIT(8'h04)) 
    sysref_edge_i_1
       (.I0(cfg_sysref_disable),
        .I1(sysref_d2),
        .I2(sysref_d3),
        .O(sysref_edge0));
  FDRE sysref_edge_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref_edge0),
        .Q(sysref_edge_reg_0),
        .R(1'b0));
  (* IOB = "TRUE" *) 
  FDRE #(
    .INIT(1'b0)) 
    sysref_r_reg
       (.C(clk),
        .CE(1'b1),
        .D(sysref),
        .Q(sysref_r),
        .R(1'b0));
endmodule

(* ALIGN_MUX_REGISTERED = "0" *) (* CHAR_INFO_REGISTERED = "0" *) (* CW = "16" *) 
(* DATA_PATH_WIDTH = "4" *) (* DW = "128" *) (* ELASTIC_BUFFER_SIZE = "128" *) 
(* HW = "8" *) (* LINK_MODE = "1" *) (* LMFC_COUNTER_WIDTH = "7" *) 
(* MAX_BEATS_PER_MULTIFRAME = "128" *) (* MAX_OCTETS_PER_FRAME = "16" *) (* MAX_OCTETS_PER_MULTIFRAME = "512" *) 
(* NUM_INPUT_PIPELINE = "1" *) (* NUM_LANES = "4" *) (* NUM_LINKS = "1" *) 
(* ORIG_REF_NAME = "jesd204_rx" *) (* SCRAMBLER_REGISTERED = "0" *) 
module jesd204_rx_0_jesd204_rx
   (clk,
    reset,
    phy_data,
    phy_header,
    phy_charisk,
    phy_notintable,
    phy_disperr,
    phy_block_sync,
    sysref,
    lmfc_edge,
    lmfc_clk,
    event_sysref_alignment_error,
    event_sysref_edge,
    sync,
    phy_en_char_align,
    rx_data,
    rx_valid,
    rx_eof,
    rx_sof,
    cfg_lanes_disable,
    cfg_links_disable,
    cfg_beats_per_multiframe,
    cfg_octets_per_frame,
    cfg_lmfc_offset,
    cfg_sysref_disable,
    cfg_sysref_oneshot,
    cfg_buffer_early_release,
    cfg_buffer_delay,
    cfg_disable_char_replacement,
    cfg_disable_scrambler,
    ctrl_err_statistics_reset,
    ctrl_err_statistics_mask,
    status_err_statistics_cnt,
    ilas_config_valid,
    ilas_config_addr,
    ilas_config_data,
    status_ctrl_state,
    status_lane_cgs_state,
    status_lane_ifs_ready,
    status_lane_latency,
    status_lane_emb_state);
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

  wire \<const0> ;
  wire buffer_release_d1;
  wire buffer_release_n;
  wire buffer_release_opportunity;
  wire [7:0]cfg_beats_per_multiframe;
  wire [7:0]cfg_buffer_delay;
  wire cfg_buffer_early_release;
  wire cfg_disable_scrambler;
  wire [3:0]cfg_lanes_disable;
  wire [0:0]cfg_links_disable;
  wire [7:0]cfg_lmfc_offset;
  wire [7:0]cfg_octets_per_frame;
  wire cfg_sysref_disable;
  wire cfg_sysref_oneshot;
  wire cgs_beat_has_error;
  wire cgs_beat_has_error_0;
  wire cgs_beat_has_error_4;
  wire cgs_beat_has_error_8;
  wire [3:0]cgs_ready;
  wire [3:0]cgs_reset;
  wire [3:0]charisk28;
  wire [3:0]charisk28_12;
  wire [3:0]charisk28_13;
  wire [3:0]charisk28_14;
  wire clk;
  wire [6:0]ctrl_err_statistics_mask;
  wire ctrl_err_statistics_reset;
  wire [31:24]data_aligned_s;
  wire [31:24]data_aligned_s_10;
  wire [31:24]data_aligned_s_2;
  wire [31:24]data_aligned_s_6;
  wire eof_reset;
  wire event_sysref_alignment_error;
  wire event_sysref_edge;
  wire [1:1]frame_align;
  wire [1:1]frame_align_1;
  wire [1:1]frame_align_5;
  wire [1:1]frame_align_9;
  wire [3:3]\i_align_mux/in_charisk_d1 ;
  wire [3:3]\i_align_mux/in_charisk_d1_15 ;
  wire [3:3]\i_align_mux/in_charisk_d1_18 ;
  wire [3:3]\i_align_mux/in_charisk_d1_20 ;
  wire \i_ilas_monitor/prev_was_last0 ;
  wire \i_ilas_monitor/prev_was_last0_11 ;
  wire \i_ilas_monitor/prev_was_last0_3 ;
  wire \i_ilas_monitor/prev_was_last0_7 ;
  wire i_input_pipeline_stage_n_0;
  wire i_input_pipeline_stage_n_10;
  wire i_input_pipeline_stage_n_15;
  wire i_input_pipeline_stage_n_157;
  wire i_input_pipeline_stage_n_158;
  wire i_input_pipeline_stage_n_159;
  wire i_input_pipeline_stage_n_160;
  wire i_input_pipeline_stage_n_161;
  wire i_input_pipeline_stage_n_173;
  wire i_input_pipeline_stage_n_174;
  wire i_input_pipeline_stage_n_175;
  wire i_input_pipeline_stage_n_176;
  wire i_input_pipeline_stage_n_177;
  wire i_input_pipeline_stage_n_189;
  wire i_input_pipeline_stage_n_190;
  wire i_input_pipeline_stage_n_191;
  wire i_input_pipeline_stage_n_192;
  wire i_input_pipeline_stage_n_193;
  wire i_input_pipeline_stage_n_205;
  wire i_input_pipeline_stage_n_206;
  wire i_input_pipeline_stage_n_207;
  wire i_input_pipeline_stage_n_208;
  wire i_input_pipeline_stage_n_209;
  wire i_input_pipeline_stage_n_212;
  wire i_input_pipeline_stage_n_213;
  wire i_input_pipeline_stage_n_214;
  wire i_input_pipeline_stage_n_215;
  wire i_input_pipeline_stage_n_5;
  wire i_lmfc_n_4;
  wire [3:0]ifs_ready;
  wire [3:0]ifs_reset;
  wire [7:0]ilas_config_addr;
  wire [127:0]ilas_config_data;
  wire [3:0]ilas_config_valid;
  wire [31:24]in_data_d1;
  wire [31:24]in_data_d1_16;
  wire [31:24]in_data_d1_19;
  wire [31:24]in_data_d1_21;
  wire latency_monitor_reset;
  wire lmfc_clk;
  wire lmfc_edge;
  wire \mode_8b10b.gen_lane[0].i_lane_n_49 ;
  wire \mode_8b10b.gen_lane[0].i_lane_n_52 ;
  wire \mode_8b10b.gen_lane[0].i_lane_n_54 ;
  wire \mode_8b10b.gen_lane[1].i_lane_n_18 ;
  wire \mode_8b10b.gen_lane[1].i_lane_n_20 ;
  wire \mode_8b10b.gen_lane[2].i_lane_n_18 ;
  wire \mode_8b10b.gen_lane[2].i_lane_n_20 ;
  wire \mode_8b10b.gen_lane[2].i_lane_n_6 ;
  wire \mode_8b10b.gen_lane[3].i_lane_n_18 ;
  wire \mode_8b10b.gen_lane[3].i_lane_n_19 ;
  wire \mode_8b10b.gen_lane[3].i_lane_n_21 ;
  wire p_1_out;
  wire p_27_out;
  wire p_4_out;
  wire p_7_out;
  wire p_7_out_17;
  wire p_9_out;
  wire [15:0]phy_charisk;
  wire [127:0]phy_data;
  wire [127:0]phy_data_r;
  wire [15:0]phy_disperr;
  wire phy_en_char_align;
  wire [15:0]phy_notintable;
  wire reset;
  wire [127:0]rx_data;
  wire [3:3]\^rx_eof ;
  wire [3:0]\^rx_sof ;
  wire rx_valid;
  wire [1:0]status_ctrl_state;
  wire [127:0]status_err_statistics_cnt;
  wire status_err_statistics_cnt0;
  wire [7:0]status_lane_cgs_state;
  wire [3:0]status_lane_ifs_ready;
  wire [55:0]status_lane_latency;
  wire [0:0]sync;
  wire sysref;

  assign rx_eof[3] = \^rx_eof [3];
  assign rx_eof[2:1] = \^rx_sof [3:2];
  assign rx_eof[0] = \^rx_sof [3];
  assign rx_sof[3:2] = \^rx_sof [3:2];
  assign rx_sof[1] = \^rx_sof [3];
  assign rx_sof[0] = \^rx_sof [0];
  assign status_lane_emb_state[11] = \<const0> ;
  assign status_lane_emb_state[10] = \<const0> ;
  assign status_lane_emb_state[9] = \<const0> ;
  assign status_lane_emb_state[8] = \<const0> ;
  assign status_lane_emb_state[7] = \<const0> ;
  assign status_lane_emb_state[6] = \<const0> ;
  assign status_lane_emb_state[5] = \<const0> ;
  assign status_lane_emb_state[4] = \<const0> ;
  assign status_lane_emb_state[3] = \<const0> ;
  assign status_lane_emb_state[2] = \<const0> ;
  assign status_lane_emb_state[1] = \<const0> ;
  assign status_lane_emb_state[0] = \<const0> ;
  GND GND
       (.G(\<const0> ));
  FDRE #(
    .INIT(1'b0)) 
    buffer_release_d1_reg
       (.C(clk),
        .CE(1'b1),
        .D(\mode_8b10b.gen_lane[3].i_lane_n_18 ),
        .Q(buffer_release_d1),
        .R(1'b0));
  FDSE #(
    .INIT(1'b1)) 
    buffer_release_n_reg
       (.C(clk),
        .CE(1'b1),
        .D(\mode_8b10b.gen_lane[0].i_lane_n_54 ),
        .Q(buffer_release_n),
        .S(reset));
  FDRE #(
    .INIT(1'b0)) 
    buffer_release_opportunity_reg
       (.C(clk),
        .CE(1'b1),
        .D(i_lmfc_n_4),
        .Q(buffer_release_opportunity),
        .R(1'b0));
  FDRE #(
    .INIT(1'b1)) 
    eof_reset_reg
       (.C(clk),
        .CE(1'b1),
        .D(buffer_release_n),
        .Q(eof_reset),
        .R(1'b0));
  jesd204_rx_0_jesd204_eof_generator i_eof_gen
       (.cfg_octets_per_frame(cfg_octets_per_frame[3:0]),
        .clk(clk),
        .eof_reset(eof_reset),
        .rx_eof(\^rx_eof ),
        .rx_sof({\^rx_sof [3:2],\^rx_sof [0]}));
  jesd204_rx_0_pipeline_stage__parameterized2 i_input_pipeline_stage
       (.D(data_aligned_s_10),
        .\FSM_onehot_state[2]_i_2_0 (status_lane_cgs_state[1]),
        .\FSM_onehot_state[2]_i_2_1 (status_lane_cgs_state[0]),
        .\FSM_onehot_state[2]_i_2__0_0 (status_lane_cgs_state[3]),
        .\FSM_onehot_state[2]_i_2__0_1 (status_lane_cgs_state[2]),
        .\FSM_onehot_state[2]_i_2__1_0 (status_lane_cgs_state[5]),
        .\FSM_onehot_state[2]_i_2__1_1 (status_lane_cgs_state[4]),
        .\FSM_onehot_state[2]_i_2__2_0 (status_lane_cgs_state[7]),
        .\FSM_onehot_state[2]_i_2__2_1 (status_lane_cgs_state[6]),
        .\FSM_onehot_state_reg[0] (i_input_pipeline_stage_n_161),
        .\FSM_onehot_state_reg[0]_0 (i_input_pipeline_stage_n_177),
        .\FSM_onehot_state_reg[0]_1 (i_input_pipeline_stage_n_193),
        .\FSM_onehot_state_reg[0]_10 (\mode_8b10b.gen_lane[3].i_lane_n_19 ),
        .\FSM_onehot_state_reg[0]_2 (i_input_pipeline_stage_n_209),
        .\FSM_onehot_state_reg[0]_3 (\mode_8b10b.gen_lane[0].i_lane_n_52 ),
        .\FSM_onehot_state_reg[0]_4 (\mode_8b10b.gen_lane[0].i_lane_n_49 ),
        .\FSM_onehot_state_reg[0]_5 (\mode_8b10b.gen_lane[1].i_lane_n_20 ),
        .\FSM_onehot_state_reg[0]_6 (\mode_8b10b.gen_lane[1].i_lane_n_18 ),
        .\FSM_onehot_state_reg[0]_7 (\mode_8b10b.gen_lane[2].i_lane_n_20 ),
        .\FSM_onehot_state_reg[0]_8 (\mode_8b10b.gen_lane[2].i_lane_n_18 ),
        .\FSM_onehot_state_reg[0]_9 (\mode_8b10b.gen_lane[3].i_lane_n_21 ),
        .Q(\i_align_mux/in_charisk_d1 ),
        .cgs_beat_has_error(cgs_beat_has_error_8),
        .cgs_beat_has_error_11(cgs_beat_has_error),
        .cgs_beat_has_error_5(cgs_beat_has_error_4),
        .cgs_beat_has_error_8(cgs_beat_has_error_0),
        .charisk28(charisk28_14),
        .charisk28_0(charisk28_13),
        .charisk28_1(charisk28_12),
        .charisk28_2(charisk28),
        .clk(clk),
        .ctrl_err_statistics_mask(ctrl_err_statistics_mask[2:0]),
        .frame_align(frame_align_9),
        .frame_align_10(frame_align),
        .frame_align_4(frame_align_5),
        .frame_align_7(frame_align_1),
        .\frame_align_reg[0] (status_lane_latency[0]),
        .\frame_align_reg[0]_0 (status_lane_latency[14]),
        .\frame_align_reg[0]_1 (status_lane_latency[28]),
        .\frame_align_reg[0]_2 (status_lane_latency[42]),
        .ifs_ready(ifs_ready),
        .ifs_ready_reg(i_input_pipeline_stage_n_0),
        .ifs_ready_reg_0(i_input_pipeline_stage_n_5),
        .ifs_ready_reg_1(i_input_pipeline_stage_n_10),
        .ifs_ready_reg_2(i_input_pipeline_stage_n_15),
        .ifs_ready_reg_3(i_input_pipeline_stage_n_212),
        .ifs_ready_reg_4(i_input_pipeline_stage_n_213),
        .ifs_ready_reg_5(i_input_pipeline_stage_n_214),
        .ifs_ready_reg_6(i_input_pipeline_stage_n_215),
        .ifs_ready_reg_7(ifs_reset),
        .\ilas_config_data_reg[24] (status_lane_latency[1]),
        .\ilas_config_data_reg[24]_0 (status_lane_latency[15]),
        .\ilas_config_data_reg[24]_1 (status_lane_latency[29]),
        .\ilas_config_data_reg[24]_2 (status_lane_latency[43]),
        .\ilas_config_data_reg[31] (in_data_d1),
        .\ilas_config_data_reg[31]_0 (in_data_d1_16),
        .\ilas_config_data_reg[31]_1 (in_data_d1_19),
        .\ilas_config_data_reg[31]_2 (in_data_d1_21),
        .\in_dly_reg[107]_0 (data_aligned_s_6),
        .\in_dly_reg[139]_0 (data_aligned_s_2),
        .\in_dly_reg[171]_0 (data_aligned_s),
        .\in_dly_reg[187]_0 (phy_data_r),
        .\in_dly_reg[187]_1 ({phy_data,phy_charisk,phy_notintable,phy_disperr}),
        .\in_dly_reg[23]_0 ({i_input_pipeline_stage_n_157,i_input_pipeline_stage_n_158,i_input_pipeline_stage_n_159,i_input_pipeline_stage_n_160}),
        .\in_dly_reg[27]_0 ({i_input_pipeline_stage_n_173,i_input_pipeline_stage_n_174,i_input_pipeline_stage_n_175,i_input_pipeline_stage_n_176}),
        .\in_dly_reg[31]_0 ({i_input_pipeline_stage_n_189,i_input_pipeline_stage_n_190,i_input_pipeline_stage_n_191,i_input_pipeline_stage_n_192}),
        .\in_dly_reg[35]_0 ({i_input_pipeline_stage_n_205,i_input_pipeline_stage_n_206,i_input_pipeline_stage_n_207,i_input_pipeline_stage_n_208}),
        .prev_was_last0(\i_ilas_monitor/prev_was_last0_11 ),
        .prev_was_last0_3(\i_ilas_monitor/prev_was_last0_7 ),
        .prev_was_last0_6(\i_ilas_monitor/prev_was_last0_3 ),
        .prev_was_last0_9(\i_ilas_monitor/prev_was_last0 ),
        .prev_was_last_reg(\i_align_mux/in_charisk_d1_15 ),
        .prev_was_last_reg_0(\i_align_mux/in_charisk_d1_18 ),
        .prev_was_last_reg_1(\i_align_mux/in_charisk_d1_20 ));
  jesd204_rx_0_jesd204_lmfc i_lmfc
       (.cfg_beats_per_multiframe(cfg_beats_per_multiframe),
        .cfg_buffer_delay(cfg_buffer_delay),
        .cfg_buffer_early_release(cfg_buffer_early_release),
        .cfg_buffer_early_release_0(i_lmfc_n_4),
        .cfg_lmfc_offset(cfg_lmfc_offset),
        .cfg_sysref_disable(cfg_sysref_disable),
        .cfg_sysref_oneshot(cfg_sysref_oneshot),
        .clk(clk),
        .event_sysref_alignment_error(event_sysref_alignment_error),
        .lmfc_clk(lmfc_clk),
        .lmfc_edge_reg_0(lmfc_edge),
        .reset(reset),
        .sysref(sysref),
        .sysref_edge_reg_0(event_sysref_edge));
  jesd204_rx_0_pipeline_stage__parameterized3 i_output_pipeline_stage
       (.buffer_release_d1(buffer_release_d1),
        .clk(clk),
        .rx_valid(rx_valid));
  jesd204_rx_0_jesd204_rx_lane \mode_8b10b.gen_lane[0].i_lane 
       (.D(data_aligned_s_10),
        .E(p_9_out),
        .\FSM_onehot_state_reg[0] (\mode_8b10b.gen_lane[0].i_lane_n_52 ),
        .\FSM_onehot_state_reg[0]_0 (i_input_pipeline_stage_n_161),
        .\FSM_onehot_state_reg[0]_1 (cgs_reset[0]),
        .\FSM_onehot_state_reg[1] (status_lane_cgs_state[0]),
        .\FSM_onehot_state_reg[2] (status_lane_cgs_state[1]),
        .Q(in_data_d1),
        .SR(status_err_statistics_cnt0),
        .\beat_error_count_reg[1] (\mode_8b10b.gen_lane[0].i_lane_n_49 ),
        .buffer_release_n(buffer_release_n),
        .buffer_release_n_reg(\mode_8b10b.gen_lane[2].i_lane_n_6 ),
        .buffer_release_opportunity(buffer_release_opportunity),
        .buffer_release_opportunity_reg(\mode_8b10b.gen_lane[0].i_lane_n_54 ),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cfg_lanes_disable({cfg_lanes_disable[3],cfg_lanes_disable[0]}),
        .cgs_beat_has_error(cgs_beat_has_error_8),
        .cgs_ready(cgs_ready[0]),
        .clk(clk),
        .ctrl_err_statistics_reset(ctrl_err_statistics_reset),
        .frame_align(frame_align_9),
        .\frame_align_reg[0]_0 (status_lane_latency[0]),
        .\frame_align_reg[0]_1 (i_input_pipeline_stage_n_0),
        .\frame_align_reg[1]_0 (status_lane_latency[1]),
        .ifs_ready(ifs_ready[0]),
        .ifs_ready_reg_0(i_input_pipeline_stage_n_212),
        .ilas_config_addr(ilas_config_addr[1:0]),
        .ilas_config_data(ilas_config_data[31:0]),
        .ilas_config_valid_reg(ilas_config_valid[0]),
        .\in_charisk_d1_reg[3] (\i_align_mux/in_charisk_d1 ),
        .\in_charisk_d1_reg[3]_0 (charisk28_14),
        .\in_data_d1_reg[31] (phy_data_r[31:0]),
        .mem_reg(\mode_8b10b.gen_lane[3].i_lane_n_18 ),
        .p_7_out(p_7_out),
        .\phy_char_err_reg[3]_0 ({i_input_pipeline_stage_n_157,i_input_pipeline_stage_n_158,i_input_pipeline_stage_n_159,i_input_pipeline_stage_n_160}),
        .prev_was_last0(\i_ilas_monitor/prev_was_last0_11 ),
        .reset(reset),
        .rx_data(rx_data[31:0]),
        .status_err_statistics_cnt(status_err_statistics_cnt[31:0]),
        .status_lane_ifs_ready(status_lane_ifs_ready[0]));
  jesd204_rx_0_jesd204_rx_lane_0 \mode_8b10b.gen_lane[1].i_lane 
       (.D(data_aligned_s_6),
        .E(p_7_out_17),
        .\FSM_onehot_state_reg[0] (\mode_8b10b.gen_lane[1].i_lane_n_20 ),
        .\FSM_onehot_state_reg[0]_0 (i_input_pipeline_stage_n_177),
        .\FSM_onehot_state_reg[0]_1 (cgs_reset[1]),
        .\FSM_onehot_state_reg[1] (status_lane_cgs_state[2]),
        .\FSM_onehot_state_reg[2] (status_lane_cgs_state[3]),
        .Q(in_data_d1_16),
        .SR(status_err_statistics_cnt0),
        .\beat_error_count_reg[1] (\mode_8b10b.gen_lane[1].i_lane_n_18 ),
        .buffer_release_n(buffer_release_n),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cgs_beat_has_error(cgs_beat_has_error_4),
        .cgs_ready(cgs_ready[1]),
        .clk(clk),
        .frame_align(frame_align_5),
        .\frame_align_reg[0]_0 (status_lane_latency[14]),
        .\frame_align_reg[0]_1 (i_input_pipeline_stage_n_5),
        .\frame_align_reg[1]_0 (status_lane_latency[15]),
        .ifs_ready(ifs_ready[1]),
        .ifs_ready_reg_0(i_input_pipeline_stage_n_213),
        .ilas_config_addr(ilas_config_addr[3:2]),
        .ilas_config_data(ilas_config_data[63:32]),
        .ilas_config_valid_reg(ilas_config_valid[1]),
        .\in_charisk_d1_reg[3] (\i_align_mux/in_charisk_d1_15 ),
        .\in_charisk_d1_reg[3]_0 (charisk28_13),
        .\in_data_d1_reg[31] (phy_data_r[63:32]),
        .mem_reg(\mode_8b10b.gen_lane[3].i_lane_n_18 ),
        .p_27_out(p_27_out),
        .\phy_char_err_reg[3]_0 ({i_input_pipeline_stage_n_173,i_input_pipeline_stage_n_174,i_input_pipeline_stage_n_175,i_input_pipeline_stage_n_176}),
        .prev_was_last0(\i_ilas_monitor/prev_was_last0_7 ),
        .rx_data(rx_data[63:32]),
        .status_err_statistics_cnt(status_err_statistics_cnt[63:32]),
        .status_lane_ifs_ready(status_lane_ifs_ready[1]));
  jesd204_rx_0_jesd204_rx_lane_1 \mode_8b10b.gen_lane[2].i_lane 
       (.D(data_aligned_s_2),
        .E(p_4_out),
        .\FSM_onehot_state_reg[0] (\mode_8b10b.gen_lane[2].i_lane_n_20 ),
        .\FSM_onehot_state_reg[0]_0 (i_input_pipeline_stage_n_193),
        .\FSM_onehot_state_reg[0]_1 (cgs_reset[2]),
        .\FSM_onehot_state_reg[1] (status_lane_cgs_state[4]),
        .\FSM_onehot_state_reg[2] (status_lane_cgs_state[5]),
        .Q(in_data_d1_19),
        .SR(status_err_statistics_cnt0),
        .\beat_error_count_reg[1] (\mode_8b10b.gen_lane[2].i_lane_n_18 ),
        .buffer_release_n(buffer_release_n),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cfg_lanes_disable(cfg_lanes_disable[2:1]),
        .\cfg_lanes_disable[2] (\mode_8b10b.gen_lane[2].i_lane_n_6 ),
        .cgs_beat_has_error(cgs_beat_has_error_0),
        .cgs_ready(cgs_ready[2]),
        .clk(clk),
        .frame_align(frame_align_1),
        .\frame_align_reg[0]_0 (status_lane_latency[28]),
        .\frame_align_reg[0]_1 (i_input_pipeline_stage_n_10),
        .\frame_align_reg[1]_0 (status_lane_latency[29]),
        .ifs_ready(ifs_ready[2]),
        .ifs_ready_reg_0(i_input_pipeline_stage_n_214),
        .ilas_config_addr(ilas_config_addr[5:4]),
        .ilas_config_data(ilas_config_data[95:64]),
        .ilas_config_valid_reg(ilas_config_valid[2]),
        .\in_charisk_d1_reg[3] (\i_align_mux/in_charisk_d1_18 ),
        .\in_charisk_d1_reg[3]_0 (charisk28_12),
        .\in_data_d1_reg[31] (phy_data_r[95:64]),
        .mem_reg(\mode_8b10b.gen_lane[3].i_lane_n_18 ),
        .p_27_out(p_27_out),
        .\phy_char_err_reg[3]_0 ({i_input_pipeline_stage_n_189,i_input_pipeline_stage_n_190,i_input_pipeline_stage_n_191,i_input_pipeline_stage_n_192}),
        .prev_was_last0(\i_ilas_monitor/prev_was_last0_3 ),
        .rx_data(rx_data[95:64]),
        .status_err_statistics_cnt(status_err_statistics_cnt[95:64]),
        .status_lane_ifs_ready(status_lane_ifs_ready[2]));
  jesd204_rx_0_jesd204_rx_lane_2 \mode_8b10b.gen_lane[3].i_lane 
       (.D(data_aligned_s),
        .E(p_1_out),
        .\FSM_onehot_state_reg[0] (\mode_8b10b.gen_lane[3].i_lane_n_21 ),
        .\FSM_onehot_state_reg[0]_0 (i_input_pipeline_stage_n_209),
        .\FSM_onehot_state_reg[0]_1 (cgs_reset[3]),
        .\FSM_onehot_state_reg[1] (status_lane_cgs_state[6]),
        .\FSM_onehot_state_reg[2] (status_lane_cgs_state[7]),
        .Q(in_data_d1_21),
        .SR(status_err_statistics_cnt0),
        .\beat_error_count_reg[1] (\mode_8b10b.gen_lane[3].i_lane_n_19 ),
        .buffer_release_n(buffer_release_n),
        .buffer_release_n_reg(\mode_8b10b.gen_lane[3].i_lane_n_18 ),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cgs_beat_has_error(cgs_beat_has_error),
        .cgs_ready(cgs_ready[3]),
        .clk(clk),
        .frame_align(frame_align),
        .\frame_align_reg[0]_0 (status_lane_latency[42]),
        .\frame_align_reg[0]_1 (i_input_pipeline_stage_n_15),
        .\frame_align_reg[1]_0 (status_lane_latency[43]),
        .ifs_ready(ifs_ready[3]),
        .ifs_ready_reg_0(i_input_pipeline_stage_n_215),
        .ilas_config_addr(ilas_config_addr[7:6]),
        .ilas_config_data(ilas_config_data[127:96]),
        .ilas_config_valid_reg(ilas_config_valid[3]),
        .\in_charisk_d1_reg[3] (\i_align_mux/in_charisk_d1_20 ),
        .\in_charisk_d1_reg[3]_0 (charisk28),
        .\in_data_d1_reg[31] (phy_data_r[127:96]),
        .p_7_out(p_7_out),
        .\phy_char_err_reg[3]_0 ({i_input_pipeline_stage_n_205,i_input_pipeline_stage_n_206,i_input_pipeline_stage_n_207,i_input_pipeline_stage_n_208}),
        .prev_was_last0(\i_ilas_monitor/prev_was_last0 ),
        .rx_data(rx_data[127:96]),
        .status_err_statistics_cnt(status_err_statistics_cnt[127:96]),
        .status_lane_ifs_ready(status_lane_ifs_ready[3]));
  jesd204_rx_0_jesd204_lane_latency_monitor \mode_8b10b.i_lane_latency_monitor 
       (.E(p_9_out),
        .clk(clk),
        .\gen_lane[1].lane_latency_mem_reg[1][11]_0 (p_7_out_17),
        .\gen_lane[2].lane_latency_mem_reg[2][11]_0 (p_4_out),
        .\gen_lane[3].lane_latency_mem_reg[3][11]_0 (p_1_out),
        .latency_monitor_reset(latency_monitor_reset),
        .status_lane_ifs_ready(status_lane_ifs_ready),
        .status_lane_latency({status_lane_latency[55:44],status_lane_latency[41:30],status_lane_latency[27:16],status_lane_latency[13:2]}));
  jesd204_rx_0_jesd204_rx_ctrl \mode_8b10b.i_rx_ctrl 
       (.Q(cgs_reset),
        .cfg_lanes_disable(cfg_lanes_disable),
        .cfg_links_disable(cfg_links_disable),
        .cgs_ready(cgs_ready),
        .clk(clk),
        .\ifs_rst_reg[3]_0 (ifs_reset),
        .latency_monitor_reset(latency_monitor_reset),
        .phy_en_char_align(phy_en_char_align),
        .reset(reset),
        .status_ctrl_state(status_ctrl_state),
        .sync(sync),
        .\sync_n_reg[0]_0 (lmfc_edge));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_cgs" *) 
module jesd204_rx_0_jesd204_rx_cgs
   (cgs_ready,
    SR,
    \beat_error_count_reg[1]_0 ,
    \FSM_onehot_state_reg[1]_0 ,
    \FSM_onehot_state_reg[0]_0 ,
    \FSM_onehot_state_reg[2]_0 ,
    clk,
    \FSM_onehot_state_reg[0]_1 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_2 );
  output [0:0]cgs_ready;
  output [0:0]SR;
  output \beat_error_count_reg[1]_0 ;
  output \FSM_onehot_state_reg[1]_0 ;
  output \FSM_onehot_state_reg[0]_0 ;
  output \FSM_onehot_state_reg[2]_0 ;
  input clk;
  input \FSM_onehot_state_reg[0]_1 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_2 ;

  wire \FSM_onehot_state[0]_i_1__2_n_0 ;
  wire \FSM_onehot_state[1]_i_1__2_n_0 ;
  wire \FSM_onehot_state[2]_i_1__2_n_0 ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire \FSM_onehot_state_reg[0]_1 ;
  wire [0:0]\FSM_onehot_state_reg[0]_2 ;
  wire \FSM_onehot_state_reg[1]_0 ;
  wire \FSM_onehot_state_reg[2]_0 ;
  wire [0:0]SR;
  wire \beat_error_count[0]_i_1__2_n_0 ;
  wire \beat_error_count[1]_i_1__2_n_0 ;
  wire \beat_error_count_reg[1]_0 ;
  wire \beat_error_count_reg_n_0_[0] ;
  wire \beat_error_count_reg_n_0_[1] ;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire rdy_i_1__2_n_0;

  LUT5 #(
    .INIT(32'hFFFFE222)) 
    \FSM_onehot_state[0]_i_1__2 
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[0]_i_1__2_n_0 ));
  LUT5 #(
    .INIT(32'h0000EEE2)) 
    \FSM_onehot_state[1]_i_1__2 
       (.I0(\FSM_onehot_state_reg[1]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(\FSM_onehot_state_reg[2]_0 ),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[1]_i_1__2_n_0 ));
  LUT5 #(
    .INIT(32'h00002E22)) 
    \FSM_onehot_state[2]_i_1__2 
       (.I0(\FSM_onehot_state_reg[2]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[2]_i_1__2_n_0 ));
  LUT3 #(
    .INIT(8'h80)) 
    \FSM_onehot_state[2]_i_6__2 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(\FSM_onehot_state_reg[1]_0 ),
        .O(\beat_error_count_reg[1]_0 ));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b1)) 
    \FSM_onehot_state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[0]_i_1__2_n_0 ),
        .Q(\FSM_onehot_state_reg[0]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[1]_i_1__2_n_0 ),
        .Q(\FSM_onehot_state_reg[1]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[2]_i_1__2_n_0 ),
        .Q(\FSM_onehot_state_reg[2]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair70" *) 
  LUT3 #(
    .INIT(8'h04)) 
    \beat_error_count[0]_i_1__2 
       (.I0(\beat_error_count_reg_n_0_[0] ),
        .I1(cgs_beat_has_error),
        .I2(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[0]_i_1__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair70" *) 
  LUT4 #(
    .INIT(16'h0060)) 
    \beat_error_count[1]_i_1__2 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[1]_i_1__2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[0]_i_1__2_n_0 ),
        .Q(\beat_error_count_reg_n_0_[0] ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[1]_i_1__2_n_0 ),
        .Q(\beat_error_count_reg_n_0_[1] ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair71" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \phy_char_err[3]_i_1__2 
       (.I0(cgs_ready),
        .O(SR));
  (* SOFT_HLUTNM = "soft_lutpair71" *) 
  LUT3 #(
    .INIT(8'hDC)) 
    rdy_i_1__2
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[2]_0 ),
        .I2(cgs_ready),
        .O(rdy_i_1__2_n_0));
  FDRE #(
    .INIT(1'b0)) 
    rdy_reg
       (.C(clk),
        .CE(1'b1),
        .D(rdy_i_1__2_n_0),
        .Q(cgs_ready),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_cgs" *) 
module jesd204_rx_0_jesd204_rx_cgs_14
   (cgs_ready,
    SR,
    \beat_error_count_reg[1]_0 ,
    \FSM_onehot_state_reg[1]_0 ,
    \FSM_onehot_state_reg[0]_0 ,
    \FSM_onehot_state_reg[2]_0 ,
    clk,
    \FSM_onehot_state_reg[0]_1 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_2 );
  output [0:0]cgs_ready;
  output [0:0]SR;
  output \beat_error_count_reg[1]_0 ;
  output \FSM_onehot_state_reg[1]_0 ;
  output \FSM_onehot_state_reg[0]_0 ;
  output \FSM_onehot_state_reg[2]_0 ;
  input clk;
  input \FSM_onehot_state_reg[0]_1 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_2 ;

  wire \FSM_onehot_state[0]_i_1_n_0 ;
  wire \FSM_onehot_state[1]_i_1_n_0 ;
  wire \FSM_onehot_state[2]_i_1_n_0 ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire \FSM_onehot_state_reg[0]_1 ;
  wire [0:0]\FSM_onehot_state_reg[0]_2 ;
  wire \FSM_onehot_state_reg[1]_0 ;
  wire \FSM_onehot_state_reg[2]_0 ;
  wire [0:0]SR;
  wire \beat_error_count[0]_i_1_n_0 ;
  wire \beat_error_count[1]_i_1_n_0 ;
  wire \beat_error_count_reg[1]_0 ;
  wire \beat_error_count_reg_n_0_[0] ;
  wire \beat_error_count_reg_n_0_[1] ;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire rdy_i_1_n_0;

  LUT5 #(
    .INIT(32'hFFFFE222)) 
    \FSM_onehot_state[0]_i_1 
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[0]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h0000EEE2)) 
    \FSM_onehot_state[1]_i_1 
       (.I0(\FSM_onehot_state_reg[1]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(\FSM_onehot_state_reg[2]_0 ),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[1]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00002E22)) 
    \FSM_onehot_state[2]_i_1 
       (.I0(\FSM_onehot_state_reg[2]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[2]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'h80)) 
    \FSM_onehot_state[2]_i_6 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(\FSM_onehot_state_reg[1]_0 ),
        .O(\beat_error_count_reg[1]_0 ));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b1)) 
    \FSM_onehot_state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[0]_i_1_n_0 ),
        .Q(\FSM_onehot_state_reg[0]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[1]_i_1_n_0 ),
        .Q(\FSM_onehot_state_reg[1]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[2]_i_1_n_0 ),
        .Q(\FSM_onehot_state_reg[2]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair34" *) 
  LUT3 #(
    .INIT(8'h04)) 
    \beat_error_count[0]_i_1 
       (.I0(\beat_error_count_reg_n_0_[0] ),
        .I1(cgs_beat_has_error),
        .I2(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair34" *) 
  LUT4 #(
    .INIT(16'h0060)) 
    \beat_error_count[1]_i_1 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[1]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[0]_i_1_n_0 ),
        .Q(\beat_error_count_reg_n_0_[0] ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[1]_i_1_n_0 ),
        .Q(\beat_error_count_reg_n_0_[1] ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair35" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \phy_char_err[3]_i_1 
       (.I0(cgs_ready),
        .O(SR));
  (* SOFT_HLUTNM = "soft_lutpair35" *) 
  LUT3 #(
    .INIT(8'hDC)) 
    rdy_i_1
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[2]_0 ),
        .I2(cgs_ready),
        .O(rdy_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    rdy_reg
       (.C(clk),
        .CE(1'b1),
        .D(rdy_i_1_n_0),
        .Q(cgs_ready),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_cgs" *) 
module jesd204_rx_0_jesd204_rx_cgs_4
   (cgs_ready,
    SR,
    \beat_error_count_reg[1]_0 ,
    \FSM_onehot_state_reg[1]_0 ,
    \FSM_onehot_state_reg[0]_0 ,
    \FSM_onehot_state_reg[2]_0 ,
    clk,
    \FSM_onehot_state_reg[0]_1 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_2 );
  output [0:0]cgs_ready;
  output [0:0]SR;
  output \beat_error_count_reg[1]_0 ;
  output \FSM_onehot_state_reg[1]_0 ;
  output \FSM_onehot_state_reg[0]_0 ;
  output \FSM_onehot_state_reg[2]_0 ;
  input clk;
  input \FSM_onehot_state_reg[0]_1 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_2 ;

  wire \FSM_onehot_state[0]_i_1__1_n_0 ;
  wire \FSM_onehot_state[1]_i_1__1_n_0 ;
  wire \FSM_onehot_state[2]_i_1__1_n_0 ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire \FSM_onehot_state_reg[0]_1 ;
  wire [0:0]\FSM_onehot_state_reg[0]_2 ;
  wire \FSM_onehot_state_reg[1]_0 ;
  wire \FSM_onehot_state_reg[2]_0 ;
  wire [0:0]SR;
  wire \beat_error_count[0]_i_1__1_n_0 ;
  wire \beat_error_count[1]_i_1__1_n_0 ;
  wire \beat_error_count_reg[1]_0 ;
  wire \beat_error_count_reg_n_0_[0] ;
  wire \beat_error_count_reg_n_0_[1] ;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire rdy_i_1__1_n_0;

  LUT5 #(
    .INIT(32'hFFFFE222)) 
    \FSM_onehot_state[0]_i_1__1 
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[0]_i_1__1_n_0 ));
  LUT5 #(
    .INIT(32'h0000EEE2)) 
    \FSM_onehot_state[1]_i_1__1 
       (.I0(\FSM_onehot_state_reg[1]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(\FSM_onehot_state_reg[2]_0 ),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[1]_i_1__1_n_0 ));
  LUT5 #(
    .INIT(32'h00002E22)) 
    \FSM_onehot_state[2]_i_1__1 
       (.I0(\FSM_onehot_state_reg[2]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[2]_i_1__1_n_0 ));
  LUT3 #(
    .INIT(8'h80)) 
    \FSM_onehot_state[2]_i_6__1 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(\FSM_onehot_state_reg[1]_0 ),
        .O(\beat_error_count_reg[1]_0 ));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b1)) 
    \FSM_onehot_state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[0]_i_1__1_n_0 ),
        .Q(\FSM_onehot_state_reg[0]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[1]_i_1__1_n_0 ),
        .Q(\FSM_onehot_state_reg[1]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[2]_i_1__1_n_0 ),
        .Q(\FSM_onehot_state_reg[2]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair58" *) 
  LUT3 #(
    .INIT(8'h04)) 
    \beat_error_count[0]_i_1__1 
       (.I0(\beat_error_count_reg_n_0_[0] ),
        .I1(cgs_beat_has_error),
        .I2(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[0]_i_1__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair58" *) 
  LUT4 #(
    .INIT(16'h0060)) 
    \beat_error_count[1]_i_1__1 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[1]_i_1__1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[0]_i_1__1_n_0 ),
        .Q(\beat_error_count_reg_n_0_[0] ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[1]_i_1__1_n_0 ),
        .Q(\beat_error_count_reg_n_0_[1] ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair59" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \phy_char_err[3]_i_1__1 
       (.I0(cgs_ready),
        .O(SR));
  (* SOFT_HLUTNM = "soft_lutpair59" *) 
  LUT3 #(
    .INIT(8'hDC)) 
    rdy_i_1__1
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[2]_0 ),
        .I2(cgs_ready),
        .O(rdy_i_1__1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    rdy_reg
       (.C(clk),
        .CE(1'b1),
        .D(rdy_i_1__1_n_0),
        .Q(cgs_ready),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_cgs" *) 
module jesd204_rx_0_jesd204_rx_cgs_9
   (cgs_ready,
    SR,
    \beat_error_count_reg[1]_0 ,
    \FSM_onehot_state_reg[1]_0 ,
    \FSM_onehot_state_reg[0]_0 ,
    \FSM_onehot_state_reg[2]_0 ,
    clk,
    \FSM_onehot_state_reg[0]_1 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_2 );
  output [0:0]cgs_ready;
  output [0:0]SR;
  output \beat_error_count_reg[1]_0 ;
  output \FSM_onehot_state_reg[1]_0 ;
  output \FSM_onehot_state_reg[0]_0 ;
  output \FSM_onehot_state_reg[2]_0 ;
  input clk;
  input \FSM_onehot_state_reg[0]_1 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_2 ;

  wire \FSM_onehot_state[0]_i_1__0_n_0 ;
  wire \FSM_onehot_state[1]_i_1__0_n_0 ;
  wire \FSM_onehot_state[2]_i_1__0_n_0 ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire \FSM_onehot_state_reg[0]_1 ;
  wire [0:0]\FSM_onehot_state_reg[0]_2 ;
  wire \FSM_onehot_state_reg[1]_0 ;
  wire \FSM_onehot_state_reg[2]_0 ;
  wire [0:0]SR;
  wire \beat_error_count[0]_i_1__0_n_0 ;
  wire \beat_error_count[1]_i_1__0_n_0 ;
  wire \beat_error_count_reg[1]_0 ;
  wire \beat_error_count_reg_n_0_[0] ;
  wire \beat_error_count_reg_n_0_[1] ;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire rdy_i_1__0_n_0;

  LUT5 #(
    .INIT(32'hFFFFE222)) 
    \FSM_onehot_state[0]_i_1__0 
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[0]_i_1__0_n_0 ));
  LUT5 #(
    .INIT(32'h0000EEE2)) 
    \FSM_onehot_state[1]_i_1__0 
       (.I0(\FSM_onehot_state_reg[1]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(\FSM_onehot_state_reg[2]_0 ),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[1]_i_1__0_n_0 ));
  LUT5 #(
    .INIT(32'h00002E22)) 
    \FSM_onehot_state[2]_i_1__0 
       (.I0(\FSM_onehot_state_reg[2]_0 ),
        .I1(\FSM_onehot_state_reg[0]_1 ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[1]_0 ),
        .I4(\FSM_onehot_state_reg[0]_2 ),
        .O(\FSM_onehot_state[2]_i_1__0_n_0 ));
  LUT3 #(
    .INIT(8'h80)) 
    \FSM_onehot_state[2]_i_6__0 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(\FSM_onehot_state_reg[1]_0 ),
        .O(\beat_error_count_reg[1]_0 ));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b1)) 
    \FSM_onehot_state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[0]_i_1__0_n_0 ),
        .Q(\FSM_onehot_state_reg[0]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[1]_i_1__0_n_0 ),
        .Q(\FSM_onehot_state_reg[1]_0 ),
        .R(1'b0));
  (* FSM_ENCODED_STATES = "CGS_STATE_CHECK:010,CGS_STATE_DATA:100,CGS_STATE_INIT:001" *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_onehot_state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_onehot_state[2]_i_1__0_n_0 ),
        .Q(\FSM_onehot_state_reg[2]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair45" *) 
  LUT3 #(
    .INIT(8'h04)) 
    \beat_error_count[0]_i_1__0 
       (.I0(\beat_error_count_reg_n_0_[0] ),
        .I1(cgs_beat_has_error),
        .I2(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[0]_i_1__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair45" *) 
  LUT4 #(
    .INIT(16'h0060)) 
    \beat_error_count[1]_i_1__0 
       (.I0(\beat_error_count_reg_n_0_[1] ),
        .I1(\beat_error_count_reg_n_0_[0] ),
        .I2(cgs_beat_has_error),
        .I3(\FSM_onehot_state_reg[0]_0 ),
        .O(\beat_error_count[1]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[0]_i_1__0_n_0 ),
        .Q(\beat_error_count_reg_n_0_[0] ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \beat_error_count_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\beat_error_count[1]_i_1__0_n_0 ),
        .Q(\beat_error_count_reg_n_0_[1] ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair46" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \phy_char_err[3]_i_1__0 
       (.I0(cgs_ready),
        .O(SR));
  (* SOFT_HLUTNM = "soft_lutpair46" *) 
  LUT3 #(
    .INIT(8'hDC)) 
    rdy_i_1__0
       (.I0(\FSM_onehot_state_reg[0]_0 ),
        .I1(\FSM_onehot_state_reg[2]_0 ),
        .I2(cgs_ready),
        .O(rdy_i_1__0_n_0));
  FDRE #(
    .INIT(1'b0)) 
    rdy_reg
       (.C(clk),
        .CE(1'b1),
        .D(rdy_i_1__0_n_0),
        .Q(cgs_ready),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_ctrl" *) 
module jesd204_rx_0_jesd204_rx_ctrl
   (phy_en_char_align,
    sync,
    latency_monitor_reset,
    Q,
    \ifs_rst_reg[3]_0 ,
    status_ctrl_state,
    clk,
    cgs_ready,
    cfg_lanes_disable,
    \sync_n_reg[0]_0 ,
    cfg_links_disable,
    reset);
  output phy_en_char_align;
  output [0:0]sync;
  output latency_monitor_reset;
  output [3:0]Q;
  output [3:0]\ifs_rst_reg[3]_0 ;
  output [1:0]status_ctrl_state;
  input clk;
  input [3:0]cgs_ready;
  input [3:0]cfg_lanes_disable;
  input \sync_n_reg[0]_0 ;
  input [0:0]cfg_links_disable;
  input reset;

  wire \FSM_sequential_state[0]_i_1_n_0 ;
  wire \FSM_sequential_state[1]_i_1_n_0 ;
  wire \FSM_sequential_state[2]_i_1_n_0 ;
  wire \FSM_sequential_state[2]_i_2_n_0 ;
  wire \FSM_sequential_state[2]_i_4_n_0 ;
  wire \FSM_sequential_state[2]_i_5_n_0 ;
  wire \FSM_sequential_state[2]_i_6_n_0 ;
  wire \FSM_sequential_state[2]_i_7_n_0 ;
  wire [3:0]Q;
  wire [3:0]cfg_lanes_disable;
  wire [0:0]cfg_links_disable;
  wire [3:0]cgs_ready;
  wire cgs_rst0;
  wire clk;
  wire [9:0]deglitch_counter0;
  wire \deglitch_counter[9]_i_1_n_0 ;
  wire \deglitch_counter[9]_i_4_n_0 ;
  wire [9:0]deglitch_counter_reg;
  wire en_align_i_1_n_0;
  wire [2:0]good_counter;
  wire \good_counter[0]_i_1_n_0 ;
  wire \good_counter[1]_i_1_n_0 ;
  wire \good_counter[2]_i_1_n_0 ;
  wire \good_counter[2]_i_2_n_0 ;
  wire \ifs_rst[3]_i_1_n_0 ;
  wire [3:0]\ifs_rst_reg[3]_0 ;
  wire latency_monitor_reset;
  wire latency_monitor_reset_i_1_n_0;
  wire phy_en_char_align;
  wire reset;
  wire sel;
  wire [2:0]state;
  wire state_good__4;
  wire [1:0]status_ctrl_state;
  wire \status_state[0]_i_1_n_0 ;
  wire \status_state[1]_i_1_n_0 ;
  wire [0:0]sync;
  wire \sync_n[0]_i_1_n_0 ;
  wire \sync_n_reg[0]_0 ;

  LUT6 #(
    .INIT(64'hFF7F7F7F00800080)) 
    \FSM_sequential_state[0]_i_1 
       (.I0(good_counter[0]),
        .I1(good_counter[1]),
        .I2(good_counter[2]),
        .I3(state[2]),
        .I4(state_good__4),
        .I5(state[0]),
        .O(\FSM_sequential_state[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFFDFCFDF00200020)) 
    \FSM_sequential_state[1]_i_1 
       (.I0(state[0]),
        .I1(\FSM_sequential_state[2]_i_2_n_0 ),
        .I2(good_counter[2]),
        .I3(state[2]),
        .I4(state_good__4),
        .I5(state[1]),
        .O(\FSM_sequential_state[1]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFFFF0800F0FF0800)) 
    \FSM_sequential_state[2]_i_1 
       (.I0(state[0]),
        .I1(state[1]),
        .I2(\FSM_sequential_state[2]_i_2_n_0 ),
        .I3(good_counter[2]),
        .I4(state[2]),
        .I5(state_good__4),
        .O(\FSM_sequential_state[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair86" *) 
  LUT2 #(
    .INIT(4'h7)) 
    \FSM_sequential_state[2]_i_2 
       (.I0(good_counter[0]),
        .I1(good_counter[1]),
        .O(\FSM_sequential_state[2]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hABAFFFFFABAFABAF)) 
    \FSM_sequential_state[2]_i_3 
       (.I0(\FSM_sequential_state[2]_i_4_n_0 ),
        .I1(state[2]),
        .I2(state[1]),
        .I3(state[0]),
        .I4(\deglitch_counter[9]_i_4_n_0 ),
        .I5(\FSM_sequential_state[2]_i_5_n_0 ),
        .O(state_good__4));
  LUT5 #(
    .INIT(32'hA8A8A800)) 
    \FSM_sequential_state[2]_i_4 
       (.I0(\FSM_sequential_state[2]_i_6_n_0 ),
        .I1(cgs_ready[0]),
        .I2(cfg_lanes_disable[0]),
        .I3(cgs_ready[1]),
        .I4(cfg_lanes_disable[1]),
        .O(\FSM_sequential_state[2]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000100000)) 
    \FSM_sequential_state[2]_i_5 
       (.I0(deglitch_counter_reg[6]),
        .I1(deglitch_counter_reg[7]),
        .I2(\FSM_sequential_state[2]_i_7_n_0 ),
        .I3(state[2]),
        .I4(state[0]),
        .I5(deglitch_counter_reg[5]),
        .O(\FSM_sequential_state[2]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h000E000E000E0000)) 
    \FSM_sequential_state[2]_i_6 
       (.I0(cgs_ready[2]),
        .I1(cfg_lanes_disable[2]),
        .I2(state[2]),
        .I3(state[0]),
        .I4(cfg_lanes_disable[3]),
        .I5(cgs_ready[3]),
        .O(\FSM_sequential_state[2]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \FSM_sequential_state[2]_i_7 
       (.I0(deglitch_counter_reg[8]),
        .I1(deglitch_counter_reg[9]),
        .O(\FSM_sequential_state[2]_i_7_n_0 ));
  (* FSM_ENCODED_STATES = "iSTATE:100,STATE_RESET:000,STATE_WAIT_FOR_PHY:001,STATE_CGS:010,STATE_DEGLITCH:011," *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_sequential_state[0]_i_1_n_0 ),
        .Q(state[0]),
        .R(reset));
  (* FSM_ENCODED_STATES = "iSTATE:100,STATE_RESET:000,STATE_WAIT_FOR_PHY:001,STATE_CGS:010,STATE_DEGLITCH:011," *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_sequential_state[1]_i_1_n_0 ),
        .Q(state[1]),
        .R(reset));
  (* FSM_ENCODED_STATES = "iSTATE:100,STATE_RESET:000,STATE_WAIT_FOR_PHY:001,STATE_CGS:010,STATE_DEGLITCH:011," *) 
  FDRE #(
    .INIT(1'b0)) 
    \FSM_sequential_state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\FSM_sequential_state[2]_i_1_n_0 ),
        .Q(state[2]),
        .R(reset));
  LUT3 #(
    .INIT(8'h01)) 
    \cgs_rst[3]_i_1 
       (.I0(state[1]),
        .I1(state[0]),
        .I2(state[2]),
        .O(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \cgs_rst_reg[0] 
       (.C(clk),
        .CE(en_align_i_1_n_0),
        .D(cfg_lanes_disable[0]),
        .Q(Q[0]),
        .S(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \cgs_rst_reg[1] 
       (.C(clk),
        .CE(en_align_i_1_n_0),
        .D(cfg_lanes_disable[1]),
        .Q(Q[1]),
        .S(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \cgs_rst_reg[2] 
       (.C(clk),
        .CE(en_align_i_1_n_0),
        .D(cfg_lanes_disable[2]),
        .Q(Q[2]),
        .S(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \cgs_rst_reg[3] 
       (.C(clk),
        .CE(en_align_i_1_n_0),
        .D(cfg_lanes_disable[3]),
        .Q(Q[3]),
        .S(cgs_rst0));
  (* SOFT_HLUTNM = "soft_lutpair87" *) 
  LUT1 #(
    .INIT(2'h1)) 
    \deglitch_counter[0]_i_1 
       (.I0(deglitch_counter_reg[0]),
        .O(deglitch_counter0[0]));
  (* SOFT_HLUTNM = "soft_lutpair87" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \deglitch_counter[1]_i_1 
       (.I0(deglitch_counter_reg[1]),
        .I1(deglitch_counter_reg[0]),
        .O(deglitch_counter0[1]));
  (* SOFT_HLUTNM = "soft_lutpair85" *) 
  LUT3 #(
    .INIT(8'hA9)) 
    \deglitch_counter[2]_i_1 
       (.I0(deglitch_counter_reg[2]),
        .I1(deglitch_counter_reg[0]),
        .I2(deglitch_counter_reg[1]),
        .O(deglitch_counter0[2]));
  (* SOFT_HLUTNM = "soft_lutpair85" *) 
  LUT4 #(
    .INIT(16'hAAA9)) 
    \deglitch_counter[3]_i_1 
       (.I0(deglitch_counter_reg[3]),
        .I1(deglitch_counter_reg[1]),
        .I2(deglitch_counter_reg[0]),
        .I3(deglitch_counter_reg[2]),
        .O(deglitch_counter0[3]));
  (* SOFT_HLUTNM = "soft_lutpair82" *) 
  LUT5 #(
    .INIT(32'hAAAAAAA9)) 
    \deglitch_counter[4]_i_1 
       (.I0(deglitch_counter_reg[4]),
        .I1(deglitch_counter_reg[2]),
        .I2(deglitch_counter_reg[0]),
        .I3(deglitch_counter_reg[1]),
        .I4(deglitch_counter_reg[3]),
        .O(deglitch_counter0[4]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAAAA9)) 
    \deglitch_counter[5]_i_1 
       (.I0(deglitch_counter_reg[5]),
        .I1(deglitch_counter_reg[3]),
        .I2(deglitch_counter_reg[1]),
        .I3(deglitch_counter_reg[0]),
        .I4(deglitch_counter_reg[2]),
        .I5(deglitch_counter_reg[4]),
        .O(deglitch_counter0[5]));
  LUT3 #(
    .INIT(8'hA9)) 
    \deglitch_counter[6]_i_1 
       (.I0(deglitch_counter_reg[6]),
        .I1(\deglitch_counter[9]_i_4_n_0 ),
        .I2(deglitch_counter_reg[5]),
        .O(deglitch_counter0[6]));
  (* SOFT_HLUTNM = "soft_lutpair81" *) 
  LUT4 #(
    .INIT(16'hAAA9)) 
    \deglitch_counter[7]_i_1 
       (.I0(deglitch_counter_reg[7]),
        .I1(deglitch_counter_reg[5]),
        .I2(\deglitch_counter[9]_i_4_n_0 ),
        .I3(deglitch_counter_reg[6]),
        .O(deglitch_counter0[7]));
  (* SOFT_HLUTNM = "soft_lutpair81" *) 
  LUT5 #(
    .INIT(32'hAAAAAAA9)) 
    \deglitch_counter[8]_i_1 
       (.I0(deglitch_counter_reg[8]),
        .I1(deglitch_counter_reg[6]),
        .I2(\deglitch_counter[9]_i_4_n_0 ),
        .I3(deglitch_counter_reg[5]),
        .I4(deglitch_counter_reg[7]),
        .O(deglitch_counter0[8]));
  LUT3 #(
    .INIT(8'hBF)) 
    \deglitch_counter[9]_i_1 
       (.I0(state[2]),
        .I1(state[1]),
        .I2(state[0]),
        .O(\deglitch_counter[9]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \deglitch_counter[9]_i_2 
       (.I0(\deglitch_counter[9]_i_4_n_0 ),
        .I1(deglitch_counter_reg[5]),
        .I2(deglitch_counter_reg[6]),
        .I3(deglitch_counter_reg[8]),
        .I4(deglitch_counter_reg[9]),
        .I5(deglitch_counter_reg[7]),
        .O(sel));
  LUT6 #(
    .INIT(64'hFFFFFFFE00000001)) 
    \deglitch_counter[9]_i_3 
       (.I0(deglitch_counter_reg[8]),
        .I1(deglitch_counter_reg[6]),
        .I2(\deglitch_counter[9]_i_4_n_0 ),
        .I3(deglitch_counter_reg[5]),
        .I4(deglitch_counter_reg[7]),
        .I5(deglitch_counter_reg[9]),
        .O(deglitch_counter0[9]));
  (* SOFT_HLUTNM = "soft_lutpair82" *) 
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    \deglitch_counter[9]_i_4 
       (.I0(deglitch_counter_reg[3]),
        .I1(deglitch_counter_reg[1]),
        .I2(deglitch_counter_reg[0]),
        .I3(deglitch_counter_reg[2]),
        .I4(deglitch_counter_reg[4]),
        .O(\deglitch_counter[9]_i_4_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[0] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[0]),
        .Q(deglitch_counter_reg[0]),
        .S(\deglitch_counter[9]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[1] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[1]),
        .Q(deglitch_counter_reg[1]),
        .S(\deglitch_counter[9]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[2] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[2]),
        .Q(deglitch_counter_reg[2]),
        .S(\deglitch_counter[9]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[3] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[3]),
        .Q(deglitch_counter_reg[3]),
        .S(\deglitch_counter[9]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[4] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[4]),
        .Q(deglitch_counter_reg[4]),
        .S(\deglitch_counter[9]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[5] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[5]),
        .Q(deglitch_counter_reg[5]),
        .S(\deglitch_counter[9]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[6] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[6]),
        .Q(deglitch_counter_reg[6]),
        .R(\deglitch_counter[9]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[7] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[7]),
        .Q(deglitch_counter_reg[7]),
        .R(\deglitch_counter[9]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[8] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[8]),
        .Q(deglitch_counter_reg[8]),
        .R(\deglitch_counter[9]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b1)) 
    \deglitch_counter_reg[9] 
       (.C(clk),
        .CE(sel),
        .D(deglitch_counter0[9]),
        .Q(deglitch_counter_reg[9]),
        .R(\deglitch_counter[9]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'h02)) 
    en_align_i_1
       (.I0(state[1]),
        .I1(state[2]),
        .I2(state[0]),
        .O(en_align_i_1_n_0));
  FDRE #(
    .INIT(1'b0)) 
    en_align_reg
       (.C(clk),
        .CE(1'b1),
        .D(en_align_i_1_n_0),
        .Q(phy_en_char_align),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair86" *) 
  LUT2 #(
    .INIT(4'h1)) 
    \good_counter[0]_i_1 
       (.I0(good_counter[0]),
        .I1(\good_counter[2]_i_2_n_0 ),
        .O(\good_counter[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair84" *) 
  LUT3 #(
    .INIT(8'h06)) 
    \good_counter[1]_i_1 
       (.I0(good_counter[1]),
        .I1(good_counter[0]),
        .I2(\good_counter[2]_i_2_n_0 ),
        .O(\good_counter[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair84" *) 
  LUT4 #(
    .INIT(16'h006A)) 
    \good_counter[2]_i_1 
       (.I0(good_counter[2]),
        .I1(good_counter[0]),
        .I2(good_counter[1]),
        .I3(\good_counter[2]_i_2_n_0 ),
        .O(\good_counter[2]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h00000000DDD0DD00)) 
    \good_counter[2]_i_2 
       (.I0(\FSM_sequential_state[2]_i_5_n_0 ),
        .I1(\deglitch_counter[9]_i_4_n_0 ),
        .I2(state[0]),
        .I3(state[1]),
        .I4(state[2]),
        .I5(\FSM_sequential_state[2]_i_4_n_0 ),
        .O(\good_counter[2]_i_2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \good_counter_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\good_counter[0]_i_1_n_0 ),
        .Q(good_counter[0]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \good_counter_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\good_counter[1]_i_1_n_0 ),
        .Q(good_counter[1]),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \good_counter_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\good_counter[2]_i_1_n_0 ),
        .Q(good_counter[2]),
        .R(1'b0));
  LUT4 #(
    .INIT(16'h0008)) 
    \ifs_rst[3]_i_1 
       (.I0(state[2]),
        .I1(\sync_n_reg[0]_0 ),
        .I2(state[1]),
        .I3(state[0]),
        .O(\ifs_rst[3]_i_1_n_0 ));
  FDSE #(
    .INIT(1'b1)) 
    \ifs_rst_reg[0] 
       (.C(clk),
        .CE(\ifs_rst[3]_i_1_n_0 ),
        .D(cfg_lanes_disable[0]),
        .Q(\ifs_rst_reg[3]_0 [0]),
        .S(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \ifs_rst_reg[1] 
       (.C(clk),
        .CE(\ifs_rst[3]_i_1_n_0 ),
        .D(cfg_lanes_disable[1]),
        .Q(\ifs_rst_reg[3]_0 [1]),
        .S(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \ifs_rst_reg[2] 
       (.C(clk),
        .CE(\ifs_rst[3]_i_1_n_0 ),
        .D(cfg_lanes_disable[2]),
        .Q(\ifs_rst_reg[3]_0 [2]),
        .S(cgs_rst0));
  FDSE #(
    .INIT(1'b1)) 
    \ifs_rst_reg[3] 
       (.C(clk),
        .CE(\ifs_rst[3]_i_1_n_0 ),
        .D(cfg_lanes_disable[3]),
        .Q(\ifs_rst_reg[3]_0 [3]),
        .S(cgs_rst0));
  (* SOFT_HLUTNM = "soft_lutpair83" *) 
  LUT5 #(
    .INIT(32'hCCCCCC4F)) 
    latency_monitor_reset_i_1
       (.I0(\sync_n_reg[0]_0 ),
        .I1(latency_monitor_reset),
        .I2(state[2]),
        .I3(state[0]),
        .I4(state[1]),
        .O(latency_monitor_reset_i_1_n_0));
  FDRE latency_monitor_reset_reg
       (.C(clk),
        .CE(1'b1),
        .D(latency_monitor_reset_i_1_n_0),
        .Q(latency_monitor_reset),
        .R(1'b0));
  LUT2 #(
    .INIT(4'hB)) 
    \status_state[0]_i_1 
       (.I0(state[2]),
        .I1(state[1]),
        .O(\status_state[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair83" *) 
  LUT3 #(
    .INIT(8'h1C)) 
    \status_state[1]_i_1 
       (.I0(state[0]),
        .I1(state[1]),
        .I2(state[2]),
        .O(\status_state[1]_i_1_n_0 ));
  FDRE \status_state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\status_state[0]_i_1_n_0 ),
        .Q(status_ctrl_state[0]),
        .R(1'b0));
  FDRE \status_state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\status_state[1]_i_1_n_0 ),
        .Q(status_ctrl_state[1]),
        .R(1'b0));
  LUT6 #(
    .INIT(64'hAAAAAAF0AAAAEEFF)) 
    \sync_n[0]_i_1 
       (.I0(sync),
        .I1(\sync_n_reg[0]_0 ),
        .I2(cfg_links_disable),
        .I3(state[2]),
        .I4(state[0]),
        .I5(state[1]),
        .O(\sync_n[0]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b1)) 
    \sync_n_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\sync_n[0]_i_1_n_0 ),
        .Q(sync),
        .R(1'b0));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_lane" *) 
module jesd204_rx_0_jesd204_rx_lane
   (rx_data,
    \frame_align_reg[1]_0 ,
    \frame_align_reg[0]_0 ,
    ifs_ready,
    ilas_config_valid_reg,
    cgs_ready,
    E,
    Q,
    \in_charisk_d1_reg[3] ,
    ilas_config_addr,
    \beat_error_count_reg[1] ,
    \FSM_onehot_state_reg[1] ,
    SR,
    \FSM_onehot_state_reg[0] ,
    \FSM_onehot_state_reg[2] ,
    buffer_release_opportunity_reg,
    ilas_config_data,
    status_err_statistics_cnt,
    clk,
    mem_reg,
    \frame_align_reg[0]_1 ,
    prev_was_last0,
    buffer_release_n,
    ifs_ready_reg_0,
    frame_align,
    status_lane_ifs_ready,
    cfg_disable_scrambler,
    D,
    \in_data_d1_reg[31] ,
    \in_charisk_d1_reg[3]_0 ,
    cfg_lanes_disable,
    p_7_out,
    reset,
    ctrl_err_statistics_reset,
    buffer_release_n_reg,
    buffer_release_opportunity,
    \FSM_onehot_state_reg[0]_0 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_1 ,
    \phy_char_err_reg[3]_0 );
  output [31:0]rx_data;
  output \frame_align_reg[1]_0 ;
  output \frame_align_reg[0]_0 ;
  output [0:0]ifs_ready;
  output ilas_config_valid_reg;
  output [0:0]cgs_ready;
  output [0:0]E;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3] ;
  output [1:0]ilas_config_addr;
  output \beat_error_count_reg[1] ;
  output \FSM_onehot_state_reg[1] ;
  output [0:0]SR;
  output \FSM_onehot_state_reg[0] ;
  output \FSM_onehot_state_reg[2] ;
  output buffer_release_opportunity_reg;
  output [31:0]ilas_config_data;
  output [31:0]status_err_statistics_cnt;
  input clk;
  input mem_reg;
  input \frame_align_reg[0]_1 ;
  input prev_was_last0;
  input buffer_release_n;
  input ifs_ready_reg_0;
  input [0:0]frame_align;
  input [0:0]status_lane_ifs_ready;
  input cfg_disable_scrambler;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31] ;
  input [3:0]\in_charisk_d1_reg[3]_0 ;
  input [1:0]cfg_lanes_disable;
  input p_7_out;
  input reset;
  input ctrl_err_statistics_reset;
  input buffer_release_n_reg;
  input buffer_release_opportunity;
  input \FSM_onehot_state_reg[0]_0 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_1 ;
  input [3:0]\phy_char_err_reg[3]_0 ;

  wire [7:0]D;
  wire [0:0]E;
  wire \FSM_onehot_state_reg[0] ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire [0:0]\FSM_onehot_state_reg[0]_1 ;
  wire \FSM_onehot_state_reg[1] ;
  wire \FSM_onehot_state_reg[2] ;
  wire [7:0]Q;
  wire [0:0]SR;
  wire \beat_error_count_reg[1] ;
  wire buffer_release_n;
  wire buffer_release_n_reg;
  wire buffer_release_opportunity;
  wire buffer_release_opportunity_reg;
  wire cfg_disable_scrambler;
  wire [1:0]cfg_lanes_disable;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire ctrl_err_statistics_reset;
  wire [23:0]data_aligned_s;
  wire [31:0]data_scrambled_s;
  wire [0:0]frame_align;
  wire \frame_align[1]_i_1_n_0 ;
  wire \frame_align_reg[0]_0 ;
  wire \frame_align_reg[0]_1 ;
  wire \frame_align_reg[1]_0 ;
  wire [32:32]full_state;
  wire i___0_carry_i_1_n_0;
  wire i___0_carry_i_2_n_0;
  wire i___65_carry_i_1_n_0;
  wire i___65_carry_i_2_n_0;
  wire i_align_mux_n_52;
  wire i_align_mux_n_54;
  wire i_align_mux_n_55;
  wire i_cgs_n_1;
  wire i_ilas_monitor_n_3;
  wire [0:0]ifs_ready;
  wire ifs_ready_reg_0;
  wire [1:0]ilas_config_addr;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg;
  wire [0:0]\in_charisk_d1_reg[3] ;
  wire [3:0]\in_charisk_d1_reg[3]_0 ;
  wire [31:0]\in_data_d1_reg[31] ;
  wire mem_reg;
  wire p_0_in0_in;
  wire p_0_in1_in;
  wire p_0_in_0;
  wire p_37_out;
  wire p_7_out;
  wire [3:0]\phy_char_err_reg[3]_0 ;
  wire \phy_char_err_reg_n_0_[0] ;
  wire prev_was_last;
  wire prev_was_last0;
  wire reset;
  wire [31:0]rx_data;
  wire state;
  wire [31:0]status_err_statistics_cnt;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ;
  wire \status_err_statistics_cnt[31]_i_1__0_n_0 ;
  wire \status_err_statistics_cnt[31]_i_2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_3_n_0 ;
  wire \status_err_statistics_cnt[31]_i_4_n_0 ;
  wire \status_err_statistics_cnt[31]_i_5_n_0 ;
  wire \status_err_statistics_cnt[31]_i_6_n_0 ;
  wire [0:0]status_lane_ifs_ready;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED ;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED ;

  (* SOFT_HLUTNM = "soft_lutpair43" *) 
  LUT3 #(
    .INIT(8'hE2)) 
    \frame_align[1]_i_1 
       (.I0(frame_align),
        .I1(ifs_ready),
        .I2(\frame_align_reg[1]_0 ),
        .O(\frame_align[1]_i_1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align_reg[0]_1 ),
        .Q(\frame_align_reg[0]_0 ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align[1]_i_1_n_0 ),
        .Q(\frame_align_reg[1]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair43" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \gen_lane[0].lane_captured[0]_i_1 
       (.I0(ifs_ready),
        .I1(status_lane_ifs_ready),
        .O(E));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___0_carry_i_1
       (.I0(status_err_statistics_cnt[0]),
        .I1(\phy_char_err_reg_n_0_[0] ),
        .I2(p_0_in1_in),
        .I3(status_err_statistics_cnt[1]),
        .O(i___0_carry_i_1_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___0_carry_i_2
       (.I0(status_err_statistics_cnt[0]),
        .I1(p_0_in1_in),
        .I2(\phy_char_err_reg_n_0_[0] ),
        .O(i___0_carry_i_2_n_0));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___65_carry_i_1
       (.I0(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I1(p_0_in_0),
        .I2(p_0_in0_in),
        .I3(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ),
        .O(i___65_carry_i_1_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___65_carry_i_2
       (.I0(p_0_in0_in),
        .I1(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I2(p_0_in_0),
        .O(i___65_carry_i_2_n_0));
  jesd204_rx_0_align_mux_13 i_align_mux
       (.D(D),
        .Q(Q),
        .SR(p_37_out),
        .WEBWE(i_align_mux_n_55),
        .buffer_release_n(buffer_release_n),
        .buffer_release_n_reg(buffer_release_n_reg),
        .buffer_release_opportunity(buffer_release_opportunity),
        .buffer_release_opportunity_reg(buffer_release_opportunity_reg),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cfg_lanes_disable(cfg_lanes_disable),
        .clk(clk),
        .data_aligned_s(data_aligned_s),
        .data_scrambled_s({data_scrambled_s[31:16],data_scrambled_s[9:8]}),
        .\ilas_config_data_reg[5] (\frame_align_reg[1]_0 ),
        .\ilas_config_data_reg[5]_0 (\frame_align_reg[0]_0 ),
        .ilas_config_valid_reg(i_align_mux_n_52),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_ilas_monitor_n_3),
        .\in_charisk_d1_reg[3]_0 (\in_charisk_d1_reg[3] ),
        .\in_charisk_d1_reg[3]_1 (\in_charisk_d1_reg[3]_0 ),
        .\in_data_d1_reg[31]_0 (\in_data_d1_reg[31] ),
        .mem_reg(full_state),
        .p_7_out(p_7_out),
        .prev_was_last(prev_was_last),
        .state(state),
        .state_reg(i_align_mux_n_54),
        .state_reg_0(ifs_ready));
  jesd204_rx_0_jesd204_rx_cgs_14 i_cgs
       (.\FSM_onehot_state_reg[0]_0 (\FSM_onehot_state_reg[0] ),
        .\FSM_onehot_state_reg[0]_1 (\FSM_onehot_state_reg[0]_0 ),
        .\FSM_onehot_state_reg[0]_2 (\FSM_onehot_state_reg[0]_1 ),
        .\FSM_onehot_state_reg[1]_0 (\FSM_onehot_state_reg[1] ),
        .\FSM_onehot_state_reg[2]_0 (\FSM_onehot_state_reg[2] ),
        .SR(i_cgs_n_1),
        .\beat_error_count_reg[1]_0 (\beat_error_count_reg[1] ),
        .cgs_beat_has_error(cgs_beat_has_error),
        .cgs_ready(cgs_ready),
        .clk(clk));
  jesd204_rx_0_jesd204_scrambler_15 i_descrambler
       (.D({D,data_aligned_s[22:10],data_aligned_s[7:0]}),
        .DIADI({data_scrambled_s[15:10],data_scrambled_s[7:0]}),
        .Q(full_state),
        .SR(p_37_out),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .clk(clk));
  jesd204_rx_0_elastic_buffer_16 i_elastic_buffer
       (.SR(p_37_out),
        .WEBWE(i_align_mux_n_55),
        .buffer_release_n(buffer_release_n),
        .clk(clk),
        .data_scrambled_s(data_scrambled_s),
        .mem_reg_0(mem_reg),
        .rx_data(rx_data));
  jesd204_rx_0_jesd204_ilas_monitor_17 i_ilas_monitor
       (.D({D,data_aligned_s}),
        .clk(clk),
        .ilas_config_addr(ilas_config_addr),
        .\ilas_config_addr_reg[1]_0 (i_ilas_monitor_n_3),
        .ilas_config_data(ilas_config_data),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_align_mux_n_52),
        .prev_was_last(prev_was_last),
        .prev_was_last0(prev_was_last0),
        .state(state),
        .state_reg_0(i_align_mux_n_54));
  FDRE #(
    .INIT(1'b0)) 
    ifs_ready_reg
       (.C(clk),
        .CE(1'b1),
        .D(ifs_ready_reg_0),
        .Q(ifs_ready),
        .R(1'b0));
  FDRE \phy_char_err_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [0]),
        .Q(\phy_char_err_reg_n_0_[0] ),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [1]),
        .Q(p_0_in_0),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [2]),
        .Q(p_0_in0_in),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [3]),
        .Q(p_0_in1_in),
        .R(i_cgs_n_1));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,status_err_statistics_cnt[1],1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 }),
        .S({status_err_statistics_cnt[3:2],i___0_carry_i_1_n_0,i___0_carry_i_2_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }),
        .S(status_err_statistics_cnt[7:4]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }),
        .S(status_err_statistics_cnt[11:8]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }),
        .S(status_err_statistics_cnt[15:12]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }),
        .S(status_err_statistics_cnt[19:16]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }),
        .S(status_err_statistics_cnt[23:20]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }),
        .S(status_err_statistics_cnt[27:24]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }),
        .S(status_err_statistics_cnt[31:28]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,i___65_carry_i_1_n_0,i___65_carry_i_2_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }));
  LUT2 #(
    .INIT(4'hE)) 
    \status_err_statistics_cnt[31]_i_1 
       (.I0(reset),
        .I1(ctrl_err_statistics_reset),
        .O(SR));
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    \status_err_statistics_cnt[31]_i_1__0 
       (.I0(\status_err_statistics_cnt[31]_i_2_n_0 ),
        .I1(\status_err_statistics_cnt[31]_i_3_n_0 ),
        .I2(\status_err_statistics_cnt[31]_i_4_n_0 ),
        .I3(\status_err_statistics_cnt[31]_i_5_n_0 ),
        .I4(\status_err_statistics_cnt[31]_i_6_n_0 ),
        .O(\status_err_statistics_cnt[31]_i_1__0_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_2 
       (.I0(status_err_statistics_cnt[24]),
        .I1(status_err_statistics_cnt[25]),
        .I2(status_err_statistics_cnt[22]),
        .I3(status_err_statistics_cnt[23]),
        .I4(status_err_statistics_cnt[21]),
        .I5(status_err_statistics_cnt[20]),
        .O(\status_err_statistics_cnt[31]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_3 
       (.I0(status_err_statistics_cnt[30]),
        .I1(status_err_statistics_cnt[31]),
        .I2(status_err_statistics_cnt[28]),
        .I3(status_err_statistics_cnt[29]),
        .I4(status_err_statistics_cnt[27]),
        .I5(status_err_statistics_cnt[26]),
        .O(\status_err_statistics_cnt[31]_i_3_n_0 ));
  LUT3 #(
    .INIT(8'h7F)) 
    \status_err_statistics_cnt[31]_i_4 
       (.I0(status_err_statistics_cnt[7]),
        .I1(status_err_statistics_cnt[6]),
        .I2(status_err_statistics_cnt[5]),
        .O(\status_err_statistics_cnt[31]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_5 
       (.I0(status_err_statistics_cnt[18]),
        .I1(status_err_statistics_cnt[19]),
        .I2(status_err_statistics_cnt[16]),
        .I3(status_err_statistics_cnt[17]),
        .I4(status_err_statistics_cnt[15]),
        .I5(status_err_statistics_cnt[14]),
        .O(\status_err_statistics_cnt[31]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_6 
       (.I0(status_err_statistics_cnt[12]),
        .I1(status_err_statistics_cnt[13]),
        .I2(status_err_statistics_cnt[10]),
        .I3(status_err_statistics_cnt[11]),
        .I4(status_err_statistics_cnt[9]),
        .I5(status_err_statistics_cnt[8]),
        .O(\status_err_statistics_cnt[31]_i_6_n_0 ));
  FDRE \status_err_statistics_cnt_reg[0] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ),
        .Q(status_err_statistics_cnt[0]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[10] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ),
        .Q(status_err_statistics_cnt[10]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[11] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ),
        .Q(status_err_statistics_cnt[11]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[12] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ),
        .Q(status_err_statistics_cnt[12]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[13] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ),
        .Q(status_err_statistics_cnt[13]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[14] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ),
        .Q(status_err_statistics_cnt[14]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[15] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ),
        .Q(status_err_statistics_cnt[15]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[16] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ),
        .Q(status_err_statistics_cnt[16]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[17] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ),
        .Q(status_err_statistics_cnt[17]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[18] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ),
        .Q(status_err_statistics_cnt[18]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[19] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ),
        .Q(status_err_statistics_cnt[19]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[1] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ),
        .Q(status_err_statistics_cnt[1]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[20] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ),
        .Q(status_err_statistics_cnt[20]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[21] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ),
        .Q(status_err_statistics_cnt[21]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[22] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ),
        .Q(status_err_statistics_cnt[22]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[23] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ),
        .Q(status_err_statistics_cnt[23]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[24] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ),
        .Q(status_err_statistics_cnt[24]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[25] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ),
        .Q(status_err_statistics_cnt[25]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[26] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ),
        .Q(status_err_statistics_cnt[26]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[27] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ),
        .Q(status_err_statistics_cnt[27]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[28] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ),
        .Q(status_err_statistics_cnt[28]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[29] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ),
        .Q(status_err_statistics_cnt[29]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[2] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ),
        .Q(status_err_statistics_cnt[2]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[30] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ),
        .Q(status_err_statistics_cnt[30]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[31] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ),
        .Q(status_err_statistics_cnt[31]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[3] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ),
        .Q(status_err_statistics_cnt[3]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[4] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ),
        .Q(status_err_statistics_cnt[4]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[5] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ),
        .Q(status_err_statistics_cnt[5]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[6] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ),
        .Q(status_err_statistics_cnt[6]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[7] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ),
        .Q(status_err_statistics_cnt[7]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[8] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ),
        .Q(status_err_statistics_cnt[8]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[9] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__0_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ),
        .Q(status_err_statistics_cnt[9]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_lane" *) 
module jesd204_rx_0_jesd204_rx_lane_0
   (\frame_align_reg[1]_0 ,
    \frame_align_reg[0]_0 ,
    ifs_ready,
    ilas_config_valid_reg,
    cgs_ready,
    E,
    Q,
    \in_charisk_d1_reg[3] ,
    p_27_out,
    ilas_config_addr,
    \beat_error_count_reg[1] ,
    \FSM_onehot_state_reg[1] ,
    \FSM_onehot_state_reg[0] ,
    \FSM_onehot_state_reg[2] ,
    rx_data,
    ilas_config_data,
    status_err_statistics_cnt,
    clk,
    \frame_align_reg[0]_1 ,
    prev_was_last0,
    buffer_release_n,
    ifs_ready_reg_0,
    frame_align,
    status_lane_ifs_ready,
    cfg_disable_scrambler,
    D,
    \in_data_d1_reg[31] ,
    \in_charisk_d1_reg[3]_0 ,
    mem_reg,
    \FSM_onehot_state_reg[0]_0 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_1 ,
    \phy_char_err_reg[3]_0 ,
    SR);
  output \frame_align_reg[1]_0 ;
  output \frame_align_reg[0]_0 ;
  output [0:0]ifs_ready;
  output ilas_config_valid_reg;
  output [0:0]cgs_ready;
  output [0:0]E;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3] ;
  output p_27_out;
  output [1:0]ilas_config_addr;
  output \beat_error_count_reg[1] ;
  output \FSM_onehot_state_reg[1] ;
  output \FSM_onehot_state_reg[0] ;
  output \FSM_onehot_state_reg[2] ;
  output [31:0]rx_data;
  output [31:0]ilas_config_data;
  output [31:0]status_err_statistics_cnt;
  input clk;
  input \frame_align_reg[0]_1 ;
  input prev_was_last0;
  input buffer_release_n;
  input ifs_ready_reg_0;
  input [0:0]frame_align;
  input [0:0]status_lane_ifs_ready;
  input cfg_disable_scrambler;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31] ;
  input [3:0]\in_charisk_d1_reg[3]_0 ;
  input mem_reg;
  input \FSM_onehot_state_reg[0]_0 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_1 ;
  input [3:0]\phy_char_err_reg[3]_0 ;
  input [0:0]SR;

  wire [7:0]D;
  wire [0:0]E;
  wire \FSM_onehot_state_reg[0] ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire [0:0]\FSM_onehot_state_reg[0]_1 ;
  wire \FSM_onehot_state_reg[1] ;
  wire \FSM_onehot_state_reg[2] ;
  wire [7:0]Q;
  wire [0:0]SR;
  wire \beat_error_count_reg[1] ;
  wire buffer_release_n;
  wire cfg_disable_scrambler;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [31:0]data_scrambled_s;
  wire [0:0]frame_align;
  wire \frame_align[1]_i_1__0_n_0 ;
  wire \frame_align_reg[0]_0 ;
  wire \frame_align_reg[0]_1 ;
  wire \frame_align_reg[1]_0 ;
  wire [32:32]full_state;
  wire i___0_carry_i_1__0_n_0;
  wire i___0_carry_i_2__0_n_0;
  wire i___65_carry_i_1__0_n_0;
  wire i___65_carry_i_2__0_n_0;
  wire i_align_mux_n_52;
  wire i_align_mux_n_53;
  wire i_align_mux_n_54;
  wire i_cgs_n_1;
  wire i_ilas_monitor_n_2;
  wire i_ilas_monitor_n_3;
  wire [0:0]ifs_ready;
  wire ifs_ready_reg_0;
  wire [1:0]ilas_config_addr;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg;
  wire [0:0]\in_charisk_d1_reg[3] ;
  wire [3:0]\in_charisk_d1_reg[3]_0 ;
  wire [31:0]\in_data_d1_reg[31] ;
  wire mem_reg;
  wire p_0_in0_in;
  wire p_0_in1_in;
  wire p_0_in_0;
  wire p_27_out;
  wire [3:0]\phy_char_err_reg[3]_0 ;
  wire \phy_char_err_reg_n_0_[0] ;
  wire prev_was_last0;
  wire [31:0]rx_data;
  wire state;
  wire [31:0]status_err_statistics_cnt;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ;
  wire \status_err_statistics_cnt[31]_i_1__1_n_0 ;
  wire \status_err_statistics_cnt[31]_i_2__0_n_0 ;
  wire \status_err_statistics_cnt[31]_i_3__0_n_0 ;
  wire \status_err_statistics_cnt[31]_i_4__0_n_0 ;
  wire \status_err_statistics_cnt[31]_i_5__0_n_0 ;
  wire \status_err_statistics_cnt[31]_i_6__0_n_0 ;
  wire [0:0]status_lane_ifs_ready;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED ;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED ;

  (* SOFT_HLUTNM = "soft_lutpair55" *) 
  LUT3 #(
    .INIT(8'hE2)) 
    \frame_align[1]_i_1__0 
       (.I0(frame_align),
        .I1(ifs_ready),
        .I2(\frame_align_reg[1]_0 ),
        .O(\frame_align[1]_i_1__0_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align_reg[0]_1 ),
        .Q(\frame_align_reg[0]_0 ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align[1]_i_1__0_n_0 ),
        .Q(\frame_align_reg[1]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair55" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \gen_lane[1].lane_captured[1]_i_1 
       (.I0(ifs_ready),
        .I1(status_lane_ifs_ready),
        .O(E));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___0_carry_i_1__0
       (.I0(status_err_statistics_cnt[0]),
        .I1(\phy_char_err_reg_n_0_[0] ),
        .I2(p_0_in1_in),
        .I3(status_err_statistics_cnt[1]),
        .O(i___0_carry_i_1__0_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___0_carry_i_2__0
       (.I0(status_err_statistics_cnt[0]),
        .I1(p_0_in1_in),
        .I2(\phy_char_err_reg_n_0_[0] ),
        .O(i___0_carry_i_2__0_n_0));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___65_carry_i_1__0
       (.I0(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I1(p_0_in_0),
        .I2(p_0_in0_in),
        .I3(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ),
        .O(i___65_carry_i_1__0_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___65_carry_i_2__0
       (.I0(p_0_in0_in),
        .I1(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I2(p_0_in_0),
        .O(i___65_carry_i_2__0_n_0));
  jesd204_rx_0_align_mux_8 i_align_mux
       (.D(D),
        .Q(Q),
        .SS(p_27_out),
        .WEBWE(i_align_mux_n_54),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .clk(clk),
        .data_aligned_s(data_aligned_s),
        .data_scrambled_s({data_scrambled_s[31:16],data_scrambled_s[9:8]}),
        .ifs_ready_reg(i_align_mux_n_53),
        .\ilas_config_data_reg[5] (\frame_align_reg[1]_0 ),
        .\ilas_config_data_reg[5]_0 (\frame_align_reg[0]_0 ),
        .ilas_config_valid_reg(i_align_mux_n_52),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_ilas_monitor_n_3),
        .\in_charisk_d1_reg[3]_0 (\in_charisk_d1_reg[3] ),
        .\in_charisk_d1_reg[3]_1 (\in_charisk_d1_reg[3]_0 ),
        .\in_data_d1_reg[31]_0 (\in_data_d1_reg[31] ),
        .mem_reg(full_state),
        .state(state),
        .state_reg(ifs_ready),
        .\wr_addr_reg[0] (i_ilas_monitor_n_2));
  jesd204_rx_0_jesd204_rx_cgs_9 i_cgs
       (.\FSM_onehot_state_reg[0]_0 (\FSM_onehot_state_reg[0] ),
        .\FSM_onehot_state_reg[0]_1 (\FSM_onehot_state_reg[0]_0 ),
        .\FSM_onehot_state_reg[0]_2 (\FSM_onehot_state_reg[0]_1 ),
        .\FSM_onehot_state_reg[1]_0 (\FSM_onehot_state_reg[1] ),
        .\FSM_onehot_state_reg[2]_0 (\FSM_onehot_state_reg[2] ),
        .SR(i_cgs_n_1),
        .\beat_error_count_reg[1]_0 (\beat_error_count_reg[1] ),
        .cgs_beat_has_error(cgs_beat_has_error),
        .cgs_ready(cgs_ready),
        .clk(clk));
  jesd204_rx_0_jesd204_scrambler_10 i_descrambler
       (.D({D,data_aligned_s[22:10],data_aligned_s[7:0]}),
        .DIADI({data_scrambled_s[15:10],data_scrambled_s[7:0]}),
        .Q(full_state),
        .SS(p_27_out),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .clk(clk));
  jesd204_rx_0_elastic_buffer_11 i_elastic_buffer
       (.SR(p_27_out),
        .WEBWE(i_align_mux_n_54),
        .buffer_release_n(buffer_release_n),
        .clk(clk),
        .data_scrambled_s(data_scrambled_s),
        .mem_reg_0(mem_reg),
        .rx_data(rx_data));
  jesd204_rx_0_jesd204_ilas_monitor_12 i_ilas_monitor
       (.D({D,data_aligned_s}),
        .clk(clk),
        .ilas_config_addr(ilas_config_addr),
        .\ilas_config_addr_reg[1]_0 (i_ilas_monitor_n_3),
        .ilas_config_data(ilas_config_data),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_align_mux_n_52),
        .prev_was_last0(prev_was_last0),
        .prev_was_last_reg_0(i_ilas_monitor_n_2),
        .state(state),
        .state_reg_0(i_align_mux_n_53),
        .\wr_addr_reg[0] (ifs_ready));
  FDRE #(
    .INIT(1'b0)) 
    ifs_ready_reg
       (.C(clk),
        .CE(1'b1),
        .D(ifs_ready_reg_0),
        .Q(ifs_ready),
        .R(1'b0));
  FDRE \phy_char_err_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [0]),
        .Q(\phy_char_err_reg_n_0_[0] ),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [1]),
        .Q(p_0_in_0),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [2]),
        .Q(p_0_in0_in),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [3]),
        .Q(p_0_in1_in),
        .R(i_cgs_n_1));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,status_err_statistics_cnt[1],1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 }),
        .S({status_err_statistics_cnt[3:2],i___0_carry_i_1__0_n_0,i___0_carry_i_2__0_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }),
        .S(status_err_statistics_cnt[7:4]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }),
        .S(status_err_statistics_cnt[11:8]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }),
        .S(status_err_statistics_cnt[15:12]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }),
        .S(status_err_statistics_cnt[19:16]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }),
        .S(status_err_statistics_cnt[23:20]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }),
        .S(status_err_statistics_cnt[27:24]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }),
        .S(status_err_statistics_cnt[31:28]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,i___65_carry_i_1__0_n_0,i___65_carry_i_2__0_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }));
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    \status_err_statistics_cnt[31]_i_1__1 
       (.I0(\status_err_statistics_cnt[31]_i_2__0_n_0 ),
        .I1(\status_err_statistics_cnt[31]_i_3__0_n_0 ),
        .I2(\status_err_statistics_cnt[31]_i_4__0_n_0 ),
        .I3(\status_err_statistics_cnt[31]_i_5__0_n_0 ),
        .I4(\status_err_statistics_cnt[31]_i_6__0_n_0 ),
        .O(\status_err_statistics_cnt[31]_i_1__1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_2__0 
       (.I0(status_err_statistics_cnt[24]),
        .I1(status_err_statistics_cnt[25]),
        .I2(status_err_statistics_cnt[22]),
        .I3(status_err_statistics_cnt[23]),
        .I4(status_err_statistics_cnt[21]),
        .I5(status_err_statistics_cnt[20]),
        .O(\status_err_statistics_cnt[31]_i_2__0_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_3__0 
       (.I0(status_err_statistics_cnt[30]),
        .I1(status_err_statistics_cnt[31]),
        .I2(status_err_statistics_cnt[28]),
        .I3(status_err_statistics_cnt[29]),
        .I4(status_err_statistics_cnt[27]),
        .I5(status_err_statistics_cnt[26]),
        .O(\status_err_statistics_cnt[31]_i_3__0_n_0 ));
  LUT3 #(
    .INIT(8'h7F)) 
    \status_err_statistics_cnt[31]_i_4__0 
       (.I0(status_err_statistics_cnt[7]),
        .I1(status_err_statistics_cnt[6]),
        .I2(status_err_statistics_cnt[5]),
        .O(\status_err_statistics_cnt[31]_i_4__0_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_5__0 
       (.I0(status_err_statistics_cnt[18]),
        .I1(status_err_statistics_cnt[19]),
        .I2(status_err_statistics_cnt[16]),
        .I3(status_err_statistics_cnt[17]),
        .I4(status_err_statistics_cnt[15]),
        .I5(status_err_statistics_cnt[14]),
        .O(\status_err_statistics_cnt[31]_i_5__0_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_6__0 
       (.I0(status_err_statistics_cnt[12]),
        .I1(status_err_statistics_cnt[13]),
        .I2(status_err_statistics_cnt[10]),
        .I3(status_err_statistics_cnt[11]),
        .I4(status_err_statistics_cnt[9]),
        .I5(status_err_statistics_cnt[8]),
        .O(\status_err_statistics_cnt[31]_i_6__0_n_0 ));
  FDRE \status_err_statistics_cnt_reg[0] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ),
        .Q(status_err_statistics_cnt[0]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[10] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ),
        .Q(status_err_statistics_cnt[10]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[11] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ),
        .Q(status_err_statistics_cnt[11]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[12] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ),
        .Q(status_err_statistics_cnt[12]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[13] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ),
        .Q(status_err_statistics_cnt[13]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[14] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ),
        .Q(status_err_statistics_cnt[14]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[15] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ),
        .Q(status_err_statistics_cnt[15]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[16] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ),
        .Q(status_err_statistics_cnt[16]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[17] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ),
        .Q(status_err_statistics_cnt[17]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[18] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ),
        .Q(status_err_statistics_cnt[18]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[19] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ),
        .Q(status_err_statistics_cnt[19]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[1] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ),
        .Q(status_err_statistics_cnt[1]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[20] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ),
        .Q(status_err_statistics_cnt[20]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[21] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ),
        .Q(status_err_statistics_cnt[21]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[22] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ),
        .Q(status_err_statistics_cnt[22]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[23] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ),
        .Q(status_err_statistics_cnt[23]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[24] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ),
        .Q(status_err_statistics_cnt[24]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[25] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ),
        .Q(status_err_statistics_cnt[25]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[26] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ),
        .Q(status_err_statistics_cnt[26]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[27] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ),
        .Q(status_err_statistics_cnt[27]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[28] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ),
        .Q(status_err_statistics_cnt[28]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[29] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ),
        .Q(status_err_statistics_cnt[29]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[2] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ),
        .Q(status_err_statistics_cnt[2]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[30] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ),
        .Q(status_err_statistics_cnt[30]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[31] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ),
        .Q(status_err_statistics_cnt[31]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[3] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ),
        .Q(status_err_statistics_cnt[3]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[4] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ),
        .Q(status_err_statistics_cnt[4]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[5] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ),
        .Q(status_err_statistics_cnt[5]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[6] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ),
        .Q(status_err_statistics_cnt[6]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[7] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ),
        .Q(status_err_statistics_cnt[7]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[8] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ),
        .Q(status_err_statistics_cnt[8]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[9] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__1_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ),
        .Q(status_err_statistics_cnt[9]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_lane" *) 
module jesd204_rx_0_jesd204_rx_lane_1
   (\frame_align_reg[1]_0 ,
    \frame_align_reg[0]_0 ,
    ifs_ready,
    ilas_config_valid_reg,
    cgs_ready,
    E,
    \cfg_lanes_disable[2] ,
    Q,
    \in_charisk_d1_reg[3] ,
    ilas_config_addr,
    \beat_error_count_reg[1] ,
    \FSM_onehot_state_reg[1] ,
    \FSM_onehot_state_reg[0] ,
    \FSM_onehot_state_reg[2] ,
    rx_data,
    ilas_config_data,
    status_err_statistics_cnt,
    clk,
    \frame_align_reg[0]_1 ,
    prev_was_last0,
    buffer_release_n,
    ifs_ready_reg_0,
    frame_align,
    status_lane_ifs_ready,
    cfg_lanes_disable,
    p_27_out,
    cfg_disable_scrambler,
    D,
    \in_data_d1_reg[31] ,
    \in_charisk_d1_reg[3]_0 ,
    mem_reg,
    \FSM_onehot_state_reg[0]_0 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_1 ,
    \phy_char_err_reg[3]_0 ,
    SR);
  output \frame_align_reg[1]_0 ;
  output \frame_align_reg[0]_0 ;
  output [0:0]ifs_ready;
  output ilas_config_valid_reg;
  output [0:0]cgs_ready;
  output [0:0]E;
  output \cfg_lanes_disable[2] ;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3] ;
  output [1:0]ilas_config_addr;
  output \beat_error_count_reg[1] ;
  output \FSM_onehot_state_reg[1] ;
  output \FSM_onehot_state_reg[0] ;
  output \FSM_onehot_state_reg[2] ;
  output [31:0]rx_data;
  output [31:0]ilas_config_data;
  output [31:0]status_err_statistics_cnt;
  input clk;
  input \frame_align_reg[0]_1 ;
  input prev_was_last0;
  input buffer_release_n;
  input ifs_ready_reg_0;
  input [0:0]frame_align;
  input [0:0]status_lane_ifs_ready;
  input [1:0]cfg_lanes_disable;
  input p_27_out;
  input cfg_disable_scrambler;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31] ;
  input [3:0]\in_charisk_d1_reg[3]_0 ;
  input mem_reg;
  input \FSM_onehot_state_reg[0]_0 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_1 ;
  input [3:0]\phy_char_err_reg[3]_0 ;
  input [0:0]SR;

  wire [7:0]D;
  wire [0:0]E;
  wire \FSM_onehot_state_reg[0] ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire [0:0]\FSM_onehot_state_reg[0]_1 ;
  wire \FSM_onehot_state_reg[1] ;
  wire \FSM_onehot_state_reg[2] ;
  wire [7:0]Q;
  wire [0:0]SR;
  wire \beat_error_count_reg[1] ;
  wire buffer_release_n;
  wire cfg_disable_scrambler;
  wire [1:0]cfg_lanes_disable;
  wire \cfg_lanes_disable[2] ;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [31:0]data_scrambled_s;
  wire [0:0]frame_align;
  wire \frame_align[1]_i_1__1_n_0 ;
  wire \frame_align_reg[0]_0 ;
  wire \frame_align_reg[0]_1 ;
  wire \frame_align_reg[1]_0 ;
  wire [32:32]full_state;
  wire i___0_carry_i_1__1_n_0;
  wire i___0_carry_i_2__1_n_0;
  wire i___65_carry_i_1__1_n_0;
  wire i___65_carry_i_2__1_n_0;
  wire i_align_mux_n_53;
  wire i_align_mux_n_54;
  wire i_align_mux_n_55;
  wire i_cgs_n_1;
  wire i_ilas_monitor_n_2;
  wire i_ilas_monitor_n_3;
  wire [0:0]ifs_ready;
  wire ifs_ready_reg_0;
  wire [1:0]ilas_config_addr;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg;
  wire [0:0]\in_charisk_d1_reg[3] ;
  wire [3:0]\in_charisk_d1_reg[3]_0 ;
  wire [31:0]\in_data_d1_reg[31] ;
  wire mem_reg;
  wire p_0_in0_in;
  wire p_0_in1_in;
  wire p_0_in_0;
  wire p_17_out;
  wire p_27_out;
  wire [3:0]\phy_char_err_reg[3]_0 ;
  wire \phy_char_err_reg_n_0_[0] ;
  wire prev_was_last0;
  wire [31:0]rx_data;
  wire state;
  wire [31:0]status_err_statistics_cnt;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ;
  wire \status_err_statistics_cnt[31]_i_1__2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_2__1_n_0 ;
  wire \status_err_statistics_cnt[31]_i_3__1_n_0 ;
  wire \status_err_statistics_cnt[31]_i_4__1_n_0 ;
  wire \status_err_statistics_cnt[31]_i_5__1_n_0 ;
  wire \status_err_statistics_cnt[31]_i_6__1_n_0 ;
  wire [0:0]status_lane_ifs_ready;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED ;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED ;

  (* SOFT_HLUTNM = "soft_lutpair68" *) 
  LUT3 #(
    .INIT(8'hE2)) 
    \frame_align[1]_i_1__1 
       (.I0(frame_align),
        .I1(ifs_ready),
        .I2(\frame_align_reg[1]_0 ),
        .O(\frame_align[1]_i_1__1_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align_reg[0]_1 ),
        .Q(\frame_align_reg[0]_0 ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align[1]_i_1__1_n_0 ),
        .Q(\frame_align_reg[1]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair68" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \gen_lane[2].lane_captured[2]_i_1 
       (.I0(ifs_ready),
        .I1(status_lane_ifs_ready),
        .O(E));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___0_carry_i_1__1
       (.I0(status_err_statistics_cnt[0]),
        .I1(\phy_char_err_reg_n_0_[0] ),
        .I2(p_0_in1_in),
        .I3(status_err_statistics_cnt[1]),
        .O(i___0_carry_i_1__1_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___0_carry_i_2__1
       (.I0(status_err_statistics_cnt[0]),
        .I1(p_0_in1_in),
        .I2(\phy_char_err_reg_n_0_[0] ),
        .O(i___0_carry_i_2__1_n_0));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___65_carry_i_1__1
       (.I0(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I1(p_0_in_0),
        .I2(p_0_in0_in),
        .I3(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ),
        .O(i___65_carry_i_1__1_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___65_carry_i_2__1
       (.I0(p_0_in0_in),
        .I1(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I2(p_0_in_0),
        .O(i___65_carry_i_2__1_n_0));
  jesd204_rx_0_align_mux_3 i_align_mux
       (.D(D),
        .Q(Q),
        .WEBWE(i_align_mux_n_55),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .cfg_lanes_disable(cfg_lanes_disable),
        .\cfg_lanes_disable[2] (\cfg_lanes_disable[2] ),
        .clk(clk),
        .data_aligned_s(data_aligned_s),
        .data_scrambled_s({data_scrambled_s[31:16],data_scrambled_s[9:8]}),
        .ifs_ready_reg(i_align_mux_n_54),
        .\ilas_config_data_reg[5] (\frame_align_reg[1]_0 ),
        .\ilas_config_data_reg[5]_0 (\frame_align_reg[0]_0 ),
        .ilas_config_valid_reg(i_align_mux_n_53),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_ilas_monitor_n_3),
        .\in_charisk_d1_reg[3]_0 (\in_charisk_d1_reg[3] ),
        .\in_charisk_d1_reg[3]_1 (\in_charisk_d1_reg[3]_0 ),
        .\in_data_d1_reg[31]_0 (\in_data_d1_reg[31] ),
        .mem_reg(full_state),
        .p_17_out(p_17_out),
        .p_27_out(p_27_out),
        .state(state),
        .state_reg(ifs_ready),
        .\wr_addr_reg[6] (i_ilas_monitor_n_2));
  jesd204_rx_0_jesd204_rx_cgs_4 i_cgs
       (.\FSM_onehot_state_reg[0]_0 (\FSM_onehot_state_reg[0] ),
        .\FSM_onehot_state_reg[0]_1 (\FSM_onehot_state_reg[0]_0 ),
        .\FSM_onehot_state_reg[0]_2 (\FSM_onehot_state_reg[0]_1 ),
        .\FSM_onehot_state_reg[1]_0 (\FSM_onehot_state_reg[1] ),
        .\FSM_onehot_state_reg[2]_0 (\FSM_onehot_state_reg[2] ),
        .SR(i_cgs_n_1),
        .\beat_error_count_reg[1]_0 (\beat_error_count_reg[1] ),
        .cgs_beat_has_error(cgs_beat_has_error),
        .cgs_ready(cgs_ready),
        .clk(clk));
  jesd204_rx_0_jesd204_scrambler_5 i_descrambler
       (.D({D,data_aligned_s[22:10],data_aligned_s[7:0]}),
        .DIADI({data_scrambled_s[15:10],data_scrambled_s[7:0]}),
        .Q(full_state),
        .SR(p_17_out),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .clk(clk));
  jesd204_rx_0_elastic_buffer_6 i_elastic_buffer
       (.SR(p_17_out),
        .WEBWE(i_align_mux_n_55),
        .buffer_release_n(buffer_release_n),
        .clk(clk),
        .data_scrambled_s(data_scrambled_s),
        .mem_reg_0(mem_reg),
        .rx_data(rx_data));
  jesd204_rx_0_jesd204_ilas_monitor_7 i_ilas_monitor
       (.D({D,data_aligned_s}),
        .clk(clk),
        .ilas_config_addr(ilas_config_addr),
        .\ilas_config_addr_reg[1]_0 (i_ilas_monitor_n_3),
        .ilas_config_data(ilas_config_data),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_align_mux_n_53),
        .prev_was_last0(prev_was_last0),
        .prev_was_last_reg_0(i_ilas_monitor_n_2),
        .state(state),
        .state_reg_0(i_align_mux_n_54),
        .\wr_addr_reg[6] (ifs_ready));
  FDRE #(
    .INIT(1'b0)) 
    ifs_ready_reg
       (.C(clk),
        .CE(1'b1),
        .D(ifs_ready_reg_0),
        .Q(ifs_ready),
        .R(1'b0));
  FDRE \phy_char_err_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [0]),
        .Q(\phy_char_err_reg_n_0_[0] ),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [1]),
        .Q(p_0_in_0),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [2]),
        .Q(p_0_in0_in),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [3]),
        .Q(p_0_in1_in),
        .R(i_cgs_n_1));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,status_err_statistics_cnt[1],1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 }),
        .S({status_err_statistics_cnt[3:2],i___0_carry_i_1__1_n_0,i___0_carry_i_2__1_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }),
        .S(status_err_statistics_cnt[7:4]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }),
        .S(status_err_statistics_cnt[11:8]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }),
        .S(status_err_statistics_cnt[15:12]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }),
        .S(status_err_statistics_cnt[19:16]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }),
        .S(status_err_statistics_cnt[23:20]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }),
        .S(status_err_statistics_cnt[27:24]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }),
        .S(status_err_statistics_cnt[31:28]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,i___65_carry_i_1__1_n_0,i___65_carry_i_2__1_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }));
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    \status_err_statistics_cnt[31]_i_1__2 
       (.I0(\status_err_statistics_cnt[31]_i_2__1_n_0 ),
        .I1(\status_err_statistics_cnt[31]_i_3__1_n_0 ),
        .I2(\status_err_statistics_cnt[31]_i_4__1_n_0 ),
        .I3(\status_err_statistics_cnt[31]_i_5__1_n_0 ),
        .I4(\status_err_statistics_cnt[31]_i_6__1_n_0 ),
        .O(\status_err_statistics_cnt[31]_i_1__2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_2__1 
       (.I0(status_err_statistics_cnt[24]),
        .I1(status_err_statistics_cnt[25]),
        .I2(status_err_statistics_cnt[22]),
        .I3(status_err_statistics_cnt[23]),
        .I4(status_err_statistics_cnt[21]),
        .I5(status_err_statistics_cnt[20]),
        .O(\status_err_statistics_cnt[31]_i_2__1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_3__1 
       (.I0(status_err_statistics_cnt[30]),
        .I1(status_err_statistics_cnt[31]),
        .I2(status_err_statistics_cnt[28]),
        .I3(status_err_statistics_cnt[29]),
        .I4(status_err_statistics_cnt[27]),
        .I5(status_err_statistics_cnt[26]),
        .O(\status_err_statistics_cnt[31]_i_3__1_n_0 ));
  LUT3 #(
    .INIT(8'h7F)) 
    \status_err_statistics_cnt[31]_i_4__1 
       (.I0(status_err_statistics_cnt[7]),
        .I1(status_err_statistics_cnt[6]),
        .I2(status_err_statistics_cnt[5]),
        .O(\status_err_statistics_cnt[31]_i_4__1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_5__1 
       (.I0(status_err_statistics_cnt[18]),
        .I1(status_err_statistics_cnt[19]),
        .I2(status_err_statistics_cnt[16]),
        .I3(status_err_statistics_cnt[17]),
        .I4(status_err_statistics_cnt[15]),
        .I5(status_err_statistics_cnt[14]),
        .O(\status_err_statistics_cnt[31]_i_5__1_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_6__1 
       (.I0(status_err_statistics_cnt[12]),
        .I1(status_err_statistics_cnt[13]),
        .I2(status_err_statistics_cnt[10]),
        .I3(status_err_statistics_cnt[11]),
        .I4(status_err_statistics_cnt[9]),
        .I5(status_err_statistics_cnt[8]),
        .O(\status_err_statistics_cnt[31]_i_6__1_n_0 ));
  FDRE \status_err_statistics_cnt_reg[0] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ),
        .Q(status_err_statistics_cnt[0]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[10] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ),
        .Q(status_err_statistics_cnt[10]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[11] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ),
        .Q(status_err_statistics_cnt[11]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[12] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ),
        .Q(status_err_statistics_cnt[12]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[13] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ),
        .Q(status_err_statistics_cnt[13]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[14] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ),
        .Q(status_err_statistics_cnt[14]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[15] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ),
        .Q(status_err_statistics_cnt[15]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[16] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ),
        .Q(status_err_statistics_cnt[16]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[17] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ),
        .Q(status_err_statistics_cnt[17]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[18] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ),
        .Q(status_err_statistics_cnt[18]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[19] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ),
        .Q(status_err_statistics_cnt[19]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[1] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ),
        .Q(status_err_statistics_cnt[1]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[20] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ),
        .Q(status_err_statistics_cnt[20]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[21] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ),
        .Q(status_err_statistics_cnt[21]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[22] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ),
        .Q(status_err_statistics_cnt[22]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[23] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ),
        .Q(status_err_statistics_cnt[23]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[24] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ),
        .Q(status_err_statistics_cnt[24]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[25] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ),
        .Q(status_err_statistics_cnt[25]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[26] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ),
        .Q(status_err_statistics_cnt[26]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[27] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ),
        .Q(status_err_statistics_cnt[27]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[28] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ),
        .Q(status_err_statistics_cnt[28]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[29] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ),
        .Q(status_err_statistics_cnt[29]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[2] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ),
        .Q(status_err_statistics_cnt[2]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[30] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ),
        .Q(status_err_statistics_cnt[30]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[31] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ),
        .Q(status_err_statistics_cnt[31]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[3] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ),
        .Q(status_err_statistics_cnt[3]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[4] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ),
        .Q(status_err_statistics_cnt[4]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[5] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ),
        .Q(status_err_statistics_cnt[5]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[6] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ),
        .Q(status_err_statistics_cnt[6]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[7] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ),
        .Q(status_err_statistics_cnt[7]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[8] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ),
        .Q(status_err_statistics_cnt[8]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[9] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_1__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ),
        .Q(status_err_statistics_cnt[9]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "jesd204_rx_lane" *) 
module jesd204_rx_0_jesd204_rx_lane_2
   (\frame_align_reg[1]_0 ,
    \frame_align_reg[0]_0 ,
    ifs_ready,
    ilas_config_valid_reg,
    cgs_ready,
    E,
    Q,
    \in_charisk_d1_reg[3] ,
    p_7_out,
    ilas_config_addr,
    buffer_release_n_reg,
    \beat_error_count_reg[1] ,
    \FSM_onehot_state_reg[1] ,
    \FSM_onehot_state_reg[0] ,
    \FSM_onehot_state_reg[2] ,
    rx_data,
    ilas_config_data,
    status_err_statistics_cnt,
    clk,
    \frame_align_reg[0]_1 ,
    prev_was_last0,
    buffer_release_n,
    ifs_ready_reg_0,
    frame_align,
    status_lane_ifs_ready,
    cfg_disable_scrambler,
    D,
    \in_data_d1_reg[31] ,
    \in_charisk_d1_reg[3]_0 ,
    \FSM_onehot_state_reg[0]_0 ,
    cgs_beat_has_error,
    \FSM_onehot_state_reg[0]_1 ,
    \phy_char_err_reg[3]_0 ,
    SR);
  output \frame_align_reg[1]_0 ;
  output \frame_align_reg[0]_0 ;
  output [0:0]ifs_ready;
  output ilas_config_valid_reg;
  output [0:0]cgs_ready;
  output [0:0]E;
  output [7:0]Q;
  output [0:0]\in_charisk_d1_reg[3] ;
  output p_7_out;
  output [1:0]ilas_config_addr;
  output buffer_release_n_reg;
  output \beat_error_count_reg[1] ;
  output \FSM_onehot_state_reg[1] ;
  output \FSM_onehot_state_reg[0] ;
  output \FSM_onehot_state_reg[2] ;
  output [31:0]rx_data;
  output [31:0]ilas_config_data;
  output [31:0]status_err_statistics_cnt;
  input clk;
  input \frame_align_reg[0]_1 ;
  input prev_was_last0;
  input buffer_release_n;
  input ifs_ready_reg_0;
  input [0:0]frame_align;
  input [0:0]status_lane_ifs_ready;
  input cfg_disable_scrambler;
  input [7:0]D;
  input [31:0]\in_data_d1_reg[31] ;
  input [3:0]\in_charisk_d1_reg[3]_0 ;
  input \FSM_onehot_state_reg[0]_0 ;
  input cgs_beat_has_error;
  input [0:0]\FSM_onehot_state_reg[0]_1 ;
  input [3:0]\phy_char_err_reg[3]_0 ;
  input [0:0]SR;

  wire [7:0]D;
  wire [0:0]E;
  wire \FSM_onehot_state_reg[0] ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire [0:0]\FSM_onehot_state_reg[0]_1 ;
  wire \FSM_onehot_state_reg[1] ;
  wire \FSM_onehot_state_reg[2] ;
  wire [7:0]Q;
  wire [0:0]SR;
  wire \beat_error_count_reg[1] ;
  wire buffer_release_n;
  wire buffer_release_n_reg;
  wire cfg_disable_scrambler;
  wire cgs_beat_has_error;
  wire [0:0]cgs_ready;
  wire clk;
  wire [23:0]data_aligned_s;
  wire [31:0]data_scrambled_s;
  wire [0:0]frame_align;
  wire \frame_align[1]_i_1__2_n_0 ;
  wire \frame_align_reg[0]_0 ;
  wire \frame_align_reg[0]_1 ;
  wire \frame_align_reg[1]_0 ;
  wire [32:32]full_state;
  wire i___0_carry_i_1__2_n_0;
  wire i___0_carry_i_2__2_n_0;
  wire i___65_carry_i_1__2_n_0;
  wire i___65_carry_i_2__2_n_0;
  wire i_align_mux_n_52;
  wire i_align_mux_n_53;
  wire i_align_mux_n_54;
  wire i_cgs_n_1;
  wire i_ilas_monitor_n_2;
  wire i_ilas_monitor_n_3;
  wire [0:0]ifs_ready;
  wire ifs_ready_reg_0;
  wire [1:0]ilas_config_addr;
  wire [31:0]ilas_config_data;
  wire ilas_config_valid_reg;
  wire [0:0]\in_charisk_d1_reg[3] ;
  wire [3:0]\in_charisk_d1_reg[3]_0 ;
  wire [31:0]\in_data_d1_reg[31] ;
  wire p_0_in0_in;
  wire p_0_in1_in;
  wire p_0_in_0;
  wire p_7_out;
  wire [3:0]\phy_char_err_reg[3]_0 ;
  wire \phy_char_err_reg_n_0_[0] ;
  wire prev_was_last0;
  wire [31:0]rx_data;
  wire state;
  wire [31:0]status_err_statistics_cnt;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ;
  wire \status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ;
  wire \status_err_statistics_cnt[31]_i_2__2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_3__2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_4__2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_5__2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_6__2_n_0 ;
  wire \status_err_statistics_cnt[31]_i_7_n_0 ;
  wire [0:0]status_lane_ifs_ready;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED ;
  wire [3:3]\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED ;

  (* SOFT_HLUTNM = "soft_lutpair80" *) 
  LUT3 #(
    .INIT(8'hE2)) 
    \frame_align[1]_i_1__2 
       (.I0(frame_align),
        .I1(ifs_ready),
        .I2(\frame_align_reg[1]_0 ),
        .O(\frame_align[1]_i_1__2_n_0 ));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align_reg[0]_1 ),
        .Q(\frame_align_reg[0]_0 ),
        .R(1'b0));
  FDRE #(
    .INIT(1'b0)) 
    \frame_align_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\frame_align[1]_i_1__2_n_0 ),
        .Q(\frame_align_reg[1]_0 ),
        .R(1'b0));
  (* SOFT_HLUTNM = "soft_lutpair80" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \gen_lane[3].lane_captured[3]_i_1 
       (.I0(ifs_ready),
        .I1(status_lane_ifs_ready),
        .O(E));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___0_carry_i_1__2
       (.I0(status_err_statistics_cnt[0]),
        .I1(\phy_char_err_reg_n_0_[0] ),
        .I2(p_0_in1_in),
        .I3(status_err_statistics_cnt[1]),
        .O(i___0_carry_i_1__2_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___0_carry_i_2__2
       (.I0(status_err_statistics_cnt[0]),
        .I1(p_0_in1_in),
        .I2(\phy_char_err_reg_n_0_[0] ),
        .O(i___0_carry_i_2__2_n_0));
  LUT4 #(
    .INIT(16'h17E8)) 
    i___65_carry_i_1__2
       (.I0(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I1(p_0_in_0),
        .I2(p_0_in0_in),
        .I3(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ),
        .O(i___65_carry_i_1__2_n_0));
  LUT3 #(
    .INIT(8'h96)) 
    i___65_carry_i_2__2
       (.I0(p_0_in0_in),
        .I1(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 ),
        .I2(p_0_in_0),
        .O(i___65_carry_i_2__2_n_0));
  jesd204_rx_0_align_mux i_align_mux
       (.D(D),
        .Q(Q),
        .SS(p_7_out),
        .WEBWE(i_align_mux_n_54),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .clk(clk),
        .data_aligned_s(data_aligned_s),
        .data_scrambled_s({data_scrambled_s[31:16],data_scrambled_s[9:8]}),
        .ifs_ready_reg(i_align_mux_n_53),
        .\ilas_config_data_reg[5] (\frame_align_reg[1]_0 ),
        .\ilas_config_data_reg[5]_0 (\frame_align_reg[0]_0 ),
        .ilas_config_valid_reg(i_align_mux_n_52),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_ilas_monitor_n_3),
        .\in_charisk_d1_reg[3]_0 (\in_charisk_d1_reg[3] ),
        .\in_charisk_d1_reg[3]_1 (\in_charisk_d1_reg[3]_0 ),
        .\in_data_d1_reg[31]_0 (\in_data_d1_reg[31] ),
        .mem_reg(full_state),
        .state(state),
        .state_reg(ifs_ready),
        .\wr_addr_reg[0] (i_ilas_monitor_n_2));
  jesd204_rx_0_jesd204_rx_cgs i_cgs
       (.\FSM_onehot_state_reg[0]_0 (\FSM_onehot_state_reg[0] ),
        .\FSM_onehot_state_reg[0]_1 (\FSM_onehot_state_reg[0]_0 ),
        .\FSM_onehot_state_reg[0]_2 (\FSM_onehot_state_reg[0]_1 ),
        .\FSM_onehot_state_reg[1]_0 (\FSM_onehot_state_reg[1] ),
        .\FSM_onehot_state_reg[2]_0 (\FSM_onehot_state_reg[2] ),
        .SR(i_cgs_n_1),
        .\beat_error_count_reg[1]_0 (\beat_error_count_reg[1] ),
        .cgs_beat_has_error(cgs_beat_has_error),
        .cgs_ready(cgs_ready),
        .clk(clk));
  jesd204_rx_0_jesd204_scrambler i_descrambler
       (.D({D,data_aligned_s[22:10],data_aligned_s[7:0]}),
        .DIADI({data_scrambled_s[15:10],data_scrambled_s[7:0]}),
        .Q(full_state),
        .SS(p_7_out),
        .cfg_disable_scrambler(cfg_disable_scrambler),
        .clk(clk));
  jesd204_rx_0_elastic_buffer i_elastic_buffer
       (.SR(p_7_out),
        .WEBWE(i_align_mux_n_54),
        .buffer_release_n(buffer_release_n),
        .buffer_release_n_reg(buffer_release_n_reg),
        .clk(clk),
        .data_scrambled_s(data_scrambled_s),
        .rx_data(rx_data));
  jesd204_rx_0_jesd204_ilas_monitor i_ilas_monitor
       (.D({D,data_aligned_s}),
        .clk(clk),
        .ilas_config_addr(ilas_config_addr),
        .\ilas_config_addr_reg[1]_0 (i_ilas_monitor_n_3),
        .ilas_config_data(ilas_config_data),
        .ilas_config_valid_reg_0(ilas_config_valid_reg),
        .ilas_config_valid_reg_1(i_align_mux_n_52),
        .prev_was_last0(prev_was_last0),
        .prev_was_last_reg_0(i_ilas_monitor_n_2),
        .state(state),
        .state_reg_0(i_align_mux_n_53),
        .\wr_addr_reg[0] (ifs_ready));
  FDRE #(
    .INIT(1'b0)) 
    ifs_ready_reg
       (.C(clk),
        .CE(1'b1),
        .D(ifs_ready_reg_0),
        .Q(ifs_ready),
        .R(1'b0));
  FDRE \phy_char_err_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [0]),
        .Q(\phy_char_err_reg_n_0_[0] ),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [1]),
        .Q(p_0_in_0),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [2]),
        .Q(p_0_in0_in),
        .R(i_cgs_n_1));
  FDRE \phy_char_err_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(\phy_char_err_reg[3]_0 [3]),
        .Q(p_0_in1_in),
        .R(i_cgs_n_1));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,status_err_statistics_cnt[1],1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_7 }),
        .S({status_err_statistics_cnt[3:2],i___0_carry_i_1__2_n_0,i___0_carry_i_2__2_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }),
        .S(status_err_statistics_cnt[7:4]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }),
        .S(status_err_statistics_cnt[11:8]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }),
        .S(status_err_statistics_cnt[15:12]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }),
        .S(status_err_statistics_cnt[19:16]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }),
        .S(status_err_statistics_cnt[23:20]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }),
        .S(status_err_statistics_cnt[27:24]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___0_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___0_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }),
        .S(status_err_statistics_cnt[31:28]));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry 
       (.CI(1'b0),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_6 ,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry_n_5 ,i___65_carry_i_1__2_n_0,i___65_carry_i_2__2_n_0}));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__0 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__0_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__1 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__1_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__2 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__2_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__3 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__3_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__4 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__4_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__5 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_0 ),
        .CO({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__5_n_7 }));
  CARRY4 \status_err_statistics_cnt0_inferred__1/i___65_carry__6 
       (.CI(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_0 ),
        .CO({\NLW_status_err_statistics_cnt0_inferred__1/i___65_carry__6_CO_UNCONNECTED [3],\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_1 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_2 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_3 }),
        .CYINIT(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0}),
        .O({\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 }),
        .S({\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_4 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_5 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_6 ,\status_err_statistics_cnt0_inferred__1/i___0_carry__6_n_7 }));
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    \status_err_statistics_cnt[31]_i_2__2 
       (.I0(\status_err_statistics_cnt[31]_i_3__2_n_0 ),
        .I1(\status_err_statistics_cnt[31]_i_4__2_n_0 ),
        .I2(\status_err_statistics_cnt[31]_i_5__2_n_0 ),
        .I3(\status_err_statistics_cnt[31]_i_6__2_n_0 ),
        .I4(\status_err_statistics_cnt[31]_i_7_n_0 ),
        .O(\status_err_statistics_cnt[31]_i_2__2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_3__2 
       (.I0(status_err_statistics_cnt[24]),
        .I1(status_err_statistics_cnt[25]),
        .I2(status_err_statistics_cnt[22]),
        .I3(status_err_statistics_cnt[23]),
        .I4(status_err_statistics_cnt[21]),
        .I5(status_err_statistics_cnt[20]),
        .O(\status_err_statistics_cnt[31]_i_3__2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_4__2 
       (.I0(status_err_statistics_cnt[30]),
        .I1(status_err_statistics_cnt[31]),
        .I2(status_err_statistics_cnt[28]),
        .I3(status_err_statistics_cnt[29]),
        .I4(status_err_statistics_cnt[27]),
        .I5(status_err_statistics_cnt[26]),
        .O(\status_err_statistics_cnt[31]_i_4__2_n_0 ));
  LUT3 #(
    .INIT(8'h7F)) 
    \status_err_statistics_cnt[31]_i_5__2 
       (.I0(status_err_statistics_cnt[7]),
        .I1(status_err_statistics_cnt[6]),
        .I2(status_err_statistics_cnt[5]),
        .O(\status_err_statistics_cnt[31]_i_5__2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_6__2 
       (.I0(status_err_statistics_cnt[18]),
        .I1(status_err_statistics_cnt[19]),
        .I2(status_err_statistics_cnt[16]),
        .I3(status_err_statistics_cnt[17]),
        .I4(status_err_statistics_cnt[15]),
        .I5(status_err_statistics_cnt[14]),
        .O(\status_err_statistics_cnt[31]_i_6__2_n_0 ));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \status_err_statistics_cnt[31]_i_7 
       (.I0(status_err_statistics_cnt[12]),
        .I1(status_err_statistics_cnt[13]),
        .I2(status_err_statistics_cnt[10]),
        .I3(status_err_statistics_cnt[11]),
        .I4(status_err_statistics_cnt[9]),
        .I5(status_err_statistics_cnt[8]),
        .O(\status_err_statistics_cnt[31]_i_7_n_0 ));
  FDRE \status_err_statistics_cnt_reg[0] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_7 ),
        .Q(status_err_statistics_cnt[0]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[10] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_5 ),
        .Q(status_err_statistics_cnt[10]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[11] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_4 ),
        .Q(status_err_statistics_cnt[11]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[12] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_7 ),
        .Q(status_err_statistics_cnt[12]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[13] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_6 ),
        .Q(status_err_statistics_cnt[13]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[14] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_5 ),
        .Q(status_err_statistics_cnt[14]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[15] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__2_n_4 ),
        .Q(status_err_statistics_cnt[15]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[16] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_7 ),
        .Q(status_err_statistics_cnt[16]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[17] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_6 ),
        .Q(status_err_statistics_cnt[17]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[18] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_5 ),
        .Q(status_err_statistics_cnt[18]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[19] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__3_n_4 ),
        .Q(status_err_statistics_cnt[19]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[1] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_6 ),
        .Q(status_err_statistics_cnt[1]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[20] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_7 ),
        .Q(status_err_statistics_cnt[20]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[21] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_6 ),
        .Q(status_err_statistics_cnt[21]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[22] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_5 ),
        .Q(status_err_statistics_cnt[22]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[23] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__4_n_4 ),
        .Q(status_err_statistics_cnt[23]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[24] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_7 ),
        .Q(status_err_statistics_cnt[24]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[25] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_6 ),
        .Q(status_err_statistics_cnt[25]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[26] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_5 ),
        .Q(status_err_statistics_cnt[26]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[27] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__5_n_4 ),
        .Q(status_err_statistics_cnt[27]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[28] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_7 ),
        .Q(status_err_statistics_cnt[28]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[29] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_6 ),
        .Q(status_err_statistics_cnt[29]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[2] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_5 ),
        .Q(status_err_statistics_cnt[2]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[30] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_5 ),
        .Q(status_err_statistics_cnt[30]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[31] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__6_n_4 ),
        .Q(status_err_statistics_cnt[31]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[3] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry_n_4 ),
        .Q(status_err_statistics_cnt[3]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[4] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_7 ),
        .Q(status_err_statistics_cnt[4]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[5] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_6 ),
        .Q(status_err_statistics_cnt[5]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[6] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_5 ),
        .Q(status_err_statistics_cnt[6]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[7] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__0_n_4 ),
        .Q(status_err_statistics_cnt[7]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[8] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_7 ),
        .Q(status_err_statistics_cnt[8]),
        .R(SR));
  FDRE \status_err_statistics_cnt_reg[9] 
       (.C(clk),
        .CE(\status_err_statistics_cnt[31]_i_2__2_n_0 ),
        .D(\status_err_statistics_cnt0_inferred__1/i___65_carry__1_n_6 ),
        .Q(status_err_statistics_cnt[9]),
        .R(SR));
endmodule

(* ORIG_REF_NAME = "jesd204_scrambler" *) 
module jesd204_rx_0_jesd204_scrambler
   (DIADI,
    Q,
    cfg_disable_scrambler,
    D,
    SS,
    clk);
  output [13:0]DIADI;
  output [0:0]Q;
  input cfg_disable_scrambler;
  input [28:0]D;
  input [0:0]SS;
  input clk;

  wire [28:0]D;
  wire [13:0]DIADI;
  wire [0:0]Q;
  wire [0:0]SS;
  wire cfg_disable_scrambler;
  wire clk;
  wire [46:33]full_state;

  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_10__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[45]),
        .I2(full_state[46]),
        .I3(D[7]),
        .O(DIADI[7]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_11__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[44]),
        .I2(full_state[45]),
        .I3(D[6]),
        .O(DIADI[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_12__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[44]),
        .I3(D[5]),
        .O(DIADI[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_13__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[42]),
        .I3(D[4]),
        .O(DIADI[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_14__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[42]),
        .I2(full_state[41]),
        .I3(D[3]),
        .O(DIADI[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_15__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[41]),
        .I2(full_state[40]),
        .I3(D[2]),
        .O(DIADI[2]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_16__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[40]),
        .I2(full_state[39]),
        .I3(D[1]),
        .O(DIADI[1]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_17__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[39]),
        .I2(full_state[38]),
        .I3(D[0]),
        .O(DIADI[0]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_2__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[38]),
        .I2(full_state[37]),
        .I3(D[13]),
        .O(DIADI[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_3__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[37]),
        .I2(full_state[36]),
        .I3(D[12]),
        .O(DIADI[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_4__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[36]),
        .I2(full_state[35]),
        .I3(D[11]),
        .O(DIADI[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_5__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[35]),
        .I2(full_state[34]),
        .I3(D[10]),
        .O(DIADI[10]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_6__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[34]),
        .I2(full_state[33]),
        .I3(D[9]),
        .O(DIADI[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_7__2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[33]),
        .I2(Q),
        .I3(D[8]),
        .O(DIADI[8]));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(Q),
        .R(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(full_state[42]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(full_state[43]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(full_state[44]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(full_state[45]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(full_state[46]),
        .S(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(full_state[33]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(full_state[34]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(full_state[35]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(full_state[36]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(full_state[37]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(full_state[38]),
        .R(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(full_state[39]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(full_state[40]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(full_state[41]),
        .S(SS));
endmodule

(* ORIG_REF_NAME = "jesd204_scrambler" *) 
module jesd204_rx_0_jesd204_scrambler_10
   (DIADI,
    Q,
    cfg_disable_scrambler,
    D,
    SS,
    clk);
  output [13:0]DIADI;
  output [0:0]Q;
  input cfg_disable_scrambler;
  input [28:0]D;
  input [0:0]SS;
  input clk;

  wire [28:0]D;
  wire [13:0]DIADI;
  wire [0:0]Q;
  wire [0:0]SS;
  wire cfg_disable_scrambler;
  wire clk;
  wire [46:33]full_state;

  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_10__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[44]),
        .I2(full_state[45]),
        .I3(D[6]),
        .O(DIADI[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_11__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[44]),
        .I3(D[5]),
        .O(DIADI[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_12__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[42]),
        .I3(D[4]),
        .O(DIADI[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_13__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[42]),
        .I2(full_state[41]),
        .I3(D[3]),
        .O(DIADI[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_14__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[41]),
        .I2(full_state[40]),
        .I3(D[2]),
        .O(DIADI[2]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_15__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[40]),
        .I2(full_state[39]),
        .I3(D[1]),
        .O(DIADI[1]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_16__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[39]),
        .I2(full_state[38]),
        .I3(D[0]),
        .O(DIADI[0]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_1__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[38]),
        .I2(full_state[37]),
        .I3(D[13]),
        .O(DIADI[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_2__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[37]),
        .I2(full_state[36]),
        .I3(D[12]),
        .O(DIADI[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_3__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[36]),
        .I2(full_state[35]),
        .I3(D[11]),
        .O(DIADI[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_4__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[35]),
        .I2(full_state[34]),
        .I3(D[10]),
        .O(DIADI[10]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_5__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[34]),
        .I2(full_state[33]),
        .I3(D[9]),
        .O(DIADI[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_6__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[33]),
        .I2(Q),
        .I3(D[8]),
        .O(DIADI[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_9__0
       (.I0(cfg_disable_scrambler),
        .I1(full_state[45]),
        .I2(full_state[46]),
        .I3(D[7]),
        .O(DIADI[7]));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(Q),
        .R(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(full_state[42]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(full_state[43]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(full_state[44]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(full_state[45]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(full_state[46]),
        .S(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(full_state[33]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(full_state[34]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(full_state[35]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(full_state[36]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(full_state[37]),
        .R(SS));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(full_state[38]),
        .R(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(full_state[39]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(full_state[40]),
        .S(SS));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(full_state[41]),
        .S(SS));
endmodule

(* ORIG_REF_NAME = "jesd204_scrambler" *) 
module jesd204_rx_0_jesd204_scrambler_15
   (DIADI,
    Q,
    cfg_disable_scrambler,
    D,
    SR,
    clk);
  output [13:0]DIADI;
  output [0:0]Q;
  input cfg_disable_scrambler;
  input [28:0]D;
  input [0:0]SR;
  input clk;

  wire [28:0]D;
  wire [13:0]DIADI;
  wire [0:0]Q;
  wire [0:0]SR;
  wire cfg_disable_scrambler;
  wire clk;
  wire [46:33]full_state;

  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[38]),
        .I2(full_state[37]),
        .I3(D[13]),
        .O(DIADI[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_10
       (.I0(cfg_disable_scrambler),
        .I1(full_state[44]),
        .I2(full_state[45]),
        .I3(D[6]),
        .O(DIADI[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_11
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[44]),
        .I3(D[5]),
        .O(DIADI[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_12
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[42]),
        .I3(D[4]),
        .O(DIADI[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_13
       (.I0(cfg_disable_scrambler),
        .I1(full_state[42]),
        .I2(full_state[41]),
        .I3(D[3]),
        .O(DIADI[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_14
       (.I0(cfg_disable_scrambler),
        .I1(full_state[41]),
        .I2(full_state[40]),
        .I3(D[2]),
        .O(DIADI[2]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_15
       (.I0(cfg_disable_scrambler),
        .I1(full_state[40]),
        .I2(full_state[39]),
        .I3(D[1]),
        .O(DIADI[1]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_16
       (.I0(cfg_disable_scrambler),
        .I1(full_state[39]),
        .I2(full_state[38]),
        .I3(D[0]),
        .O(DIADI[0]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_2
       (.I0(cfg_disable_scrambler),
        .I1(full_state[37]),
        .I2(full_state[36]),
        .I3(D[12]),
        .O(DIADI[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_3
       (.I0(cfg_disable_scrambler),
        .I1(full_state[36]),
        .I2(full_state[35]),
        .I3(D[11]),
        .O(DIADI[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_4
       (.I0(cfg_disable_scrambler),
        .I1(full_state[35]),
        .I2(full_state[34]),
        .I3(D[10]),
        .O(DIADI[10]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_5
       (.I0(cfg_disable_scrambler),
        .I1(full_state[34]),
        .I2(full_state[33]),
        .I3(D[9]),
        .O(DIADI[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_6
       (.I0(cfg_disable_scrambler),
        .I1(full_state[33]),
        .I2(Q),
        .I3(D[8]),
        .O(DIADI[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_9
       (.I0(cfg_disable_scrambler),
        .I1(full_state[45]),
        .I2(full_state[46]),
        .I3(D[7]),
        .O(DIADI[7]));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(Q),
        .R(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(full_state[42]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(full_state[43]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(full_state[44]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(full_state[45]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(full_state[46]),
        .S(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(full_state[33]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(full_state[34]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(full_state[35]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(full_state[36]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(full_state[37]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(full_state[38]),
        .R(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(full_state[39]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(full_state[40]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(full_state[41]),
        .S(SR));
endmodule

(* ORIG_REF_NAME = "jesd204_scrambler" *) 
module jesd204_rx_0_jesd204_scrambler_5
   (DIADI,
    Q,
    cfg_disable_scrambler,
    D,
    SR,
    clk);
  output [13:0]DIADI;
  output [0:0]Q;
  input cfg_disable_scrambler;
  input [28:0]D;
  input [0:0]SR;
  input clk;

  wire [28:0]D;
  wire [13:0]DIADI;
  wire [0:0]Q;
  wire [0:0]SR;
  wire cfg_disable_scrambler;
  wire clk;
  wire [46:33]full_state;

  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_10__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[44]),
        .I2(full_state[45]),
        .I3(D[6]),
        .O(DIADI[6]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_11__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[44]),
        .I3(D[5]),
        .O(DIADI[5]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_12__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[43]),
        .I2(full_state[42]),
        .I3(D[4]),
        .O(DIADI[4]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_13__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[42]),
        .I2(full_state[41]),
        .I3(D[3]),
        .O(DIADI[3]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_14__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[41]),
        .I2(full_state[40]),
        .I3(D[2]),
        .O(DIADI[2]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_15__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[40]),
        .I2(full_state[39]),
        .I3(D[1]),
        .O(DIADI[1]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_16__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[39]),
        .I2(full_state[38]),
        .I3(D[0]),
        .O(DIADI[0]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_1__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[38]),
        .I2(full_state[37]),
        .I3(D[13]),
        .O(DIADI[13]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_2__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[37]),
        .I2(full_state[36]),
        .I3(D[12]),
        .O(DIADI[12]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_3__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[36]),
        .I2(full_state[35]),
        .I3(D[11]),
        .O(DIADI[11]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_4__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[35]),
        .I2(full_state[34]),
        .I3(D[10]),
        .O(DIADI[10]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_5__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[34]),
        .I2(full_state[33]),
        .I3(D[9]),
        .O(DIADI[9]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_6__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[33]),
        .I2(Q),
        .I3(D[8]),
        .O(DIADI[8]));
  LUT4 #(
    .INIT(16'hEB14)) 
    mem_reg_i_9__1
       (.I0(cfg_disable_scrambler),
        .I1(full_state[45]),
        .I2(full_state[46]),
        .I3(D[7]),
        .O(DIADI[7]));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(D[21]),
        .Q(Q),
        .R(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(D[16]),
        .Q(full_state[42]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(D[17]),
        .Q(full_state[43]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(D[18]),
        .Q(full_state[44]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(D[19]),
        .Q(full_state[45]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(D[20]),
        .Q(full_state[46]),
        .S(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[1] 
       (.C(clk),
        .CE(1'b1),
        .D(D[22]),
        .Q(full_state[33]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[2] 
       (.C(clk),
        .CE(1'b1),
        .D(D[23]),
        .Q(full_state[34]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[3] 
       (.C(clk),
        .CE(1'b1),
        .D(D[24]),
        .Q(full_state[35]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(D[25]),
        .Q(full_state[36]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(D[26]),
        .Q(full_state[37]),
        .R(SR));
  FDRE #(
    .INIT(1'b0)) 
    \state_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(D[27]),
        .Q(full_state[38]),
        .R(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(D[28]),
        .Q(full_state[39]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(D[14]),
        .Q(full_state[40]),
        .S(SR));
  FDSE #(
    .INIT(1'b1)) 
    \state_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(D[15]),
        .Q(full_state[41]),
        .S(SR));
endmodule

(* ORIG_REF_NAME = "pipeline_stage" *) 
module jesd204_rx_0_pipeline_stage__parameterized2
   (ifs_ready_reg,
    charisk28,
    ifs_ready_reg_0,
    charisk28_0,
    ifs_ready_reg_1,
    charisk28_1,
    ifs_ready_reg_2,
    charisk28_2,
    prev_was_last0,
    D,
    \in_dly_reg[187]_0 ,
    \in_dly_reg[23]_0 ,
    \FSM_onehot_state_reg[0] ,
    frame_align,
    cgs_beat_has_error,
    prev_was_last0_3,
    \in_dly_reg[107]_0 ,
    \in_dly_reg[27]_0 ,
    \FSM_onehot_state_reg[0]_0 ,
    frame_align_4,
    cgs_beat_has_error_5,
    prev_was_last0_6,
    \in_dly_reg[139]_0 ,
    \in_dly_reg[31]_0 ,
    \FSM_onehot_state_reg[0]_1 ,
    frame_align_7,
    cgs_beat_has_error_8,
    prev_was_last0_9,
    \in_dly_reg[171]_0 ,
    \in_dly_reg[35]_0 ,
    \FSM_onehot_state_reg[0]_2 ,
    frame_align_10,
    cgs_beat_has_error_11,
    ifs_ready_reg_3,
    ifs_ready_reg_4,
    ifs_ready_reg_5,
    ifs_ready_reg_6,
    ifs_ready,
    \frame_align_reg[0] ,
    \frame_align_reg[0]_0 ,
    \frame_align_reg[0]_1 ,
    \frame_align_reg[0]_2 ,
    Q,
    \ilas_config_data_reg[24] ,
    \ilas_config_data_reg[31] ,
    ctrl_err_statistics_mask,
    \FSM_onehot_state_reg[0]_3 ,
    \FSM_onehot_state_reg[0]_4 ,
    \FSM_onehot_state[2]_i_2_0 ,
    \FSM_onehot_state[2]_i_2_1 ,
    prev_was_last_reg,
    \ilas_config_data_reg[24]_0 ,
    \ilas_config_data_reg[31]_0 ,
    \FSM_onehot_state_reg[0]_5 ,
    \FSM_onehot_state_reg[0]_6 ,
    \FSM_onehot_state[2]_i_2__0_0 ,
    \FSM_onehot_state[2]_i_2__0_1 ,
    prev_was_last_reg_0,
    \ilas_config_data_reg[24]_1 ,
    \ilas_config_data_reg[31]_1 ,
    \FSM_onehot_state_reg[0]_7 ,
    \FSM_onehot_state_reg[0]_8 ,
    \FSM_onehot_state[2]_i_2__1_0 ,
    \FSM_onehot_state[2]_i_2__1_1 ,
    prev_was_last_reg_1,
    \ilas_config_data_reg[24]_2 ,
    \ilas_config_data_reg[31]_2 ,
    \FSM_onehot_state_reg[0]_9 ,
    \FSM_onehot_state_reg[0]_10 ,
    \FSM_onehot_state[2]_i_2__2_0 ,
    \FSM_onehot_state[2]_i_2__2_1 ,
    ifs_ready_reg_7,
    \in_dly_reg[187]_1 ,
    clk);
  output ifs_ready_reg;
  output [3:0]charisk28;
  output ifs_ready_reg_0;
  output [3:0]charisk28_0;
  output ifs_ready_reg_1;
  output [3:0]charisk28_1;
  output ifs_ready_reg_2;
  output [3:0]charisk28_2;
  output prev_was_last0;
  output [7:0]D;
  output [127:0]\in_dly_reg[187]_0 ;
  output [3:0]\in_dly_reg[23]_0 ;
  output \FSM_onehot_state_reg[0] ;
  output [0:0]frame_align;
  output cgs_beat_has_error;
  output prev_was_last0_3;
  output [7:0]\in_dly_reg[107]_0 ;
  output [3:0]\in_dly_reg[27]_0 ;
  output \FSM_onehot_state_reg[0]_0 ;
  output [0:0]frame_align_4;
  output cgs_beat_has_error_5;
  output prev_was_last0_6;
  output [7:0]\in_dly_reg[139]_0 ;
  output [3:0]\in_dly_reg[31]_0 ;
  output \FSM_onehot_state_reg[0]_1 ;
  output [0:0]frame_align_7;
  output cgs_beat_has_error_8;
  output prev_was_last0_9;
  output [7:0]\in_dly_reg[171]_0 ;
  output [3:0]\in_dly_reg[35]_0 ;
  output \FSM_onehot_state_reg[0]_2 ;
  output [0:0]frame_align_10;
  output cgs_beat_has_error_11;
  output ifs_ready_reg_3;
  output ifs_ready_reg_4;
  output ifs_ready_reg_5;
  output ifs_ready_reg_6;
  input [3:0]ifs_ready;
  input \frame_align_reg[0] ;
  input \frame_align_reg[0]_0 ;
  input \frame_align_reg[0]_1 ;
  input \frame_align_reg[0]_2 ;
  input [0:0]Q;
  input \ilas_config_data_reg[24] ;
  input [7:0]\ilas_config_data_reg[31] ;
  input [2:0]ctrl_err_statistics_mask;
  input \FSM_onehot_state_reg[0]_3 ;
  input \FSM_onehot_state_reg[0]_4 ;
  input \FSM_onehot_state[2]_i_2_0 ;
  input \FSM_onehot_state[2]_i_2_1 ;
  input [0:0]prev_was_last_reg;
  input \ilas_config_data_reg[24]_0 ;
  input [7:0]\ilas_config_data_reg[31]_0 ;
  input \FSM_onehot_state_reg[0]_5 ;
  input \FSM_onehot_state_reg[0]_6 ;
  input \FSM_onehot_state[2]_i_2__0_0 ;
  input \FSM_onehot_state[2]_i_2__0_1 ;
  input [0:0]prev_was_last_reg_0;
  input \ilas_config_data_reg[24]_1 ;
  input [7:0]\ilas_config_data_reg[31]_1 ;
  input \FSM_onehot_state_reg[0]_7 ;
  input \FSM_onehot_state_reg[0]_8 ;
  input \FSM_onehot_state[2]_i_2__1_0 ;
  input \FSM_onehot_state[2]_i_2__1_1 ;
  input [0:0]prev_was_last_reg_1;
  input \ilas_config_data_reg[24]_2 ;
  input [7:0]\ilas_config_data_reg[31]_2 ;
  input \FSM_onehot_state_reg[0]_9 ;
  input \FSM_onehot_state_reg[0]_10 ;
  input \FSM_onehot_state[2]_i_2__2_0 ;
  input \FSM_onehot_state[2]_i_2__2_1 ;
  input [3:0]ifs_ready_reg_7;
  input [175:0]\in_dly_reg[187]_1 ;
  input clk;

  wire [7:0]D;
  wire \FSM_onehot_state[2]_i_10__0_n_0 ;
  wire \FSM_onehot_state[2]_i_10__1_n_0 ;
  wire \FSM_onehot_state[2]_i_10__2_n_0 ;
  wire \FSM_onehot_state[2]_i_10_n_0 ;
  wire \FSM_onehot_state[2]_i_11__0_n_0 ;
  wire \FSM_onehot_state[2]_i_11__1_n_0 ;
  wire \FSM_onehot_state[2]_i_11__2_n_0 ;
  wire \FSM_onehot_state[2]_i_11_n_0 ;
  wire \FSM_onehot_state[2]_i_12__0_n_0 ;
  wire \FSM_onehot_state[2]_i_12__1_n_0 ;
  wire \FSM_onehot_state[2]_i_12__2_n_0 ;
  wire \FSM_onehot_state[2]_i_12_n_0 ;
  wire \FSM_onehot_state[2]_i_2_0 ;
  wire \FSM_onehot_state[2]_i_2_1 ;
  wire \FSM_onehot_state[2]_i_2__0_0 ;
  wire \FSM_onehot_state[2]_i_2__0_1 ;
  wire \FSM_onehot_state[2]_i_2__1_0 ;
  wire \FSM_onehot_state[2]_i_2__1_1 ;
  wire \FSM_onehot_state[2]_i_2__2_0 ;
  wire \FSM_onehot_state[2]_i_2__2_1 ;
  wire \FSM_onehot_state[2]_i_4__0_n_0 ;
  wire \FSM_onehot_state[2]_i_4__1_n_0 ;
  wire \FSM_onehot_state[2]_i_4__2_n_0 ;
  wire \FSM_onehot_state[2]_i_4_n_0 ;
  wire \FSM_onehot_state[2]_i_5__0_n_0 ;
  wire \FSM_onehot_state[2]_i_5__1_n_0 ;
  wire \FSM_onehot_state[2]_i_5__2_n_0 ;
  wire \FSM_onehot_state[2]_i_5_n_0 ;
  wire \FSM_onehot_state[2]_i_7__0_n_0 ;
  wire \FSM_onehot_state[2]_i_7__1_n_0 ;
  wire \FSM_onehot_state[2]_i_7__2_n_0 ;
  wire \FSM_onehot_state[2]_i_7_n_0 ;
  wire \FSM_onehot_state[2]_i_8__0_n_0 ;
  wire \FSM_onehot_state[2]_i_8__1_n_0 ;
  wire \FSM_onehot_state[2]_i_8__2_n_0 ;
  wire \FSM_onehot_state[2]_i_8_n_0 ;
  wire \FSM_onehot_state[2]_i_9__0_n_0 ;
  wire \FSM_onehot_state[2]_i_9__1_n_0 ;
  wire \FSM_onehot_state[2]_i_9__2_n_0 ;
  wire \FSM_onehot_state[2]_i_9_n_0 ;
  wire \FSM_onehot_state_reg[0] ;
  wire \FSM_onehot_state_reg[0]_0 ;
  wire \FSM_onehot_state_reg[0]_1 ;
  wire \FSM_onehot_state_reg[0]_10 ;
  wire \FSM_onehot_state_reg[0]_2 ;
  wire \FSM_onehot_state_reg[0]_3 ;
  wire \FSM_onehot_state_reg[0]_4 ;
  wire \FSM_onehot_state_reg[0]_5 ;
  wire \FSM_onehot_state_reg[0]_6 ;
  wire \FSM_onehot_state_reg[0]_7 ;
  wire \FSM_onehot_state_reg[0]_8 ;
  wire \FSM_onehot_state_reg[0]_9 ;
  wire [0:0]Q;
  wire cgs_beat_has_error;
  wire cgs_beat_has_error_11;
  wire cgs_beat_has_error_5;
  wire cgs_beat_has_error_8;
  wire [3:0]charisk28;
  wire [3:0]charisk28_0;
  wire [3:0]charisk28_1;
  wire [3:0]charisk28_2;
  wire clk;
  wire [2:0]ctrl_err_statistics_mask;
  wire [0:0]frame_align;
  wire \frame_align[0]_i_2__0_n_0 ;
  wire \frame_align[0]_i_2__1_n_0 ;
  wire \frame_align[0]_i_2__2_n_0 ;
  wire \frame_align[0]_i_2_n_0 ;
  wire \frame_align[1]_i_3__0_n_0 ;
  wire \frame_align[1]_i_3__1_n_0 ;
  wire \frame_align[1]_i_3__2_n_0 ;
  wire \frame_align[1]_i_3_n_0 ;
  wire [0:0]frame_align_10;
  wire [0:0]frame_align_4;
  wire [0:0]frame_align_7;
  wire \frame_align_reg[0] ;
  wire \frame_align_reg[0]_0 ;
  wire \frame_align_reg[0]_1 ;
  wire \frame_align_reg[0]_2 ;
  wire [3:0]ifs_ready;
  wire ifs_ready_i_3__0_n_0;
  wire ifs_ready_i_3__1_n_0;
  wire ifs_ready_i_3__2_n_0;
  wire ifs_ready_i_3_n_0;
  wire ifs_ready_reg;
  wire ifs_ready_reg_0;
  wire ifs_ready_reg_1;
  wire ifs_ready_reg_2;
  wire ifs_ready_reg_3;
  wire ifs_ready_reg_4;
  wire ifs_ready_reg_5;
  wire ifs_ready_reg_6;
  wire [3:0]ifs_ready_reg_7;
  wire \ilas_config_data_reg[24] ;
  wire \ilas_config_data_reg[24]_0 ;
  wire \ilas_config_data_reg[24]_1 ;
  wire \ilas_config_data_reg[24]_2 ;
  wire [7:0]\ilas_config_data_reg[31] ;
  wire [7:0]\ilas_config_data_reg[31]_0 ;
  wire [7:0]\ilas_config_data_reg[31]_1 ;
  wire [7:0]\ilas_config_data_reg[31]_2 ;
  wire \in_charisk_d1[0]_i_2__0_n_0 ;
  wire \in_charisk_d1[0]_i_2__1_n_0 ;
  wire \in_charisk_d1[0]_i_2__2_n_0 ;
  wire \in_charisk_d1[0]_i_2_n_0 ;
  wire \in_charisk_d1[1]_i_2__0_n_0 ;
  wire \in_charisk_d1[1]_i_2__1_n_0 ;
  wire \in_charisk_d1[1]_i_2__2_n_0 ;
  wire \in_charisk_d1[1]_i_2_n_0 ;
  wire \in_charisk_d1[2]_i_2__0_n_0 ;
  wire \in_charisk_d1[2]_i_2__1_n_0 ;
  wire \in_charisk_d1[2]_i_2__2_n_0 ;
  wire \in_charisk_d1[2]_i_2_n_0 ;
  wire \in_charisk_d1[3]_i_2__0_n_0 ;
  wire \in_charisk_d1[3]_i_2__1_n_0 ;
  wire \in_charisk_d1[3]_i_2__2_n_0 ;
  wire \in_charisk_d1[3]_i_2_n_0 ;
  wire [7:0]\in_dly_reg[107]_0 ;
  wire [7:0]\in_dly_reg[139]_0 ;
  wire [7:0]\in_dly_reg[171]_0 ;
  wire [127:0]\in_dly_reg[187]_0 ;
  wire [175:0]\in_dly_reg[187]_1 ;
  wire [3:0]\in_dly_reg[23]_0 ;
  wire [3:0]\in_dly_reg[27]_0 ;
  wire [3:0]\in_dly_reg[31]_0 ;
  wire [3:0]\in_dly_reg[35]_0 ;
  wire \mode_8b10b.gen_lane[0].i_lane/cgs_beat_is_cgs ;
  wire [1:0]\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 ;
  wire [3:3]\mode_8b10b.gen_lane[0].i_lane/charisk28_aligned_s ;
  wire \mode_8b10b.gen_lane[1].i_lane/cgs_beat_is_cgs ;
  wire [1:0]\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 ;
  wire [3:3]\mode_8b10b.gen_lane[1].i_lane/charisk28_aligned_s ;
  wire \mode_8b10b.gen_lane[2].i_lane/cgs_beat_is_cgs ;
  wire [1:0]\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 ;
  wire [3:3]\mode_8b10b.gen_lane[2].i_lane/charisk28_aligned_s ;
  wire \mode_8b10b.gen_lane[3].i_lane/cgs_beat_is_cgs ;
  wire [1:0]\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 ;
  wire [3:3]\mode_8b10b.gen_lane[3].i_lane/charisk28_aligned_s ;
  wire \phy_char_err[0]_i_2__0_n_0 ;
  wire \phy_char_err[0]_i_2__1_n_0 ;
  wire \phy_char_err[0]_i_2__2_n_0 ;
  wire \phy_char_err[0]_i_2_n_0 ;
  wire \phy_char_err[1]_i_2__0_n_0 ;
  wire \phy_char_err[1]_i_2__1_n_0 ;
  wire \phy_char_err[1]_i_2__2_n_0 ;
  wire \phy_char_err[1]_i_2_n_0 ;
  wire \phy_char_err[2]_i_2__0_n_0 ;
  wire \phy_char_err[2]_i_2__1_n_0 ;
  wire \phy_char_err[2]_i_2__2_n_0 ;
  wire \phy_char_err[2]_i_2_n_0 ;
  wire \phy_char_err[3]_i_3__0_n_0 ;
  wire \phy_char_err[3]_i_3__1_n_0 ;
  wire \phy_char_err[3]_i_3__2_n_0 ;
  wire \phy_char_err[3]_i_3_n_0 ;
  wire [15:0]phy_charisk_r;
  wire [15:0]phy_disperr_r;
  wire [15:0]phy_notintable_r;
  wire prev_was_last0;
  wire prev_was_last0_3;
  wire prev_was_last0_6;
  wire prev_was_last0_9;
  wire prev_was_last_i_3__0_n_0;
  wire prev_was_last_i_3__1_n_0;
  wire prev_was_last_i_3__2_n_0;
  wire prev_was_last_i_3_n_0;
  wire [0:0]prev_was_last_reg;
  wire [0:0]prev_was_last_reg_0;
  wire [0:0]prev_was_last_reg_1;

  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_10 
       (.I0(phy_notintable_r[2]),
        .I1(phy_disperr_r[2]),
        .O(\FSM_onehot_state[2]_i_10_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_10__0 
       (.I0(phy_notintable_r[6]),
        .I1(phy_disperr_r[6]),
        .O(\FSM_onehot_state[2]_i_10__0_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_10__1 
       (.I0(phy_notintable_r[10]),
        .I1(phy_disperr_r[10]),
        .O(\FSM_onehot_state[2]_i_10__1_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_10__2 
       (.I0(phy_notintable_r[14]),
        .I1(phy_disperr_r[14]),
        .O(\FSM_onehot_state[2]_i_10__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair12" *) 
  LUT3 #(
    .INIT(8'h40)) 
    \FSM_onehot_state[2]_i_11 
       (.I0(\in_dly_reg[187]_0 [22]),
        .I1(\in_dly_reg[187]_0 [21]),
        .I2(phy_charisk_r[3]),
        .O(\FSM_onehot_state[2]_i_11_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair11" *) 
  LUT3 #(
    .INIT(8'h40)) 
    \FSM_onehot_state[2]_i_11__0 
       (.I0(\in_dly_reg[187]_0 [54]),
        .I1(\in_dly_reg[187]_0 [53]),
        .I2(phy_charisk_r[7]),
        .O(\FSM_onehot_state[2]_i_11__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT3 #(
    .INIT(8'h40)) 
    \FSM_onehot_state[2]_i_11__1 
       (.I0(\in_dly_reg[187]_0 [86]),
        .I1(\in_dly_reg[187]_0 [85]),
        .I2(phy_charisk_r[11]),
        .O(\FSM_onehot_state[2]_i_11__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair13" *) 
  LUT3 #(
    .INIT(8'h40)) 
    \FSM_onehot_state[2]_i_11__2 
       (.I0(\in_dly_reg[187]_0 [118]),
        .I1(\in_dly_reg[187]_0 [117]),
        .I2(phy_charisk_r[15]),
        .O(\FSM_onehot_state[2]_i_11__2_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000000080)) 
    \FSM_onehot_state[2]_i_12 
       (.I0(\in_dly_reg[187]_0 [23]),
        .I1(\in_dly_reg[187]_0 [29]),
        .I2(\in_dly_reg[187]_0 [31]),
        .I3(\in_dly_reg[187]_0 [30]),
        .I4(phy_disperr_r[3]),
        .I5(phy_notintable_r[3]),
        .O(\FSM_onehot_state[2]_i_12_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000000080)) 
    \FSM_onehot_state[2]_i_12__0 
       (.I0(\in_dly_reg[187]_0 [55]),
        .I1(\in_dly_reg[187]_0 [61]),
        .I2(\in_dly_reg[187]_0 [63]),
        .I3(\in_dly_reg[187]_0 [62]),
        .I4(phy_disperr_r[7]),
        .I5(phy_notintable_r[7]),
        .O(\FSM_onehot_state[2]_i_12__0_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000000080)) 
    \FSM_onehot_state[2]_i_12__1 
       (.I0(\in_dly_reg[187]_0 [87]),
        .I1(\in_dly_reg[187]_0 [93]),
        .I2(\in_dly_reg[187]_0 [95]),
        .I3(\in_dly_reg[187]_0 [94]),
        .I4(phy_disperr_r[11]),
        .I5(phy_notintable_r[11]),
        .O(\FSM_onehot_state[2]_i_12__1_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000000080)) 
    \FSM_onehot_state[2]_i_12__2 
       (.I0(\in_dly_reg[187]_0 [119]),
        .I1(\in_dly_reg[187]_0 [125]),
        .I2(\in_dly_reg[187]_0 [127]),
        .I3(\in_dly_reg[187]_0 [126]),
        .I4(phy_disperr_r[15]),
        .I5(phy_notintable_r[15]),
        .O(\FSM_onehot_state[2]_i_12__2_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFEAAAAAAA)) 
    \FSM_onehot_state[2]_i_2 
       (.I0(\FSM_onehot_state[2]_i_4_n_0 ),
        .I1(\FSM_onehot_state[2]_i_5_n_0 ),
        .I2(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [0]),
        .I3(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [1]),
        .I4(\FSM_onehot_state_reg[0]_3 ),
        .I5(\FSM_onehot_state_reg[0]_4 ),
        .O(\FSM_onehot_state_reg[0] ));
  LUT6 #(
    .INIT(64'hFFFFFFFFEAAAAAAA)) 
    \FSM_onehot_state[2]_i_2__0 
       (.I0(\FSM_onehot_state[2]_i_4__0_n_0 ),
        .I1(\FSM_onehot_state[2]_i_5__0_n_0 ),
        .I2(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [0]),
        .I3(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [1]),
        .I4(\FSM_onehot_state_reg[0]_5 ),
        .I5(\FSM_onehot_state_reg[0]_6 ),
        .O(\FSM_onehot_state_reg[0]_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFEAAAAAAA)) 
    \FSM_onehot_state[2]_i_2__1 
       (.I0(\FSM_onehot_state[2]_i_4__1_n_0 ),
        .I1(\FSM_onehot_state[2]_i_5__1_n_0 ),
        .I2(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [0]),
        .I3(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [1]),
        .I4(\FSM_onehot_state_reg[0]_7 ),
        .I5(\FSM_onehot_state_reg[0]_8 ),
        .O(\FSM_onehot_state_reg[0]_1 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFEAAAAAAA)) 
    \FSM_onehot_state[2]_i_2__2 
       (.I0(\FSM_onehot_state[2]_i_4__2_n_0 ),
        .I1(\FSM_onehot_state[2]_i_5__2_n_0 ),
        .I2(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [0]),
        .I3(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [1]),
        .I4(\FSM_onehot_state_reg[0]_9 ),
        .I5(\FSM_onehot_state_reg[0]_10 ),
        .O(\FSM_onehot_state_reg[0]_2 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \FSM_onehot_state[2]_i_3 
       (.I0(phy_notintable_r[2]),
        .I1(phy_disperr_r[2]),
        .I2(\FSM_onehot_state[2]_i_7_n_0 ),
        .I3(\FSM_onehot_state[2]_i_8_n_0 ),
        .I4(phy_notintable_r[1]),
        .I5(phy_disperr_r[1]),
        .O(cgs_beat_has_error));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \FSM_onehot_state[2]_i_3__0 
       (.I0(phy_notintable_r[6]),
        .I1(phy_disperr_r[6]),
        .I2(\FSM_onehot_state[2]_i_7__0_n_0 ),
        .I3(\FSM_onehot_state[2]_i_8__0_n_0 ),
        .I4(phy_notintable_r[5]),
        .I5(phy_disperr_r[5]),
        .O(cgs_beat_has_error_5));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \FSM_onehot_state[2]_i_3__1 
       (.I0(phy_notintable_r[10]),
        .I1(phy_disperr_r[10]),
        .I2(\FSM_onehot_state[2]_i_7__1_n_0 ),
        .I3(\FSM_onehot_state[2]_i_8__1_n_0 ),
        .I4(phy_notintable_r[9]),
        .I5(phy_disperr_r[9]),
        .O(cgs_beat_has_error_8));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \FSM_onehot_state[2]_i_3__2 
       (.I0(phy_notintable_r[14]),
        .I1(phy_disperr_r[14]),
        .I2(\FSM_onehot_state[2]_i_7__2_n_0 ),
        .I3(\FSM_onehot_state[2]_i_8__2_n_0 ),
        .I4(phy_notintable_r[13]),
        .I5(phy_disperr_r[13]),
        .O(cgs_beat_has_error_11));
  LUT6 #(
    .INIT(64'hEAAAAAAAAAAAABA8)) 
    \FSM_onehot_state[2]_i_4 
       (.I0(\FSM_onehot_state[2]_i_2_0 ),
        .I1(\FSM_onehot_state[2]_i_9_n_0 ),
        .I2(\FSM_onehot_state[2]_i_8_n_0 ),
        .I3(\FSM_onehot_state[2]_i_2_1 ),
        .I4(\FSM_onehot_state[2]_i_10_n_0 ),
        .I5(\FSM_onehot_state[2]_i_7_n_0 ),
        .O(\FSM_onehot_state[2]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hEAAAAAAAAAAAABA8)) 
    \FSM_onehot_state[2]_i_4__0 
       (.I0(\FSM_onehot_state[2]_i_2__0_0 ),
        .I1(\FSM_onehot_state[2]_i_9__0_n_0 ),
        .I2(\FSM_onehot_state[2]_i_8__0_n_0 ),
        .I3(\FSM_onehot_state[2]_i_2__0_1 ),
        .I4(\FSM_onehot_state[2]_i_10__0_n_0 ),
        .I5(\FSM_onehot_state[2]_i_7__0_n_0 ),
        .O(\FSM_onehot_state[2]_i_4__0_n_0 ));
  LUT6 #(
    .INIT(64'hEAAAAAAAAAAAABA8)) 
    \FSM_onehot_state[2]_i_4__1 
       (.I0(\FSM_onehot_state[2]_i_2__1_0 ),
        .I1(\FSM_onehot_state[2]_i_9__1_n_0 ),
        .I2(\FSM_onehot_state[2]_i_8__1_n_0 ),
        .I3(\FSM_onehot_state[2]_i_2__1_1 ),
        .I4(\FSM_onehot_state[2]_i_10__1_n_0 ),
        .I5(\FSM_onehot_state[2]_i_7__1_n_0 ),
        .O(\FSM_onehot_state[2]_i_4__1_n_0 ));
  LUT6 #(
    .INIT(64'hEAAAAAAAAAAAABA8)) 
    \FSM_onehot_state[2]_i_4__2 
       (.I0(\FSM_onehot_state[2]_i_2__2_0 ),
        .I1(\FSM_onehot_state[2]_i_9__2_n_0 ),
        .I2(\FSM_onehot_state[2]_i_8__2_n_0 ),
        .I3(\FSM_onehot_state[2]_i_2__2_1 ),
        .I4(\FSM_onehot_state[2]_i_10__2_n_0 ),
        .I5(\FSM_onehot_state[2]_i_7__2_n_0 ),
        .O(\FSM_onehot_state[2]_i_4__2_n_0 ));
  LUT6 #(
    .INIT(64'h2000000000000000)) 
    \FSM_onehot_state[2]_i_5 
       (.I0(\in_charisk_d1[3]_i_2_n_0 ),
        .I1(\FSM_onehot_state[2]_i_10_n_0 ),
        .I2(phy_charisk_r[2]),
        .I3(\in_charisk_d1[2]_i_2_n_0 ),
        .I4(\FSM_onehot_state[2]_i_11_n_0 ),
        .I5(\FSM_onehot_state[2]_i_12_n_0 ),
        .O(\FSM_onehot_state[2]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h2000000000000000)) 
    \FSM_onehot_state[2]_i_5__0 
       (.I0(\in_charisk_d1[3]_i_2__0_n_0 ),
        .I1(\FSM_onehot_state[2]_i_10__0_n_0 ),
        .I2(phy_charisk_r[6]),
        .I3(\in_charisk_d1[2]_i_2__0_n_0 ),
        .I4(\FSM_onehot_state[2]_i_11__0_n_0 ),
        .I5(\FSM_onehot_state[2]_i_12__0_n_0 ),
        .O(\FSM_onehot_state[2]_i_5__0_n_0 ));
  LUT6 #(
    .INIT(64'h2000000000000000)) 
    \FSM_onehot_state[2]_i_5__1 
       (.I0(\in_charisk_d1[3]_i_2__1_n_0 ),
        .I1(\FSM_onehot_state[2]_i_10__1_n_0 ),
        .I2(phy_charisk_r[10]),
        .I3(\in_charisk_d1[2]_i_2__1_n_0 ),
        .I4(\FSM_onehot_state[2]_i_11__1_n_0 ),
        .I5(\FSM_onehot_state[2]_i_12__1_n_0 ),
        .O(\FSM_onehot_state[2]_i_5__1_n_0 ));
  LUT6 #(
    .INIT(64'h2000000000000000)) 
    \FSM_onehot_state[2]_i_5__2 
       (.I0(\in_charisk_d1[3]_i_2__2_n_0 ),
        .I1(\FSM_onehot_state[2]_i_10__2_n_0 ),
        .I2(phy_charisk_r[14]),
        .I3(\in_charisk_d1[2]_i_2__2_n_0 ),
        .I4(\FSM_onehot_state[2]_i_11__2_n_0 ),
        .I5(\FSM_onehot_state[2]_i_12__2_n_0 ),
        .O(\FSM_onehot_state[2]_i_5__2_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_7 
       (.I0(phy_notintable_r[3]),
        .I1(phy_disperr_r[3]),
        .O(\FSM_onehot_state[2]_i_7_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_7__0 
       (.I0(phy_notintable_r[7]),
        .I1(phy_disperr_r[7]),
        .O(\FSM_onehot_state[2]_i_7__0_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_7__1 
       (.I0(phy_notintable_r[11]),
        .I1(phy_disperr_r[11]),
        .O(\FSM_onehot_state[2]_i_7__1_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_7__2 
       (.I0(phy_notintable_r[15]),
        .I1(phy_disperr_r[15]),
        .O(\FSM_onehot_state[2]_i_7__2_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_8 
       (.I0(phy_notintable_r[0]),
        .I1(phy_disperr_r[0]),
        .O(\FSM_onehot_state[2]_i_8_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_8__0 
       (.I0(phy_notintable_r[4]),
        .I1(phy_disperr_r[4]),
        .O(\FSM_onehot_state[2]_i_8__0_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_8__1 
       (.I0(phy_notintable_r[8]),
        .I1(phy_disperr_r[8]),
        .O(\FSM_onehot_state[2]_i_8__1_n_0 ));
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_8__2 
       (.I0(phy_notintable_r[12]),
        .I1(phy_disperr_r[12]),
        .O(\FSM_onehot_state[2]_i_8__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair24" *) 
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_9 
       (.I0(phy_notintable_r[1]),
        .I1(phy_disperr_r[1]),
        .O(\FSM_onehot_state[2]_i_9_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair25" *) 
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_9__0 
       (.I0(phy_notintable_r[5]),
        .I1(phy_disperr_r[5]),
        .O(\FSM_onehot_state[2]_i_9__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair23" *) 
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_9__1 
       (.I0(phy_notintable_r[9]),
        .I1(phy_disperr_r[9]),
        .O(\FSM_onehot_state[2]_i_9__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair26" *) 
  LUT2 #(
    .INIT(4'hE)) 
    \FSM_onehot_state[2]_i_9__2 
       (.I0(phy_notintable_r[13]),
        .I1(phy_disperr_r[13]),
        .O(\FSM_onehot_state[2]_i_9__2_n_0 ));
  LUT6 #(
    .INIT(64'hFFFF8F0000008F00)) 
    \frame_align[0]_i_1 
       (.I0(\frame_align[0]_i_2__2_n_0 ),
        .I1(charisk28[2]),
        .I2(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [1]),
        .I3(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [0]),
        .I4(ifs_ready[0]),
        .I5(\frame_align_reg[0] ),
        .O(ifs_ready_reg));
  LUT6 #(
    .INIT(64'hFFFF8F0000008F00)) 
    \frame_align[0]_i_1__0 
       (.I0(\frame_align[0]_i_2__1_n_0 ),
        .I1(charisk28_0[2]),
        .I2(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [1]),
        .I3(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [0]),
        .I4(ifs_ready[1]),
        .I5(\frame_align_reg[0]_0 ),
        .O(ifs_ready_reg_0));
  LUT6 #(
    .INIT(64'hFFFF8F0000008F00)) 
    \frame_align[0]_i_1__1 
       (.I0(\frame_align[0]_i_2__0_n_0 ),
        .I1(charisk28_1[2]),
        .I2(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [1]),
        .I3(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [0]),
        .I4(ifs_ready[2]),
        .I5(\frame_align_reg[0]_1 ),
        .O(ifs_ready_reg_1));
  LUT6 #(
    .INIT(64'hFFFF8F0000008F00)) 
    \frame_align[0]_i_1__2 
       (.I0(\frame_align[0]_i_2_n_0 ),
        .I1(charisk28_2[2]),
        .I2(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [1]),
        .I3(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [0]),
        .I4(ifs_ready[3]),
        .I5(\frame_align_reg[0]_2 ),
        .O(ifs_ready_reg_2));
  LUT3 #(
    .INIT(8'h40)) 
    \frame_align[0]_i_2 
       (.I0(\in_dly_reg[187]_0 [118]),
        .I1(\in_dly_reg[187]_0 [119]),
        .I2(\in_dly_reg[187]_0 [117]),
        .O(\frame_align[0]_i_2_n_0 ));
  LUT3 #(
    .INIT(8'h40)) 
    \frame_align[0]_i_2__0 
       (.I0(\in_dly_reg[187]_0 [86]),
        .I1(\in_dly_reg[187]_0 [87]),
        .I2(\in_dly_reg[187]_0 [85]),
        .O(\frame_align[0]_i_2__0_n_0 ));
  LUT3 #(
    .INIT(8'h40)) 
    \frame_align[0]_i_2__1 
       (.I0(\in_dly_reg[187]_0 [54]),
        .I1(\in_dly_reg[187]_0 [55]),
        .I2(\in_dly_reg[187]_0 [53]),
        .O(\frame_align[0]_i_2__1_n_0 ));
  LUT3 #(
    .INIT(8'h40)) 
    \frame_align[0]_i_2__2 
       (.I0(\in_dly_reg[187]_0 [22]),
        .I1(\in_dly_reg[187]_0 [23]),
        .I2(\in_dly_reg[187]_0 [21]),
        .O(\frame_align[0]_i_2__2_n_0 ));
  LUT5 #(
    .INIT(32'h20000000)) 
    \frame_align[0]_i_3 
       (.I0(\frame_align[1]_i_3_n_0 ),
        .I1(\in_dly_reg[187]_0 [14]),
        .I2(\in_dly_reg[187]_0 [15]),
        .I3(\in_dly_reg[187]_0 [13]),
        .I4(\in_charisk_d1[1]_i_2_n_0 ),
        .O(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [1]));
  LUT5 #(
    .INIT(32'h20000000)) 
    \frame_align[0]_i_3__0 
       (.I0(\frame_align[1]_i_3__0_n_0 ),
        .I1(\in_dly_reg[187]_0 [46]),
        .I2(\in_dly_reg[187]_0 [47]),
        .I3(\in_dly_reg[187]_0 [45]),
        .I4(\in_charisk_d1[1]_i_2__0_n_0 ),
        .O(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [1]));
  LUT5 #(
    .INIT(32'h20000000)) 
    \frame_align[0]_i_3__1 
       (.I0(\frame_align[1]_i_3__1_n_0 ),
        .I1(\in_dly_reg[187]_0 [78]),
        .I2(\in_dly_reg[187]_0 [79]),
        .I3(\in_dly_reg[187]_0 [77]),
        .I4(\in_charisk_d1[1]_i_2__1_n_0 ),
        .O(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [1]));
  LUT5 #(
    .INIT(32'h20000000)) 
    \frame_align[0]_i_3__2 
       (.I0(\frame_align[1]_i_3__2_n_0 ),
        .I1(\in_dly_reg[187]_0 [110]),
        .I2(\in_dly_reg[187]_0 [111]),
        .I3(\in_dly_reg[187]_0 [109]),
        .I4(\in_charisk_d1[1]_i_2__2_n_0 ),
        .O(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [1]));
  LUT6 #(
    .INIT(64'h0000000008000000)) 
    \frame_align[0]_i_4 
       (.I0(\in_dly_reg[187]_0 [5]),
        .I1(\in_dly_reg[187]_0 [7]),
        .I2(\in_dly_reg[187]_0 [6]),
        .I3(\in_charisk_d1[0]_i_2_n_0 ),
        .I4(phy_charisk_r[0]),
        .I5(\FSM_onehot_state[2]_i_8_n_0 ),
        .O(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [0]));
  LUT6 #(
    .INIT(64'h0000000008000000)) 
    \frame_align[0]_i_4__0 
       (.I0(\in_dly_reg[187]_0 [37]),
        .I1(\in_dly_reg[187]_0 [39]),
        .I2(\in_dly_reg[187]_0 [38]),
        .I3(\in_charisk_d1[0]_i_2__0_n_0 ),
        .I4(phy_charisk_r[4]),
        .I5(\FSM_onehot_state[2]_i_8__0_n_0 ),
        .O(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [0]));
  LUT6 #(
    .INIT(64'h0000000008000000)) 
    \frame_align[0]_i_4__1 
       (.I0(\in_dly_reg[187]_0 [69]),
        .I1(\in_dly_reg[187]_0 [71]),
        .I2(\in_dly_reg[187]_0 [70]),
        .I3(\in_charisk_d1[0]_i_2__1_n_0 ),
        .I4(phy_charisk_r[8]),
        .I5(\FSM_onehot_state[2]_i_8__1_n_0 ),
        .O(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [0]));
  LUT6 #(
    .INIT(64'h0000000008000000)) 
    \frame_align[0]_i_4__2 
       (.I0(\in_dly_reg[187]_0 [101]),
        .I1(\in_dly_reg[187]_0 [103]),
        .I2(\in_dly_reg[187]_0 [102]),
        .I3(\in_charisk_d1[0]_i_2__2_n_0 ),
        .I4(phy_charisk_r[12]),
        .I5(\FSM_onehot_state[2]_i_8__2_n_0 ),
        .O(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [0]));
  LUT6 #(
    .INIT(64'h0000800000000000)) 
    \frame_align[1]_i_2 
       (.I0(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [0]),
        .I1(\in_charisk_d1[1]_i_2_n_0 ),
        .I2(\in_dly_reg[187]_0 [13]),
        .I3(\in_dly_reg[187]_0 [15]),
        .I4(\in_dly_reg[187]_0 [14]),
        .I5(\frame_align[1]_i_3_n_0 ),
        .O(frame_align));
  LUT6 #(
    .INIT(64'h0000800000000000)) 
    \frame_align[1]_i_2__0 
       (.I0(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [0]),
        .I1(\in_charisk_d1[1]_i_2__0_n_0 ),
        .I2(\in_dly_reg[187]_0 [45]),
        .I3(\in_dly_reg[187]_0 [47]),
        .I4(\in_dly_reg[187]_0 [46]),
        .I5(\frame_align[1]_i_3__0_n_0 ),
        .O(frame_align_4));
  LUT6 #(
    .INIT(64'h0000800000000000)) 
    \frame_align[1]_i_2__1 
       (.I0(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [0]),
        .I1(\in_charisk_d1[1]_i_2__1_n_0 ),
        .I2(\in_dly_reg[187]_0 [77]),
        .I3(\in_dly_reg[187]_0 [79]),
        .I4(\in_dly_reg[187]_0 [78]),
        .I5(\frame_align[1]_i_3__1_n_0 ),
        .O(frame_align_7));
  LUT6 #(
    .INIT(64'h0000800000000000)) 
    \frame_align[1]_i_2__2 
       (.I0(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [0]),
        .I1(\in_charisk_d1[1]_i_2__2_n_0 ),
        .I2(\in_dly_reg[187]_0 [109]),
        .I3(\in_dly_reg[187]_0 [111]),
        .I4(\in_dly_reg[187]_0 [110]),
        .I5(\frame_align[1]_i_3__2_n_0 ),
        .O(frame_align_10));
  (* SOFT_HLUTNM = "soft_lutpair24" *) 
  LUT3 #(
    .INIT(8'h02)) 
    \frame_align[1]_i_3 
       (.I0(phy_charisk_r[1]),
        .I1(phy_disperr_r[1]),
        .I2(phy_notintable_r[1]),
        .O(\frame_align[1]_i_3_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair25" *) 
  LUT3 #(
    .INIT(8'h02)) 
    \frame_align[1]_i_3__0 
       (.I0(phy_charisk_r[5]),
        .I1(phy_disperr_r[5]),
        .I2(phy_notintable_r[5]),
        .O(\frame_align[1]_i_3__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair23" *) 
  LUT3 #(
    .INIT(8'h02)) 
    \frame_align[1]_i_3__1 
       (.I0(phy_charisk_r[9]),
        .I1(phy_disperr_r[9]),
        .I2(phy_notintable_r[9]),
        .O(\frame_align[1]_i_3__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair26" *) 
  LUT3 #(
    .INIT(8'h02)) 
    \frame_align[1]_i_3__2 
       (.I0(phy_charisk_r[13]),
        .I1(phy_disperr_r[13]),
        .I2(phy_notintable_r[13]),
        .O(\frame_align[1]_i_3__2_n_0 ));
  LUT4 #(
    .INIT(16'h00AB)) 
    ifs_ready_i_1
       (.I0(ifs_ready[0]),
        .I1(\mode_8b10b.gen_lane[0].i_lane/cgs_beat_is_cgs ),
        .I2(cgs_beat_has_error),
        .I3(ifs_ready_reg_7[0]),
        .O(ifs_ready_reg_3));
  LUT4 #(
    .INIT(16'h00AB)) 
    ifs_ready_i_1__0
       (.I0(ifs_ready[1]),
        .I1(\mode_8b10b.gen_lane[1].i_lane/cgs_beat_is_cgs ),
        .I2(cgs_beat_has_error_5),
        .I3(ifs_ready_reg_7[1]),
        .O(ifs_ready_reg_4));
  LUT4 #(
    .INIT(16'h00AB)) 
    ifs_ready_i_1__1
       (.I0(ifs_ready[2]),
        .I1(\mode_8b10b.gen_lane[2].i_lane/cgs_beat_is_cgs ),
        .I2(cgs_beat_has_error_8),
        .I3(ifs_ready_reg_7[2]),
        .O(ifs_ready_reg_5));
  LUT4 #(
    .INIT(16'h00AB)) 
    ifs_ready_i_1__2
       (.I0(ifs_ready[3]),
        .I1(\mode_8b10b.gen_lane[3].i_lane/cgs_beat_is_cgs ),
        .I2(cgs_beat_has_error_11),
        .I3(ifs_ready_reg_7[3]),
        .O(ifs_ready_reg_6));
  LUT5 #(
    .INIT(32'h80000000)) 
    ifs_ready_i_2
       (.I0(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [1]),
        .I1(\mode_8b10b.gen_lane[0].i_lane/char_is_cgs__1 [0]),
        .I2(ifs_ready_i_3_n_0),
        .I3(charisk28[2]),
        .I4(\in_charisk_d1[3]_i_2_n_0 ),
        .O(\mode_8b10b.gen_lane[0].i_lane/cgs_beat_is_cgs ));
  LUT5 #(
    .INIT(32'h80000000)) 
    ifs_ready_i_2__0
       (.I0(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [1]),
        .I1(\mode_8b10b.gen_lane[1].i_lane/char_is_cgs__1 [0]),
        .I2(ifs_ready_i_3__0_n_0),
        .I3(charisk28_0[2]),
        .I4(\in_charisk_d1[3]_i_2__0_n_0 ),
        .O(\mode_8b10b.gen_lane[1].i_lane/cgs_beat_is_cgs ));
  LUT5 #(
    .INIT(32'h80000000)) 
    ifs_ready_i_2__1
       (.I0(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [1]),
        .I1(\mode_8b10b.gen_lane[2].i_lane/char_is_cgs__1 [0]),
        .I2(ifs_ready_i_3__1_n_0),
        .I3(charisk28_1[2]),
        .I4(\in_charisk_d1[3]_i_2__1_n_0 ),
        .O(\mode_8b10b.gen_lane[2].i_lane/cgs_beat_is_cgs ));
  LUT5 #(
    .INIT(32'h80000000)) 
    ifs_ready_i_2__2
       (.I0(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [1]),
        .I1(\mode_8b10b.gen_lane[3].i_lane/char_is_cgs__1 [0]),
        .I2(ifs_ready_i_3__2_n_0),
        .I3(charisk28_2[2]),
        .I4(\in_charisk_d1[3]_i_2__2_n_0 ),
        .O(\mode_8b10b.gen_lane[3].i_lane/cgs_beat_is_cgs ));
  (* SOFT_HLUTNM = "soft_lutpair12" *) 
  LUT4 #(
    .INIT(16'h0080)) 
    ifs_ready_i_3
       (.I0(\FSM_onehot_state[2]_i_12_n_0 ),
        .I1(phy_charisk_r[3]),
        .I2(\in_dly_reg[187]_0 [21]),
        .I3(\in_dly_reg[187]_0 [22]),
        .O(ifs_ready_i_3_n_0));
  (* SOFT_HLUTNM = "soft_lutpair11" *) 
  LUT4 #(
    .INIT(16'h0080)) 
    ifs_ready_i_3__0
       (.I0(\FSM_onehot_state[2]_i_12__0_n_0 ),
        .I1(phy_charisk_r[7]),
        .I2(\in_dly_reg[187]_0 [53]),
        .I3(\in_dly_reg[187]_0 [54]),
        .O(ifs_ready_i_3__0_n_0));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT4 #(
    .INIT(16'h0080)) 
    ifs_ready_i_3__1
       (.I0(\FSM_onehot_state[2]_i_12__1_n_0 ),
        .I1(phy_charisk_r[11]),
        .I2(\in_dly_reg[187]_0 [85]),
        .I3(\in_dly_reg[187]_0 [86]),
        .O(ifs_ready_i_3__1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair13" *) 
  LUT4 #(
    .INIT(16'h0080)) 
    ifs_ready_i_3__2
       (.I0(\FSM_onehot_state[2]_i_12__2_n_0 ),
        .I1(phy_charisk_r[15]),
        .I2(\in_dly_reg[187]_0 [117]),
        .I3(\in_dly_reg[187]_0 [118]),
        .O(ifs_ready_i_3__2_n_0));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[24]_i_1 
       (.I0(\in_dly_reg[187]_0 [8]),
        .I1(\in_dly_reg[187]_0 [16]),
        .I2(\ilas_config_data_reg[31] [0]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [0]),
        .O(D[0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[24]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [40]),
        .I1(\in_dly_reg[187]_0 [48]),
        .I2(\ilas_config_data_reg[31]_0 [0]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [32]),
        .O(\in_dly_reg[107]_0 [0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[24]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [72]),
        .I1(\in_dly_reg[187]_0 [80]),
        .I2(\ilas_config_data_reg[31]_1 [0]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [64]),
        .O(\in_dly_reg[139]_0 [0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[24]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [104]),
        .I1(\in_dly_reg[187]_0 [112]),
        .I2(\ilas_config_data_reg[31]_2 [0]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [96]),
        .O(\in_dly_reg[171]_0 [0]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[25]_i_1 
       (.I0(\in_dly_reg[187]_0 [9]),
        .I1(\in_dly_reg[187]_0 [17]),
        .I2(\ilas_config_data_reg[31] [1]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [1]),
        .O(D[1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[25]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [41]),
        .I1(\in_dly_reg[187]_0 [49]),
        .I2(\ilas_config_data_reg[31]_0 [1]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [33]),
        .O(\in_dly_reg[107]_0 [1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[25]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [73]),
        .I1(\in_dly_reg[187]_0 [81]),
        .I2(\ilas_config_data_reg[31]_1 [1]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [65]),
        .O(\in_dly_reg[139]_0 [1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[25]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [105]),
        .I1(\in_dly_reg[187]_0 [113]),
        .I2(\ilas_config_data_reg[31]_2 [1]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [97]),
        .O(\in_dly_reg[171]_0 [1]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[26]_i_1 
       (.I0(\in_dly_reg[187]_0 [10]),
        .I1(\in_dly_reg[187]_0 [18]),
        .I2(\ilas_config_data_reg[31] [2]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [2]),
        .O(D[2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[26]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [42]),
        .I1(\in_dly_reg[187]_0 [50]),
        .I2(\ilas_config_data_reg[31]_0 [2]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [34]),
        .O(\in_dly_reg[107]_0 [2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[26]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [74]),
        .I1(\in_dly_reg[187]_0 [82]),
        .I2(\ilas_config_data_reg[31]_1 [2]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [66]),
        .O(\in_dly_reg[139]_0 [2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[26]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [106]),
        .I1(\in_dly_reg[187]_0 [114]),
        .I2(\ilas_config_data_reg[31]_2 [2]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [98]),
        .O(\in_dly_reg[171]_0 [2]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[27]_i_1 
       (.I0(\in_dly_reg[187]_0 [11]),
        .I1(\in_dly_reg[187]_0 [19]),
        .I2(\ilas_config_data_reg[31] [3]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [3]),
        .O(D[3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[27]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [43]),
        .I1(\in_dly_reg[187]_0 [51]),
        .I2(\ilas_config_data_reg[31]_0 [3]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [35]),
        .O(\in_dly_reg[107]_0 [3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[27]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [75]),
        .I1(\in_dly_reg[187]_0 [83]),
        .I2(\ilas_config_data_reg[31]_1 [3]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [67]),
        .O(\in_dly_reg[139]_0 [3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[27]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [107]),
        .I1(\in_dly_reg[187]_0 [115]),
        .I2(\ilas_config_data_reg[31]_2 [3]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [99]),
        .O(\in_dly_reg[171]_0 [3]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[28]_i_1 
       (.I0(\in_dly_reg[187]_0 [12]),
        .I1(\in_dly_reg[187]_0 [20]),
        .I2(\ilas_config_data_reg[31] [4]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [4]),
        .O(D[4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[28]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [44]),
        .I1(\in_dly_reg[187]_0 [52]),
        .I2(\ilas_config_data_reg[31]_0 [4]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [36]),
        .O(\in_dly_reg[107]_0 [4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[28]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [76]),
        .I1(\in_dly_reg[187]_0 [84]),
        .I2(\ilas_config_data_reg[31]_1 [4]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [68]),
        .O(\in_dly_reg[139]_0 [4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[28]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [108]),
        .I1(\in_dly_reg[187]_0 [116]),
        .I2(\ilas_config_data_reg[31]_2 [4]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [100]),
        .O(\in_dly_reg[171]_0 [4]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[29]_i_1 
       (.I0(\in_dly_reg[187]_0 [13]),
        .I1(\in_dly_reg[187]_0 [21]),
        .I2(\ilas_config_data_reg[31] [5]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [5]),
        .O(D[5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[29]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [45]),
        .I1(\in_dly_reg[187]_0 [53]),
        .I2(\ilas_config_data_reg[31]_0 [5]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [37]),
        .O(\in_dly_reg[107]_0 [5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[29]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [77]),
        .I1(\in_dly_reg[187]_0 [85]),
        .I2(\ilas_config_data_reg[31]_1 [5]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [69]),
        .O(\in_dly_reg[139]_0 [5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[29]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [109]),
        .I1(\in_dly_reg[187]_0 [117]),
        .I2(\ilas_config_data_reg[31]_2 [5]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [101]),
        .O(\in_dly_reg[171]_0 [5]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[30]_i_1 
       (.I0(\in_dly_reg[187]_0 [14]),
        .I1(\in_dly_reg[187]_0 [22]),
        .I2(\ilas_config_data_reg[31] [6]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [6]),
        .O(D[6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[30]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [46]),
        .I1(\in_dly_reg[187]_0 [54]),
        .I2(\ilas_config_data_reg[31]_0 [6]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [38]),
        .O(\in_dly_reg[107]_0 [6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[30]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [78]),
        .I1(\in_dly_reg[187]_0 [86]),
        .I2(\ilas_config_data_reg[31]_1 [6]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [70]),
        .O(\in_dly_reg[139]_0 [6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[30]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [110]),
        .I1(\in_dly_reg[187]_0 [118]),
        .I2(\ilas_config_data_reg[31]_2 [6]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [102]),
        .O(\in_dly_reg[171]_0 [6]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[31]_i_1 
       (.I0(\in_dly_reg[187]_0 [15]),
        .I1(\in_dly_reg[187]_0 [23]),
        .I2(\ilas_config_data_reg[31] [7]),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(\in_dly_reg[187]_0 [7]),
        .O(D[7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[31]_i_1__0 
       (.I0(\in_dly_reg[187]_0 [47]),
        .I1(\in_dly_reg[187]_0 [55]),
        .I2(\ilas_config_data_reg[31]_0 [7]),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(\in_dly_reg[187]_0 [39]),
        .O(\in_dly_reg[107]_0 [7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[31]_i_1__1 
       (.I0(\in_dly_reg[187]_0 [79]),
        .I1(\in_dly_reg[187]_0 [87]),
        .I2(\ilas_config_data_reg[31]_1 [7]),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(\in_dly_reg[187]_0 [71]),
        .O(\in_dly_reg[139]_0 [7]));
  LUT6 #(
    .INIT(64'hCCFFAAF0CC00AAF0)) 
    \ilas_config_data[31]_i_1__2 
       (.I0(\in_dly_reg[187]_0 [111]),
        .I1(\in_dly_reg[187]_0 [119]),
        .I2(\ilas_config_data_reg[31]_2 [7]),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(\in_dly_reg[187]_0 [103]),
        .O(\in_dly_reg[171]_0 [7]));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[0]_i_1 
       (.I0(phy_notintable_r[0]),
        .I1(phy_disperr_r[0]),
        .I2(phy_charisk_r[0]),
        .I3(\in_charisk_d1[0]_i_2_n_0 ),
        .O(charisk28[0]));
  (* SOFT_HLUTNM = "soft_lutpair16" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[0]_i_1__0 
       (.I0(phy_notintable_r[4]),
        .I1(phy_disperr_r[4]),
        .I2(phy_charisk_r[4]),
        .I3(\in_charisk_d1[0]_i_2__0_n_0 ),
        .O(charisk28_0[0]));
  (* SOFT_HLUTNM = "soft_lutpair10" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[0]_i_1__1 
       (.I0(phy_notintable_r[8]),
        .I1(phy_disperr_r[8]),
        .I2(phy_charisk_r[8]),
        .I3(\in_charisk_d1[0]_i_2__1_n_0 ),
        .O(charisk28_1[0]));
  (* SOFT_HLUTNM = "soft_lutpair20" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[0]_i_1__2 
       (.I0(phy_notintable_r[12]),
        .I1(phy_disperr_r[12]),
        .I2(phy_charisk_r[12]),
        .I3(\in_charisk_d1[0]_i_2__2_n_0 ),
        .O(charisk28_2[0]));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[0]_i_2 
       (.I0(\in_dly_reg[187]_0 [0]),
        .I1(\in_dly_reg[187]_0 [2]),
        .I2(\in_dly_reg[187]_0 [1]),
        .I3(\in_dly_reg[187]_0 [4]),
        .I4(\in_dly_reg[187]_0 [3]),
        .O(\in_charisk_d1[0]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[0]_i_2__0 
       (.I0(\in_dly_reg[187]_0 [32]),
        .I1(\in_dly_reg[187]_0 [34]),
        .I2(\in_dly_reg[187]_0 [33]),
        .I3(\in_dly_reg[187]_0 [36]),
        .I4(\in_dly_reg[187]_0 [35]),
        .O(\in_charisk_d1[0]_i_2__0_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[0]_i_2__1 
       (.I0(\in_dly_reg[187]_0 [64]),
        .I1(\in_dly_reg[187]_0 [66]),
        .I2(\in_dly_reg[187]_0 [65]),
        .I3(\in_dly_reg[187]_0 [68]),
        .I4(\in_dly_reg[187]_0 [67]),
        .O(\in_charisk_d1[0]_i_2__1_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[0]_i_2__2 
       (.I0(\in_dly_reg[187]_0 [96]),
        .I1(\in_dly_reg[187]_0 [98]),
        .I2(\in_dly_reg[187]_0 [97]),
        .I3(\in_dly_reg[187]_0 [100]),
        .I4(\in_dly_reg[187]_0 [99]),
        .O(\in_charisk_d1[0]_i_2__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair19" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[1]_i_1 
       (.I0(phy_notintable_r[1]),
        .I1(phy_disperr_r[1]),
        .I2(phy_charisk_r[1]),
        .I3(\in_charisk_d1[1]_i_2_n_0 ),
        .O(charisk28[1]));
  (* SOFT_HLUTNM = "soft_lutpair15" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[1]_i_1__0 
       (.I0(phy_notintable_r[5]),
        .I1(phy_disperr_r[5]),
        .I2(phy_charisk_r[5]),
        .I3(\in_charisk_d1[1]_i_2__0_n_0 ),
        .O(charisk28_0[1]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[1]_i_1__1 
       (.I0(phy_notintable_r[9]),
        .I1(phy_disperr_r[9]),
        .I2(phy_charisk_r[9]),
        .I3(\in_charisk_d1[1]_i_2__1_n_0 ),
        .O(charisk28_1[1]));
  (* SOFT_HLUTNM = "soft_lutpair22" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[1]_i_1__2 
       (.I0(phy_notintable_r[13]),
        .I1(phy_disperr_r[13]),
        .I2(phy_charisk_r[13]),
        .I3(\in_charisk_d1[1]_i_2__2_n_0 ),
        .O(charisk28_2[1]));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[1]_i_2 
       (.I0(\in_dly_reg[187]_0 [8]),
        .I1(\in_dly_reg[187]_0 [10]),
        .I2(\in_dly_reg[187]_0 [9]),
        .I3(\in_dly_reg[187]_0 [12]),
        .I4(\in_dly_reg[187]_0 [11]),
        .O(\in_charisk_d1[1]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[1]_i_2__0 
       (.I0(\in_dly_reg[187]_0 [40]),
        .I1(\in_dly_reg[187]_0 [42]),
        .I2(\in_dly_reg[187]_0 [41]),
        .I3(\in_dly_reg[187]_0 [44]),
        .I4(\in_dly_reg[187]_0 [43]),
        .O(\in_charisk_d1[1]_i_2__0_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[1]_i_2__1 
       (.I0(\in_dly_reg[187]_0 [72]),
        .I1(\in_dly_reg[187]_0 [74]),
        .I2(\in_dly_reg[187]_0 [73]),
        .I3(\in_dly_reg[187]_0 [76]),
        .I4(\in_dly_reg[187]_0 [75]),
        .O(\in_charisk_d1[1]_i_2__1_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[1]_i_2__2 
       (.I0(\in_dly_reg[187]_0 [104]),
        .I1(\in_dly_reg[187]_0 [106]),
        .I2(\in_dly_reg[187]_0 [105]),
        .I3(\in_dly_reg[187]_0 [108]),
        .I4(\in_dly_reg[187]_0 [107]),
        .O(\in_charisk_d1[1]_i_2__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair17" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[2]_i_1 
       (.I0(phy_notintable_r[2]),
        .I1(phy_disperr_r[2]),
        .I2(phy_charisk_r[2]),
        .I3(\in_charisk_d1[2]_i_2_n_0 ),
        .O(charisk28[2]));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[2]_i_1__0 
       (.I0(phy_notintable_r[6]),
        .I1(phy_disperr_r[6]),
        .I2(phy_charisk_r[6]),
        .I3(\in_charisk_d1[2]_i_2__0_n_0 ),
        .O(charisk28_0[2]));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[2]_i_1__1 
       (.I0(phy_notintable_r[10]),
        .I1(phy_disperr_r[10]),
        .I2(phy_charisk_r[10]),
        .I3(\in_charisk_d1[2]_i_2__1_n_0 ),
        .O(charisk28_1[2]));
  (* SOFT_HLUTNM = "soft_lutpair21" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[2]_i_1__2 
       (.I0(phy_notintable_r[14]),
        .I1(phy_disperr_r[14]),
        .I2(phy_charisk_r[14]),
        .I3(\in_charisk_d1[2]_i_2__2_n_0 ),
        .O(charisk28_2[2]));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[2]_i_2 
       (.I0(\in_dly_reg[187]_0 [16]),
        .I1(\in_dly_reg[187]_0 [18]),
        .I2(\in_dly_reg[187]_0 [17]),
        .I3(\in_dly_reg[187]_0 [20]),
        .I4(\in_dly_reg[187]_0 [19]),
        .O(\in_charisk_d1[2]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[2]_i_2__0 
       (.I0(\in_dly_reg[187]_0 [48]),
        .I1(\in_dly_reg[187]_0 [50]),
        .I2(\in_dly_reg[187]_0 [49]),
        .I3(\in_dly_reg[187]_0 [52]),
        .I4(\in_dly_reg[187]_0 [51]),
        .O(\in_charisk_d1[2]_i_2__0_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[2]_i_2__1 
       (.I0(\in_dly_reg[187]_0 [80]),
        .I1(\in_dly_reg[187]_0 [82]),
        .I2(\in_dly_reg[187]_0 [81]),
        .I3(\in_dly_reg[187]_0 [84]),
        .I4(\in_dly_reg[187]_0 [83]),
        .O(\in_charisk_d1[2]_i_2__1_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[2]_i_2__2 
       (.I0(\in_dly_reg[187]_0 [112]),
        .I1(\in_dly_reg[187]_0 [114]),
        .I2(\in_dly_reg[187]_0 [113]),
        .I3(\in_dly_reg[187]_0 [116]),
        .I4(\in_dly_reg[187]_0 [115]),
        .O(\in_charisk_d1[2]_i_2__2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair18" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[3]_i_1 
       (.I0(phy_notintable_r[3]),
        .I1(phy_disperr_r[3]),
        .I2(phy_charisk_r[3]),
        .I3(\in_charisk_d1[3]_i_2_n_0 ),
        .O(charisk28[3]));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[3]_i_1__0 
       (.I0(phy_notintable_r[7]),
        .I1(phy_disperr_r[7]),
        .I2(phy_charisk_r[7]),
        .I3(\in_charisk_d1[3]_i_2__0_n_0 ),
        .O(charisk28_0[3]));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[3]_i_1__1 
       (.I0(phy_notintable_r[11]),
        .I1(phy_disperr_r[11]),
        .I2(phy_charisk_r[11]),
        .I3(\in_charisk_d1[3]_i_2__1_n_0 ),
        .O(charisk28_1[3]));
  (* SOFT_HLUTNM = "soft_lutpair14" *) 
  LUT4 #(
    .INIT(16'h1000)) 
    \in_charisk_d1[3]_i_1__2 
       (.I0(phy_notintable_r[15]),
        .I1(phy_disperr_r[15]),
        .I2(phy_charisk_r[15]),
        .I3(\in_charisk_d1[3]_i_2__2_n_0 ),
        .O(charisk28_2[3]));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[3]_i_2 
       (.I0(\in_dly_reg[187]_0 [24]),
        .I1(\in_dly_reg[187]_0 [26]),
        .I2(\in_dly_reg[187]_0 [25]),
        .I3(\in_dly_reg[187]_0 [28]),
        .I4(\in_dly_reg[187]_0 [27]),
        .O(\in_charisk_d1[3]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[3]_i_2__0 
       (.I0(\in_dly_reg[187]_0 [56]),
        .I1(\in_dly_reg[187]_0 [58]),
        .I2(\in_dly_reg[187]_0 [57]),
        .I3(\in_dly_reg[187]_0 [60]),
        .I4(\in_dly_reg[187]_0 [59]),
        .O(\in_charisk_d1[3]_i_2__0_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[3]_i_2__1 
       (.I0(\in_dly_reg[187]_0 [88]),
        .I1(\in_dly_reg[187]_0 [90]),
        .I2(\in_dly_reg[187]_0 [89]),
        .I3(\in_dly_reg[187]_0 [92]),
        .I4(\in_dly_reg[187]_0 [91]),
        .O(\in_charisk_d1[3]_i_2__1_n_0 ));
  LUT5 #(
    .INIT(32'h04000000)) 
    \in_charisk_d1[3]_i_2__2 
       (.I0(\in_dly_reg[187]_0 [120]),
        .I1(\in_dly_reg[187]_0 [122]),
        .I2(\in_dly_reg[187]_0 [121]),
        .I3(\in_dly_reg[187]_0 [124]),
        .I4(\in_dly_reg[187]_0 [123]),
        .O(\in_charisk_d1[3]_i_2__2_n_0 ));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[100] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [88]),
        .Q(\in_dly_reg[187]_0 [40]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[101] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [89]),
        .Q(\in_dly_reg[187]_0 [41]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[102] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [90]),
        .Q(\in_dly_reg[187]_0 [42]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[103] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [91]),
        .Q(\in_dly_reg[187]_0 [43]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[104] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [92]),
        .Q(\in_dly_reg[187]_0 [44]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[105] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [93]),
        .Q(\in_dly_reg[187]_0 [45]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[106] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [94]),
        .Q(\in_dly_reg[187]_0 [46]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[107] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [95]),
        .Q(\in_dly_reg[187]_0 [47]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[108] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [96]),
        .Q(\in_dly_reg[187]_0 [48]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[109] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [97]),
        .Q(\in_dly_reg[187]_0 [49]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[10] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [6]),
        .Q(phy_disperr_r[6]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[110] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [98]),
        .Q(\in_dly_reg[187]_0 [50]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[111] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [99]),
        .Q(\in_dly_reg[187]_0 [51]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[112] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [100]),
        .Q(\in_dly_reg[187]_0 [52]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[113] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [101]),
        .Q(\in_dly_reg[187]_0 [53]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[114] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [102]),
        .Q(\in_dly_reg[187]_0 [54]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[115] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [103]),
        .Q(\in_dly_reg[187]_0 [55]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[116] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [104]),
        .Q(\in_dly_reg[187]_0 [56]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[117] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [105]),
        .Q(\in_dly_reg[187]_0 [57]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[118] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [106]),
        .Q(\in_dly_reg[187]_0 [58]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[119] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [107]),
        .Q(\in_dly_reg[187]_0 [59]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[11] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [7]),
        .Q(phy_disperr_r[7]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[120] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [108]),
        .Q(\in_dly_reg[187]_0 [60]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[121] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [109]),
        .Q(\in_dly_reg[187]_0 [61]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[122] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [110]),
        .Q(\in_dly_reg[187]_0 [62]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[123] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [111]),
        .Q(\in_dly_reg[187]_0 [63]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[124] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [112]),
        .Q(\in_dly_reg[187]_0 [64]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[125] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [113]),
        .Q(\in_dly_reg[187]_0 [65]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[126] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [114]),
        .Q(\in_dly_reg[187]_0 [66]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[127] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [115]),
        .Q(\in_dly_reg[187]_0 [67]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[128] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [116]),
        .Q(\in_dly_reg[187]_0 [68]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[129] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [117]),
        .Q(\in_dly_reg[187]_0 [69]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[12] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [8]),
        .Q(phy_disperr_r[8]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[130] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [118]),
        .Q(\in_dly_reg[187]_0 [70]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[131] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [119]),
        .Q(\in_dly_reg[187]_0 [71]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[132] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [120]),
        .Q(\in_dly_reg[187]_0 [72]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[133] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [121]),
        .Q(\in_dly_reg[187]_0 [73]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[134] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [122]),
        .Q(\in_dly_reg[187]_0 [74]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[135] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [123]),
        .Q(\in_dly_reg[187]_0 [75]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[136] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [124]),
        .Q(\in_dly_reg[187]_0 [76]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[137] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [125]),
        .Q(\in_dly_reg[187]_0 [77]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[138] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [126]),
        .Q(\in_dly_reg[187]_0 [78]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[139] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [127]),
        .Q(\in_dly_reg[187]_0 [79]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[13] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [9]),
        .Q(phy_disperr_r[9]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[140] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [128]),
        .Q(\in_dly_reg[187]_0 [80]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[141] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [129]),
        .Q(\in_dly_reg[187]_0 [81]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[142] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [130]),
        .Q(\in_dly_reg[187]_0 [82]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[143] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [131]),
        .Q(\in_dly_reg[187]_0 [83]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[144] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [132]),
        .Q(\in_dly_reg[187]_0 [84]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[145] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [133]),
        .Q(\in_dly_reg[187]_0 [85]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[146] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [134]),
        .Q(\in_dly_reg[187]_0 [86]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[147] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [135]),
        .Q(\in_dly_reg[187]_0 [87]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[148] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [136]),
        .Q(\in_dly_reg[187]_0 [88]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[149] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [137]),
        .Q(\in_dly_reg[187]_0 [89]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[14] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [10]),
        .Q(phy_disperr_r[10]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[150] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [138]),
        .Q(\in_dly_reg[187]_0 [90]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[151] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [139]),
        .Q(\in_dly_reg[187]_0 [91]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[152] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [140]),
        .Q(\in_dly_reg[187]_0 [92]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[153] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [141]),
        .Q(\in_dly_reg[187]_0 [93]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[154] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [142]),
        .Q(\in_dly_reg[187]_0 [94]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[155] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [143]),
        .Q(\in_dly_reg[187]_0 [95]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[156] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [144]),
        .Q(\in_dly_reg[187]_0 [96]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[157] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [145]),
        .Q(\in_dly_reg[187]_0 [97]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[158] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [146]),
        .Q(\in_dly_reg[187]_0 [98]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[159] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [147]),
        .Q(\in_dly_reg[187]_0 [99]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[15] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [11]),
        .Q(phy_disperr_r[11]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[160] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [148]),
        .Q(\in_dly_reg[187]_0 [100]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[161] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [149]),
        .Q(\in_dly_reg[187]_0 [101]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[162] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [150]),
        .Q(\in_dly_reg[187]_0 [102]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[163] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [151]),
        .Q(\in_dly_reg[187]_0 [103]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[164] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [152]),
        .Q(\in_dly_reg[187]_0 [104]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[165] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [153]),
        .Q(\in_dly_reg[187]_0 [105]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[166] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [154]),
        .Q(\in_dly_reg[187]_0 [106]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[167] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [155]),
        .Q(\in_dly_reg[187]_0 [107]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[168] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [156]),
        .Q(\in_dly_reg[187]_0 [108]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[169] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [157]),
        .Q(\in_dly_reg[187]_0 [109]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[16] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [12]),
        .Q(phy_disperr_r[12]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[170] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [158]),
        .Q(\in_dly_reg[187]_0 [110]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[171] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [159]),
        .Q(\in_dly_reg[187]_0 [111]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[172] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [160]),
        .Q(\in_dly_reg[187]_0 [112]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[173] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [161]),
        .Q(\in_dly_reg[187]_0 [113]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[174] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [162]),
        .Q(\in_dly_reg[187]_0 [114]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[175] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [163]),
        .Q(\in_dly_reg[187]_0 [115]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[176] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [164]),
        .Q(\in_dly_reg[187]_0 [116]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[177] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [165]),
        .Q(\in_dly_reg[187]_0 [117]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[178] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [166]),
        .Q(\in_dly_reg[187]_0 [118]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[179] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [167]),
        .Q(\in_dly_reg[187]_0 [119]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[17] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [13]),
        .Q(phy_disperr_r[13]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[180] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [168]),
        .Q(\in_dly_reg[187]_0 [120]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[181] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [169]),
        .Q(\in_dly_reg[187]_0 [121]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[182] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [170]),
        .Q(\in_dly_reg[187]_0 [122]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[183] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [171]),
        .Q(\in_dly_reg[187]_0 [123]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[184] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [172]),
        .Q(\in_dly_reg[187]_0 [124]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[185] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [173]),
        .Q(\in_dly_reg[187]_0 [125]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[186] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [174]),
        .Q(\in_dly_reg[187]_0 [126]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[187] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [175]),
        .Q(\in_dly_reg[187]_0 [127]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[18] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [14]),
        .Q(phy_disperr_r[14]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[19] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [15]),
        .Q(phy_disperr_r[15]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[20] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [16]),
        .Q(phy_notintable_r[0]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[21] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [17]),
        .Q(phy_notintable_r[1]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[22] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [18]),
        .Q(phy_notintable_r[2]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[23] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [19]),
        .Q(phy_notintable_r[3]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[24] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [20]),
        .Q(phy_notintable_r[4]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[25] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [21]),
        .Q(phy_notintable_r[5]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[26] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [22]),
        .Q(phy_notintable_r[6]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[27] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [23]),
        .Q(phy_notintable_r[7]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[28] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [24]),
        .Q(phy_notintable_r[8]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[29] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [25]),
        .Q(phy_notintable_r[9]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[30] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [26]),
        .Q(phy_notintable_r[10]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[31] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [27]),
        .Q(phy_notintable_r[11]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[32] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [28]),
        .Q(phy_notintable_r[12]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[33] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [29]),
        .Q(phy_notintable_r[13]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[34] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [30]),
        .Q(phy_notintable_r[14]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[35] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [31]),
        .Q(phy_notintable_r[15]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[36] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [32]),
        .Q(phy_charisk_r[0]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[37] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [33]),
        .Q(phy_charisk_r[1]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[38] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [34]),
        .Q(phy_charisk_r[2]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[39] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [35]),
        .Q(phy_charisk_r[3]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[40] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [36]),
        .Q(phy_charisk_r[4]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[41] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [37]),
        .Q(phy_charisk_r[5]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[42] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [38]),
        .Q(phy_charisk_r[6]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[43] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [39]),
        .Q(phy_charisk_r[7]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[44] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [40]),
        .Q(phy_charisk_r[8]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[45] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [41]),
        .Q(phy_charisk_r[9]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[46] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [42]),
        .Q(phy_charisk_r[10]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[47] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [43]),
        .Q(phy_charisk_r[11]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[48] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [44]),
        .Q(phy_charisk_r[12]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[49] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [45]),
        .Q(phy_charisk_r[13]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[4] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [0]),
        .Q(phy_disperr_r[0]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[50] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [46]),
        .Q(phy_charisk_r[14]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[51] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [47]),
        .Q(phy_charisk_r[15]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[5] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [1]),
        .Q(phy_disperr_r[1]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[60] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [48]),
        .Q(\in_dly_reg[187]_0 [0]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[61] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [49]),
        .Q(\in_dly_reg[187]_0 [1]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[62] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [50]),
        .Q(\in_dly_reg[187]_0 [2]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[63] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [51]),
        .Q(\in_dly_reg[187]_0 [3]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[64] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [52]),
        .Q(\in_dly_reg[187]_0 [4]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[65] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [53]),
        .Q(\in_dly_reg[187]_0 [5]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[66] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [54]),
        .Q(\in_dly_reg[187]_0 [6]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[67] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [55]),
        .Q(\in_dly_reg[187]_0 [7]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[68] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [56]),
        .Q(\in_dly_reg[187]_0 [8]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[69] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [57]),
        .Q(\in_dly_reg[187]_0 [9]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[6] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [2]),
        .Q(phy_disperr_r[2]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[70] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [58]),
        .Q(\in_dly_reg[187]_0 [10]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[71] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [59]),
        .Q(\in_dly_reg[187]_0 [11]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[72] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [60]),
        .Q(\in_dly_reg[187]_0 [12]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[73] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [61]),
        .Q(\in_dly_reg[187]_0 [13]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[74] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [62]),
        .Q(\in_dly_reg[187]_0 [14]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[75] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [63]),
        .Q(\in_dly_reg[187]_0 [15]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[76] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [64]),
        .Q(\in_dly_reg[187]_0 [16]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[77] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [65]),
        .Q(\in_dly_reg[187]_0 [17]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[78] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [66]),
        .Q(\in_dly_reg[187]_0 [18]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[79] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [67]),
        .Q(\in_dly_reg[187]_0 [19]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[7] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [3]),
        .Q(phy_disperr_r[3]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[80] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [68]),
        .Q(\in_dly_reg[187]_0 [20]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[81] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [69]),
        .Q(\in_dly_reg[187]_0 [21]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[82] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [70]),
        .Q(\in_dly_reg[187]_0 [22]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[83] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [71]),
        .Q(\in_dly_reg[187]_0 [23]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[84] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [72]),
        .Q(\in_dly_reg[187]_0 [24]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[85] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [73]),
        .Q(\in_dly_reg[187]_0 [25]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[86] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [74]),
        .Q(\in_dly_reg[187]_0 [26]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[87] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [75]),
        .Q(\in_dly_reg[187]_0 [27]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[88] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [76]),
        .Q(\in_dly_reg[187]_0 [28]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[89] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [77]),
        .Q(\in_dly_reg[187]_0 [29]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[8] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [4]),
        .Q(phy_disperr_r[4]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[90] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [78]),
        .Q(\in_dly_reg[187]_0 [30]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[91] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [79]),
        .Q(\in_dly_reg[187]_0 [31]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[92] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [80]),
        .Q(\in_dly_reg[187]_0 [32]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[93] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [81]),
        .Q(\in_dly_reg[187]_0 [33]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[94] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [82]),
        .Q(\in_dly_reg[187]_0 [34]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[95] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [83]),
        .Q(\in_dly_reg[187]_0 [35]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[96] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [84]),
        .Q(\in_dly_reg[187]_0 [36]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[97] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [85]),
        .Q(\in_dly_reg[187]_0 [37]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[98] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [86]),
        .Q(\in_dly_reg[187]_0 [38]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[99] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [87]),
        .Q(\in_dly_reg[187]_0 [39]),
        .R(1'b0));
  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[9] 
       (.C(clk),
        .CE(1'b1),
        .D(\in_dly_reg[187]_1 [5]),
        .Q(phy_disperr_r[5]),
        .R(1'b0));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[0]_i_1 
       (.I0(\phy_char_err[0]_i_2_n_0 ),
        .I1(\in_charisk_d1[0]_i_2_n_0 ),
        .I2(phy_notintable_r[0]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[0]),
        .O(\in_dly_reg[23]_0 [0]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[0]_i_1__0 
       (.I0(\phy_char_err[0]_i_2__0_n_0 ),
        .I1(\in_charisk_d1[0]_i_2__0_n_0 ),
        .I2(phy_notintable_r[4]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[4]),
        .O(\in_dly_reg[27]_0 [0]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[0]_i_1__1 
       (.I0(\phy_char_err[0]_i_2__1_n_0 ),
        .I1(\in_charisk_d1[0]_i_2__1_n_0 ),
        .I2(phy_notintable_r[8]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[8]),
        .O(\in_dly_reg[31]_0 [0]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[0]_i_1__2 
       (.I0(\phy_char_err[0]_i_2__2_n_0 ),
        .I1(\in_charisk_d1[0]_i_2__2_n_0 ),
        .I2(phy_notintable_r[12]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[12]),
        .O(\in_dly_reg[35]_0 [0]));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[0]_i_2 
       (.I0(phy_notintable_r[0]),
        .I1(phy_disperr_r[0]),
        .I2(phy_charisk_r[0]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[0]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair16" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[0]_i_2__0 
       (.I0(phy_notintable_r[4]),
        .I1(phy_disperr_r[4]),
        .I2(phy_charisk_r[4]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[0]_i_2__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair10" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[0]_i_2__1 
       (.I0(phy_notintable_r[8]),
        .I1(phy_disperr_r[8]),
        .I2(phy_charisk_r[8]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[0]_i_2__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair20" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[0]_i_2__2 
       (.I0(phy_notintable_r[12]),
        .I1(phy_disperr_r[12]),
        .I2(phy_charisk_r[12]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[0]_i_2__2_n_0 ));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[1]_i_1 
       (.I0(\phy_char_err[1]_i_2_n_0 ),
        .I1(\in_charisk_d1[1]_i_2_n_0 ),
        .I2(phy_notintable_r[1]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[1]),
        .O(\in_dly_reg[23]_0 [1]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[1]_i_1__0 
       (.I0(\phy_char_err[1]_i_2__0_n_0 ),
        .I1(\in_charisk_d1[1]_i_2__0_n_0 ),
        .I2(phy_notintable_r[5]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[5]),
        .O(\in_dly_reg[27]_0 [1]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[1]_i_1__1 
       (.I0(\phy_char_err[1]_i_2__1_n_0 ),
        .I1(\in_charisk_d1[1]_i_2__1_n_0 ),
        .I2(phy_notintable_r[9]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[9]),
        .O(\in_dly_reg[31]_0 [1]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[1]_i_1__2 
       (.I0(\phy_char_err[1]_i_2__2_n_0 ),
        .I1(\in_charisk_d1[1]_i_2__2_n_0 ),
        .I2(phy_notintable_r[13]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[13]),
        .O(\in_dly_reg[35]_0 [1]));
  (* SOFT_HLUTNM = "soft_lutpair19" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[1]_i_2 
       (.I0(phy_notintable_r[1]),
        .I1(phy_disperr_r[1]),
        .I2(phy_charisk_r[1]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[1]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair15" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[1]_i_2__0 
       (.I0(phy_notintable_r[5]),
        .I1(phy_disperr_r[5]),
        .I2(phy_charisk_r[5]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[1]_i_2__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[1]_i_2__1 
       (.I0(phy_notintable_r[9]),
        .I1(phy_disperr_r[9]),
        .I2(phy_charisk_r[9]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[1]_i_2__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair22" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[1]_i_2__2 
       (.I0(phy_notintable_r[13]),
        .I1(phy_disperr_r[13]),
        .I2(phy_charisk_r[13]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[1]_i_2__2_n_0 ));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[2]_i_1 
       (.I0(\phy_char_err[2]_i_2_n_0 ),
        .I1(\in_charisk_d1[2]_i_2_n_0 ),
        .I2(phy_notintable_r[2]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[2]),
        .O(\in_dly_reg[23]_0 [2]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[2]_i_1__0 
       (.I0(\phy_char_err[2]_i_2__0_n_0 ),
        .I1(\in_charisk_d1[2]_i_2__0_n_0 ),
        .I2(phy_notintable_r[6]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[6]),
        .O(\in_dly_reg[27]_0 [2]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[2]_i_1__1 
       (.I0(\phy_char_err[2]_i_2__1_n_0 ),
        .I1(\in_charisk_d1[2]_i_2__1_n_0 ),
        .I2(phy_notintable_r[10]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[10]),
        .O(\in_dly_reg[31]_0 [2]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[2]_i_1__2 
       (.I0(\phy_char_err[2]_i_2__2_n_0 ),
        .I1(\in_charisk_d1[2]_i_2__2_n_0 ),
        .I2(phy_notintable_r[14]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[14]),
        .O(\in_dly_reg[35]_0 [2]));
  (* SOFT_HLUTNM = "soft_lutpair17" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[2]_i_2 
       (.I0(phy_notintable_r[2]),
        .I1(phy_disperr_r[2]),
        .I2(phy_charisk_r[2]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[2]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[2]_i_2__0 
       (.I0(phy_notintable_r[6]),
        .I1(phy_disperr_r[6]),
        .I2(phy_charisk_r[6]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[2]_i_2__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[2]_i_2__1 
       (.I0(phy_notintable_r[10]),
        .I1(phy_disperr_r[10]),
        .I2(phy_charisk_r[10]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[2]_i_2__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair21" *) 
  LUT4 #(
    .INIT(16'h0010)) 
    \phy_char_err[2]_i_2__2 
       (.I0(phy_notintable_r[14]),
        .I1(phy_disperr_r[14]),
        .I2(phy_charisk_r[14]),
        .I3(ctrl_err_statistics_mask[2]),
        .O(\phy_char_err[2]_i_2__2_n_0 ));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[3]_i_2 
       (.I0(\phy_char_err[3]_i_3_n_0 ),
        .I1(\in_charisk_d1[3]_i_2_n_0 ),
        .I2(phy_notintable_r[3]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[3]),
        .O(\in_dly_reg[23]_0 [3]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[3]_i_2__0 
       (.I0(\phy_char_err[3]_i_3__0_n_0 ),
        .I1(\in_charisk_d1[3]_i_2__0_n_0 ),
        .I2(phy_notintable_r[7]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[7]),
        .O(\in_dly_reg[27]_0 [3]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[3]_i_2__1 
       (.I0(\phy_char_err[3]_i_3__1_n_0 ),
        .I1(\in_charisk_d1[3]_i_2__1_n_0 ),
        .I2(phy_notintable_r[11]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[11]),
        .O(\in_dly_reg[31]_0 [3]));
  LUT6 #(
    .INIT(64'h22F2FFFF22F222F2)) 
    \phy_char_err[3]_i_2__2 
       (.I0(\phy_char_err[3]_i_3__2_n_0 ),
        .I1(\in_charisk_d1[3]_i_2__2_n_0 ),
        .I2(phy_notintable_r[15]),
        .I3(ctrl_err_statistics_mask[1]),
        .I4(ctrl_err_statistics_mask[0]),
        .I5(phy_disperr_r[15]),
        .O(\in_dly_reg[35]_0 [3]));
  (* SOFT_HLUTNM = "soft_lutpair18" *) 
  LUT4 #(
    .INIT(16'h0004)) 
    \phy_char_err[3]_i_3 
       (.I0(ctrl_err_statistics_mask[2]),
        .I1(phy_charisk_r[3]),
        .I2(phy_disperr_r[3]),
        .I3(phy_notintable_r[3]),
        .O(\phy_char_err[3]_i_3_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT4 #(
    .INIT(16'h0004)) 
    \phy_char_err[3]_i_3__0 
       (.I0(ctrl_err_statistics_mask[2]),
        .I1(phy_charisk_r[7]),
        .I2(phy_disperr_r[7]),
        .I3(phy_notintable_r[7]),
        .O(\phy_char_err[3]_i_3__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT4 #(
    .INIT(16'h0004)) 
    \phy_char_err[3]_i_3__1 
       (.I0(ctrl_err_statistics_mask[2]),
        .I1(phy_charisk_r[11]),
        .I2(phy_disperr_r[11]),
        .I3(phy_notintable_r[11]),
        .O(\phy_char_err[3]_i_3__1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair14" *) 
  LUT4 #(
    .INIT(16'h0004)) 
    \phy_char_err[3]_i_3__2 
       (.I0(ctrl_err_statistics_mask[2]),
        .I1(phy_charisk_r[15]),
        .I2(phy_disperr_r[15]),
        .I3(phy_notintable_r[15]),
        .O(\phy_char_err[3]_i_3__2_n_0 ));
  LUT5 #(
    .INIT(32'h2000FFFF)) 
    prev_was_last_i_1
       (.I0(\mode_8b10b.gen_lane[0].i_lane/charisk28_aligned_s ),
        .I1(D[7]),
        .I2(D[6]),
        .I3(D[5]),
        .I4(ifs_ready[0]),
        .O(prev_was_last0));
  LUT5 #(
    .INIT(32'h2000FFFF)) 
    prev_was_last_i_1__0
       (.I0(\mode_8b10b.gen_lane[1].i_lane/charisk28_aligned_s ),
        .I1(\in_dly_reg[107]_0 [7]),
        .I2(\in_dly_reg[107]_0 [6]),
        .I3(\in_dly_reg[107]_0 [5]),
        .I4(ifs_ready[1]),
        .O(prev_was_last0_3));
  LUT5 #(
    .INIT(32'h2000FFFF)) 
    prev_was_last_i_1__1
       (.I0(\mode_8b10b.gen_lane[2].i_lane/charisk28_aligned_s ),
        .I1(\in_dly_reg[139]_0 [7]),
        .I2(\in_dly_reg[139]_0 [6]),
        .I3(\in_dly_reg[139]_0 [5]),
        .I4(ifs_ready[2]),
        .O(prev_was_last0_6));
  LUT5 #(
    .INIT(32'h2000FFFF)) 
    prev_was_last_i_1__2
       (.I0(\mode_8b10b.gen_lane[3].i_lane/charisk28_aligned_s ),
        .I1(\in_dly_reg[171]_0 [7]),
        .I2(\in_dly_reg[171]_0 [6]),
        .I3(\in_dly_reg[171]_0 [5]),
        .I4(ifs_ready[3]),
        .O(prev_was_last0_9));
  LUT6 #(
    .INIT(64'hEEFFAAFAEEAAAAFA)) 
    prev_was_last_i_2
       (.I0(prev_was_last_i_3_n_0),
        .I1(charisk28[2]),
        .I2(Q),
        .I3(\ilas_config_data_reg[24] ),
        .I4(\frame_align_reg[0] ),
        .I5(charisk28[0]),
        .O(\mode_8b10b.gen_lane[0].i_lane/charisk28_aligned_s ));
  LUT6 #(
    .INIT(64'hEEFFAAFAEEAAAAFA)) 
    prev_was_last_i_2__0
       (.I0(prev_was_last_i_3__0_n_0),
        .I1(charisk28_0[2]),
        .I2(prev_was_last_reg),
        .I3(\ilas_config_data_reg[24]_0 ),
        .I4(\frame_align_reg[0]_0 ),
        .I5(charisk28_0[0]),
        .O(\mode_8b10b.gen_lane[1].i_lane/charisk28_aligned_s ));
  LUT6 #(
    .INIT(64'hEEFFAAFAEEAAAAFA)) 
    prev_was_last_i_2__1
       (.I0(prev_was_last_i_3__1_n_0),
        .I1(charisk28_1[2]),
        .I2(prev_was_last_reg_0),
        .I3(\ilas_config_data_reg[24]_1 ),
        .I4(\frame_align_reg[0]_1 ),
        .I5(charisk28_1[0]),
        .O(\mode_8b10b.gen_lane[2].i_lane/charisk28_aligned_s ));
  LUT6 #(
    .INIT(64'hEEFFAAFAEEAAAAFA)) 
    prev_was_last_i_2__2
       (.I0(prev_was_last_i_3__2_n_0),
        .I1(charisk28_2[2]),
        .I2(prev_was_last_reg_1),
        .I3(\ilas_config_data_reg[24]_2 ),
        .I4(\frame_align_reg[0]_2 ),
        .I5(charisk28_2[0]),
        .O(\mode_8b10b.gen_lane[3].i_lane/charisk28_aligned_s ));
  LUT6 #(
    .INIT(64'h0000002000000000)) 
    prev_was_last_i_3
       (.I0(\ilas_config_data_reg[24] ),
        .I1(\frame_align_reg[0] ),
        .I2(phy_charisk_r[1]),
        .I3(phy_disperr_r[1]),
        .I4(phy_notintable_r[1]),
        .I5(\in_charisk_d1[1]_i_2_n_0 ),
        .O(prev_was_last_i_3_n_0));
  LUT6 #(
    .INIT(64'h0000002000000000)) 
    prev_was_last_i_3__0
       (.I0(\ilas_config_data_reg[24]_0 ),
        .I1(\frame_align_reg[0]_0 ),
        .I2(phy_charisk_r[5]),
        .I3(phy_disperr_r[5]),
        .I4(phy_notintable_r[5]),
        .I5(\in_charisk_d1[1]_i_2__0_n_0 ),
        .O(prev_was_last_i_3__0_n_0));
  LUT6 #(
    .INIT(64'h0000002000000000)) 
    prev_was_last_i_3__1
       (.I0(\ilas_config_data_reg[24]_1 ),
        .I1(\frame_align_reg[0]_1 ),
        .I2(phy_charisk_r[9]),
        .I3(phy_disperr_r[9]),
        .I4(phy_notintable_r[9]),
        .I5(\in_charisk_d1[1]_i_2__1_n_0 ),
        .O(prev_was_last_i_3__1_n_0));
  LUT6 #(
    .INIT(64'h0000002000000000)) 
    prev_was_last_i_3__2
       (.I0(\ilas_config_data_reg[24]_2 ),
        .I1(\frame_align_reg[0]_2 ),
        .I2(phy_charisk_r[13]),
        .I3(phy_disperr_r[13]),
        .I4(phy_notintable_r[13]),
        .I5(\in_charisk_d1[1]_i_2__2_n_0 ),
        .O(prev_was_last_i_3__2_n_0));
endmodule

(* ORIG_REF_NAME = "pipeline_stage" *) 
module jesd204_rx_0_pipeline_stage__parameterized3
   (rx_valid,
    buffer_release_d1,
    clk);
  output rx_valid;
  input buffer_release_d1;
  input clk;

  wire buffer_release_d1;
  wire clk;
  wire rx_valid;

  (* SHREG_EXTRACT = "no" *) 
  FDRE \in_dly_reg[0] 
       (.C(clk),
        .CE(1'b1),
        .D(buffer_release_d1),
        .Q(rx_valid),
        .R(1'b0));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
