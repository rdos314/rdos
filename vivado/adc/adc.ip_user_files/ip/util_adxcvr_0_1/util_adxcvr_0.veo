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

// IP VLNV: analog.com:user:util_adxcvr:1.0
// IP Revision: 1

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
util_adxcvr_0 your_instance_name (
  .up_rstn(up_rstn),                          // input wire up_rstn
  .up_clk(up_clk),                            // input wire up_clk
  .qpll_ref_clk_0(qpll_ref_clk_0),            // input wire qpll_ref_clk_0
  .up_qpll_rst_0(up_qpll_rst_0),              // input wire up_qpll_rst_0
  .cpll_ref_clk_0(cpll_ref_clk_0),            // input wire cpll_ref_clk_0
  .up_cpll_rst_0(up_cpll_rst_0),              // input wire up_cpll_rst_0
  .rx_0_p(rx_0_p),                            // input wire rx_0_p
  .rx_0_n(rx_0_n),                            // input wire rx_0_n
  .rx_out_clk_0(rx_out_clk_0),                // output wire rx_out_clk_0
  .rx_clk_0(rx_clk_0),                        // input wire rx_clk_0
  .rx_charisk_0(rx_charisk_0),                // output wire [3 : 0] rx_charisk_0
  .rx_disperr_0(rx_disperr_0),                // output wire [3 : 0] rx_disperr_0
  .rx_notintable_0(rx_notintable_0),          // output wire [3 : 0] rx_notintable_0
  .rx_data_0(rx_data_0),                      // output wire [31 : 0] rx_data_0
  .rx_calign_0(rx_calign_0),                  // input wire rx_calign_0
  .tx_0_p(tx_0_p),                            // output wire tx_0_p
  .tx_0_n(tx_0_n),                            // output wire tx_0_n
  .tx_out_clk_0(tx_out_clk_0),                // output wire tx_out_clk_0
  .tx_clk_0(tx_clk_0),                        // input wire tx_clk_0
  .tx_charisk_0(tx_charisk_0),                // input wire [3 : 0] tx_charisk_0
  .tx_data_0(tx_data_0),                      // input wire [31 : 0] tx_data_0
  .up_cm_enb_0(up_cm_enb_0),                  // input wire up_cm_enb_0
  .up_cm_addr_0(up_cm_addr_0),                // input wire [11 : 0] up_cm_addr_0
  .up_cm_wr_0(up_cm_wr_0),                    // input wire up_cm_wr_0
  .up_cm_wdata_0(up_cm_wdata_0),              // input wire [15 : 0] up_cm_wdata_0
  .up_cm_rdata_0(up_cm_rdata_0),              // output wire [15 : 0] up_cm_rdata_0
  .up_cm_ready_0(up_cm_ready_0),              // output wire up_cm_ready_0
  .up_es_enb_0(up_es_enb_0),                  // input wire up_es_enb_0
  .up_es_addr_0(up_es_addr_0),                // input wire [11 : 0] up_es_addr_0
  .up_es_wr_0(up_es_wr_0),                    // input wire up_es_wr_0
  .up_es_wdata_0(up_es_wdata_0),              // input wire [15 : 0] up_es_wdata_0
  .up_es_rdata_0(up_es_rdata_0),              // output wire [15 : 0] up_es_rdata_0
  .up_es_ready_0(up_es_ready_0),              // output wire up_es_ready_0
  .up_es_reset_0(up_es_reset_0),              // input wire up_es_reset_0
  .up_rx_pll_locked_0(up_rx_pll_locked_0),    // output wire up_rx_pll_locked_0
  .up_rx_rst_0(up_rx_rst_0),                  // input wire up_rx_rst_0
  .up_rx_user_ready_0(up_rx_user_ready_0),    // input wire up_rx_user_ready_0
  .up_rx_rst_done_0(up_rx_rst_done_0),        // output wire up_rx_rst_done_0
  .up_rx_lpm_dfe_n_0(up_rx_lpm_dfe_n_0),      // input wire up_rx_lpm_dfe_n_0
  .up_rx_rate_0(up_rx_rate_0),                // input wire [2 : 0] up_rx_rate_0
  .up_rx_sys_clk_sel_0(up_rx_sys_clk_sel_0),  // input wire [1 : 0] up_rx_sys_clk_sel_0
  .up_rx_out_clk_sel_0(up_rx_out_clk_sel_0),  // input wire [2 : 0] up_rx_out_clk_sel_0
  .up_rx_enb_0(up_rx_enb_0),                  // input wire up_rx_enb_0
  .up_rx_addr_0(up_rx_addr_0),                // input wire [11 : 0] up_rx_addr_0
  .up_rx_wr_0(up_rx_wr_0),                    // input wire up_rx_wr_0
  .up_rx_wdata_0(up_rx_wdata_0),              // input wire [15 : 0] up_rx_wdata_0
  .up_rx_rdata_0(up_rx_rdata_0),              // output wire [15 : 0] up_rx_rdata_0
  .up_rx_ready_0(up_rx_ready_0),              // output wire up_rx_ready_0
  .up_tx_pll_locked_0(up_tx_pll_locked_0),    // output wire up_tx_pll_locked_0
  .up_tx_rst_0(up_tx_rst_0),                  // input wire up_tx_rst_0
  .up_tx_user_ready_0(up_tx_user_ready_0),    // input wire up_tx_user_ready_0
  .up_tx_rst_done_0(up_tx_rst_done_0),        // output wire up_tx_rst_done_0
  .up_tx_lpm_dfe_n_0(up_tx_lpm_dfe_n_0),      // input wire up_tx_lpm_dfe_n_0
  .up_tx_rate_0(up_tx_rate_0),                // input wire [2 : 0] up_tx_rate_0
  .up_tx_sys_clk_sel_0(up_tx_sys_clk_sel_0),  // input wire [1 : 0] up_tx_sys_clk_sel_0
  .up_tx_out_clk_sel_0(up_tx_out_clk_sel_0),  // input wire [2 : 0] up_tx_out_clk_sel_0
  .up_tx_diffctrl_0(up_tx_diffctrl_0),        // input wire [4 : 0] up_tx_diffctrl_0
  .up_tx_postcursor_0(up_tx_postcursor_0),    // input wire [4 : 0] up_tx_postcursor_0
  .up_tx_precursor_0(up_tx_precursor_0),      // input wire [4 : 0] up_tx_precursor_0
  .up_tx_enb_0(up_tx_enb_0),                  // input wire up_tx_enb_0
  .up_tx_addr_0(up_tx_addr_0),                // input wire [11 : 0] up_tx_addr_0
  .up_tx_wr_0(up_tx_wr_0),                    // input wire up_tx_wr_0
  .up_tx_wdata_0(up_tx_wdata_0),              // input wire [15 : 0] up_tx_wdata_0
  .up_tx_rdata_0(up_tx_rdata_0),              // output wire [15 : 0] up_tx_rdata_0
  .up_tx_ready_0(up_tx_ready_0),              // output wire up_tx_ready_0
  .cpll_ref_clk_1(cpll_ref_clk_1),            // input wire cpll_ref_clk_1
  .up_cpll_rst_1(up_cpll_rst_1),              // input wire up_cpll_rst_1
  .rx_1_p(rx_1_p),                            // input wire rx_1_p
  .rx_1_n(rx_1_n),                            // input wire rx_1_n
  .rx_out_clk_1(rx_out_clk_1),                // output wire rx_out_clk_1
  .rx_clk_1(rx_clk_1),                        // input wire rx_clk_1
  .rx_charisk_1(rx_charisk_1),                // output wire [3 : 0] rx_charisk_1
  .rx_disperr_1(rx_disperr_1),                // output wire [3 : 0] rx_disperr_1
  .rx_notintable_1(rx_notintable_1),          // output wire [3 : 0] rx_notintable_1
  .rx_data_1(rx_data_1),                      // output wire [31 : 0] rx_data_1
  .rx_calign_1(rx_calign_1),                  // input wire rx_calign_1
  .tx_1_p(tx_1_p),                            // output wire tx_1_p
  .tx_1_n(tx_1_n),                            // output wire tx_1_n
  .tx_out_clk_1(tx_out_clk_1),                // output wire tx_out_clk_1
  .tx_clk_1(tx_clk_1),                        // input wire tx_clk_1
  .tx_charisk_1(tx_charisk_1),                // input wire [3 : 0] tx_charisk_1
  .tx_data_1(tx_data_1),                      // input wire [31 : 0] tx_data_1
  .up_es_enb_1(up_es_enb_1),                  // input wire up_es_enb_1
  .up_es_addr_1(up_es_addr_1),                // input wire [11 : 0] up_es_addr_1
  .up_es_wr_1(up_es_wr_1),                    // input wire up_es_wr_1
  .up_es_wdata_1(up_es_wdata_1),              // input wire [15 : 0] up_es_wdata_1
  .up_es_rdata_1(up_es_rdata_1),              // output wire [15 : 0] up_es_rdata_1
  .up_es_ready_1(up_es_ready_1),              // output wire up_es_ready_1
  .up_es_reset_1(up_es_reset_1),              // input wire up_es_reset_1
  .up_rx_pll_locked_1(up_rx_pll_locked_1),    // output wire up_rx_pll_locked_1
  .up_rx_rst_1(up_rx_rst_1),                  // input wire up_rx_rst_1
  .up_rx_user_ready_1(up_rx_user_ready_1),    // input wire up_rx_user_ready_1
  .up_rx_rst_done_1(up_rx_rst_done_1),        // output wire up_rx_rst_done_1
  .up_rx_lpm_dfe_n_1(up_rx_lpm_dfe_n_1),      // input wire up_rx_lpm_dfe_n_1
  .up_rx_rate_1(up_rx_rate_1),                // input wire [2 : 0] up_rx_rate_1
  .up_rx_sys_clk_sel_1(up_rx_sys_clk_sel_1),  // input wire [1 : 0] up_rx_sys_clk_sel_1
  .up_rx_out_clk_sel_1(up_rx_out_clk_sel_1),  // input wire [2 : 0] up_rx_out_clk_sel_1
  .up_rx_enb_1(up_rx_enb_1),                  // input wire up_rx_enb_1
  .up_rx_addr_1(up_rx_addr_1),                // input wire [11 : 0] up_rx_addr_1
  .up_rx_wr_1(up_rx_wr_1),                    // input wire up_rx_wr_1
  .up_rx_wdata_1(up_rx_wdata_1),              // input wire [15 : 0] up_rx_wdata_1
  .up_rx_rdata_1(up_rx_rdata_1),              // output wire [15 : 0] up_rx_rdata_1
  .up_rx_ready_1(up_rx_ready_1),              // output wire up_rx_ready_1
  .up_tx_pll_locked_1(up_tx_pll_locked_1),    // output wire up_tx_pll_locked_1
  .up_tx_rst_1(up_tx_rst_1),                  // input wire up_tx_rst_1
  .up_tx_user_ready_1(up_tx_user_ready_1),    // input wire up_tx_user_ready_1
  .up_tx_rst_done_1(up_tx_rst_done_1),        // output wire up_tx_rst_done_1
  .up_tx_lpm_dfe_n_1(up_tx_lpm_dfe_n_1),      // input wire up_tx_lpm_dfe_n_1
  .up_tx_rate_1(up_tx_rate_1),                // input wire [2 : 0] up_tx_rate_1
  .up_tx_sys_clk_sel_1(up_tx_sys_clk_sel_1),  // input wire [1 : 0] up_tx_sys_clk_sel_1
  .up_tx_out_clk_sel_1(up_tx_out_clk_sel_1),  // input wire [2 : 0] up_tx_out_clk_sel_1
  .up_tx_diffctrl_1(up_tx_diffctrl_1),        // input wire [4 : 0] up_tx_diffctrl_1
  .up_tx_postcursor_1(up_tx_postcursor_1),    // input wire [4 : 0] up_tx_postcursor_1
  .up_tx_precursor_1(up_tx_precursor_1),      // input wire [4 : 0] up_tx_precursor_1
  .up_tx_enb_1(up_tx_enb_1),                  // input wire up_tx_enb_1
  .up_tx_addr_1(up_tx_addr_1),                // input wire [11 : 0] up_tx_addr_1
  .up_tx_wr_1(up_tx_wr_1),                    // input wire up_tx_wr_1
  .up_tx_wdata_1(up_tx_wdata_1),              // input wire [15 : 0] up_tx_wdata_1
  .up_tx_rdata_1(up_tx_rdata_1),              // output wire [15 : 0] up_tx_rdata_1
  .up_tx_ready_1(up_tx_ready_1),              // output wire up_tx_ready_1
  .cpll_ref_clk_2(cpll_ref_clk_2),            // input wire cpll_ref_clk_2
  .up_cpll_rst_2(up_cpll_rst_2),              // input wire up_cpll_rst_2
  .rx_2_p(rx_2_p),                            // input wire rx_2_p
  .rx_2_n(rx_2_n),                            // input wire rx_2_n
  .rx_out_clk_2(rx_out_clk_2),                // output wire rx_out_clk_2
  .rx_clk_2(rx_clk_2),                        // input wire rx_clk_2
  .rx_charisk_2(rx_charisk_2),                // output wire [3 : 0] rx_charisk_2
  .rx_disperr_2(rx_disperr_2),                // output wire [3 : 0] rx_disperr_2
  .rx_notintable_2(rx_notintable_2),          // output wire [3 : 0] rx_notintable_2
  .rx_data_2(rx_data_2),                      // output wire [31 : 0] rx_data_2
  .rx_calign_2(rx_calign_2),                  // input wire rx_calign_2
  .tx_2_p(tx_2_p),                            // output wire tx_2_p
  .tx_2_n(tx_2_n),                            // output wire tx_2_n
  .tx_out_clk_2(tx_out_clk_2),                // output wire tx_out_clk_2
  .tx_clk_2(tx_clk_2),                        // input wire tx_clk_2
  .tx_charisk_2(tx_charisk_2),                // input wire [3 : 0] tx_charisk_2
  .tx_data_2(tx_data_2),                      // input wire [31 : 0] tx_data_2
  .up_es_enb_2(up_es_enb_2),                  // input wire up_es_enb_2
  .up_es_addr_2(up_es_addr_2),                // input wire [11 : 0] up_es_addr_2
  .up_es_wr_2(up_es_wr_2),                    // input wire up_es_wr_2
  .up_es_wdata_2(up_es_wdata_2),              // input wire [15 : 0] up_es_wdata_2
  .up_es_rdata_2(up_es_rdata_2),              // output wire [15 : 0] up_es_rdata_2
  .up_es_ready_2(up_es_ready_2),              // output wire up_es_ready_2
  .up_es_reset_2(up_es_reset_2),              // input wire up_es_reset_2
  .up_rx_pll_locked_2(up_rx_pll_locked_2),    // output wire up_rx_pll_locked_2
  .up_rx_rst_2(up_rx_rst_2),                  // input wire up_rx_rst_2
  .up_rx_user_ready_2(up_rx_user_ready_2),    // input wire up_rx_user_ready_2
  .up_rx_rst_done_2(up_rx_rst_done_2),        // output wire up_rx_rst_done_2
  .up_rx_lpm_dfe_n_2(up_rx_lpm_dfe_n_2),      // input wire up_rx_lpm_dfe_n_2
  .up_rx_rate_2(up_rx_rate_2),                // input wire [2 : 0] up_rx_rate_2
  .up_rx_sys_clk_sel_2(up_rx_sys_clk_sel_2),  // input wire [1 : 0] up_rx_sys_clk_sel_2
  .up_rx_out_clk_sel_2(up_rx_out_clk_sel_2),  // input wire [2 : 0] up_rx_out_clk_sel_2
  .up_rx_enb_2(up_rx_enb_2),                  // input wire up_rx_enb_2
  .up_rx_addr_2(up_rx_addr_2),                // input wire [11 : 0] up_rx_addr_2
  .up_rx_wr_2(up_rx_wr_2),                    // input wire up_rx_wr_2
  .up_rx_wdata_2(up_rx_wdata_2),              // input wire [15 : 0] up_rx_wdata_2
  .up_rx_rdata_2(up_rx_rdata_2),              // output wire [15 : 0] up_rx_rdata_2
  .up_rx_ready_2(up_rx_ready_2),              // output wire up_rx_ready_2
  .up_tx_pll_locked_2(up_tx_pll_locked_2),    // output wire up_tx_pll_locked_2
  .up_tx_rst_2(up_tx_rst_2),                  // input wire up_tx_rst_2
  .up_tx_user_ready_2(up_tx_user_ready_2),    // input wire up_tx_user_ready_2
  .up_tx_rst_done_2(up_tx_rst_done_2),        // output wire up_tx_rst_done_2
  .up_tx_lpm_dfe_n_2(up_tx_lpm_dfe_n_2),      // input wire up_tx_lpm_dfe_n_2
  .up_tx_rate_2(up_tx_rate_2),                // input wire [2 : 0] up_tx_rate_2
  .up_tx_sys_clk_sel_2(up_tx_sys_clk_sel_2),  // input wire [1 : 0] up_tx_sys_clk_sel_2
  .up_tx_out_clk_sel_2(up_tx_out_clk_sel_2),  // input wire [2 : 0] up_tx_out_clk_sel_2
  .up_tx_diffctrl_2(up_tx_diffctrl_2),        // input wire [4 : 0] up_tx_diffctrl_2
  .up_tx_postcursor_2(up_tx_postcursor_2),    // input wire [4 : 0] up_tx_postcursor_2
  .up_tx_precursor_2(up_tx_precursor_2),      // input wire [4 : 0] up_tx_precursor_2
  .up_tx_enb_2(up_tx_enb_2),                  // input wire up_tx_enb_2
  .up_tx_addr_2(up_tx_addr_2),                // input wire [11 : 0] up_tx_addr_2
  .up_tx_wr_2(up_tx_wr_2),                    // input wire up_tx_wr_2
  .up_tx_wdata_2(up_tx_wdata_2),              // input wire [15 : 0] up_tx_wdata_2
  .up_tx_rdata_2(up_tx_rdata_2),              // output wire [15 : 0] up_tx_rdata_2
  .up_tx_ready_2(up_tx_ready_2),              // output wire up_tx_ready_2
  .cpll_ref_clk_3(cpll_ref_clk_3),            // input wire cpll_ref_clk_3
  .up_cpll_rst_3(up_cpll_rst_3),              // input wire up_cpll_rst_3
  .rx_3_p(rx_3_p),                            // input wire rx_3_p
  .rx_3_n(rx_3_n),                            // input wire rx_3_n
  .rx_out_clk_3(rx_out_clk_3),                // output wire rx_out_clk_3
  .rx_clk_3(rx_clk_3),                        // input wire rx_clk_3
  .rx_charisk_3(rx_charisk_3),                // output wire [3 : 0] rx_charisk_3
  .rx_disperr_3(rx_disperr_3),                // output wire [3 : 0] rx_disperr_3
  .rx_notintable_3(rx_notintable_3),          // output wire [3 : 0] rx_notintable_3
  .rx_data_3(rx_data_3),                      // output wire [31 : 0] rx_data_3
  .rx_calign_3(rx_calign_3),                  // input wire rx_calign_3
  .tx_3_p(tx_3_p),                            // output wire tx_3_p
  .tx_3_n(tx_3_n),                            // output wire tx_3_n
  .tx_out_clk_3(tx_out_clk_3),                // output wire tx_out_clk_3
  .tx_clk_3(tx_clk_3),                        // input wire tx_clk_3
  .tx_charisk_3(tx_charisk_3),                // input wire [3 : 0] tx_charisk_3
  .tx_data_3(tx_data_3),                      // input wire [31 : 0] tx_data_3
  .up_es_enb_3(up_es_enb_3),                  // input wire up_es_enb_3
  .up_es_addr_3(up_es_addr_3),                // input wire [11 : 0] up_es_addr_3
  .up_es_wr_3(up_es_wr_3),                    // input wire up_es_wr_3
  .up_es_wdata_3(up_es_wdata_3),              // input wire [15 : 0] up_es_wdata_3
  .up_es_rdata_3(up_es_rdata_3),              // output wire [15 : 0] up_es_rdata_3
  .up_es_ready_3(up_es_ready_3),              // output wire up_es_ready_3
  .up_es_reset_3(up_es_reset_3),              // input wire up_es_reset_3
  .up_rx_pll_locked_3(up_rx_pll_locked_3),    // output wire up_rx_pll_locked_3
  .up_rx_rst_3(up_rx_rst_3),                  // input wire up_rx_rst_3
  .up_rx_user_ready_3(up_rx_user_ready_3),    // input wire up_rx_user_ready_3
  .up_rx_rst_done_3(up_rx_rst_done_3),        // output wire up_rx_rst_done_3
  .up_rx_lpm_dfe_n_3(up_rx_lpm_dfe_n_3),      // input wire up_rx_lpm_dfe_n_3
  .up_rx_rate_3(up_rx_rate_3),                // input wire [2 : 0] up_rx_rate_3
  .up_rx_sys_clk_sel_3(up_rx_sys_clk_sel_3),  // input wire [1 : 0] up_rx_sys_clk_sel_3
  .up_rx_out_clk_sel_3(up_rx_out_clk_sel_3),  // input wire [2 : 0] up_rx_out_clk_sel_3
  .up_rx_enb_3(up_rx_enb_3),                  // input wire up_rx_enb_3
  .up_rx_addr_3(up_rx_addr_3),                // input wire [11 : 0] up_rx_addr_3
  .up_rx_wr_3(up_rx_wr_3),                    // input wire up_rx_wr_3
  .up_rx_wdata_3(up_rx_wdata_3),              // input wire [15 : 0] up_rx_wdata_3
  .up_rx_rdata_3(up_rx_rdata_3),              // output wire [15 : 0] up_rx_rdata_3
  .up_rx_ready_3(up_rx_ready_3),              // output wire up_rx_ready_3
  .up_tx_pll_locked_3(up_tx_pll_locked_3),    // output wire up_tx_pll_locked_3
  .up_tx_rst_3(up_tx_rst_3),                  // input wire up_tx_rst_3
  .up_tx_user_ready_3(up_tx_user_ready_3),    // input wire up_tx_user_ready_3
  .up_tx_rst_done_3(up_tx_rst_done_3),        // output wire up_tx_rst_done_3
  .up_tx_lpm_dfe_n_3(up_tx_lpm_dfe_n_3),      // input wire up_tx_lpm_dfe_n_3
  .up_tx_rate_3(up_tx_rate_3),                // input wire [2 : 0] up_tx_rate_3
  .up_tx_sys_clk_sel_3(up_tx_sys_clk_sel_3),  // input wire [1 : 0] up_tx_sys_clk_sel_3
  .up_tx_out_clk_sel_3(up_tx_out_clk_sel_3),  // input wire [2 : 0] up_tx_out_clk_sel_3
  .up_tx_diffctrl_3(up_tx_diffctrl_3),        // input wire [4 : 0] up_tx_diffctrl_3
  .up_tx_postcursor_3(up_tx_postcursor_3),    // input wire [4 : 0] up_tx_postcursor_3
  .up_tx_precursor_3(up_tx_precursor_3),      // input wire [4 : 0] up_tx_precursor_3
  .up_tx_enb_3(up_tx_enb_3),                  // input wire up_tx_enb_3
  .up_tx_addr_3(up_tx_addr_3),                // input wire [11 : 0] up_tx_addr_3
  .up_tx_wr_3(up_tx_wr_3),                    // input wire up_tx_wr_3
  .up_tx_wdata_3(up_tx_wdata_3),              // input wire [15 : 0] up_tx_wdata_3
  .up_tx_rdata_3(up_tx_rdata_3),              // output wire [15 : 0] up_tx_rdata_3
  .up_tx_ready_3(up_tx_ready_3)              // output wire up_tx_ready_3
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

