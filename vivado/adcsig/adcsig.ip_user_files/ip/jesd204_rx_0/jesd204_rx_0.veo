// (c) Copyright 1995-2020 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: analog.com:user:jesd204_rx:1.0
// IP Revision: 1

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
jesd204_rx_0 your_instance_name (
  .clk(clk),                                                    // input wire clk
  .reset(reset),                                                // input wire reset
  .phy_data(phy_data),                                          // input wire [127 : 0] phy_data
  .phy_header(phy_header),                                      // input wire [7 : 0] phy_header
  .phy_charisk(phy_charisk),                                    // input wire [15 : 0] phy_charisk
  .phy_notintable(phy_notintable),                              // input wire [15 : 0] phy_notintable
  .phy_disperr(phy_disperr),                                    // input wire [15 : 0] phy_disperr
  .phy_block_sync(phy_block_sync),                              // input wire [3 : 0] phy_block_sync
  .sysref(sysref),                                              // input wire sysref
  .lmfc_edge(lmfc_edge),                                        // output wire lmfc_edge
  .lmfc_clk(lmfc_clk),                                          // output wire lmfc_clk
  .event_sysref_alignment_error(event_sysref_alignment_error),  // output wire event_sysref_alignment_error
  .event_sysref_edge(event_sysref_edge),                        // output wire event_sysref_edge
  .sync(sync),                                                  // output wire [0 : 0] sync
  .phy_en_char_align(phy_en_char_align),                        // output wire phy_en_char_align
  .rx_data(rx_data),                                            // output wire [127 : 0] rx_data
  .rx_valid(rx_valid),                                          // output wire rx_valid
  .rx_eof(rx_eof),                                              // output wire [3 : 0] rx_eof
  .rx_sof(rx_sof),                                              // output wire [3 : 0] rx_sof
  .cfg_lanes_disable(cfg_lanes_disable),                        // input wire [3 : 0] cfg_lanes_disable
  .cfg_links_disable(cfg_links_disable),                        // input wire [0 : 0] cfg_links_disable
  .cfg_beats_per_multiframe(cfg_beats_per_multiframe),          // input wire [7 : 0] cfg_beats_per_multiframe
  .cfg_octets_per_frame(cfg_octets_per_frame),                  // input wire [7 : 0] cfg_octets_per_frame
  .cfg_lmfc_offset(cfg_lmfc_offset),                            // input wire [7 : 0] cfg_lmfc_offset
  .cfg_sysref_disable(cfg_sysref_disable),                      // input wire cfg_sysref_disable
  .cfg_sysref_oneshot(cfg_sysref_oneshot),                      // input wire cfg_sysref_oneshot
  .cfg_buffer_early_release(cfg_buffer_early_release),          // input wire cfg_buffer_early_release
  .cfg_buffer_delay(cfg_buffer_delay),                          // input wire [7 : 0] cfg_buffer_delay
  .cfg_disable_char_replacement(cfg_disable_char_replacement),  // input wire cfg_disable_char_replacement
  .cfg_disable_scrambler(cfg_disable_scrambler),                // input wire cfg_disable_scrambler
  .ctrl_err_statistics_reset(ctrl_err_statistics_reset),        // input wire ctrl_err_statistics_reset
  .ctrl_err_statistics_mask(ctrl_err_statistics_mask),          // input wire [6 : 0] ctrl_err_statistics_mask
  .status_err_statistics_cnt(status_err_statistics_cnt),        // output wire [127 : 0] status_err_statistics_cnt
  .ilas_config_valid(ilas_config_valid),                        // output wire [3 : 0] ilas_config_valid
  .ilas_config_addr(ilas_config_addr),                          // output wire [7 : 0] ilas_config_addr
  .ilas_config_data(ilas_config_data),                          // output wire [127 : 0] ilas_config_data
  .status_ctrl_state(status_ctrl_state),                        // output wire [1 : 0] status_ctrl_state
  .status_lane_cgs_state(status_lane_cgs_state),                // output wire [7 : 0] status_lane_cgs_state
  .status_lane_ifs_ready(status_lane_ifs_ready),                // output wire [3 : 0] status_lane_ifs_ready
  .status_lane_latency(status_lane_latency),                    // output wire [55 : 0] status_lane_latency
  .status_lane_emb_state(status_lane_emb_state)                // output wire [11 : 0] status_lane_emb_state
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

