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

  wire                 user_clk;
  wire                 user_reset;
  wire                 user_lnk_up;
  wire                 user_lnk_rate;
  wire [1:0]           user_lnk_width;
  wire                 cfg_interrupt_msienable;  
  
  wire                 spi_locked;


  wire                 rx_clk;
  wire                 tx_clk;
    
  wire                 rx_ref_clk;
  wire                 rx_sysref;
  wire                 rx_sync;

  wire                 tx_ref_clk;
  wire                 tx_ref_clk2;
  wire                 tx_sysref;
  wire                 tx_sync;

  wire                 trig;


// SPI

  wire                 adc_spi_read;
  wire                 adc_spi_write;
  wire [11:0]          adc_spi_adr;
  wire [7:0]           adc_spi_in_data;
  wire [7:0]           adc_spi_out_data;
  wire                 adc_spi_running;
  wire                 adc_spi_done;

  wire                 spi_rq;
  wire [31:0]          spi_rq_data;

  wire                 spi_rp;
  wire [29:0]          spi_rp_data;
  wire                 spi_rp_ack;

// Reset

  reg                  up_reset;
  reg [7:0]            pci_reset_cnt;

  reg                  adc_index;
  wire [63:0]          adc_phys;
  wire                 adc_valid;

  reg                  dac_index;
  wire [63:0]          dac_phys;
  wire                 dac_valid;

// ADC

  wire                 adc_start;
  wire                 adc_stop;
  wire                 adc_started;
  wire                 adc_probing;
  wire                 adc_running;
  wire                 adc_test_mode;

  wire [31:0]          rx_sync_fail_cnt;
  wire [31:0]          rx_sync_ok_cnt;
  wire [63:0]          rx_sysref_cnt;

  reg [31:0]           up_adc_sync_fail_cnt;
  reg [31:0]           up_adc_sync_ok_cnt;
  reg [63:0]           up_adc_sysref_cnt;
  
  wire                 rx_adc_wr;
  wire [1023:0]        rx_adc_data;
  reg [63:0]           up_adc_address;

  reg                  pci_rx_wr;
  reg                  pci_curr_wr;
  reg                  pci_adc_wr;
  reg [63:0]           pci_adc_address;
  reg [1023:0]         pci_adc_data;



// PCI bar

  wire [7:0]           bar_control;

  wire [9:0]           pci_bar0_rd_address;
  wire                 pci_bar0_rd;

  reg  [31:0]          pci_bar0_rp_data;
  reg                  pci_bar0_rp;

  wire [9:0]           pci_bar0_wr_address;
  wire [31:0]          pci_bar0_wr_data;
  wire [3:0]           pci_bar0_wr_be;
  wire                 pci_bar0_wr;


  wire [16:0]          pci_bar1_rd_address;
  wire                 pci_bar1_rd;

  reg  [31:0]          pci_bar1_rp_data;
  reg                  pci_bar1_rp;

  wire [16:0]          pci_bar1_wr_address;
  wire [31:0]          pci_bar1_wr_data;
  wire [3:0]           pci_bar1_wr_be;
  wire                 pci_bar1_wr;


  wire [16:0]          pci_bar2_rd_address;
  wire                 pci_bar2_rd;

  reg  [31:0]          pci_bar2_rp_data;
  reg                  pci_bar2_rp;

  wire [16:0]          pci_bar2_wr_address;
  wire [31:0]          pci_bar2_wr_data;
  wire [3:0]           pci_bar2_wr_be;
  wire                 pci_bar2_wr;


// up bar

  reg [9:0]            up_bar0_rd_address;
  reg                  up_bar0_rd;

  wire [31:0]          up_bar0_rp_data;
  wire                 up_bar0_rp;

  reg  [9:0]           up_bar0_wr_address;
  reg  [31:0]          up_bar0_wr_data;
  reg  [3:0]           up_bar0_wr_be;
  reg                  up_bar0_wr;


  reg [16:0]           up_bar1_rd_address;
  reg                  up_bar1_rd;

  wire [31:0]          up_bar1_rp_data;
  wire                 up_bar1_rp;

  reg  [16:0]          up_bar1_wr_address;
  reg  [31:0]          up_bar1_wr_data;
  reg  [3:0]           up_bar1_wr_be;
  reg                  up_bar1_wr;


  reg [16:0]           up_bar2_rd_address;
  reg                  up_bar2_rd;

  wire [31:0]          up_bar2_rp_data;
  wire                 up_bar2_rp;

  reg  [16:0]          up_bar2_wr_address;
  reg  [31:0]          up_bar2_wr_data;
  reg  [3:0]           up_bar2_wr_be;
  reg                  up_bar2_wr;

