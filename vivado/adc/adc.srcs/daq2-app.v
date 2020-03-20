module daq2_app
(
  input                   clk,
  input                   reset,

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

  input                   up_clk,
  input                   spi_sys_clk,

  input                   trig,

  inout                   adc_fdb,
  inout                   adc_fda,
  inout                   dac_irq,
  inout       [ 1:0]      clkd_status,

  inout                   adc_pd,
  inout                   dac_txen,
  inout                   dac_reset,
  inout                   clkd_sync,

  output                  rx_valid,
  output reg  [63:0]      rx_sysref_cnt,

  input                   adc_start,
  input                   adc_stop,
  output reg              adc_running,
  
  input                   adc_fifo_rd,
  output [111:0]          adc_fifo_data,
  output                  adc_fifo_full,
  output                  adc_fifo_empty,

  output [19:0]           adc_spi_fifo_out,
  output                  adc_spi_fifo_empty,
  input                   adc_spi_fifo_ack
);

 wire                     rx_clk;
 wire                     tx_clk;

 wire [15:0]              rx_phy_charisk;
 wire [15:0]              rx_phy_disperr;
 wire [15:0]              rx_phy_notintable;
 wire [127:0]             rx_phy_data;
 wire                     rx_phy_char_align;
 wire [3:0]               rx_pll_locked;

 wire [3:0]               ilas_config_valid;
 wire [7:0]               ilas_config_addr;
 wire [127:0]             ilas_config_data;
 
 wire [1:0]               status_ctrl_state;
 wire [7:0]               status_lane_cgs_state;
 wire [3:0]               status_lane_ifs_ready;
  
 wire [127:0]             rx_data;
 wire [3:0]               rx_eof;
 wire [3:0]               rx_sof;

 wire [15:0]              tx_phy_charisk;
 wire [127:0]             tx_phy_data;
   
 reg  [127:0]             tx_data = 0;

 reg                      adc_start_m;
 reg                      adc_stop_m;

 reg [4:0]                adc_start_cnt;
 reg [4:0]                adc_stop_cnt;

 reg                      pend_start;
 reg                      qpll_rst;
 wire                     qpll_locked;

 reg                      up_rstn;
 wire                     up_rx_rst; 
 wire                     up_rx_user_ready;
 wire [3:0]               up_rx_rst_done;

 reg  [3:0]               up_pll_rst_cnt;
 reg  [3:0]               up_rx_rst_cnt;
 reg  [6:0]               up_rx_user_ready_cnt;

 reg                      lmfc_clk_s;
 reg                      lmfc_clk_c;

 reg [13:0]               adcA_0;
 reg [13:0]               adcA_1;
 reg [13:0]               adcA_2;
 reg [13:0]               adcA_3;

 reg [13:0]               adcB_0;
 reg [13:0]               adcB_1;
 reg [13:0]               adcB_2;
 reg [13:0]               adcB_3;

 reg                      adc_wr;


  system_util_daq2_xcvr_0 util_daq2_xcvr
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
        .up_qpll_rst_0(qpll_rst),
        .up_qpll_locked_0(qpll_locked),
        .up_rstn(up_rstn),
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
        .up_rx_pll_locked_0(rx_pll_locked[0]),
        .up_rx_pll_locked_1(rx_pll_locked[1]),
        .up_rx_pll_locked_2(rx_pll_locked[2]),
        .up_rx_pll_locked_3(rx_pll_locked[3]),
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
        .up_rx_rst_0(up_rx_rst),
        .up_rx_rst_1(up_rx_rst),
        .up_rx_rst_2(up_rx_rst),
        .up_rx_rst_3(up_rx_rst),
        .up_rx_rst_done_0(up_rx_rst_done[0]),
        .up_rx_rst_done_1(up_rx_rst_done[1]),
        .up_rx_rst_done_2(up_rx_rst_done[2]),
        .up_rx_rst_done_3(up_rx_rst_done[3]),
        .up_rx_sys_clk_sel_0(2'd3),
        .up_rx_sys_clk_sel_1(2'd3),
        .up_rx_sys_clk_sel_2(2'd3),
        .up_rx_sys_clk_sel_3(2'd3),
        .up_rx_user_ready_0(up_rx_user_ready),
        .up_rx_user_ready_1(up_rx_user_ready),
        .up_rx_user_ready_2(up_rx_user_ready),
        .up_rx_user_ready_3(up_rx_user_ready),
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

system_rx_0 system_rx_0_inst
       (.cfg_beats_per_multiframe(3),
        .cfg_buffer_delay(0),
        .cfg_buffer_early_release(0),
        .cfg_disable_char_replacement(0),
        .cfg_disable_scrambler(0),
        .cfg_lanes_disable(0),
        .cfg_links_disable(0),
        .cfg_lmfc_offset(0),
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
        .rx_data(rx_data),
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

system_tx_0 system_tx_0_inst
       (.cfg_beats_per_multiframe(3),
        .cfg_continuous_cgs(0),
        .cfg_continuous_ilas(0),
        .cfg_disable_char_replacement(0),
        .cfg_disable_scrambler(0),
        .cfg_lanes_disable(0),
        .cfg_links_disable(0),
        .cfg_lmfc_offset(0),
        .cfg_mframes_per_ilas(0),
        .cfg_octets_per_frame(0),
        .cfg_skip_ilas(0),
        .cfg_sysref_disable(0),
        .cfg_sysref_oneshot(0),
        .clk(tx_clk),
        .ctrl_manual_sync_request(0),
        .event_sysref_alignment_error(),
        .event_sysref_edge(),
        .ilas_config_addr(),
        .ilas_config_data(0),
        .ilas_config_rd(),
        .phy_charisk(tx_phy_charisk),
        .phy_data(tx_phy_data),
        .reset(reset),
        .status_state(),
        .status_sync(),
        .sync(tx_sync),
        .sysref(tx_sysref),
        .tx_data(tx_data),
        .tx_ready(1),
        .tx_valid(1));

adc_fifo adc_fifo_inst (
  .rst(reset),           // input wire rst
  .wr_clk(rx_clk),       // input wire wr_clk
  .rd_clk(clk),          // input wire rd_clk
  .din({adcB_3, adcA_3, adcB_2, adcA_2, adcB_1, adcA_1, adcB_0, adcA_0}),        // input wire [111 : 0] din
  .wr_en(adc_wr),        // input wire wr_en
  .rd_en(adc_fifo_rd),   // input wire rd_en
  .dout(adc_fifo_data),  // output wire [111 : 0] dout
  .full(adc_fifo_full),  // output wire full
  .empty(adc_fifo_empty) // output wire empty
);

adc_spi_fifo adc_spi_fifo_inst (
  .rst(reset),                  // input wire rst
  .wr_clk(rx_clk),              // input wire wr_clk
  .rd_clk(spi_sys_clk),         // input wire rd_clk
  .din(0),                      // input wire [19 : 0] din
  .wr_en(0),                    // input wire wr_en
  .rd_en(adc_spi_fifo_ack),     // input wire rd_en
  .dout(adc_spi_fifo_out),      // output wire [19 : 0] dout
  .full(),                      // output wire full
  .empty(adc_spi_fifo_empty)    // output wire empty
);

  assign adc_pd = adc_running ? 1'b0 : 1'b1;
  assign up_rx_rst = up_rx_rst_cnt[3];
  assign up_rx_user_ready = up_rx_user_ready_cnt[6];

generate
  begin : daq2_app

    always @(posedge clk) 
    begin
      if (reset)
      begin
        adc_start_m <= 0;
        adc_stop_m <= 0;
      end
      else
      begin
        if (adc_start)
        begin
          adc_start_m <= 1;
          adc_start_cnt <= 0;
        end
        else
        begin
          if (adc_start_m)
          begin
            adc_start_cnt <= adc_start_cnt + 1;
            if (adc_start_cnt[4] == 1)
              adc_start_m <= 0;
          end

          if (adc_stop)
          begin
            adc_stop_m <= 1;
            adc_stop_cnt <= 0;
          end
          else
          begin
            if (adc_stop_m)
            begin
              adc_stop_cnt <= adc_stop_cnt + 1;
              if (adc_stop_cnt[4] == 1)
                adc_stop_m <= 0;
            end
          end
        end
      end
    end
        
    always @(posedge up_clk) 
    begin
      if (reset)
      begin
        adc_running <= 0;
        pend_start <= 0;
        up_rstn <= 0;
        qpll_rst <= 0;
      end
      else
      begin
        if (adc_start_m)
        begin
          up_rstn <= 0;
          qpll_rst <= 1;
          up_pll_rst_cnt <= 4'h8; 
          up_rx_rst_cnt <= 4'h8;    
          up_rx_user_ready_cnt <= 7'h00;  
          pend_start <= 1;
        end
        else
        begin
          qpll_rst <= 0;

          if (adc_stop_m)
          begin
            pend_start <= 0;
            adc_running <= 0;
            up_rstn <= 0;
          end
          else
          begin
            up_rstn <= 1;

            if (pend_start)
            begin
              if (up_rstn == 1)
              begin
                if (qpll_locked)
                  if (up_pll_rst_cnt[3] == 1'b1) 
                    up_pll_rst_cnt <= up_pll_rst_cnt + 1'b1;

                if ((up_pll_rst_cnt[3] == 1'b1) || (rx_pll_locked != 4'b1111))
                  up_rx_rst_cnt <= 4'h8; 
                else 
                  if (up_rx_rst_cnt[3] == 1'b1) 
                    up_rx_rst_cnt <= up_rx_rst_cnt + 1'b1;

                if (up_rx_rst_cnt[3] == 1'b1) 
                  up_rx_user_ready_cnt <= 7'h00;   
                else 
                begin
                  if (up_rx_user_ready_cnt[6] == 1'b0) 
                    up_rx_user_ready_cnt <= up_rx_user_ready_cnt + 1'b1;
                  else
                  begin
                    pend_start <= 0;
                    adc_running <= 1;
                  end
                end
              end
            end
          end
        end
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (adc_running)
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
        adcA_0 <= {rx_data[7:0], rx_data[39:34]};
        adcA_1 <= {rx_data[15:8], rx_data[47:42]};
        adcA_2 <= {rx_data[23:16], rx_data[55:50]};
        adcA_3 <= {rx_data[31:24], rx_data[63:58]};
        adcB_0 <= {rx_data[71:64], rx_data[103:98]};
        adcB_1 <= {rx_data[79:72], rx_data[111:106]};
        adcB_2 <= {rx_data[87:80], rx_data[119:114]};
        adcB_3 <= {rx_data[95:88], rx_data[127:122]};
        adc_wr <= 1;
      end
      else
        adc_wr <= 0;
    end

  end
endgenerate

endmodule
