//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
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
//-----------------------------------------------------------------------------
// Project    : Series-7 Integrated Block for PCI Express
// File       : xilinx_pcie_2_1_ep_7x.v
// Version    : 3.3
//--
//-- Description:  PCI Express Endpoint example FPGA design
//--
//------------------------------------------------------------------------------

`timescale 1ns / 1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
module xilinx_pcie_2_1_ep_7x # (
  parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
  parameter EXT_PIPE_SIM        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.	
  parameter PCIE_EXT_CLK        = "FALSE",    // Use External Clocking Module
  parameter PCIE_EXT_GT_COMMON  = "FALSE",
  parameter REF_CLK_FREQ        = 0,     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
  parameter C_DATA_WIDTH        = 128, // RX/TX interface data width
  parameter KEEP_WIDTH          = C_DATA_WIDTH / 8 // TSTRB width
) (
  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn,


  output                                      led_0,
  output                                      led_1,
  output                                      led_2,
  output                                      led_3,

  input                                       sys_clk_p,
  input                                       sys_clk_n,
  input                                       sys_rst_n
);

// Register Declaration

  wire                                        user_clk;
  wire                                        user_reset;
  wire                                        user_lnk_up;

  reg                                         user_reset_q;
  reg                                         user_lnk_up_q;
  reg    [25:0]                               user_clk_heartbeat = 'h0;

// Local Parameters
  localparam TCQ               = 1;
  localparam USER_CLK_FREQ     = 4;
  localparam USER_CLK2_DIV2    = "TRUE";
  localparam USERCLK2_FREQ     = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ: USER_CLK_FREQ;

pci_app pci_app_inst (
    .pci_exp_txp(pci_exp_txp),
    .pci_exp_txn(pci_exp_txn),
    .pci_exp_rxp(pci_exp_rxp),
    .pci_exp_rxn(pci_exp_rxn),

    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n_c),
    
    .user_clk(user_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up)
);


 //-----------------------------I/O BUFFERS------------------------//

  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

  IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));

  OBUF   led_0_obuf (.O(led_0), .I(sys_rst_n_c));
  OBUF   led_1_obuf (.O(led_1), .I(!user_reset));
  OBUF   led_2_obuf (.O(led_2), .I(user_lnk_up));
  OBUF   led_3_obuf (.O(led_3), .I(user_clk_heartbeat[25]));

  always @(posedge user_clk) begin
    user_reset_q  <= user_reset;
    user_lnk_up_q <= user_lnk_up;
  end

  // Create a Clock Heartbeat on LED #3
  always @(posedge user_clk) begin
      user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
  end




endmodule
