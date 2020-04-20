////////////////////////////////////////////////////////////////////////////////
// RDOS operating system
// Copyright (C) 1988-2020, Leif Ekblad
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version. The only exception to this rule
// is for commercial usage in embedded systems. For information on
// usage in commercial embedded systems, contact embedded@rdos.net
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// The author of this program may be contacted at leif@rdos.net
//
// adc.v
// Top-level DAQ2 module
//
////////////////////////////////////////////////////////////////////////////////

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

  input                   pci_ref_clk_p,
  input                   pci_ref_clk_n,
  input                   pci_rst_n,

  input                   sys_clk_p,
  input                   sys_clk_n,

  input                   user_clk_p,
  input                   user_clk_n,

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
  output      [ 3:0]      tx_data_p,
  output      [ 3:0]      tx_data_n,

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
  wire                 sys_clk;

  wire                 pcie_ref_clk;
  wire                 pcie_reset_n;
  wire                 pcie_user_clk;
  wire                 pcie_user_reset;

  wire                 pcie_user_lnk_up;
  wire                 pcie_user_lnk_rate;
  wire [1:0]           pcie_user_lnk_width;
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

  reg [7:0]            pci_reset_cnt;


// ADC

  wire                 rx_adc_wr;
  wire [1023:0]        rx_adc_data;

  wire                 pci_adc_bar_irq;
  wire                 pci_adc_block_irq;

  wire                 adc_full;

  wire [127:0]         pci_adc_header;
  wire [1023:0]        pci_adc_data;
  wire                 pci_adc_wr;
  wire                 pci_adc_ack;

  wire [15:0]          pci_adc_phys_index;

  wire                 up_adc_started;
  wire                 up_adc_probing;
  wire                 up_adc_running;

  wire                 rx_adc_sync_ok;
  wire                 rx_adc_sync_fail;

  wire [2:0]           adc_state;

  wire                 adc_up_rstn;
  wire                 adc_qpll_rst;
  wire                 adc_rst;
  wire                 adc_user_ready;

  wire [3:0]           adc_pll_locked;
  wire [3:0]           adc_rst_done;

  wire [63:0]          rx_sysref_cnt;

  
// PCI bar

  wire [9:0]           pci_bar0_rd_address;
  wire                 pci_bar0_rd;

  wire [31:0]          pci_bar0_rp_data;
  wire                 pci_bar0_rp;

  wire [9:0]           pci_bar0_wr_address;
  wire [31:0]          pci_bar0_wr_data;
  wire [3:0]           pci_bar0_wr_be;
  wire                 pci_bar0_wr;


  wire [16:0]          pci_bar1_rd_address;
  wire                 pci_bar1_rd;

  wire [31:0]          pci_bar1_rp_data;
  wire                 pci_bar1_rp;

  wire [16:0]          pci_bar1_wr_address;
  wire [31:0]          pci_bar1_wr_data;
  wire [3:0]           pci_bar1_wr_be;
  wire                 pci_bar1_wr;


  wire [16:0]          pci_bar2_rd_address;
  wire                 pci_bar2_rd;

  wire [31:0]          pci_bar2_rp_data;
  wire                 pci_bar2_rp;

  wire [16:0]          pci_bar2_wr_address;
  wire [31:0]          pci_bar2_wr_data;
  wire [3:0]           pci_bar2_wr_be;
  wire                 pci_bar2_wr;

// sys module

  wire                 tx_pci_control_msg;
  wire [7:0]           tx_pci_control_index;
  wire [7:0]           tx_pci_control_data;
  reg                  rx_up_control_msg_3;
  reg                  rx_up_control_msg;
  reg  [7:0]           rx_up_control_index;
  reg  [7:0]           rx_up_control_data;


  wire                 tx_up_control_msg;
  wire [7:0]           tx_up_control_index;
  wire [7:0]           tx_up_control_data;
  reg                  rx_pci_control_msg_3;
  reg                  rx_pci_control_msg;
  reg  [7:0]           rx_pci_control_index;
  reg  [7:0]           rx_pci_control_data;

// LED

  reg [31:0]           sys_cnt;
  reg [31:0]           user_cnt;
  reg [31:0]           pcie_cnt;
  reg [31:0]           rx_cnt;

  reg                  sys_led;
  reg                  user_led;
  reg                  pcie_led;
  reg                  rx_led;


