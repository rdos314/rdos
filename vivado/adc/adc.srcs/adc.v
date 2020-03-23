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
  
  wire                   spi_locked;

  wire [31:0]            rx_sync_fail_cnt;
  wire [31:0]            rx_sync_ok_cnt;

  reg [31:0]             pci_sync_fail_cnt;
  reg [31:0]             pci_sync_ok_cnt;

  wire                   rx_clk;
  wire                   tx_clk;
    
  wire                   rx_ref_clk;
  wire                   rx_sysref;
  wire                   rx_sync;

  wire                   tx_ref_clk;
  wire                   tx_ref_clk2;
  wire                   tx_sysref;
  wire                   tx_sync;

  wire                   trig;

  wire [63:0]            rx_sysref_cnt;
  reg [63:0]             pci_sysref_cnt;
  
  wire                   rx_adc_wr;
  wire [1023:0]          rx_adc_data;

  reg                    pci_rx_wr;
  reg                    pci_curr_wr;
  reg                    pci_adc_wr;
  reg [1023:0]           pci_adc_data;

  wire                   up_adc_spi_read;
  wire                   up_adc_spi_write;
  wire [11:0]            up_adc_spi_adr;
  wire [7:0]             up_adc_spi_in_data;
  wire [7:0]             up_adc_spi_out_data;
  wire                   up_adc_spi_running;
  wire                   up_adc_spi_done;

  wire [31:0]            pci_spi_rq_in;
  wire                   pci_spi_wr;

  wire                   up_spi_rq_ack;
  wire [31:0]            up_spi_rq_out;
  wire                   up_spi_rq_empty;

  wire [29:0]            up_spi_rp_in;
  wire                   up_spi_rp;

  wire                   pci_spi_rp_ack;
  wire [29:0]            pci_spi_rp_out;
  wire                   pci_spi_rp_empty;

  wire                   pci_adc_start;
  reg                    pci_up_start;
  reg [2:0]              pci_start_cnt;

  wire                   pci_adc_stop;
  reg                    pci_up_stop;
  reg [2:0]              pci_stop_cnt;

  reg                    up_pci_start;
  reg                    up_curr_start;
  reg                    up_adc_start;

  reg                    up_pci_stop;
  reg                    up_curr_stop;
  reg                    up_adc_stop;

  wire                   up_adc_started;
  reg                    pci_adc_started;

  wire                   up_adc_probing;
  reg                    pci_adc_probing;

  wire                   up_adc_running;
  reg                    pci_adc_running;

  wire [7:0]             pci_test_mode;
  reg [7:0]              up_test_mode;

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
    .clk_in1(user_clk));   // input clk_in1

daq2_app daq2_app_inst (
  .reset(user_reset),
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
  
  .adc_start(up_adc_start),
  .adc_stop(up_adc_stop),
  .adc_started(up_adc_started),
  .adc_probing(up_adc_probing),
  .adc_running(up_adc_running),
  .adc_test_mode(up_test_mode),

  .adc_sync_fail_cnt(rx_sync_fail_cnt),
  .adc_sync_ok_cnt(rx_sync_ok_cnt),
  
  .adc_wr(rx_adc_wr),
  .adc_data(rx_adc_data),
    
  .up_adc_spi_read(up_adc_spi_read),
  .up_adc_spi_write(up_adc_spi_write),
  .up_adc_spi_adr(up_adc_spi_adr),
  .up_adc_spi_in_data(up_adc_spi_in_data),
  .up_adc_spi_out_data(up_adc_spi_out_data),
  .up_adc_spi_running(up_adc_spi_running),
  .up_adc_spi_done(up_adc_spi_done)
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

    .spi_wr(pci_spi_wr),
    .spi_rq_in(pci_spi_rq_in),

    .spi_rp_empty(pci_spi_rp_empty),
    .spi_rp_data(pci_spi_rp_out),
    .spi_rp_ack(pci_spi_rp_ack),

    .bar_control(bar_control),
    .bar_adc_test_mode(pci_test_mode),

    .adc_sync_fail_cnt(pci_sync_fail_cnt),
    .adc_sync_ok_cnt(pci_sync_ok_cnt),

    .adc_start(pci_adc_start),
    .adc_stop(pci_adc_stop),
    .adc_started(pci_adc_started),
    .adc_probing(pci_adc_probing),
    .adc_running(pci_adc_running),

    .adc_sysref_cnt(pci_sysref_cnt),
    
    .adc_wr(pci_adc_wr),
    .adc_data(pci_adc_data)
);

spi_fifo_rq spi_fifo_rq_inst (
  .rst(user_reset),             // input wire rst
  .wr_clk(user_clk),            // input wire wr_clk
  .rd_clk(up_clk),              // input wire rd_clk
  .din(pci_spi_rq_in),          // input wire [31 : 0] din
  .wr_en(pci_spi_wr),           // input wire wr_en
  .rd_en(up_spi_rq_ack),        // input wire rd_en
  .dout(up_spi_rq_out),         // output wire [31 : 0] dout
  .full(),                      // output wire full
  .empty(up_spi_rq_empty)       // output wire empty
);

