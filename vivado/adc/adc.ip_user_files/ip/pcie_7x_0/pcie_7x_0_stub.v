// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Apr  4 22:25:56 2020
// Host        : Leif-I7 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub C:/rdos/vivado/adc/adc.runs/pcie_7x_0_synth_1/pcie_7x_0_stub.v
// Design      : pcie_7x_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "pcie_7x_0_pcie2_top,Vivado 2019.2" *)
module pcie_7x_0(pci_exp_txp, pci_exp_txn, pci_exp_rxp, 
  pci_exp_rxn, int_pclk_out_slave, int_pipe_rxusrclk_out, int_rxoutclk_out, int_dclk_out, 
  int_mmcm_lock_out, int_userclk1_out, int_userclk2_out, int_oobclk_out, int_qplllock_out, 
  int_qplloutclk_out, int_qplloutrefclk_out, int_pclk_sel_slave, user_clk_out, 
  user_reset_out, user_lnk_up, user_app_rdy, s_axis_tx_tready, s_axis_tx_tdata, 
  s_axis_tx_tkeep, s_axis_tx_tlast, s_axis_tx_tvalid, s_axis_tx_tuser, m_axis_rx_tdata, 
  m_axis_rx_tkeep, m_axis_rx_tlast, m_axis_rx_tvalid, m_axis_rx_tready, m_axis_rx_tuser, 
  cfg_err_ecrc, cfg_err_ur, cfg_err_cpl_timeout, cfg_err_cpl_unexpect, cfg_err_cpl_abort, 
  cfg_err_posted, cfg_err_cor, cfg_err_atomic_egress_blocked, cfg_err_internal_cor, 
  cfg_err_malformed, cfg_err_mc_blocked, cfg_err_poisoned, cfg_err_norecovery, 
  cfg_err_tlp_cpl_header, cfg_err_cpl_rdy, cfg_err_locked, cfg_err_acs, 
  cfg_err_internal_uncor, cfg_interrupt, cfg_interrupt_rdy, cfg_interrupt_assert, 
  cfg_interrupt_di, cfg_interrupt_do, cfg_interrupt_mmenable, cfg_interrupt_msienable, 
  cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_interrupt_stat, 
  cfg_pciecap_interrupt_msgnum, pl_directed_link_change, pl_directed_link_width, 
  pl_directed_link_speed, pl_directed_link_auton, pl_upstream_prefer_deemph, 
  pl_sel_lnk_rate, pl_sel_lnk_width, pl_ltssm_state, pl_lane_reversal_mode, pl_phy_lnk_up, 
  pl_tx_pm_state, pl_rx_pm_state, pl_link_upcfg_cap, pl_link_gen2_cap, 
  pl_link_partner_gen2_supported, pl_initial_link_width, pl_directed_change_done, 
  pl_received_hot_rst, pl_transmit_hot_rst, pl_downstream_deemph_source, 
  cfg_err_aer_headerlog, cfg_aer_interrupt_msgnum, cfg_err_aer_headerlog_set, 
  cfg_aer_ecrc_check_en, cfg_aer_ecrc_gen_en, sys_clk, sys_rst_n)
