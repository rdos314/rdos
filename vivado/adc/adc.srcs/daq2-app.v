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
// daq2.v
// DAQ2 main module
//
////////////////////////////////////////////////////////////////////////////////

module daq2_app
(
  input                   reset,

  input                   up_clk,
  output                  rx_clk,
  output                  tx_clk,

  input                   rx_ref_clk,
  input                   rx_sysref,
  output                  rx_sync,
  input       [ 3:0]      rx_data_p,
  input       [ 3:0]      rx_data_n,

  input                   tx_ref_clk,
  input                   tx_sysref,
  input                   tx_sync,
  output      [ 3:0]      tx_data_p,
  output      [ 3:0]      tx_data_n,

  input                   trig,

  inout                   adc_fdb,
  inout                   adc_fda,
  inout                   dac_irq,
  inout       [ 1:0]      clkd_status,

  inout                   adc_pd,
  inout                   dac_txen,
  inout                   dac_reset,
  inout                   clkd_sync,

  output reg  [63:0]      rx_sysref_cnt,

  input                   adc_up_rstn,
  input                   adc_qpll_rst,

  input                   adc_rst,
  input                   adc_user_ready,
  output wire [3:0]       adc_pll_locked,
  output wire [3:0]       adc_rst_done,

  input                   adc_started,
  input                   adc_probing,
  input                   adc_running,
  input                   adc_delay,

  output wire             adc_sync_ok,
  output wire             adc_sync_fail,

  output reg              adc_wr,
  output reg [127:0]      adc_data
);

 wire [15:0]              rx_phy_charisk;
 wire [15:0]              rx_phy_disperr;
 wire [15:0]              rx_phy_notintable;
 wire [127:0]             rx_phy_data;
 wire                     rx_phy_char_align;

 wire [3:0]               ilas_config_valid;
 wire [7:0]               ilas_config_addr;
 wire [127:0]             ilas_config_data;
 
 wire [1:0]               status_ctrl_state;
 wire [7:0]               status_lane_cgs_state;
 wire [3:0]               status_lane_ifs_ready;
  
 wire [127:0]             jesd_rx_data;
 wire [3:0]               rx_eof;
 wire [3:0]               rx_sof;
 wire                     rx_valid;

 wire [15:0]              tx_phy_charisk;
 wire [127:0]             tx_phy_data;
   
 reg  [127:0]             tx_data = 0;

 reg                      lmfc_clk_s;
 reg                      lmfc_clk_c;

 reg                      rx_run;

 reg [1:0]                adc_sync_fail_cnt;
 reg [15:0]               adc_sync_ok_cnt;
 reg                      adc_start_found;
 reg [7:0]                delay_cnt;
 
 wire [13:0]              adcA_0;
 wire [13:0]              adcA_1;
 wire [13:0]              adcA_2;
 wire [13:0]              adcA_3;

 wire [13:0]              adcB_0;
 wire [13:0]              adcB_1;
 wire [13:0]              adcB_2;
 wire [13:0]              adcB_3;