// clock domain crossings

 (* ASYNC_REG="TRUE" *)  reg [63:0]           adc_sysref_cnt_1;
 (* ASYNC_REG="TRUE" *)  reg [63:0]           pci_adc_sysref_cnt;

 (* ASYNC_REG="TRUE" *)  reg                  up_reset_1;
 (* ASYNC_REG="TRUE" *)  reg                  up_reset;

 (* ASYNC_REG="TRUE" *)  reg                  rx_up_control_msg_1;
 (* ASYNC_REG="TRUE" *)  reg                  rx_up_control_msg_2;

 (* ASYNC_REG="TRUE" *)  reg                  rx_pci_control_msg_1;
 (* ASYNC_REG="TRUE" *)  reg                  rx_pci_control_msg_2;

 (* ASYNC_REG="TRUE" *)  reg                  adc_started_1;
 (* ASYNC_REG="TRUE" *)  reg                  rx_adc_started;

 (* ASYNC_REG="TRUE" *)  reg                  adc_probing_1;
 (* ASYNC_REG="TRUE" *)  reg                  rx_adc_probing;

 (* ASYNC_REG="TRUE" *)  reg                  adc_running_1;
 (* ASYNC_REG="TRUE" *)  reg                  rx_adc_running;

 (* ASYNC_REG="TRUE" *)  reg                  adc_sync_ok_1;
 (* ASYNC_REG="TRUE" *)  reg                  up_adc_sync_ok;

 (* ASYNC_REG="TRUE" *)  reg                  adc_sync_fail_1;
 (* ASYNC_REG="TRUE" *)  reg                  up_adc_sync_fail;

  IBUF   pci_reset_n_ibuf (.O(pcie_rst_n), .I(pci_rst_n));
  IBUFDS_GTE2 pci_refclk_ibuf (.O(pcie_ref_clk), .ODIV2(), .I(pci_ref_clk_p), .CEB(1'b0), .IB(pci_ref_clk_n));

  IBUFDS IBUFDS_inst_user_clock(
	.O(user_clk), // Buffer output
	.I(user_clk_p), // Diff_p buffer input (connect directly to top-level port)
	.IB(user_clk_n) // Diff_n buffer input (connect directly to top-level port)
);

  IBUFDS IBUFDS_inst_sys_clock(
	.O(sys_clk), // Buffer output
	.I(sys_clk_p), // Diff_p buffer input (connect directly to top-level port)
	.IB(sys_clk_n) // Diff_n buffer input (connect directly to top-level port)
);

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

clk_up clk_up_inst
   (
   .clk_out1(up_clk),
   .clk_in1(sys_clk)
); 

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

    .adc_up_rstn(adc_up_rstn),
    .adc_qpll_rst(adc_qpll_rst),

    .adc_rst(adc_rst),
    .adc_user_ready(adc_user_ready),
    .adc_pll_locked(adc_pll_locked),
    .adc_rst_done(adc_rst_done),

    .adc_started(rx_adc_started),    
    .adc_probing(rx_adc_probing),    
    .adc_running(rx_adc_running),    

    .adc_sync_ok(rx_adc_sync_ok),    
    .adc_sync_fail(rx_adc_sync_fail),    

    .rx_sysref_cnt(rx_sysref_cnt),
  
    .adc_wr(rx_adc_wr),
    .adc_data(rx_adc_data)
);

pci_app pci_app_inst (
    .pci_exp_txp(pci_exp_txp),
    .pci_exp_txn(pci_exp_txn),
    .pci_exp_rxp(pci_exp_rxp),
    .pci_exp_rxn(pci_exp_rxn),

    .sys_clk(pcie_ref_clk),
    .sys_rst_n(pcie_rst_n),
    
    .user_clk(pcie_user_clk),
    .user_reset(pcie_user_reset),
    .user_lnk_up(pcie_user_lnk_up),
    .user_lnk_rate(pcie_user_lnk_rate),
    .user_lnk_width(pcie_user_lnk_width),
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

    .adc_full(adc_full),
    .adc_bar_irq(pci_adc_bar_irq),
    .adc_block_irq(pci_adc_block_irq),    
    .adc_header(pci_adc_header),
    .adc_data(pci_adc_data),
    .adc_wr(pci_adc_wr),
    .adc_ack(pci_adc_ack)
);

daq2_spi daq2_spi_inst (
    .spi_cs_clk (spi_csn_clk),
    .spi_cs_adc (spi_csn_adc),
    .spi_cs_dac (spi_csn_dac),
    .spi_clk (spi_clk),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir),

    .reset (up_reset),
    .clk (up_clk),
    .pci_clk (pcie_user_clk),

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
    .reset(pcie_user_reset),
    .clk(pcie_user_clk),

    .rd_address(pci_bar0_rd_address),
    .rd(pci_bar0_rd),
    .rp_data(pci_bar0_rp_data),
    .rp(pci_bar0_rp),

    .wr_address(pci_bar0_wr_address),
    .wr_data(pci_bar0_wr_data),
    .wr_be(pci_bar0_wr_be),
    .wr(pci_bar0_wr),

    .spi_rq (spi_rq),
    .spi_rq_data (spi_rq_data),

    .spi_rp (spi_rp),
    .spi_rp_data (spi_rp_data),
    .spi_rp_ack (spi_rp_ack),

    .adc_sysref_cnt(pci_adc_sysref_cnt),
    .adc_phys_index(pci_adc_phys_index),
    
    .tx_control_msg(tx_pci_control_msg),
    .tx_control_index(tx_pci_control_index),
    .tx_control_data(tx_pci_control_data),
    
    .rx_control_msg(rx_pci_control_msg),
    .rx_control_index(rx_pci_control_index),
    .rx_control_data(rx_pci_control_data)
);