// sync bar

  reg                  curr_bar0_rd;
  reg                  pci_up_bar0_rd;
  reg [2:0]            pci_bar0_rd_cnt;
  reg                  curr_bar0_rp;
  reg                  q_bar0_rp;

  reg                  curr_bar0_wr;
  reg                  pci_up_bar0_wr;
  reg [2:0]            pci_bar0_wr_cnt;

  reg                  curr_bar1_rd;
  reg                  pci_up_bar1_rd;
  reg [2:0]            pci_bar1_rd_cnt;
  reg                  curr_bar1_rp;
  reg                  q_bar1_rp;

  reg                  curr_bar1_wr;
  reg                  pci_up_bar1_wr;
  reg [2:0]            pci_bar1_wr_cnt;

  reg                  curr_bar2_rd;
  reg                  pci_up_bar2_rd;
  reg [2:0]            pci_bar2_rd_cnt;

  reg                  curr_bar2_wr;
  reg                  pci_up_bar2_wr;
  reg [2:0]            pci_bar2_wr_cnt;
  reg                  curr_bar2_rp;
  reg                  q_bar2_rp;

  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
  IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
  BUFG   up_clk_inst (.I(sys_clk), .O(up_clk));

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

daq2_app daq2_app_inst (
    .reset(up_reset),
    .up_clk(up_clk),
    .rx_clk(rx_clk),
    .tx_clk(tx_clk),

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

    .rx_sysref_cnt(rx_sysref_cnt),
  
    .adc_start(adc_start),
    .adc_stop(adc_stop),
    .adc_started(adc_started),
    .adc_probing(adc_probing),
    .adc_running(adc_running),
    .adc_test_mode(adc_test_mode),

    .adc_sync_fail_cnt(rx_sync_fail_cnt),
    .adc_sync_ok_cnt(rx_sync_ok_cnt),
  
    .adc_wr(rx_adc_wr),
    .adc_data(rx_adc_data),
    
    .up_adc_spi_read(adc_spi_read),
    .up_adc_spi_write(adc_spi_write),
    .up_adc_spi_adr(adc_spi_adr),
    .up_adc_spi_in_data(adc_spi_in_data),
    .up_adc_spi_out_data(adc_spi_out_data),
    .up_adc_spi_running(adc_spi_running),
    .up_adc_spi_done(adc_spi_done)
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

    .bar0_rd_address(pci_bar0_rd_address),
    .bar0_rd(pci_bar0_rd),
    .bar0_rp_data(pci_bar0_rp_data),
    .bar0_rp(pci_bar0_rp),
    .bar0_wr_address(pci_bar0_wr_address),
    .bar0_wr_data(pci_bar0_wr_data),
    .bar0_wr_be(pci_bar0_wr_be),
    .bar0_wr(pci_bar0_wr),

    .bar1_rd_address(pci_bar1_rd_address),
    .bar1_rd(pci_bar1_rd),
    .bar1_rp_data(pci_bar1_rp_data),
    .bar1_rp(pci_bar1_rp),
    .bar1_wr_address(pci_bar1_wr_address),
    .bar1_wr_data(pci_bar1_wr_data),
    .bar1_wr_be(pci_bar1_wr_be),
    .bar1_wr(pci_bar1_wr),

    .bar2_rd_address(pci_bar2_rd_address),
    .bar2_rd(pci_bar2_rd),
    .bar2_rp_data(pci_bar2_rp_data),
    .bar2_rp(pci_bar2_rp),
    .bar2_wr_address(pci_bar2_wr_address),
    .bar2_wr_data(pci_bar2_wr_data),
    .bar2_wr_be(pci_bar2_wr_be),
    .bar2_wr(pci_bar2_wr),
    
    .adc_send(pci_adc_wr),
    .adc_address(pci_adc_address),
    .adc_data(pci_adc_data)
);

