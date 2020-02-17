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

module adc (
  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn,

  output                                      led_0,
  output                                      led_1,
  output                                      led_2,
  output                                      led_3,
  output                                      led_4,
  output                                      led_5,
  output                                      led_6,
  output                                      led_7,

  input                                       sys_clk_p,
  input                                       sys_clk_n,
  input                                       sys_rst_n
);

  parameter c_CNT = 200000000;

// Register Declaration

  wire                   user_clk;
  wire                   user_reset;
  wire                   user_lnk_up;
  wire                   user_lnk_rate;
  wire [1:0]             user_lnk_width;
  wire                   cfg_interrupt_msienable;  
  wire                   sample_clk;  
  wire                   clk;  
  wire [31:0]            bar_control;

  wire [16:0]            bar1_address;
  wire                   bar1_rd;
  wire                   bar1_rp;
  wire [4:0]             bar1_rp_address;
  wire [31:0]            bar1_rp_data;
  wire                   bar1_wr;
  wire [3:0]             bar1_wr_be;
  wire [31:0]            bar1_wr_data;
  wire                   bar1_ack;

  wire [16:0]            bar2_address;
  wire                   bar2_rd;
  wire                   bar2_rp;
  wire [4:0]             bar2_rp_address;
  wire [31:0]            bar2_rp_data;
  wire                   bar2_wr;
  wire [3:0]             bar2_wr_be;
  wire [31:0]            bar2_wr_data;
  wire                   bar2_ack;

pci_app pci_app_inst (
    .pci_exp_txp(pci_exp_txp),
    .pci_exp_txn(pci_exp_txn),
    .pci_exp_rxp(pci_exp_rxp),
    .pci_exp_rxn(pci_exp_rxn),

    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n_c),
    
    .user_clk(user_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up),
    .user_lnk_rate(user_lnk_rate),
    .user_lnk_width(user_lnk_width),
    .cfg_interrupt_msienable(cfg_interrupt_msienable),

    .bar_control(bar_control)

    .bar1_address(bar1_address),
    .bar1_rd(bar1_rd),
    .bar1_rp(bar1_rp),
    .bar1_rp_address(bar1_rp_address),
    .bar1_rp_data(bar1_rp_data),
    .bar1_wr(bar1_wr),
    .bar1_wr_be(bar1_wr_be),
    .bar1_wr_data(bar1_wr_data),
    .bar1_ack(bar1_ack),

    .bar2_address(bar2_address),
    .bar2_rd(bar2_rd),
    .bar2_rp(bar2_rp),
    .bar2_rp_address(bar2_rp_address),
    .bar2_rp_data(bar2_rp_data),
    .bar2_wr(bar2_wr),
    .bar2_wr_be(bar2_wr_be),
    .bar2_wr_data(bar2_wr_data),
    .bar2_ack(bar2_ack)
);

adc_app adc_app_inst (
    .clk(user_clk),
    .reset(user_reset),
    .sample_clk(sample_clk),

    .address(bar1_address),
    .rd(bar1_rd),
    .rp(bar1_rp),
    .rp_address(bar1_rp_address),
    .rp_data(bar1_rp_data),
    .wr(bar1_wr),
    .wr_be(bar1_wr_be),
    .wr_data(bar1_wr_data),
    .ack(bar1_ack)
);

dac_app dac_app_inst (
    .clk(user_clk),
    .reset(user_reset),
    .sample_clk(sample_clk),

    .address(bar2_address),
    .rd(bar2_rd),
    .rp(bar2_rp),
    .rp_address(bar2_rp_address),
    .rp_data(bar2_rp_data),
    .wr(bar2_wr),
    .wr_be(bar2_wr_be),
    .wr_data(bar2_wr_data),
    .ack(bar2_ack)
);

 sample_700 sample_inst  (
    .clk_out1(sample_clk),     // output clk_out1
    .clk_in1(clk)          // input clk_in1
    );

 //-----------------------------I/O BUFFERS------------------------//

  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
  IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
  BUFG   sys_clk_buf (.O(clk), .I(sys_clk));

  OBUF   led_0_obuf (.O(led_0), .I(bar_control[0]));
  OBUF   led_1_obuf (.O(led_1), .I(bar_control[1]));
  OBUF   led_2_obuf (.O(led_2), .I(bar_control[2]));
  OBUF   led_3_obuf (.O(led_3), .I(bar_control[3]));
  OBUF   led_4_obuf (.O(led_4), .I(bar_control[4]));
  OBUF   led_5_obuf (.O(led_5), .I(bar_control[5]));
  OBUF   led_6_obuf (.O(led_6), .I(bar_control[6]));
  OBUF   led_7_obuf (.O(led_7), .I(bar_control[7]));

endmodule
