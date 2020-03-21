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
  output  [7:0]           pci_exp_txp,
  output  [7:0]           pci_exp_txn,
  input   [7:0]           pci_exp_rxp,
  input   [7:0]           pci_exp_rxn,

  output                  led_0,
  output                  led_1,
  output                  led_2,
  output                  led_3,
  output                  led_4,
  output                  led_5,
  output                  led_6,
  output                  led_7,

  input                   sys_clk_p,
  input                   sys_clk_n,
  input                   sys_rst_n,

  input                   rx_ref_clk_p,
  input                   rx_ref_clk_n,
  input                   rx_sysref_p,
  input                   rx_sysref_n,
  output                  rx_sync_p,
  output                  rx_sync_n,
  input       [ 3:0]      rx_data_p,
  input       [ 3:0]      rx_data_n,

  input                   tx_ref_clk_p,
  input                   tx_ref_clk_n,
  input                   tx_sysref_p,
  input                   tx_sysref_n,
  input                   tx_sync_p,
  input                   tx_sync_n,
//  output      [ 3:0]      tx_data_p,
//  output      [ 3:0]      tx_data_n,

  input                   trig_p,
  input                   trig_n,

  inout                   adc_fdb,
  inout                   adc_fda,
  inout                   dac_irq,
  inout       [ 1:0]      clkd_status,

  inout                   adc_pd,
  inout                   dac_txen,
  inout                   dac_reset,
  inout                   clkd_sync,

  output                  spi_csn_clk,
  output                  spi_csn_dac,
  output                  spi_csn_adc,
  output                  spi_clk,
  inout                   spi_sdio,
  output                  spi_dir
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
  wire [7:0]             bar_control;
  wire [7:0]             bar_adc_test_mode;
  
  wire                   spi_locked;

  wire                   adc_start;
  wire                   adc_stop;
  wire                   adc_running;
  wire [31:0]            adc_sync_fail_cnt;
  wire [31:0]            adc_sync_ok_cnt;
    
  wire                   rx_ref_clk;
  wire                   rx_sysref;
  wire                   rx_sync;

  wire                   tx_ref_clk;
  wire                   tx_ref_clk2;
  wire                   tx_sysref;
  wire                   tx_sync;

  wire                   trig;

  wire                   rx_valid;
  wire [63:0]            rx_sysref_cnt;
  
  wire                   adc_wr;
  wire [1023:0]          adc_data;

  wire                   adc_spi_read;
  wire                   adc_spi_write;
  wire [11:0]            adc_spi_adr;
  wire [7:0]             adc_spi_in_data;
  wire [7:0]             adc_spi_out_data;
  wire                   adc_spi_running;
  wire                   adc_spi_done;

  IBUFDS_GTE2 i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (rx_ref_clk_p),
    .IB (rx_ref_clk_n),
    .O (rx_ref_clk),
    .ODIV2 ());

  IBUFDS i_ibufds_rx_sysref (
    .I (rx_sysref_p),
    .IB (rx_sysref_n),
    .O (rx_sysref));

  OBUFDS i_obufds_rx_sync (
    .I (rx_sync),
    .O (rx_sync_p),
    .OB (rx_sync_n));

  IBUFDS_GTE2 i_ibufds_tx_ref_clk (
    .CEB (1'd0),
    .I (tx_ref_clk_p),
    .IB (tx_ref_clk_n),
    .O (tx_ref_clk),
    .ODIV2 ());

  IBUFDS i_ibufds_tx_sysref (
    .I (tx_sysref_p),
    .IB (tx_sysref_n),
    .O (tx_sysref));

  IBUFDS i_ibufds_tx_sync (
    .I (tx_sync_p),
    .IB (tx_sync_n),
    .O (tx_sync));

  IBUFDS i_ibufds_trig (
    .I (trig_p),
    .IB (trig_n),
    .O (trig));

up_clk up_clk_inst
   (
    .clk_out1(up_clk),     // output clk_out1
    .clk_in1(user_clk));      // input clk_in1


daq2_app daq2_app_inst (
  .clk(user_clk),
  .up_clk(up_clk),
  .reset(user_reset),

  .rx_ref_clk(rx_ref_clk),
  .rx_sysref(rx_sysref),
  .rx_sync(rx_sync),
  .rx_data_p(rx_data_p),
  .rx_data_n(rx_data_n),

  .tx_ref_clk(tx_ref_clk),
  .tx_sysref(tx_sysref),
  .tx_sync(tx_sync),
  .tx_data_p(tx_data_p),
  .tx_data_n(tx_data_n),

  .trig(trig),

  .adc_fdb(adc_fdb),
  .adc_fda(adc_fda),
  .dac_irq(dac_irq),
  .clkd_status(clkd_status),

  .adc_pd(adc_pd),
  .dac_txen(dac_txen),
  .dac_reset(dac_reset),
  .clkd_sync(clkd_sync),

  .rx_valid(rx_valid),
  .rx_sysref_cnt(rx_sysref_cnt),
  
  .adc_start(adc_start),
  .adc_stop(adc_stop),
  .adc_running(adc_running),
  .adc_test_mode(bar_adc_test_mode),

  .adc_sync_fail_cnt(adc_sync_fail_cnt),
  .adc_sync_ok_cnt(adc_sync_ok_cnt),
  
  .adc_wr(adc_wr),
  .adc_data(adc_data),
    
  .adc_spi_read(adc_spi_read),
  .adc_spi_write(adc_spi_write),
  .adc_spi_adr(adc_spi_adr),
  .adc_spi_in_data(adc_spi_in_data),
  .adc_spi_out_data(adc_spi_out_data),
  .adc_spi_running(adc_spi_running),
  .adc_spi_done(adc_spi_done)
);

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

    .up_clk (up_clk),
    .spi_cs_clk (spi_csn_clk),
    .spi_cs_adc (spi_csn_adc),
    .spi_cs_dac (spi_csn_dac),
    .spi_clk (spi_clk),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir),

    .bar_control(bar_control),
    .bar_adc_test_mode(bar_adc_test_mode),

    .adc_sync_fail_cnt(adc_sync_fail_cnt),
    .adc_sync_ok_cnt(adc_sync_ok_cnt),

    .adc_start(adc_start),
    .adc_stop(adc_stop),
    .adc_running(adc_running),
    .adc_valid(rx_valid),
    .adc_sysref_cnt(rx_sysref_cnt),
    
    .adc_wr(adc_wr),
    .adc_data(adc_data),
    
    .adc_spi_read(adc_spi_read),
    .adc_spi_write(adc_spi_write),
    .adc_spi_adr(adc_spi_adr),
    .adc_spi_in_data(adc_spi_in_data),
    .adc_spi_out_data(adc_spi_out_data),
    .adc_spi_running(adc_spi_running),
    .adc_spi_done(adc_spi_done)
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