daq2_spi daq2_spi_inst (
    .spi_cs_clk (spi_csn_clk),
    .spi_cs_adc (spi_csn_adc),
    .spi_cs_dac (spi_csn_dac),
    .spi_clk (spi_clk),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir),

    .reset (up_reset),
    .up_clk (up_clk),

    .spi_rq (spi_rq),
    .spi_rq_data (spi_rq_data),

    .spi_rp (spi_rp),
    .spi_rp_data (spi_rp_data),
    .spi_rp_ack (spi_rp_ack),

    .adc_read(adc_spi_read),
    .adc_write(adc_spi_write),
    .adc_adr(adc_spi_adr),
    .adc_in_data(adc_spi_in_data),
    .adc_out_data(adc_spi_out_data),
    .adc_running(adc_spi_running),
    .adc_done(adc_spi_done)
);

control_bar control_bar_inst (
    .up_reset(up_reset),
    .up_clk(up_clk),

    .rd_address(up_bar0_rd_address),
    .rd(up_bar0_rd),
    .rp_data(up_bar0_rp_data),
    .rp(up_bar0_rp),

    .wr_address(up_bar0_wr_address),
    .wr_data(up_bar0_wr_data),
    .wr_be(up_bar0_wr_be),
    .wr(up_bar0_wr),

    .spi_rq (spi_rq),
    .spi_rq_data (spi_rq_data),

    .spi_rp (spi_rp),
    .spi_rp_data (spi_rp_data),
    .spi_rp_ack (spi_rp_ack),

    .adc_address(up_adc_address),
    .adc_sysref_cnt(up_adc_sysref_cnt),
    .adc_sync_fail_cnt(up_adc_sync_fail_cnt),
    .adc_sync_ok_cnt(up_adc_sync_ok_cnt),

    .adc_started(adc_started),
    .adc_probing(adc_probing),
    .adc_running(adc_running),

    .adc_start(adc_start),
    .adc_stop(adc_stop),
    .adc_test_mode(adc_test_mode),

    .state(bar_control)
);


phys_bar adc_bar_inst (
    .up_clk(up_clk),
    .up_reset(up_reset),

    .rd_address(up_bar1_rd_address),
    .rd(up_bar1_rd),
    .rp_data(up_bar1_rp_data),
    .rp(up_bar1_rp),

    .wr_address(up_bar1_wr_address),
    .wr_data(up_bar1_wr_data),
    .wr_be(up_bar1_wr_be),
    .wr(up_bar1_wr),

    .index(adc_index),
    .phys(adc_phys),
    .valid(adc_valid)
);

phys_bar dac_bar_inst (
    .up_clk(up_clk),
    .up_reset(up_reset),

    .rd_address(up_bar2_rd_address),
    .rd(up_bar2_rd),
    .rp_data(up_bar2_rp_data),
    .rp(up_bar2_rp),

    .wr_address(up_bar2_wr_address),
    .wr_data(up_bar2_wr_data),
    .wr_be(up_bar2_wr_be),
    .wr(up_bar2_wr),

    .index(dac_index),
    .phys(dac_phys),
    .valid(dac_valid)
);


 //-----------------------------I/O BUFFERS------------------------//


  OBUF   led_0_obuf (.O(led_0), .I(bar_control[0]));
  OBUF   led_1_obuf (.O(led_1), .I(bar_control[1]));
  OBUF   led_2_obuf (.O(led_2), .I(bar_control[2]));
  OBUF   led_3_obuf (.O(led_3), .I(bar_control[3]));
  OBUF   led_4_obuf (.O(led_4), .I(bar_control[4]));
  OBUF   led_5_obuf (.O(led_5), .I(bar_control[5]));
  OBUF   led_6_obuf (.O(led_6), .I(bar_control[6]));
  OBUF   led_7_obuf (.O(led_7), .I(bar_control[7]));

