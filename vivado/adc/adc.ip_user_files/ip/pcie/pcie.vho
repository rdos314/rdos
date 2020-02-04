-- (c) Copyright 1995-2020 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:pcie_7x:3.3
-- IP Revision: 11

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT pcie
  PORT (
    pci_exp_txp : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    pci_exp_txn : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    pci_exp_rxp : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    pci_exp_rxn : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    int_pclk_out_slave : OUT STD_LOGIC;
    int_pipe_rxusrclk_out : OUT STD_LOGIC;
    int_rxoutclk_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    int_dclk_out : OUT STD_LOGIC;
    int_mmcm_lock_out : OUT STD_LOGIC;
    int_userclk1_out : OUT STD_LOGIC;
    int_userclk2_out : OUT STD_LOGIC;
    int_oobclk_out : OUT STD_LOGIC;
    int_qplllock_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    int_qplloutclk_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    int_qplloutrefclk_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    int_pclk_sel_slave : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    user_clk_out : OUT STD_LOGIC;
    user_reset_out : OUT STD_LOGIC;
    user_lnk_up : OUT STD_LOGIC;
    user_app_rdy : OUT STD_LOGIC;
    s_axis_tx_tready : OUT STD_LOGIC;
    s_axis_tx_tdata : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    s_axis_tx_tkeep : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_tx_tlast : IN STD_LOGIC;
    s_axis_tx_tvalid : IN STD_LOGIC;
    s_axis_tx_tuser : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axis_rx_tdata : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
    m_axis_rx_tkeep : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_rx_tlast : OUT STD_LOGIC;
    m_axis_rx_tvalid : OUT STD_LOGIC;
    m_axis_rx_tready : IN STD_LOGIC;
    m_axis_rx_tuser : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
    cfg_err_ecrc : IN STD_LOGIC;
    cfg_err_ur : IN STD_LOGIC;
    cfg_err_cpl_timeout : IN STD_LOGIC;
    cfg_err_cpl_unexpect : IN STD_LOGIC;
    cfg_err_cpl_abort : IN STD_LOGIC;
    cfg_err_posted : IN STD_LOGIC;
    cfg_err_cor : IN STD_LOGIC;
    cfg_err_atomic_egress_blocked : IN STD_LOGIC;
    cfg_err_internal_cor : IN STD_LOGIC;
    cfg_err_malformed : IN STD_LOGIC;
    cfg_err_mc_blocked : IN STD_LOGIC;
    cfg_err_poisoned : IN STD_LOGIC;
    cfg_err_norecovery : IN STD_LOGIC;
    cfg_err_tlp_cpl_header : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    cfg_err_cpl_rdy : OUT STD_LOGIC;
    cfg_err_locked : IN STD_LOGIC;
    cfg_err_acs : IN STD_LOGIC;
    cfg_err_internal_uncor : IN STD_LOGIC;
    cfg_interrupt : IN STD_LOGIC;
    cfg_interrupt_rdy : OUT STD_LOGIC;
    cfg_interrupt_assert : IN STD_LOGIC;
    cfg_interrupt_di : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_interrupt_do : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_interrupt_mmenable : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    cfg_interrupt_msienable : OUT STD_LOGIC;
    cfg_interrupt_msixenable : OUT STD_LOGIC;
    cfg_interrupt_msixfm : OUT STD_LOGIC;
    cfg_interrupt_stat : IN STD_LOGIC;
    cfg_pciecap_interrupt_msgnum : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    pl_directed_link_change : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    pl_directed_link_width : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    pl_directed_link_speed : IN STD_LOGIC;
    pl_directed_link_auton : IN STD_LOGIC;
    pl_upstream_prefer_deemph : IN STD_LOGIC;
    pl_sel_lnk_rate : OUT STD_LOGIC;
    pl_sel_lnk_width : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    pl_ltssm_state : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    pl_lane_reversal_mode : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    pl_phy_lnk_up : OUT STD_LOGIC;
    pl_tx_pm_state : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    pl_rx_pm_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    pl_link_upcfg_cap : OUT STD_LOGIC;
    pl_link_gen2_cap : OUT STD_LOGIC;
    pl_link_partner_gen2_supported : OUT STD_LOGIC;
    pl_initial_link_width : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    pl_directed_change_done : OUT STD_LOGIC;
    pl_received_hot_rst : OUT STD_LOGIC;
    pl_transmit_hot_rst : IN STD_LOGIC;
    pl_downstream_deemph_source : IN STD_LOGIC;
    cfg_err_aer_headerlog : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    cfg_aer_interrupt_msgnum : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    cfg_err_aer_headerlog_set : OUT STD_LOGIC;
    cfg_aer_ecrc_check_en : OUT STD_LOGIC;
    cfg_aer_ecrc_gen_en : OUT STD_LOGIC;
    sys_clk : IN STD_LOGIC;
    sys_rst_n : IN STD_LOGIC
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : pcie
  PORT MAP (
    pci_exp_txp => pci_exp_txp,
    pci_exp_txn => pci_exp_txn,
    pci_exp_rxp => pci_exp_rxp,
    pci_exp_rxn => pci_exp_rxn,
    int_pclk_out_slave => int_pclk_out_slave,
    int_pipe_rxusrclk_out => int_pipe_rxusrclk_out,
    int_rxoutclk_out => int_rxoutclk_out,
    int_dclk_out => int_dclk_out,
    int_mmcm_lock_out => int_mmcm_lock_out,
    int_userclk1_out => int_userclk1_out,
    int_userclk2_out => int_userclk2_out,
    int_oobclk_out => int_oobclk_out,
    int_qplllock_out => int_qplllock_out,
    int_qplloutclk_out => int_qplloutclk_out,
    int_qplloutrefclk_out => int_qplloutrefclk_out,
    int_pclk_sel_slave => int_pclk_sel_slave,
    user_clk_out => user_clk_out,
    user_reset_out => user_reset_out,
    user_lnk_up => user_lnk_up,
    user_app_rdy => user_app_rdy,
    s_axis_tx_tready => s_axis_tx_tready,
    s_axis_tx_tdata => s_axis_tx_tdata,
    s_axis_tx_tkeep => s_axis_tx_tkeep,
    s_axis_tx_tlast => s_axis_tx_tlast,
    s_axis_tx_tvalid => s_axis_tx_tvalid,
    s_axis_tx_tuser => s_axis_tx_tuser,
    m_axis_rx_tdata => m_axis_rx_tdata,
    m_axis_rx_tkeep => m_axis_rx_tkeep,
    m_axis_rx_tlast => m_axis_rx_tlast,
    m_axis_rx_tvalid => m_axis_rx_tvalid,
    m_axis_rx_tready => m_axis_rx_tready,
    m_axis_rx_tuser => m_axis_rx_tuser,
    cfg_err_ecrc => cfg_err_ecrc,
    cfg_err_ur => cfg_err_ur,
    cfg_err_cpl_timeout => cfg_err_cpl_timeout,
    cfg_err_cpl_unexpect => cfg_err_cpl_unexpect,
    cfg_err_cpl_abort => cfg_err_cpl_abort,
    cfg_err_posted => cfg_err_posted,
    cfg_err_cor => cfg_err_cor,
    cfg_err_atomic_egress_blocked => cfg_err_atomic_egress_blocked,
    cfg_err_internal_cor => cfg_err_internal_cor,
    cfg_err_malformed => cfg_err_malformed,
    cfg_err_mc_blocked => cfg_err_mc_blocked,
    cfg_err_poisoned => cfg_err_poisoned,
    cfg_err_norecovery => cfg_err_norecovery,
    cfg_err_tlp_cpl_header => cfg_err_tlp_cpl_header,
    cfg_err_cpl_rdy => cfg_err_cpl_rdy,
    cfg_err_locked => cfg_err_locked,
    cfg_err_acs => cfg_err_acs,
    cfg_err_internal_uncor => cfg_err_internal_uncor,
    cfg_interrupt => cfg_interrupt,
    cfg_interrupt_rdy => cfg_interrupt_rdy,
    cfg_interrupt_assert => cfg_interrupt_assert,
    cfg_interrupt_di => cfg_interrupt_di,
    cfg_interrupt_do => cfg_interrupt_do,
    cfg_interrupt_mmenable => cfg_interrupt_mmenable,
    cfg_interrupt_msienable => cfg_interrupt_msienable,
    cfg_interrupt_msixenable => cfg_interrupt_msixenable,
    cfg_interrupt_msixfm => cfg_interrupt_msixfm,
    cfg_interrupt_stat => cfg_interrupt_stat,
    cfg_pciecap_interrupt_msgnum => cfg_pciecap_interrupt_msgnum,
    pl_directed_link_change => pl_directed_link_change,
    pl_directed_link_width => pl_directed_link_width,
    pl_directed_link_speed => pl_directed_link_speed,
    pl_directed_link_auton => pl_directed_link_auton,
    pl_upstream_prefer_deemph => pl_upstream_prefer_deemph,
    pl_sel_lnk_rate => pl_sel_lnk_rate,
    pl_sel_lnk_width => pl_sel_lnk_width,
    pl_ltssm_state => pl_ltssm_state,
    pl_lane_reversal_mode => pl_lane_reversal_mode,
    pl_phy_lnk_up => pl_phy_lnk_up,
    pl_tx_pm_state => pl_tx_pm_state,
    pl_rx_pm_state => pl_rx_pm_state,
    pl_link_upcfg_cap => pl_link_upcfg_cap,
    pl_link_gen2_cap => pl_link_gen2_cap,
    pl_link_partner_gen2_supported => pl_link_partner_gen2_supported,
    pl_initial_link_width => pl_initial_link_width,
    pl_directed_change_done => pl_directed_change_done,
    pl_received_hot_rst => pl_received_hot_rst,
    pl_transmit_hot_rst => pl_transmit_hot_rst,
    pl_downstream_deemph_source => pl_downstream_deemph_source,
    cfg_err_aer_headerlog => cfg_err_aer_headerlog,
    cfg_aer_interrupt_msgnum => cfg_aer_interrupt_msgnum,
    cfg_err_aer_headerlog_set => cfg_err_aer_headerlog_set,
    cfg_aer_ecrc_check_en => cfg_aer_ecrc_check_en,
    cfg_aer_ecrc_gen_en => cfg_aer_ecrc_gen_en,
    sys_clk => sys_clk,
    sys_rst_n => sys_rst_n
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file pcie.vhd when simulating
-- the core, pcie. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

