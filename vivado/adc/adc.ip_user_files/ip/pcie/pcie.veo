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

// IP VLNV: xilinx.com:ip:pcie_7x:3.3
// IP Revision: 11

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
pcie your_instance_name (
  .pci_exp_txp(pci_exp_txp),                                        // output wire [7 : 0] pci_exp_txp
  .pci_exp_txn(pci_exp_txn),                                        // output wire [7 : 0] pci_exp_txn
  .pci_exp_rxp(pci_exp_rxp),                                        // input wire [7 : 0] pci_exp_rxp
  .pci_exp_rxn(pci_exp_rxn),                                        // input wire [7 : 0] pci_exp_rxn
  .int_pclk_out_slave(int_pclk_out_slave),                          // output wire int_pclk_out_slave
  .int_pipe_rxusrclk_out(int_pipe_rxusrclk_out),                    // output wire int_pipe_rxusrclk_out
  .int_rxoutclk_out(int_rxoutclk_out),                              // output wire [7 : 0] int_rxoutclk_out
  .int_dclk_out(int_dclk_out),                                      // output wire int_dclk_out
  .int_mmcm_lock_out(int_mmcm_lock_out),                            // output wire int_mmcm_lock_out
  .int_userclk1_out(int_userclk1_out),                              // output wire int_userclk1_out
  .int_userclk2_out(int_userclk2_out),                              // output wire int_userclk2_out
  .int_oobclk_out(int_oobclk_out),                                  // output wire int_oobclk_out
  .int_qplllock_out(int_qplllock_out),                              // output wire [1 : 0] int_qplllock_out
  .int_qplloutclk_out(int_qplloutclk_out),                          // output wire [1 : 0] int_qplloutclk_out
  .int_qplloutrefclk_out(int_qplloutrefclk_out),                    // output wire [1 : 0] int_qplloutrefclk_out
  .int_pclk_sel_slave(int_pclk_sel_slave),                          // input wire [7 : 0] int_pclk_sel_slave
  .user_clk_out(user_clk_out),                                      // output wire user_clk_out
  .user_reset_out(user_reset_out),                                  // output wire user_reset_out
  .user_lnk_up(user_lnk_up),                                        // output wire user_lnk_up
  .user_app_rdy(user_app_rdy),                                      // output wire user_app_rdy
  .s_axis_tx_tready(s_axis_tx_tready),                              // output wire s_axis_tx_tready
  .s_axis_tx_tdata(s_axis_tx_tdata),                                // input wire [127 : 0] s_axis_tx_tdata
  .s_axis_tx_tkeep(s_axis_tx_tkeep),                                // input wire [15 : 0] s_axis_tx_tkeep
  .s_axis_tx_tlast(s_axis_tx_tlast),                                // input wire s_axis_tx_tlast
  .s_axis_tx_tvalid(s_axis_tx_tvalid),                              // input wire s_axis_tx_tvalid
  .s_axis_tx_tuser(s_axis_tx_tuser),                                // input wire [3 : 0] s_axis_tx_tuser
  .m_axis_rx_tdata(m_axis_rx_tdata),                                // output wire [127 : 0] m_axis_rx_tdata
  .m_axis_rx_tkeep(m_axis_rx_tkeep),                                // output wire [15 : 0] m_axis_rx_tkeep
  .m_axis_rx_tlast(m_axis_rx_tlast),                                // output wire m_axis_rx_tlast
  .m_axis_rx_tvalid(m_axis_rx_tvalid),                              // output wire m_axis_rx_tvalid
  .m_axis_rx_tready(m_axis_rx_tready),                              // input wire m_axis_rx_tready
  .m_axis_rx_tuser(m_axis_rx_tuser),                                // output wire [21 : 0] m_axis_rx_tuser
  .cfg_err_ecrc(cfg_err_ecrc),                                      // input wire cfg_err_ecrc
  .cfg_err_ur(cfg_err_ur),                                          // input wire cfg_err_ur
  .cfg_err_cpl_timeout(cfg_err_cpl_timeout),                        // input wire cfg_err_cpl_timeout
  .cfg_err_cpl_unexpect(cfg_err_cpl_unexpect),                      // input wire cfg_err_cpl_unexpect
  .cfg_err_cpl_abort(cfg_err_cpl_abort),                            // input wire cfg_err_cpl_abort
  .cfg_err_posted(cfg_err_posted),                                  // input wire cfg_err_posted
  .cfg_err_cor(cfg_err_cor),                                        // input wire cfg_err_cor
  .cfg_err_atomic_egress_blocked(cfg_err_atomic_egress_blocked),    // input wire cfg_err_atomic_egress_blocked
  .cfg_err_internal_cor(cfg_err_internal_cor),                      // input wire cfg_err_internal_cor
  .cfg_err_malformed(cfg_err_malformed),                            // input wire cfg_err_malformed
  .cfg_err_mc_blocked(cfg_err_mc_blocked),                          // input wire cfg_err_mc_blocked
  .cfg_err_poisoned(cfg_err_poisoned),                              // input wire cfg_err_poisoned
  .cfg_err_norecovery(cfg_err_norecovery),                          // input wire cfg_err_norecovery
  .cfg_err_tlp_cpl_header(cfg_err_tlp_cpl_header),                  // input wire [47 : 0] cfg_err_tlp_cpl_header
  .cfg_err_cpl_rdy(cfg_err_cpl_rdy),                                // output wire cfg_err_cpl_rdy
  .cfg_err_locked(cfg_err_locked),                                  // input wire cfg_err_locked
  .cfg_err_acs(cfg_err_acs),                                        // input wire cfg_err_acs
  .cfg_err_internal_uncor(cfg_err_internal_uncor),                  // input wire cfg_err_internal_uncor
  .cfg_interrupt(cfg_interrupt),                                    // input wire cfg_interrupt
  .cfg_interrupt_rdy(cfg_interrupt_rdy),                            // output wire cfg_interrupt_rdy
  .cfg_interrupt_assert(cfg_interrupt_assert),                      // input wire cfg_interrupt_assert
  .cfg_interrupt_di(cfg_interrupt_di),                              // input wire [7 : 0] cfg_interrupt_di
  .cfg_interrupt_do(cfg_interrupt_do),                              // output wire [7 : 0] cfg_interrupt_do
  .cfg_interrupt_mmenable(cfg_interrupt_mmenable),                  // output wire [2 : 0] cfg_interrupt_mmenable
  .cfg_interrupt_msienable(cfg_interrupt_msienable),                // output wire cfg_interrupt_msienable
  .cfg_interrupt_msixenable(cfg_interrupt_msixenable),              // output wire cfg_interrupt_msixenable
  .cfg_interrupt_msixfm(cfg_interrupt_msixfm),                      // output wire cfg_interrupt_msixfm
  .cfg_interrupt_stat(cfg_interrupt_stat),                          // input wire cfg_interrupt_stat
  .cfg_pciecap_interrupt_msgnum(cfg_pciecap_interrupt_msgnum),      // input wire [4 : 0] cfg_pciecap_interrupt_msgnum
  .pl_directed_link_change(pl_directed_link_change),                // input wire [1 : 0] pl_directed_link_change
  .pl_directed_link_width(pl_directed_link_width),                  // input wire [1 : 0] pl_directed_link_width
  .pl_directed_link_speed(pl_directed_link_speed),                  // input wire pl_directed_link_speed
  .pl_directed_link_auton(pl_directed_link_auton),                  // input wire pl_directed_link_auton
  .pl_upstream_prefer_deemph(pl_upstream_prefer_deemph),            // input wire pl_upstream_prefer_deemph
  .pl_sel_lnk_rate(pl_sel_lnk_rate),                                // output wire pl_sel_lnk_rate
  .pl_sel_lnk_width(pl_sel_lnk_width),                              // output wire [1 : 0] pl_sel_lnk_width
  .pl_ltssm_state(pl_ltssm_state),                                  // output wire [5 : 0] pl_ltssm_state
  .pl_lane_reversal_mode(pl_lane_reversal_mode),                    // output wire [1 : 0] pl_lane_reversal_mode
  .pl_phy_lnk_up(pl_phy_lnk_up),                                    // output wire pl_phy_lnk_up
  .pl_tx_pm_state(pl_tx_pm_state),                                  // output wire [2 : 0] pl_tx_pm_state
  .pl_rx_pm_state(pl_rx_pm_state),                                  // output wire [1 : 0] pl_rx_pm_state
  .pl_link_upcfg_cap(pl_link_upcfg_cap),                            // output wire pl_link_upcfg_cap
  .pl_link_gen2_cap(pl_link_gen2_cap),                              // output wire pl_link_gen2_cap
  .pl_link_partner_gen2_supported(pl_link_partner_gen2_supported),  // output wire pl_link_partner_gen2_supported
  .pl_initial_link_width(pl_initial_link_width),                    // output wire [2 : 0] pl_initial_link_width
  .pl_directed_change_done(pl_directed_change_done),                // output wire pl_directed_change_done
  .pl_received_hot_rst(pl_received_hot_rst),                        // output wire pl_received_hot_rst
  .pl_transmit_hot_rst(pl_transmit_hot_rst),                        // input wire pl_transmit_hot_rst
  .pl_downstream_deemph_source(pl_downstream_deemph_source),        // input wire pl_downstream_deemph_source
  .cfg_err_aer_headerlog(cfg_err_aer_headerlog),                    // input wire [127 : 0] cfg_err_aer_headerlog
  .cfg_aer_interrupt_msgnum(cfg_aer_interrupt_msgnum),              // input wire [4 : 0] cfg_aer_interrupt_msgnum
  .cfg_err_aer_headerlog_set(cfg_err_aer_headerlog_set),            // output wire cfg_err_aer_headerlog_set
  .cfg_aer_ecrc_check_en(cfg_aer_ecrc_check_en),                    // output wire cfg_aer_ecrc_check_en
  .cfg_aer_ecrc_gen_en(cfg_aer_ecrc_gen_en),                        // output wire cfg_aer_ecrc_gen_en
  .sys_clk(sys_clk),                                                // input wire sys_clk
  .sys_rst_n(sys_rst_n)                                            // input wire sys_rst_n
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file pcie.v when simulating
// the core, pcie. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