phys_bar dac_bar_inst (
    .clk(pcie_user_clk),
    .reset(pcie_user_reset),

    .rd_address(pci_bar2_rd_address),
    .rd(pci_bar2_rd),
    .rp_data(pci_bar2_rp_data),
    .rp(pci_bar2_rp),

    .wr_address(pci_bar2_wr_address),
    .wr_data(pci_bar2_wr_data),
    .wr_be(pci_bar2_wr_be),
    .wr(pci_bar2_wr),

    .index(0),
    .page(),
    .valid()
);

adc_app adc_app_inst (
    .rx_clk (rx_clk),
    .pci_reset (pcie_user_reset),
    .pci_clk (pcie_user_clk),
    .up_reset (up_reset),
    .up_clk (up_clk),

    .spi_read(adc_spi_read),
    .spi_write(adc_spi_write),
    .spi_adr(adc_spi_adr),
    .spi_in_data(adc_spi_in_data),
    .spi_out_data(adc_spi_out_data),
    .spi_running(adc_spi_running),
    .spi_done(adc_spi_done),

    .bar_rd_address(pci_bar1_rd_address),
    .bar_rd(pci_bar1_rd),
    .bar_rp_data(pci_bar1_rp_data),
    .bar_rp(pci_bar1_rp),
    .bar_wr_address(pci_bar1_wr_address),
    .bar_wr_data(pci_bar1_wr_data),
    .bar_wr_be(pci_bar1_wr_be),
    .bar_wr(pci_bar1_wr),

    .rx_control_msg(rx_up_control_msg),
    .rx_control_index(rx_up_control_index),
    .rx_control_data(rx_up_control_data),

    .tx_control_msg(tx_up_control_msg),
    .tx_control_index(tx_up_control_index),
    .tx_control_data(tx_up_control_data),

    .up_rstn(adc_up_rstn),
    .qpll_rst(adc_qpll_rst),

    .adc_rst(adc_rst),
    .adc_user_ready(adc_user_ready),
    .adc_pll_locked(adc_pll_locked),
    .adc_rst_done(adc_rst_done),

    .adc_started(up_adc_started),
    .adc_probing(up_adc_probing),
    .adc_running(up_adc_running),

    .adc_sync_ok(up_adc_sync_ok),
    .adc_sync_fail(up_adc_sync_fail),

    .bar_irq(pci_adc_bar_irq),
    .block_irq(pci_adc_block_irq),
    .phys_index(pci_adc_phys_index),

    .adc_in(rx_adc_wr),
    .adc_in_data(rx_adc_data),

    .adc_full(adc_full),
    .adc_out(pci_adc_wr),
    .adc_out_ack(pci_adc_ack),
    .adc_out_header(pci_adc_header),
    .adc_out_data(pci_adc_data),

    .state(adc_state)
);

 //-----------------------------I/O BUFFERS------------------------//


  OBUF   led_0_obuf (.O(led_0), .I(pcie_led));
  OBUF   led_1_obuf (.O(led_1), .I(user_led));
  OBUF   led_2_obuf (.O(led_2), .I(sys_led));
  OBUF   led_3_obuf (.O(led_3), .I(rx_led));
  OBUF   led_4_obuf (.O(led_4), .I(rx_adc_sync_ok));
  OBUF   led_5_obuf (.O(led_5), .I(adc_state[0]));
  OBUF   led_6_obuf (.O(led_6), .I(adc_state[1]));
  OBUF   led_7_obuf (.O(led_7), .I(adc_state[2]));