generate
  begin : adc

    always @ ( posedge user_clk ) 
    begin
      if (pci_bar0_rd)
      begin
        up_bar0_rd_address <= pci_bar0_rd_address;
        pci_up_bar0_rd <= 1;
        pci_bar0_rd_cnt <= 0;
      end
      else
      begin
        if (pci_up_bar0_rd)
        begin
          if (pci_bar0_rd_cnt[2])
            pci_up_bar0_rd <= 0;
          else
            pci_bar0_rd_cnt <= pci_bar0_rd_cnt + 1;
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      if (pci_up_bar0_rd != curr_bar0_rd)
      begin
        curr_bar0_rd <= pci_up_bar0_rd;
        up_bar0_rd <= pci_up_bar0_rd;
      end
      else
        up_bar0_rd <= 0;
    end

    always @ ( posedge user_clk ) 
    begin
      if (pci_bar1_rd)
      begin
        up_bar1_rd_address <= pci_bar1_rd_address;
        pci_up_bar1_rd <= 1;
        pci_bar1_rd_cnt <= 0;
      end
      else
      begin
        if (pci_up_bar1_rd)
        begin
          if (pci_bar1_rd_cnt[2])
            pci_up_bar1_rd <= 0;
          else
            pci_bar1_rd_cnt <= pci_bar1_rd_cnt + 1;
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      if (pci_up_bar1_rd != curr_bar1_rd)
      begin
        curr_bar1_rd <= pci_up_bar1_rd;
        up_bar1_rd <= pci_up_bar1_rd;
      end
      else
        up_bar1_rd <= 0;
    end


    always @ ( posedge user_clk ) 
    begin
      if (pci_bar2_rd)
      begin
        up_bar2_rd_address <= pci_bar2_rd_address;
        pci_up_bar2_rd <= 1;
        pci_bar2_rd_cnt <= 0;
      end
      else
      begin
        if (pci_up_bar2_rd)
        begin
          if (pci_bar2_rd_cnt[2])
            pci_up_bar2_rd <= 0;
          else
            pci_bar2_rd_cnt <= pci_bar2_rd_cnt + 1;
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      if (pci_up_bar2_rd != curr_bar2_rd)
      begin
        curr_bar2_rd <= pci_up_bar2_rd;
        up_bar2_rd <= pci_up_bar2_rd;
      end
      else
        up_bar2_rd <= 0;
    end


    always @ ( posedge user_clk ) 
    begin
      if (pci_bar0_wr)
      begin
        up_bar0_wr_address <= pci_bar0_wr_address;
        up_bar0_wr_data <= pci_bar0_wr_data;
        up_bar0_wr_be <= pci_bar0_wr_be;
        pci_up_bar0_wr <= 1;
        pci_bar0_wr_cnt <= 0;
      end
      else
      begin
        if (pci_up_bar0_wr)
        begin
          if (pci_bar0_wr_cnt[2])
            pci_up_bar0_wr <= 0;
          else
            pci_bar0_wr_cnt <= pci_bar0_wr_cnt + 1;
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      if (pci_up_bar0_wr != curr_bar0_wr)
      begin
        curr_bar0_wr <= pci_up_bar0_wr;
        up_bar0_wr <= pci_up_bar0_wr;
      end
      else
        up_bar0_wr <= 0;
    end


    always @ ( posedge user_clk ) 
    begin
      if (pci_bar1_wr)
      begin
        up_bar1_wr_address <= pci_bar1_wr_address;
        up_bar1_wr_data <= pci_bar1_wr_data;
        up_bar1_wr_be <= pci_bar1_wr_be;
        pci_up_bar1_wr <= 1;
        pci_bar1_wr_cnt <= 0;
      end
      else
      begin
        if (pci_up_bar1_wr)
        begin
          if (pci_bar1_wr_cnt[2])
            pci_up_bar1_wr <= 0;
          else
            pci_bar1_wr_cnt <= pci_bar1_wr_cnt + 1;
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      if (pci_up_bar1_wr != curr_bar1_wr)
      begin
        curr_bar1_wr <= pci_up_bar1_wr;
        up_bar1_wr <= pci_up_bar1_wr;
      end
      else
        up_bar1_wr <= 0;
    end


    always @ ( posedge user_clk ) 
    begin
      if (pci_bar2_wr)
      begin
        up_bar2_wr_address <= pci_bar2_wr_address;
        up_bar2_wr_data <= pci_bar2_wr_data;
        up_bar2_wr_be <= pci_bar2_wr_be;
        pci_up_bar2_wr <= 1;
        pci_bar2_wr_cnt <= 0;
      end
      else
      begin
        if (pci_up_bar2_wr)
        begin
          if (pci_bar2_wr_cnt[2])
            pci_up_bar2_wr <= 0;
          else
            pci_bar2_wr_cnt <= pci_bar2_wr_cnt + 1;
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      if (pci_up_bar2_wr != curr_bar2_wr)
      begin
        curr_bar2_wr <= pci_up_bar2_wr;
        up_bar2_wr <= pci_up_bar2_wr;
      end
      else
        up_bar2_wr <= 0;
    end

    always @ ( posedge user_clk ) 
    begin
      pci_adc_address <= up_adc_address;
      pci_adc_data <= rx_adc_data;
      pci_rx_wr <= rx_adc_wr;
    end

    always @ ( posedge user_clk ) 
    begin
      if (user_reset)
      begin
        pci_curr_wr <= 0;
        pci_adc_wr <= 0;
      end
      else
      begin
        if (pci_rx_wr != pci_curr_wr)
        begin
          pci_curr_wr <= pci_rx_wr;

          if (pci_rx_wr)
            pci_adc_wr <= 1;
          else
            pci_adc_wr <= 0;
        end
        else
          pci_adc_wr <= 0;
      end
    end


    always @(posedge user_clk) 
    begin
      if (user_reset)
      begin
        up_reset <= 1;
        pci_reset_cnt <= 0;
      end
      else
      begin
        if (pci_reset_cnt[7] == 1)
          up_reset <= 0;
        else
          pci_reset_cnt <= pci_reset_cnt + 1;
      end
    end


    always @ ( posedge up_clk ) 
    begin
      up_adc_sync_ok_cnt <= rx_sync_ok_cnt;
      up_adc_sync_fail_cnt <= rx_sync_fail_cnt;
      up_adc_sysref_cnt <= rx_sysref_cnt;
    end


    always @(posedge user_clk) 
    begin
      if (user_reset)
      begin
        pci_bar0_rp <= 0;
        pci_bar0_rp_data <= 0;
        q_bar0_rp <= 0;
        curr_bar0_rp <= 0;
      end
      else
      begin
        if (q_bar0_rp)
        begin
          pci_bar0_rp_data <= up_bar0_rp_data;
          pci_bar0_rp <= 1;
          q_bar0_rp <= 0;
        end
        else
        begin
          pci_bar0_rp <= 0;

          if (up_bar0_rp != curr_bar0_rp)
          begin
            curr_bar0_rp <= up_bar0_rp;

            if (up_bar0_rp)
              q_bar0_rp <= 1;
          end
        end
      end
    end


    always @(posedge user_clk) 
    begin
      if (user_reset)
      begin
        pci_bar1_rp <= 0;
        pci_bar1_rp_data <= 0;
        q_bar1_rp <= 0;
        curr_bar1_rp <= 0;
      end
      else
      begin
        if (q_bar1_rp)
        begin
          pci_bar1_rp_data <= up_bar1_rp_data;
          pci_bar1_rp <= 1;
          q_bar1_rp <= 0;
        end
        else
        begin
          pci_bar1_rp <= 0;

          if (up_bar1_rp != curr_bar1_rp)
          begin
            curr_bar1_rp <= up_bar1_rp;

            if (up_bar1_rp)
              q_bar1_rp <= 1;
          end
        end
      end
    end


    always @(posedge user_clk) 
    begin
      if (user_reset)
      begin
        pci_bar2_rp <= 0;
        pci_bar2_rp_data <= 0;
        q_bar2_rp <= 0;
        curr_bar2_rp <= 0;
      end
      else
      begin
        if (q_bar2_rp)
        begin
          pci_bar2_rp_data <= up_bar2_rp_data;
          pci_bar2_rp <= 1;
          q_bar2_rp <= 0;
        end
        else
        begin
          pci_bar2_rp <= 0;

          if (up_bar2_rp != curr_bar2_rp)
          begin
            curr_bar2_rp <= up_bar2_rp;

            if (up_bar2_rp)
              q_bar2_rp <= 1;
          end
        end
      end
    end

  end

endgenerate

endmodule
