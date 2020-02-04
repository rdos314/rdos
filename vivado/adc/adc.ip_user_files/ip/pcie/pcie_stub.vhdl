-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Sat Feb  1 20:24:00 2020
-- Host        : Leif-I7 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub C:/rdos/vivado/adc/adc.runs/pcie_synth_1/pcie_stub.vhdl
-- Design      : pcie
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pcie is
  Port ( 
    pci_exp_txp : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_txn : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_rxp : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_rxn : in STD_LOGIC_VECTOR ( 7 downto 0 );
    int_pclk_out_slave : out STD_LOGIC;
    int_pipe_rxusrclk_out : out STD_LOGIC;
    int_rxoutclk_out : out STD_LOGIC_VECTOR ( 7 downto 0 );
    int_dclk_out : out STD_LOGIC;
    int_mmcm_lock_out : out STD_LOGIC;
    int_userclk1_out : out STD_LOGIC;
    int_userclk2_out : out STD_LOGIC;
    int_oobclk_out : out STD_LOGIC;
    int_qplllock_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    int_qplloutclk_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    int_qplloutrefclk_out : out STD_LOGIC_VECTOR ( 1 downto 0 );
    int_pclk_sel_slave : in STD_LOGIC_VECTOR ( 7 downto 0 );
    user_clk_out : out STD_LOGIC;
    user_reset_out : out STD_LOGIC;
    user_lnk_up : out STD_LOGIC;
    user_app_rdy : out STD_LOGIC;
    s_axis_tx_tready : out STD_LOGIC;
    s_axis_tx_tdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    s_axis_tx_tkeep : in STD_LOGIC_VECTOR ( 15 downto 0 );
    s_axis_tx_tlast : in STD_LOGIC;
    s_axis_tx_tvalid : in STD_LOGIC;
    s_axis_tx_tuser : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axis_rx_tdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    m_axis_rx_tkeep : out STD_LOGIC_VECTOR ( 15 downto 0 );
    m_axis_rx_tlast : out STD_LOGIC;
    m_axis_rx_tvalid : out STD_LOGIC;
    m_axis_rx_tready : in STD_LOGIC;
    m_axis_rx_tuser : out STD_LOGIC_VECTOR ( 21 downto 0 );
    cfg_err_ecrc : in STD_LOGIC;
    cfg_err_ur : in STD_LOGIC;
    cfg_err_cpl_timeout : in STD_LOGIC;
    cfg_err_cpl_unexpect : in STD_LOGIC;
    cfg_err_cpl_abort : in STD_LOGIC;
    cfg_err_posted : in STD_LOGIC;
    cfg_err_cor : in STD_LOGIC;
    cfg_err_atomic_egress_blocked : in STD_LOGIC;
    cfg_err_internal_cor : in STD_LOGIC;
    cfg_err_malformed : in STD_LOGIC;
    cfg_err_mc_blocked : in STD_LOGIC;
    cfg_err_poisoned : in STD_LOGIC;
    cfg_err_norecovery : in STD_LOGIC;
    cfg_err_tlp_cpl_header : in STD_LOGIC_VECTOR ( 47 downto 0 );
    cfg_err_cpl_rdy : out STD_LOGIC;
    cfg_err_locked : in STD_LOGIC;
    cfg_err_acs : in STD_LOGIC;
    cfg_err_internal_uncor : in STD_LOGIC;
    cfg_interrupt : in STD_LOGIC;
    cfg_interrupt_rdy : out STD_LOGIC;
    cfg_interrupt_assert : in STD_LOGIC;
    cfg_interrupt_di : in STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_interrupt_do : out STD_LOGIC_VECTOR ( 7 downto 0 );
    cfg_interrupt_mmenable : out STD_LOGIC_VECTOR ( 2 downto 0 );
    cfg_interrupt_msienable : out STD_LOGIC;
    cfg_interrupt_msixenable : out STD_LOGIC;
    cfg_interrupt_msixfm : out STD_LOGIC;
    cfg_interrupt_stat : in STD_LOGIC;
    cfg_pciecap_interrupt_msgnum : in STD_LOGIC_VECTOR ( 4 downto 0 );
    pl_directed_link_change : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pl_directed_link_width : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pl_directed_link_speed : in STD_LOGIC;
    pl_directed_link_auton : in STD_LOGIC;
    pl_upstream_prefer_deemph : in STD_LOGIC;
    pl_sel_lnk_rate : out STD_LOGIC;
    pl_sel_lnk_width : out STD_LOGIC_VECTOR ( 1 downto 0 );
    pl_ltssm_state : out STD_LOGIC_VECTOR ( 5 downto 0 );
    pl_lane_reversal_mode : out STD_LOGIC_VECTOR ( 1 downto 0 );
    pl_phy_lnk_up : out STD_LOGIC;
    pl_tx_pm_state : out STD_LOGIC_VECTOR ( 2 downto 0 );
    pl_rx_pm_state : out STD_LOGIC_VECTOR ( 1 downto 0 );
    pl_link_upcfg_cap : out STD_LOGIC;
    pl_link_gen2_cap : out STD_LOGIC;
    pl_link_partner_gen2_supported : out STD_LOGIC;
    pl_initial_link_width : out STD_LOGIC_VECTOR ( 2 downto 0 );
    pl_directed_change_done : out STD_LOGIC;
    pl_received_hot_rst : out STD_LOGIC;
    pl_transmit_hot_rst : in STD_LOGIC;
    pl_downstream_deemph_source : in STD_LOGIC;
    cfg_err_aer_headerlog : in STD_LOGIC_VECTOR ( 127 downto 0 );
    cfg_aer_interrupt_msgnum : in STD_LOGIC_VECTOR ( 4 downto 0 );
    cfg_err_aer_headerlog_set : out STD_LOGIC;
    cfg_aer_ecrc_check_en : out STD_LOGIC;
    cfg_aer_ecrc_gen_en : out STD_LOGIC;
    sys_clk : in STD_LOGIC;
    sys_rst_n : in STD_LOGIC
  );