spi_fifo_rp spi_fifo_rp_inst (
  .rst(user_reset),             // input wire rst
  .wr_clk(up_clk),              // input wire wr_clk
  .rd_clk(user_clk),            // input wire rd_clk
  .din(up_spi_rp_in),           // input wire [29 : 0] din
  .wr_en(up_spi_rp),            // input wire wr_en
  .rd_en(pci_spi_rp_ack),       // input wire rd_en
  .dout(pci_spi_rp_out),        // output wire [29 : 0] dout
  .full(),                      // output wire full
  .empty(pci_spi_rp_empty)      // output wire empty
);

daq2_spi daq2_spi_inst (
    .spi_cs_clk (spi_csn_clk),
    .spi_cs_adc (spi_csn_adc),
    .spi_cs_dac (spi_csn_dac),
    .spi_clk (spi_clk),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir),

    .reset (user_reset),
    .up_clk (up_clk),

    .spi_rq_rd (up_spi_rq_out[31]),
    .spi_rq_cs (up_spi_rq_out[30:29]),
    .spi_rq_word (up_spi_rq_out[28]),
    .spi_rq_adr (up_spi_rq_out[27:16]),
    .spi_rq_empty (up_spi_rq_empty),
    .spi_rq_data (up_spi_rq_out[15:0]),
    .spi_rq_ack (up_spi_rq_ack),

    .adc_read(up_adc_spi_read),
    .adc_write(up_adc_spi_write),
    .adc_adr(up_adc_spi_adr),
    .adc_in_data(up_adc_spi_in_data),
    .adc_out_data(up_adc_spi_out_data),
    .adc_running(up_adc_spi_running),
    .adc_done(up_adc_spi_done),

    .spi_rp_data (up_spi_rp_in),
    .spi_rp_wr (up_spi_rp)
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


ila_3 ila3_inst (
   .clk ( user_clk ),                 // I
   .probe0(pci_adc_start),           // input wire [0:0]  probe1 
   .probe1(pci_adc_stop),            // input wire [0:0]  probe1 
   .probe2(pci_adc_started),         // input wire [0:0]  probe1 
   .probe3(pci_adc_probing),         // input wire [0:0]  probe1 
   .probe4(pci_adc_running),         // input wire [0:0]  probe1 
   .probe5(pci_test_mode),           // input wire [7:0]  probe1 
   .probe6(pci_adc_wr),              // input wire [0:0]  probe1 
   .probe7(pci_adc_data[31:0]),      // input wire [31:0]  probe1 
   .probe8(pci_adc_data[63:32]),     // input wire [31:0]  probe1 
   .probe9(pci_adc_data[95:64]),     // input wire [31:0]  probe1 
   .probe10(pci_adc_data[127:96])    // input wire [31:0]  probe1 
);


generate
  begin : adc

    always @ ( posedge user_clk ) 
    begin
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
        pci_up_start <= 0;
        pci_start_cnt <= 0;
        pci_up_stop <= 0;
        pci_stop_cnt <= 0;
      end
      else
      begin
        if (pci_adc_start)
        begin
          pci_up_start <= 1;
          pci_start_cnt <= 0;
        end
        else
        begin
          if (pci_up_start)
          begin
            if (pci_start_cnt[2] == 1)
              pci_up_start <= 0;
            else
              pci_start_cnt <= pci_start_cnt + 1;
          end
        end

        if (pci_adc_stop)
        begin
          pci_up_stop <= 1;
          pci_stop_cnt <= 0;
        end
        else
        begin
          if (pci_up_stop)
          begin
            if (pci_stop_cnt[2] == 1)
              pci_up_stop <= 0;
            else
              pci_stop_cnt <= pci_stop_cnt + 1;
          end
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      up_pci_start <= pci_up_start;
      up_pci_stop <= pci_up_stop;

      if (user_reset)
        up_test_mode <= 7;
      else
        up_test_mode <= pci_test_mode;
    end

    always @ ( posedge up_clk ) 
    begin
      if (user_reset)
      begin
        up_curr_start <= 0;
        up_adc_start <= 0;
        up_curr_stop <= 0;
        up_adc_stop <= 0;
      end
      else
      begin
        if (up_pci_start != up_curr_start)
        begin
          up_curr_start <= up_pci_start;

          if (up_pci_start)
            up_adc_start <= 1;
          else
            up_adc_start <= 0;
        end
        else
          up_adc_start <= 0;
  
        if (up_pci_stop != up_curr_stop)
        begin
          up_curr_stop <= up_pci_stop;

          if (up_pci_stop)
            up_adc_stop <= 1;
          else
            up_adc_stop <= 0;
        end
        else
          up_adc_stop <= 0;
      end
    end

    always @ ( posedge user_clk ) 
    begin
      pci_adc_started <= up_adc_started;
      pci_adc_probing <= up_adc_probing;
      pci_adc_running <= up_adc_running;
    end

    always @ ( posedge user_clk ) 
    begin
      pci_sync_ok_cnt <= rx_sync_ok_cnt;
      pci_sync_fail_cnt <= rx_sync_fail_cnt;
      pci_sysref_cnt <= rx_sysref_cnt;
    end

  end

endgenerate

endmodule