util_adxcvr_0 util_daq2_xcvr
       (.cpll_ref_clk_0(rx_ref_clk),
        .cpll_ref_clk_1(rx_ref_clk),
        .cpll_ref_clk_2(rx_ref_clk),
        .cpll_ref_clk_3(rx_ref_clk),
        .qpll_ref_clk_0(tx_ref_clk),
        .rx_0_n(rx_data_n[0]),
        .rx_0_p(rx_data_p[0]),
        .rx_1_n(rx_data_n[1]),
        .rx_1_p(rx_data_p[1]),
        .rx_2_n(rx_data_n[2]),
        .rx_2_p(rx_data_p[2]),
        .rx_3_n(rx_data_n[3]),
        .rx_3_p(rx_data_p[3]),
        .rx_calign_0(rx_phy_char_align),
        .rx_calign_1(rx_phy_char_align),
        .rx_calign_2(rx_phy_char_align),
        .rx_calign_3(rx_phy_char_align),
        .rx_charisk_0(rx_phy_charisk[3:0]),
        .rx_charisk_1(rx_phy_charisk[7:4]),
        .rx_charisk_2(rx_phy_charisk[11:8]),
        .rx_charisk_3(rx_phy_charisk[15:12]),
        .rx_clk_0(rx_clk),
        .rx_clk_1(rx_clk),
        .rx_clk_2(rx_clk),
        .rx_clk_3(rx_clk),
        .rx_data_0(rx_phy_data[31:0]),
        .rx_data_1(rx_phy_data[63:32]),
        .rx_data_2(rx_phy_data[95:64]),
        .rx_data_3(rx_phy_data[127:96]),
        .rx_disperr_0(rx_phy_disperr[3:0]),
        .rx_disperr_1(rx_phy_disperr[7:4]),
        .rx_disperr_2(rx_phy_disperr[11:8]),
        .rx_disperr_3(rx_phy_disperr[15:12]),
        .rx_notintable_0(rx_phy_notintable[3:0]),
        .rx_notintable_1(rx_phy_notintable[7:4]),
        .rx_notintable_2(rx_phy_notintable[11:8]),
        .rx_notintable_3(rx_phy_notintable[15:12]),
        .rx_out_clk_0(rx_clk),
        .tx_0_n(tx_data_n[0]),
        .tx_0_p(tx_data_p[0]),
        .tx_1_n(tx_data_n[1]),
        .tx_1_p(tx_data_p[1]),
        .tx_2_n(tx_data_n[2]),
        .tx_2_p(tx_data_p[2]),
        .tx_3_n(tx_data_n[3]),
        .tx_3_p(tx_data_p[3]),
        .tx_charisk_0(tx_phy_charisk[3:0]),
        .tx_charisk_1(tx_phy_charisk[7:4]),
        .tx_charisk_2(tx_phy_charisk[11:8]),
        .tx_charisk_3(tx_phy_charisk[15:12]),
        .tx_clk_0(tx_clk),
        .tx_clk_1(tx_clk),
        .tx_clk_2(tx_clk),
        .tx_clk_3(tx_clk),
        .tx_data_0(tx_phy_data[31:0]),
        .tx_data_1(tx_phy_data[63:32]),
        .tx_data_2(tx_phy_data[95:64]),
        .tx_data_3(tx_phy_data[127:96]),
        .tx_out_clk_0(tx_clk),
        .up_clk(up_clk),
        .up_cm_addr_0(0),
        .up_cm_enb_0(0),
        .up_cm_rdata_0(),
        .up_cm_ready_0(),
        .up_cm_wdata_0(0),
        .up_cm_wr_0(0),
        .up_cpll_rst_0(0),
        .up_cpll_rst_1(0),
        .up_cpll_rst_2(0),
        .up_cpll_rst_3(0),
        .up_es_addr_0(0),
        .up_es_addr_1(0),
        .up_es_addr_2(0),
        .up_es_addr_3(0),
        .up_es_enb_0(0),
        .up_es_enb_1(0),
        .up_es_enb_2(0),
        .up_es_enb_3(0),
        .up_es_rdata_0(),
        .up_es_rdata_1(),
        .up_es_rdata_2(),
        .up_es_rdata_3(),
        .up_es_ready_0(),
        .up_es_ready_1(),
        .up_es_ready_2(),
        .up_es_ready_3(),
        .up_es_reset_0(0),
        .up_es_reset_1(0),
        .up_es_reset_2(0),
        .up_es_reset_3(0),
        .up_es_wdata_0(0),
        .up_es_wdata_1(0),
        .up_es_wdata_2(0),
        .up_es_wdata_3(0),
        .up_es_wr_0(0),
        .up_es_wr_1(0),
        .up_es_wr_2(0),
        .up_es_wr_3(0),
        .up_qpll_rst_0(adc_qpll_rst),
        .up_rstn(adc_up_rstn),
        .up_rx_addr_0(0),
        .up_rx_addr_1(0),
        .up_rx_addr_2(0),
        .up_rx_addr_3(0),
        .up_rx_enb_0(0),
        .up_rx_enb_1(0),
        .up_rx_enb_2(0),
        .up_rx_enb_3(0),
        .up_rx_lpm_dfe_n_0(1),
        .up_rx_lpm_dfe_n_1(1),
        .up_rx_lpm_dfe_n_2(1),
        .up_rx_lpm_dfe_n_3(1),
        .up_rx_out_clk_sel_0(3'd4),
        .up_rx_out_clk_sel_1(3'd4),
        .up_rx_out_clk_sel_2(3'd4),
        .up_rx_out_clk_sel_3(3'd4),
        .up_rx_pll_locked_0(adc_pll_locked[0]),
        .up_rx_pll_locked_1(adc_pll_locked[1]),
        .up_rx_pll_locked_2(adc_pll_locked[2]),
        .up_rx_pll_locked_3(adc_pll_locked[3]),
        .up_rx_rate_0(0),
        .up_rx_rate_1(0),
        .up_rx_rate_2(0),
        .up_rx_rate_3(0),
        .up_rx_rdata_0(),
        .up_rx_rdata_1(),
        .up_rx_rdata_2(),
        .up_rx_rdata_3(),
        .up_rx_ready_0(),
        .up_rx_ready_1(),
        .up_rx_ready_2(),
        .up_rx_ready_3(),
        .up_rx_rst_0(adc_rst),
        .up_rx_rst_1(adc_rst),
        .up_rx_rst_2(adc_rst),
        .up_rx_rst_3(adc_rst),
        .up_rx_rst_done_0(adc_rst_done[0]),
        .up_rx_rst_done_1(adc_rst_done[1]),
        .up_rx_rst_done_2(adc_rst_done[2]),
        .up_rx_rst_done_3(adc_rst_done[3]),
        .up_rx_sys_clk_sel_0(2'd3),
        .up_rx_sys_clk_sel_1(2'd3),
        .up_rx_sys_clk_sel_2(2'd3),
        .up_rx_sys_clk_sel_3(2'd3),
        .up_rx_user_ready_0(adc_user_ready),
        .up_rx_user_ready_1(adc_user_ready),
        .up_rx_user_ready_2(adc_user_ready),
        .up_rx_user_ready_3(adc_user_ready),
        .up_rx_wdata_0(0),
        .up_rx_wdata_1(0),
        .up_rx_wdata_2(0),
        .up_rx_wdata_3(0),
        .up_rx_wr_0(0),
        .up_rx_wr_1(0),
        .up_rx_wr_2(0),
        .up_rx_wr_3(0),
        .up_tx_addr_0(0),
        .up_tx_addr_1(0),
        .up_tx_addr_2(0),
        .up_tx_addr_3(0),
        .up_tx_diffctrl_0(0),
        .up_tx_diffctrl_1(0),
        .up_tx_diffctrl_2(0),
        .up_tx_diffctrl_3(0),
        .up_tx_enb_0(0),
        .up_tx_enb_1(0),
        .up_tx_enb_2(0),
        .up_tx_enb_3(0),
        .up_tx_lpm_dfe_n_0(1),
        .up_tx_lpm_dfe_n_1(1),
        .up_tx_lpm_dfe_n_2(1),
        .up_tx_lpm_dfe_n_3(1),
        .up_tx_out_clk_sel_0(3'd4),
        .up_tx_out_clk_sel_1(3'd4),
        .up_tx_out_clk_sel_2(3'd4),
        .up_tx_out_clk_sel_3(3'd4),
        .up_tx_pll_locked_0(),
        .up_tx_pll_locked_1(),
        .up_tx_pll_locked_2(),
        .up_tx_pll_locked_3(),
        .up_tx_postcursor_0(0),
        .up_tx_postcursor_1(0),
        .up_tx_postcursor_2(0),
        .up_tx_postcursor_3(0),
        .up_tx_precursor_0(0),
        .up_tx_precursor_1(0),
        .up_tx_precursor_2(0),
        .up_tx_precursor_3(0),
        .up_tx_rate_0(0),
        .up_tx_rate_1(0),
        .up_tx_rate_2(0),
        .up_tx_rate_3(0),
        .up_tx_rdata_0(),
        .up_tx_rdata_1(),
        .up_tx_rdata_2(),
        .up_tx_rdata_3(),
        .up_tx_ready_0(),
        .up_tx_ready_1(),
        .up_tx_ready_2(),
        .up_tx_ready_3(),
        .up_tx_rst_0(0),
        .up_tx_rst_1(0),
        .up_tx_rst_2(0),
        .up_tx_rst_3(0),
        .up_tx_rst_done_0(),
        .up_tx_rst_done_1(),
        .up_tx_rst_done_2(),
        .up_tx_rst_done_3(),
        .up_tx_sys_clk_sel_0(0),
        .up_tx_sys_clk_sel_1(0),
        .up_tx_sys_clk_sel_2(0),
        .up_tx_sys_clk_sel_3(0),
        .up_tx_user_ready_0(1),
        .up_tx_user_ready_1(1),
        .up_tx_user_ready_2(1),
        .up_tx_user_ready_3(1),
        .up_tx_wdata_0(0),
        .up_tx_wdata_1(0),
        .up_tx_wdata_2(0),
        .up_tx_wdata_3(0),
        .up_tx_wr_0(0),
        .up_tx_wr_1(0),
        .up_tx_wr_2(0),
        .up_tx_wr_3(0));

jesd204_rx_0 jesd204_rx_0_inst
       (.cfg_beats_per_multiframe(3),
        .cfg_buffer_delay(0),
        .cfg_buffer_early_release(0),
        .cfg_disable_char_replacement(0),
        .cfg_disable_scrambler(0),
        .cfg_lanes_disable(0),
        .cfg_links_disable(0),
        .cfg_lmfc_offset(3),
        .cfg_octets_per_frame(0),
        .cfg_sysref_disable(0),
        .cfg_sysref_oneshot(0),
        .clk(rx_clk),
        .ctrl_err_statistics_mask(0),
        .ctrl_err_statistics_reset(0),
        .event_sysref_alignment_error(),
        .event_sysref_edge(),
        .ilas_config_addr(ilas_config_addr),
        .ilas_config_data(ilas_config_data),
        .ilas_config_valid(ilas_config_valid),
        .phy_block_sync({1'b0,1'b0,1'b0,1'b0}),
        .phy_charisk(rx_phy_charisk),
        .phy_data(rx_phy_data),
        .phy_disperr(rx_phy_disperr),
        .phy_en_char_align(rx_phy_char_align),
        .phy_header({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .phy_notintable(rx_phy_notintable),
        .reset(reset),
        .rx_data(jesd_rx_data),
        .rx_eof(rx_eof),
        .rx_sof(rx_sof),
        .rx_valid(rx_valid),
        .status_ctrl_state(status_ctrl_state),
        .status_err_statistics_cnt(),
        .status_lane_cgs_state(status_lane_cgs_state),
        .status_lane_emb_state(),
        .status_lane_ifs_ready(status_lane_ifs_ready),
        .status_lane_latency(),
        .sync(rx_sync),
        .sysref(rx_sysref),
        .lmfc_clk(lmfc_clk)
);


ila_0 ila_0_inst (
    .clk(rx_clk),                      // input wire clk
    .probe0(adc_started),              // input wire [0:0]  probe0  
    .probe1(adc_probing),              // input wire [0:0]  probe0  
    .probe2(adc_running),              // input wire [0:0]  probe0  
    .probe3(adc_start_found),          // input wire [0:0]  probe0  
    .probe4(rx_test_ok),               // input wire [0:0]  probe0  
    .probe5(rx_valid),                 // input wire [0:0]  probe0  
    .probe6(adcA_0),                   // input wire [13:0]  probe0  
    .probe7(adcB_0),                   // input wire [13:0]  probe0  
    .probe8(adcA_1),                   // input wire [13:0]  probe0  
    .probe9(adcB_1),                   // input wire [13:0]  probe0  
    .probe10(adcA_2),                  // input wire [13:0]  probe0  
    .probe11(adcB_2),                  // input wire [13:0]  probe0  
    .probe12(adcA_3),                  // input wire [13:0]  probe0  
    .probe13(adcB_3),                  // input wire [13:0]  probe0  
    .probe14(adc_sync_ok_cnt),         // input wire [15:0]  probe0
    .probe15(adc_sync_fail_cnt)        // input wire [15:0]  probe0
);

function check_valid;
  input [13:0] adcA_0;
  input [13:0] adcB_0;
  input [13:0] adcA_1;
  input [13:0] adcB_1;
  input [13:0] adcA_2;
  input [13:0] adcB_2;
  input [13:0] adcA_3;
  input [13:0] adcB_3;
  reg res;
  begin
    res = 0;
    
    if (adcA_0 == 14'h0000)
      if (adcB_0 == 14'h0000)
        if (adcA_1 == 14'h3FFF)
          if (adcB_1 == 14'h3FFF)
            if (adcA_2 == 14'h0000)
              if (adcB_2 == 14'h0000)
                if (adcA_3 == 14'h3FFF)
                  if (adcB_3 == 14'h3FFF)
                    res = 1;

    if (adcA_0 == 14'h3FFF)
      if (adcB_0 == 14'h3FFF)
        if (adcA_1 == 14'h0000)
          if (adcB_1 == 14'h0000)
            if (adcA_2 == 14'h3FFF)
              if (adcB_2 == 14'h3FFF)
                if (adcA_3 == 14'h0000)
                  if (adcB_3 == 14'h0000)
                    res = 1;
    check_valid = res;
  end
endfunction

  assign adc_fda = 1'bz;
  assign adc_fdb = 1'bz;
  assign dac_irq = 1'bz;
  assign clkd_status = 2'bz;
  assign clkd_sync = 2'bz;
  assign dac_txen = 1'bz;
  assign dac_reset = 1'bz;
  
  assign adc_pd = adc_started ? 1'b0 : 1'b1;
  
  assign adcA_0 = {jesd_rx_data[7:0], jesd_rx_data[39:34]};
  assign adcA_1 = {jesd_rx_data[15:8], jesd_rx_data[47:42]};
  assign adcA_2 = {jesd_rx_data[23:16], jesd_rx_data[55:50]};
  assign adcA_3 = {jesd_rx_data[31:24], jesd_rx_data[63:58]};
  assign adcB_0 = {jesd_rx_data[71:64], jesd_rx_data[103:98]};
  assign adcB_1 = {jesd_rx_data[79:72], jesd_rx_data[111:106]};
  assign adcB_2 = {jesd_rx_data[87:80], jesd_rx_data[119:114]};
  assign adcB_3 = {jesd_rx_data[95:88], jesd_rx_data[127:122]};

  assign rx_test_ok = check_valid(adcA_0, adcB_0, adcA_1, adcB_1, adcA_2, adcB_2, adcA_3, adcB_3);

  assign adc_sync_ok = adc_sync_ok_cnt[15];
  assign adc_sync_fail = adc_sync_fail_cnt[1];

generate
  begin : daq2_app

    always @ ( posedge rx_clk ) 
    begin
      if (adc_started)
      begin
        lmfc_clk_s <= lmfc_clk;
        if (lmfc_clk_c != lmfc_clk_s)
        begin
          lmfc_clk_c <= lmfc_clk_s;
          if (lmfc_clk_s == 1)
            rx_sysref_cnt <= rx_sysref_cnt + 1;
        end
      end
      else
      begin
        lmfc_clk_c <= 0;
        lmfc_clk_s <= 0;
        rx_sysref_cnt <= 0;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_valid)
      begin
        adc_data[13:0] <= adcA_0;
        adc_data[14] <= adcA_0[13];
        adc_data[15] <= adcA_0[13];
        adc_data[29:16] <= adcB_0;
        adc_data[30] <= adcB_0[13];
        adc_data[31] <= adcB_0[13];

        adc_data[45:32] <= adcA_1;
        adc_data[46] <= adcA_1[13];
        adc_data[47] <= adcA_1[13];
        adc_data[61:48] <= adcB_1;
        adc_data[62] <= adcB_1[13];
        adc_data[63] <= adcB_1[13];

        adc_data[77:64] <= adcA_2;
        adc_data[78] <= adcA_2[13];
        adc_data[79] <= adcA_2[13];
        adc_data[93:80] <= adcB_2;
        adc_data[94] <= adcB_2[13];
        adc_data[95] <= adcB_2[13];

        adc_data[109:96] <= adcA_3;
        adc_data[110] <= adcA_3[13];
        adc_data[111] <= adcA_3[13];
        adc_data[125:112] <= adcB_3;
        adc_data[126] <= adcB_3[13];
        adc_data[127] <= adcB_3[13];

        if (adc_running)
        begin
          if (adc_probing && !adc_start_found)
          begin
            if (rx_test_ok)
              adc_wr <= 0;
            else
            begin
              if (adc_delay)
              begin
                if (delay_cnt)
                  delay_cnt <= delay_cnt - 1;
                else
                  adc_start_found <= 1;
              end
              else
              begin               
                adc_wr <= 1;
                adc_start_found <= 1;
              end
            end
          end
          else
            adc_wr <= 1;
        end
        else
        begin
          adc_wr <= 0;
          adc_start_found <= 0;
          delay_cnt <= 8'hFF;
        end
      end
      else
      begin
        adc_wr <= 0;
        adc_start_found <= 0;
        delay_cnt <= 8'hFF;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (adc_probing)
      begin
        if (rx_valid && !adc_sync_ok && !adc_sync_fail && !adc_running)
        begin        
          if (rx_test_ok)
            adc_sync_ok_cnt <= adc_sync_ok_cnt + 1;
          else
            adc_sync_fail_cnt <= adc_sync_fail_cnt + 1;
        end
      end
      else
      begin
        adc_sync_fail_cnt <= 0;
        adc_sync_ok_cnt <= 0;
      end
    end


  end
endgenerate

endmodule