end pcie;

architecture stub of pcie is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "pci_exp_txp[7:0],pci_exp_txn[7:0],pci_exp_rxp[7:0],pci_exp_rxn[7:0],int_pclk_out_slave,int_pipe_rxusrclk_out,int_rxoutclk_out[7:0],int_dclk_out,int_mmcm_lock_out,int_userclk1_out,int_userclk2_out,int_oobclk_out,int_qplllock_out[1:0],int_qplloutclk_out[1:0],int_qplloutrefclk_out[1:0],int_pclk_sel_slave[7:0],user_clk_out,user_reset_out,user_lnk_up,user_app_rdy,s_axis_tx_tready,s_axis_tx_tdata[127:0],s_axis_tx_tkeep[15:0],s_axis_tx_tlast,s_axis_tx_tvalid,s_axis_tx_tuser[3:0],m_axis_rx_tdata[127:0],m_axis_rx_tkeep[15:0],m_axis_rx_tlast,m_axis_rx_tvalid,m_axis_rx_tready,m_axis_rx_tuser[21:0],cfg_err_ecrc,cfg_err_ur,cfg_err_cpl_timeout,cfg_err_cpl_unexpect,cfg_err_cpl_abort,cfg_err_posted,cfg_err_cor,cfg_err_atomic_egress_blocked,cfg_err_internal_cor,cfg_err_malformed,cfg_err_mc_blocked,cfg_err_poisoned,cfg_err_norecovery,cfg_err_tlp_cpl_header[47:0],cfg_err_cpl_rdy,cfg_err_locked,cfg_err_acs,cfg_err_internal_uncor,cfg_interrupt,cfg_interrupt_rdy,cfg_interrupt_assert,cfg_interrupt_di[7:0],cfg_interrupt_do[7:0],cfg_interrupt_mmenable[2:0],cfg_interrupt_msienable,cfg_interrupt_msixenable,cfg_interrupt_msixfm,cfg_interrupt_stat,cfg_pciecap_interrupt_msgnum[4:0],pl_directed_link_change[1:0],pl_directed_link_width[1:0],pl_directed_link_speed,pl_directed_link_auton,pl_upstream_prefer_deemph,pl_sel_lnk_rate,pl_sel_lnk_width[1:0],pl_ltssm_state[5:0],pl_lane_reversal_mode[1:0],pl_phy_lnk_up,pl_tx_pm_state[2:0],pl_rx_pm_state[1:0],pl_link_upcfg_cap,pl_link_gen2_cap,pl_link_partner_gen2_supported,pl_initial_link_width[2:0],pl_directed_change_done,pl_received_hot_rst,pl_transmit_hot_rst,pl_downstream_deemph_source,cfg_err_aer_headerlog[127:0],cfg_aer_interrupt_msgnum[4:0],cfg_err_aer_headerlog_set,cfg_aer_ecrc_check_en,cfg_aer_ecrc_gen_en,sys_clk,sys_rst_n";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "pcie_pcie2_top,Vivado 2019.2";
begin
end;
