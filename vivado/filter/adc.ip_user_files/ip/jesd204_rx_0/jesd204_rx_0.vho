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

-- IP VLNV: analog.com:user:jesd204_rx:1.0
-- IP Revision: 1

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT jesd204_rx_0
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    phy_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    phy_header : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    phy_charisk : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    phy_notintable : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    phy_disperr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    phy_block_sync : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    sysref : IN STD_LOGIC;
    lmfc_edge : OUT STD_LOGIC;
    lmfc_clk : OUT STD_LOGIC;
    event_sysref_alignment_error : OUT STD_LOGIC;
    event_sysref_edge : OUT STD_LOGIC;
    sync : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    phy_en_char_align : OUT STD_LOGIC;
    rx_data : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
    rx_valid : OUT STD_LOGIC;
    rx_eof : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    rx_sof : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    cfg_lanes_disable : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    cfg_links_disable : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    cfg_beats_per_multiframe : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_octets_per_frame : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_lmfc_offset : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_sysref_disable : IN STD_LOGIC;
    cfg_sysref_oneshot : IN STD_LOGIC;
    cfg_buffer_early_release : IN STD_LOGIC;
    cfg_buffer_delay : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_disable_char_replacement : IN STD_LOGIC;
    cfg_disable_scrambler : IN STD_LOGIC;
    ctrl_err_statistics_reset : IN STD_LOGIC;
    ctrl_err_statistics_mask : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    status_err_statistics_cnt : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
    ilas_config_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    ilas_config_addr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ilas_config_data : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
    status_ctrl_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    status_lane_cgs_state : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    status_lane_ifs_ready : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    status_lane_latency : OUT STD_LOGIC_VECTOR(55 DOWNTO 0);
    status_lane_emb_state : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : jesd204_rx_0
  PORT MAP (
    clk => clk,
    reset => reset,
    phy_data => phy_data,
    phy_header => phy_header,
    phy_charisk => phy_charisk,
    phy_notintable => phy_notintable,
    phy_disperr => phy_disperr,
    phy_block_sync => phy_block_sync,
    sysref => sysref,
    lmfc_edge => lmfc_edge,
    lmfc_clk => lmfc_clk,
    event_sysref_alignment_error => event_sysref_alignment_error,
    event_sysref_edge => event_sysref_edge,
    sync => sync,
    phy_en_char_align => phy_en_char_align,
    rx_data => rx_data,
    rx_valid => rx_valid,
    rx_eof => rx_eof,
    rx_sof => rx_sof,
    cfg_lanes_disable => cfg_lanes_disable,
    cfg_links_disable => cfg_links_disable,
    cfg_beats_per_multiframe => cfg_beats_per_multiframe,
    cfg_octets_per_frame => cfg_octets_per_frame,
    cfg_lmfc_offset => cfg_lmfc_offset,
    cfg_sysref_disable => cfg_sysref_disable,
    cfg_sysref_oneshot => cfg_sysref_oneshot,
    cfg_buffer_early_release => cfg_buffer_early_release,
    cfg_buffer_delay => cfg_buffer_delay,
    cfg_disable_char_replacement => cfg_disable_char_replacement,
    cfg_disable_scrambler => cfg_disable_scrambler,
    ctrl_err_statistics_reset => ctrl_err_statistics_reset,
    ctrl_err_statistics_mask => ctrl_err_statistics_mask,
    status_err_statistics_cnt => status_err_statistics_cnt,
    ilas_config_valid => ilas_config_valid,
    ilas_config_addr => ilas_config_addr,
    ilas_config_data => ilas_config_data,
    status_ctrl_state => status_ctrl_state,
    status_lane_cgs_state => status_lane_cgs_state,
    status_lane_ifs_ready => status_lane_ifs_ready,
    status_lane_latency => status_lane_latency,
    status_lane_emb_state => status_lane_emb_state
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