generate
  begin : adc

    always @ ( posedge pcie_ref_clk ) 
    begin
      if (pcie_cnt == 50000000)
      begin
        pcie_led <= !pcie_led;
        pcie_cnt <= 0;
      end
      else
        pcie_cnt <= pcie_cnt + 1;
    end

    always @ ( posedge user_clk ) 
    begin
      if (user_cnt == 78125000)
      begin
        user_led <= !user_led;
        user_cnt <= 0;
      end
      else
        user_cnt <= user_cnt + 1;
    end

    always @ ( posedge sys_clk ) 
    begin
      if (sys_cnt == 100000000)
      begin
        sys_led <= !sys_led;
        sys_cnt <= 0;
      end
      else
        sys_cnt <= sys_cnt + 1;
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_cnt == 93750000)
      begin
        rx_led <= !rx_led;
        rx_cnt <= 0;
      end
      else
        rx_cnt <= rx_cnt + 1;
    end

    always @ ( posedge pcie_user_clk ) 
    begin
      adc_sysref_cnt_1 <= rx_sysref_cnt;
      pci_adc_sysref_cnt <= adc_sysref_cnt_1;
    end
    
    always @ ( posedge up_clk ) 
    begin
      up_reset_1 <= pcie_user_reset;
      up_reset <= up_reset_1;
    end

    always @ ( posedge rx_clk ) 
    begin
      adc_started_1 <= up_adc_started;
      rx_adc_started <= adc_started_1;
    end

    always @ ( posedge rx_clk ) 
    begin
      adc_probing_1 <= up_adc_probing;
      rx_adc_probing <= adc_probing_1;
    end

    always @ ( posedge rx_clk ) 
    begin
      adc_running_1 <= up_adc_running;
      rx_adc_running <= adc_running_1;
    end

    always @ ( posedge up_clk ) 
    begin
      adc_sync_ok_1 <= rx_adc_sync_ok;
      up_adc_sync_ok <= adc_sync_ok_1;
    end

    always @ ( posedge up_clk ) 
    begin
      adc_sync_fail_1 <= rx_adc_sync_fail;
      up_adc_sync_fail <= adc_sync_fail_1;
    end

    always @ ( posedge up_clk ) 
    begin
      rx_up_control_msg_1 <= tx_pci_control_msg;
      rx_up_control_msg_2 <= rx_up_control_msg_1;
      rx_up_control_msg_3 <= rx_up_control_msg_2;
      
      if (!rx_up_control_msg_3 && rx_up_control_msg_2)
      begin
        rx_up_control_msg <= 1;
        rx_up_control_index <= tx_pci_control_index;
        rx_up_control_data <= tx_pci_control_data;
      end
      else
        rx_up_control_msg <= 0;
    end

    always @ ( posedge pcie_user_clk ) 
    begin
      rx_pci_control_msg_1 <= tx_up_control_msg;
      rx_pci_control_msg_2 <= rx_pci_control_msg_1;
      rx_pci_control_msg_3 <= rx_pci_control_msg_2;
      
      if (!rx_pci_control_msg_3 && rx_pci_control_msg_2)
      begin
        rx_pci_control_msg <= 1;
        rx_pci_control_index <= tx_up_control_index;
        rx_pci_control_data <= tx_up_control_data;
      end
      else
        rx_pci_control_msg <= 0;
    end


  end

endgenerate
endmodule