/* synthesis syn_black_box black_box_pad_pin="pci_exp_txp[7:0],pci_exp_txn[7:0],pci_exp_rxp[7:0],pci_exp_rxn[7:0],int_pclk_out_slave,int_pipe_rxusrclk_out,int_rxoutclk_out[7:0],int_dclk_out,int_mmcm_lock_out,int_userclk1_out,int_userclk2_out,int_oobclk_out,int_qplllock_out[1:0],int_qplloutclk_out[1:0],int_qplloutrefclk_out[1:0],int_pclk_sel_slave[7:0],user_clk_out,user_reset_out,user_lnk_up,user_app_rdy,s_axis_tx_tready,s_axis_tx_tdata[127:0],s_axis_tx_tkeep[15:0],s_axis_tx_tlast,s_axis_tx_tvalid,s_axis_tx_tuser[3:0],m_axis_rx_tdata[127:0],m_axis_rx_tkeep[15:0],m_axis_rx_tlast,m_axis_rx_tvalid,m_axis_rx_tready,m_axis_rx_tuser[21:0],cfg_err_ecrc,cfg_err_ur,cfg_err_cpl_timeout,cfg_err_cpl_unexpect,cfg_err_cpl_abort,cfg_err_posted,cfg_err_cor,cfg_err_atomic_egress_blocked,cfg_err_internal_cor,cfg_err_malformed,cfg_err_mc_blocked,cfg_err_poisoned,cfg_err_norecovery,cfg_err_tlp_cpl_header[47:0],cfg_err_cpl_rdy,cfg_err_locked,cfg_err_acs,cfg_err_internal_uncor,cfg_interrupt,cfg_interrupt_rdy,cfg_interrupt_assert,cfg_interrupt_di[7:0],cfg_interrupt_do[7:0],cfg_interrupt_mmenable[2:0],cfg_interrupt_msienable,cfg_interrupt_msixenable,cfg_interrupt_msixfm,cfg_interrupt_stat,cfg_pciecap_interrupt_msgnum[4:0],pl_directed_link_change[1:0],pl_directed_link_width[1:0],pl_directed_link_speed,pl_directed_link_auton,pl_upstream_prefer_deemph,pl_sel_lnk_rate,pl_sel_lnk_width[1:0],pl_ltssm_state[5:0],pl_lane_reversal_mode[1:0],pl_phy_lnk_up,pl_tx_pm_state[2:0],pl_rx_pm_state[1:0],pl_link_upcfg_cap,pl_link_gen2_cap,pl_link_partner_gen2_supported,pl_initial_link_width[2:0],pl_directed_change_done,pl_received_hot_rst,pl_transmit_hot_rst,pl_downstream_deemph_source,cfg_err_aer_headerlog[127:0],cfg_aer_interrupt_msgnum[4:0],cfg_err_aer_headerlog_set,cfg_aer_ecrc_check_en,cfg_aer_ecrc_gen_en,sys_clk,sys_rst_n" */;
  output [7:0]pci_exp_txp;
  output [7:0]pci_exp_txn;
  input [7:0]pci_exp_rxp;
  input [7:0]pci_exp_rxn;
  output int_pclk_out_slave;
  output int_pipe_rxusrclk_out;
  output [7:0]int_rxoutclk_out;
  output int_dclk_out;
  output int_mmcm_lock_out;
  output int_userclk1_out;
  output int_userclk2_out;
  output int_oobclk_out;
  output [1:0]int_qplllock_out;
  output [1:0]int_qplloutclk_out;
  output [1:0]int_qplloutrefclk_out;
  input [7:0]int_pclk_sel_slave;
  output user_clk_out;
  output user_reset_out;
  output user_lnk_up;
  output user_app_rdy;
  output s_axis_tx_tready;
  input [127:0]s_axis_tx_tdata;
  input [15:0]s_axis_tx_tkeep;
  input s_axis_tx_tlast;
  input s_axis_tx_tvalid;
  input [3:0]s_axis_tx_tuser;
  output [127:0]m_axis_rx_tdata;
  output [15:0]m_axis_rx_tkeep;
  output m_axis_rx_tlast;
  output m_axis_rx_tvalid;
  input m_axis_rx_tready;
  output [21:0]m_axis_rx_tuser;
  input cfg_err_ecrc;
  input cfg_err_ur;
  input cfg_err_cpl_timeout;
  input cfg_err_cpl_unexpect;
  input cfg_err_cpl_abort;
  input cfg_err_posted;
  input cfg_err_cor;
  input cfg_err_atomic_egress_blocked;
  input cfg_err_internal_cor;
  input cfg_err_malformed;
  input cfg_err_mc_blocked;
  input cfg_err_poisoned;
  input cfg_err_norecovery;
  input [47:0]cfg_err_tlp_cpl_header;
  output cfg_err_cpl_rdy;
  input cfg_err_locked;
  input cfg_err_acs;
  input cfg_err_internal_uncor;
  input cfg_interrupt;
  output cfg_interrupt_rdy;
  input cfg_interrupt_assert;
  input [7:0]cfg_interrupt_di;
  output [7:0]cfg_interrupt_do;
  output [2:0]cfg_interrupt_mmenable;
  output cfg_interrupt_msienable;
  output cfg_interrupt_msixenable;
  output cfg_interrupt_msixfm;
  input cfg_interrupt_stat;
  input [4:0]cfg_pciecap_interrupt_msgnum;
  input [1:0]pl_directed_link_change;
  input [1:0]pl_directed_link_width;
  input pl_directed_link_speed;
  input pl_directed_link_auton;
  input pl_upstream_prefer_deemph;
  output pl_sel_lnk_rate;
  output [1:0]pl_sel_lnk_width;
  output [5:0]pl_ltssm_state;
  output [1:0]pl_lane_reversal_mode;
  output pl_phy_lnk_up;
  output [2:0]pl_tx_pm_state;
  output [1:0]pl_rx_pm_state;
  output pl_link_upcfg_cap;
  output pl_link_gen2_cap;
  output pl_link_partner_gen2_supported;
  output [2:0]pl_initial_link_width;
  output pl_directed_change_done;
  output pl_received_hot_rst;
  input pl_transmit_hot_rst;
  input pl_downstream_deemph_source;
  input [127:0]cfg_err_aer_headerlog;
  input [4:0]cfg_aer_interrupt_msgnum;
  output cfg_err_aer_headerlog_set;
  output cfg_aer_ecrc_check_en;
  output cfg_aer_ecrc_gen_en;
  input sys_clk;
  input sys_rst_n;
endmodule
