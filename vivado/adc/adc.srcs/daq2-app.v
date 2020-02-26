module daq2_app
(
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


  wire [63:0]            gpio_i;
  wire [63:0]            gpio_o;
  wire [63:0]            gpio_t;
  wire [ 7:0]            spi_csn;
  wire                   spi_mosi;
  wire                   spi_miso;
  wire                   trig;

  wire                   rx_ref_clk;
  wire                   rx_sysref;
  wire                   rx_sync;
  wire                   tx_ref_clk;
  wire                   tx_sysref;
  wire                   tx_sync;

  wire        axi_ad9680_jesd_phy_en_char_align;
  wire [3:0]  util_daq2_xcvr_rx_0_rxcharisk;
  wire [3:0]  util_daq2_xcvr_rx_1_rxcharisk;
  wire [3:0]  util_daq2_xcvr_rx_2_rxcharisk;
  wire [3:0]  util_daq2_xcvr_rx_3_rxcharisk;
  wire        util_daq2_xcvr_rx_out_clk_0;

// spi

  assign spi_csn_adc = spi_csn[2];
  assign spi_csn_dac = spi_csn[1];
  assign spi_csn_clk = spi_csn[0];

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

  daq2_spi i_spi (
    .spi_csn (spi_csn[2:0]),
    .spi_clk (spi_clk),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir));

  assign gpio_i[43] = trig;

  ad_iobuf #(.DATA_WIDTH(9)) i_iobuf (
    .dio_t ({gpio_t[42:40], gpio_t[38], gpio_t[36:32]}),
    .dio_i ({gpio_o[42:40], gpio_o[38], gpio_o[36:32]}),
    .dio_o ({gpio_i[42:40], gpio_i[38], gpio_i[36:32]}),
    .dio_p ({ adc_pd,           // 42
              dac_txen,         // 41
              dac_reset,        // 40
              clkd_sync,        // 38
             adc_fdb,          // 36
              adc_fda,          // 35
              dac_irq,          // 34
              clkd_status}));   // 33-32

  ad_iobuf #(.DATA_WIDTH(17)) i_iobuf_bd (
    .dio_t (gpio_t[16:0]),
    .dio_i (gpio_o[16:0]),
    .dio_o (gpio_i[16:0]),
    .dio_p (gpio_bd));

  assign gpio_i[63:44] = gpio_o[63:44];
  assign gpio_i[39] = gpio_o[39];
  assign gpio_i[37] = gpio_o[37];
  assign gpio_i[31:17] = gpio_o[31:17];

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
        .rx_calign_0(axi_ad9680_jesd_phy_en_char_align),
        .rx_calign_1(axi_ad9680_jesd_phy_en_char_align),
        .rx_calign_2(axi_ad9680_jesd_phy_en_char_align),
        .rx_calign_3(axi_ad9680_jesd_phy_en_char_align),
        .rx_charisk_0(util_daq2_xcvr_rx_0_rxcharisk),
        .rx_charisk_1(util_daq2_xcvr_rx_1_rxcharisk),
        .rx_charisk_2(util_daq2_xcvr_rx_2_rxcharisk),
        .rx_charisk_3(util_daq2_xcvr_rx_3_rxcharisk),
        .rx_clk_0(util_daq2_xcvr_rx_out_clk_0),
        .rx_clk_1(util_daq2_xcvr_rx_out_clk_0),
        .rx_clk_2(util_daq2_xcvr_rx_out_clk_0),
        .rx_clk_3(util_daq2_xcvr_rx_out_clk_0),
        .rx_data_0(util_daq2_xcvr_rx_0_rxdata),
        .rx_data_1(util_daq2_xcvr_rx_1_rxdata),
        .rx_data_2(util_daq2_xcvr_rx_2_rxdata),
        .rx_data_3(util_daq2_xcvr_rx_3_rxdata),
        .rx_disperr_0(util_daq2_xcvr_rx_0_rxdisperr),
        .rx_disperr_1(util_daq2_xcvr_rx_1_rxdisperr),
        .rx_disperr_2(util_daq2_xcvr_rx_2_rxdisperr),
        .rx_disperr_3(util_daq2_xcvr_rx_3_rxdisperr),
        .rx_notintable_0(util_daq2_xcvr_rx_0_rxnotintable),
        .rx_notintable_1(util_daq2_xcvr_rx_1_rxnotintable),
        .rx_notintable_2(util_daq2_xcvr_rx_2_rxnotintable),
        .rx_notintable_3(util_daq2_xcvr_rx_3_rxnotintable),
        .rx_out_clk_0(util_daq2_xcvr_rx_out_clk_0),
        .tx_0_n(util_daq2_xcvr_tx_0_n),
        .tx_0_p(util_daq2_xcvr_tx_0_p),
        .tx_1_n(util_daq2_xcvr_tx_1_n),
        .tx_1_p(util_daq2_xcvr_tx_1_p),
        .tx_2_n(util_daq2_xcvr_tx_2_n),
        .tx_2_p(util_daq2_xcvr_tx_2_p),
        .tx_3_n(util_daq2_xcvr_tx_3_n),
        .tx_3_p(util_daq2_xcvr_tx_3_p),
        .tx_charisk_0(axi_ad9144_jesd_tx_phy0_txcharisk),
        .tx_charisk_1(axi_ad9144_jesd_tx_phy3_txcharisk),
        .tx_charisk_2(axi_ad9144_jesd_tx_phy1_txcharisk),
        .tx_charisk_3(axi_ad9144_jesd_tx_phy2_txcharisk),
        .tx_clk_0(util_daq2_xcvr_tx_out_clk_0),
        .tx_clk_1(util_daq2_xcvr_tx_out_clk_0),
        .tx_clk_2(util_daq2_xcvr_tx_out_clk_0),
        .tx_clk_3(util_daq2_xcvr_tx_out_clk_0),
        .tx_data_0(axi_ad9144_jesd_tx_phy0_txdata),
        .tx_data_1(axi_ad9144_jesd_tx_phy3_txdata),
        .tx_data_2(axi_ad9144_jesd_tx_phy1_txdata),
        .tx_data_3(axi_ad9144_jesd_tx_phy2_txdata),
        .tx_out_clk_0(util_daq2_xcvr_tx_out_clk_0),
        .up_clk(sys_cpu_clk),
        .up_cm_addr_0(axi_ad9144_xcvr_up_cm_0_addr),
        .up_cm_enb_0(axi_ad9144_xcvr_up_cm_0_enb),
        .up_cm_rdata_0(axi_ad9144_xcvr_up_cm_0_rdata),
        .up_cm_ready_0(axi_ad9144_xcvr_up_cm_0_ready),
        .up_cm_wdata_0(axi_ad9144_xcvr_up_cm_0_wdata),
        .up_cm_wr_0(axi_ad9144_xcvr_up_cm_0_wr),
        .up_cpll_rst_0(axi_ad9680_xcvr_up_pll_rst),
        .up_cpll_rst_1(axi_ad9680_xcvr_up_pll_rst),
        .up_cpll_rst_2(axi_ad9680_xcvr_up_pll_rst),
        .up_cpll_rst_3(axi_ad9680_xcvr_up_pll_rst),
        .up_es_addr_0(axi_ad9680_xcvr_up_es_0_addr),
        .up_es_addr_1(axi_ad9680_xcvr_up_es_1_addr),
        .up_es_addr_2(axi_ad9680_xcvr_up_es_2_addr),
        .up_es_addr_3(axi_ad9680_xcvr_up_es_3_addr),
        .up_es_enb_0(axi_ad9680_xcvr_up_es_0_enb),
        .up_es_enb_1(axi_ad9680_xcvr_up_es_1_enb),
        .up_es_enb_2(axi_ad9680_xcvr_up_es_2_enb),
        .up_es_enb_3(axi_ad9680_xcvr_up_es_3_enb),
        .up_es_rdata_0(axi_ad9680_xcvr_up_es_0_rdata),
        .up_es_rdata_1(axi_ad9680_xcvr_up_es_1_rdata),
        .up_es_rdata_2(axi_ad9680_xcvr_up_es_2_rdata),
        .up_es_rdata_3(axi_ad9680_xcvr_up_es_3_rdata),
        .up_es_ready_0(axi_ad9680_xcvr_up_es_0_ready),
        .up_es_ready_1(axi_ad9680_xcvr_up_es_1_ready),
        .up_es_ready_2(axi_ad9680_xcvr_up_es_2_ready),
        .up_es_ready_3(axi_ad9680_xcvr_up_es_3_ready),
        .up_es_reset_0(axi_ad9680_xcvr_up_es_0_reset),
        .up_es_reset_1(axi_ad9680_xcvr_up_es_1_reset),
        .up_es_reset_2(axi_ad9680_xcvr_up_es_2_reset),
        .up_es_reset_3(axi_ad9680_xcvr_up_es_3_reset),
        .up_es_wdata_0(axi_ad9680_xcvr_up_es_0_wdata),
        .up_es_wdata_1(axi_ad9680_xcvr_up_es_1_wdata),
        .up_es_wdata_2(axi_ad9680_xcvr_up_es_2_wdata),
        .up_es_wdata_3(axi_ad9680_xcvr_up_es_3_wdata),
        .up_es_wr_0(axi_ad9680_xcvr_up_es_0_wr),
        .up_es_wr_1(axi_ad9680_xcvr_up_es_1_wr),
        .up_es_wr_2(axi_ad9680_xcvr_up_es_2_wr),
        .up_es_wr_3(axi_ad9680_xcvr_up_es_3_wr),
        .up_qpll_rst_0(axi_ad9144_xcvr_up_pll_rst),
        .up_rstn(sys_cpu_resetn),
        .up_rx_addr_0(axi_ad9680_xcvr_up_ch_0_addr),
        .up_rx_addr_1(axi_ad9680_xcvr_up_ch_1_addr),
        .up_rx_addr_2(axi_ad9680_xcvr_up_ch_2_addr),
        .up_rx_addr_3(axi_ad9680_xcvr_up_ch_3_addr),
        .up_rx_enb_0(axi_ad9680_xcvr_up_ch_0_enb),
        .up_rx_enb_1(axi_ad9680_xcvr_up_ch_1_enb),
        .up_rx_enb_2(axi_ad9680_xcvr_up_ch_2_enb),
        .up_rx_enb_3(axi_ad9680_xcvr_up_ch_3_enb),
        .up_rx_lpm_dfe_n_0(axi_ad9680_xcvr_up_ch_0_lpm_dfe_n),
        .up_rx_lpm_dfe_n_1(axi_ad9680_xcvr_up_ch_1_lpm_dfe_n),
        .up_rx_lpm_dfe_n_2(axi_ad9680_xcvr_up_ch_2_lpm_dfe_n),
        .up_rx_lpm_dfe_n_3(axi_ad9680_xcvr_up_ch_3_lpm_dfe_n),
        .up_rx_out_clk_sel_0(axi_ad9680_xcvr_up_ch_0_out_clk_sel),
        .up_rx_out_clk_sel_1(axi_ad9680_xcvr_up_ch_1_out_clk_sel),
        .up_rx_out_clk_sel_2(axi_ad9680_xcvr_up_ch_2_out_clk_sel),
        .up_rx_out_clk_sel_3(axi_ad9680_xcvr_up_ch_3_out_clk_sel),
        .up_rx_pll_locked_0(axi_ad9680_xcvr_up_ch_0_pll_locked),
        .up_rx_pll_locked_1(axi_ad9680_xcvr_up_ch_1_pll_locked),
        .up_rx_pll_locked_2(axi_ad9680_xcvr_up_ch_2_pll_locked),
        .up_rx_pll_locked_3(axi_ad9680_xcvr_up_ch_3_pll_locked),
        .up_rx_rate_0(axi_ad9680_xcvr_up_ch_0_rate),
        .up_rx_rate_1(axi_ad9680_xcvr_up_ch_1_rate),
        .up_rx_rate_2(axi_ad9680_xcvr_up_ch_2_rate),
        .up_rx_rate_3(axi_ad9680_xcvr_up_ch_3_rate),
        .up_rx_rdata_0(axi_ad9680_xcvr_up_ch_0_rdata),
        .up_rx_rdata_1(axi_ad9680_xcvr_up_ch_1_rdata),
        .up_rx_rdata_2(axi_ad9680_xcvr_up_ch_2_rdata),
        .up_rx_rdata_3(axi_ad9680_xcvr_up_ch_3_rdata),
        .up_rx_ready_0(axi_ad9680_xcvr_up_ch_0_ready),
        .up_rx_ready_1(axi_ad9680_xcvr_up_ch_1_ready),
        .up_rx_ready_2(axi_ad9680_xcvr_up_ch_2_ready),
        .up_rx_ready_3(axi_ad9680_xcvr_up_ch_3_ready),
        .up_rx_rst_0(axi_ad9680_xcvr_up_ch_0_rst),
        .up_rx_rst_1(axi_ad9680_xcvr_up_ch_1_rst),
        .up_rx_rst_2(axi_ad9680_xcvr_up_ch_2_rst),
        .up_rx_rst_3(axi_ad9680_xcvr_up_ch_3_rst),
        .up_rx_rst_done_0(axi_ad9680_xcvr_up_ch_0_rst_done),
        .up_rx_rst_done_1(axi_ad9680_xcvr_up_ch_1_rst_done),
        .up_rx_rst_done_2(axi_ad9680_xcvr_up_ch_2_rst_done),
        .up_rx_rst_done_3(axi_ad9680_xcvr_up_ch_3_rst_done),
        .up_rx_sys_clk_sel_0(axi_ad9680_xcvr_up_ch_0_sys_clk_sel),
        .up_rx_sys_clk_sel_1(axi_ad9680_xcvr_up_ch_1_sys_clk_sel),
        .up_rx_sys_clk_sel_2(axi_ad9680_xcvr_up_ch_2_sys_clk_sel),
        .up_rx_sys_clk_sel_3(axi_ad9680_xcvr_up_ch_3_sys_clk_sel),
        .up_rx_user_ready_0(axi_ad9680_xcvr_up_ch_0_user_ready),
        .up_rx_user_ready_1(axi_ad9680_xcvr_up_ch_1_user_ready),
        .up_rx_user_ready_2(axi_ad9680_xcvr_up_ch_2_user_ready),
        .up_rx_user_ready_3(axi_ad9680_xcvr_up_ch_3_user_ready),
        .up_rx_wdata_0(axi_ad9680_xcvr_up_ch_0_wdata),
        .up_rx_wdata_1(axi_ad9680_xcvr_up_ch_1_wdata),
        .up_rx_wdata_2(axi_ad9680_xcvr_up_ch_2_wdata),
        .up_rx_wdata_3(axi_ad9680_xcvr_up_ch_3_wdata),
        .up_rx_wr_0(axi_ad9680_xcvr_up_ch_0_wr),
        .up_rx_wr_1(axi_ad9680_xcvr_up_ch_1_wr),
        .up_rx_wr_2(axi_ad9680_xcvr_up_ch_2_wr),
        .up_rx_wr_3(axi_ad9680_xcvr_up_ch_3_wr),
        .up_tx_addr_0(axi_ad9144_xcvr_up_ch_0_addr),
        .up_tx_addr_1(axi_ad9144_xcvr_up_ch_3_addr),
        .up_tx_addr_2(axi_ad9144_xcvr_up_ch_1_addr),
        .up_tx_addr_3(axi_ad9144_xcvr_up_ch_2_addr),
        .up_tx_diffctrl_0(axi_ad9144_xcvr_up_ch_0_tx_diffctrl),
        .up_tx_diffctrl_1(axi_ad9144_xcvr_up_ch_3_tx_diffctrl),
        .up_tx_diffctrl_2(axi_ad9144_xcvr_up_ch_1_tx_diffctrl),
        .up_tx_diffctrl_3(axi_ad9144_xcvr_up_ch_2_tx_diffctrl),
        .up_tx_enb_0(axi_ad9144_xcvr_up_ch_0_enb),
        .up_tx_enb_1(axi_ad9144_xcvr_up_ch_3_enb),
        .up_tx_enb_2(axi_ad9144_xcvr_up_ch_1_enb),
        .up_tx_enb_3(axi_ad9144_xcvr_up_ch_2_enb),
        .up_tx_lpm_dfe_n_0(axi_ad9144_xcvr_up_ch_0_lpm_dfe_n),
        .up_tx_lpm_dfe_n_1(axi_ad9144_xcvr_up_ch_3_lpm_dfe_n),
        .up_tx_lpm_dfe_n_2(axi_ad9144_xcvr_up_ch_1_lpm_dfe_n),
        .up_tx_lpm_dfe_n_3(axi_ad9144_xcvr_up_ch_2_lpm_dfe_n),
        .up_tx_out_clk_sel_0(axi_ad9144_xcvr_up_ch_0_out_clk_sel),
        .up_tx_out_clk_sel_1(axi_ad9144_xcvr_up_ch_3_out_clk_sel),
        .up_tx_out_clk_sel_2(axi_ad9144_xcvr_up_ch_1_out_clk_sel),
        .up_tx_out_clk_sel_3(axi_ad9144_xcvr_up_ch_2_out_clk_sel),
        .up_tx_pll_locked_0(axi_ad9144_xcvr_up_ch_0_pll_locked),
        .up_tx_pll_locked_1(axi_ad9144_xcvr_up_ch_3_pll_locked),
        .up_tx_pll_locked_2(axi_ad9144_xcvr_up_ch_1_pll_locked),
        .up_tx_pll_locked_3(axi_ad9144_xcvr_up_ch_2_pll_locked),
        .up_tx_postcursor_0(axi_ad9144_xcvr_up_ch_0_tx_postcursor),
        .up_tx_postcursor_1(axi_ad9144_xcvr_up_ch_3_tx_postcursor),
        .up_tx_postcursor_2(axi_ad9144_xcvr_up_ch_1_tx_postcursor),
        .up_tx_postcursor_3(axi_ad9144_xcvr_up_ch_2_tx_postcursor),
        .up_tx_precursor_0(axi_ad9144_xcvr_up_ch_0_tx_precursor),
        .up_tx_precursor_1(axi_ad9144_xcvr_up_ch_3_tx_precursor),
        .up_tx_precursor_2(axi_ad9144_xcvr_up_ch_1_tx_precursor),
        .up_tx_precursor_3(axi_ad9144_xcvr_up_ch_2_tx_precursor),
        .up_tx_rate_0(axi_ad9144_xcvr_up_ch_0_rate),
        .up_tx_rate_1(axi_ad9144_xcvr_up_ch_3_rate),
        .up_tx_rate_2(axi_ad9144_xcvr_up_ch_1_rate),
        .up_tx_rate_3(axi_ad9144_xcvr_up_ch_2_rate),
        .up_tx_rdata_0(axi_ad9144_xcvr_up_ch_0_rdata),
        .up_tx_rdata_1(axi_ad9144_xcvr_up_ch_3_rdata),
        .up_tx_rdata_2(axi_ad9144_xcvr_up_ch_1_rdata),
        .up_tx_rdata_3(axi_ad9144_xcvr_up_ch_2_rdata),
        .up_tx_ready_0(axi_ad9144_xcvr_up_ch_0_ready),
        .up_tx_ready_1(axi_ad9144_xcvr_up_ch_3_ready),
        .up_tx_ready_2(axi_ad9144_xcvr_up_ch_1_ready),
        .up_tx_ready_3(axi_ad9144_xcvr_up_ch_2_ready),
        .up_tx_rst_0(axi_ad9144_xcvr_up_ch_0_rst),
        .up_tx_rst_1(axi_ad9144_xcvr_up_ch_3_rst),
        .up_tx_rst_2(axi_ad9144_xcvr_up_ch_1_rst),
        .up_tx_rst_3(axi_ad9144_xcvr_up_ch_2_rst),
        .up_tx_rst_done_0(axi_ad9144_xcvr_up_ch_0_rst_done),
        .up_tx_rst_done_1(axi_ad9144_xcvr_up_ch_3_rst_done),
        .up_tx_rst_done_2(axi_ad9144_xcvr_up_ch_1_rst_done),
        .up_tx_rst_done_3(axi_ad9144_xcvr_up_ch_2_rst_done),
        .up_tx_sys_clk_sel_0(axi_ad9144_xcvr_up_ch_0_sys_clk_sel),
        .up_tx_sys_clk_sel_1(axi_ad9144_xcvr_up_ch_3_sys_clk_sel),
        .up_tx_sys_clk_sel_2(axi_ad9144_xcvr_up_ch_1_sys_clk_sel),
        .up_tx_sys_clk_sel_3(axi_ad9144_xcvr_up_ch_2_sys_clk_sel),
        .up_tx_user_ready_0(axi_ad9144_xcvr_up_ch_0_user_ready),
        .up_tx_user_ready_1(axi_ad9144_xcvr_up_ch_3_user_ready),
        .up_tx_user_ready_2(axi_ad9144_xcvr_up_ch_1_user_ready),
        .up_tx_user_ready_3(axi_ad9144_xcvr_up_ch_2_user_ready),
        .up_tx_wdata_0(axi_ad9144_xcvr_up_ch_0_wdata),
        .up_tx_wdata_1(axi_ad9144_xcvr_up_ch_3_wdata),
        .up_tx_wdata_2(axi_ad9144_xcvr_up_ch_1_wdata),
        .up_tx_wdata_3(axi_ad9144_xcvr_up_ch_2_wdata),
        .up_tx_wr_0(axi_ad9144_xcvr_up_ch_0_wr),
        .up_tx_wr_1(axi_ad9144_xcvr_up_ch_3_wr),
        .up_tx_wr_2(axi_ad9144_xcvr_up_ch_1_wr),
        .up_tx_wr_3(axi_ad9144_xcvr_up_ch_2_wr));

  system_rx_0 rx
       (.cfg_beats_per_multiframe(rx_axi_rx_cfg_beats_per_multiframe),
        .cfg_buffer_delay(rx_axi_rx_cfg_buffer_delay),
        .cfg_buffer_early_release(rx_axi_rx_cfg_buffer_early_release),
        .cfg_disable_char_replacement(rx_axi_rx_cfg_disable_char_replacement),
        .cfg_disable_scrambler(rx_axi_rx_cfg_disable_scrambler),
        .cfg_lanes_disable(rx_axi_rx_cfg_lanes_disable),
        .cfg_links_disable(rx_axi_rx_cfg_links_disable),
        .cfg_lmfc_offset(rx_axi_rx_cfg_lmfc_offset),
        .cfg_octets_per_frame(rx_axi_rx_cfg_octets_per_frame),
        .cfg_sysref_disable(rx_axi_rx_cfg_sysref_disable),
        .cfg_sysref_oneshot(rx_axi_rx_cfg_sysref_oneshot),
        .clk(device_clk_1),
        .ctrl_err_statistics_mask(rx_axi_rx_cfg_err_statistics_mask),
        .ctrl_err_statistics_reset(rx_axi_rx_cfg_err_statistics_reset),
        .event_sysref_alignment_error(rx_rx_event_sysref_alignment_error),
        .event_sysref_edge(rx_rx_event_sysref_edge),
        .ilas_config_addr(rx_rx_ilas_config_addr),
        .ilas_config_data(rx_rx_ilas_config_data),
        .ilas_config_valid(rx_rx_ilas_config_valid),
        .phy_block_sync({1'b0,1'b0,1'b0,1'b0}),
        .phy_charisk({util_daq2_xcvr_rx_3_rxcharisk, util_daq2_xcvr_rx_2_rxcharisk, util_daq2_xcvr_rx_1_rxcharisk, util_daq2_xcvr_rx_0_rxcharisk}),
        .phy_data({rx_phy3_1_rxdata,rx_phy2_1_rxdata,rx_phy1_1_rxdata,rx_phy0_1_rxdata}),
        .phy_disperr({rx_phy3_1_rxdisperr,rx_phy2_1_rxdisperr,rx_phy1_1_rxdisperr,rx_phy0_1_rxdisperr}),
        .phy_en_char_align(axi_ad9680_jesd_phy_en_char_align),
        .phy_header({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .phy_notintable({rx_phy3_1_rxnotintable,rx_phy2_1_rxnotintable,rx_phy1_1_rxnotintable,rx_phy0_1_rxnotintable}),
        .reset(rx_axi_core_reset),
        .rx_data(rx_rx_data),
        .rx_eof(rx_rx_eof),
        .rx_sof(rx_rx_sof),
        .rx_valid(rx_rx_valid),
        .status_ctrl_state(rx_rx_status_ctrl_state),
        .status_err_statistics_cnt(rx_rx_status_err_statistics_cnt),
        .status_lane_cgs_state(rx_rx_status_lane_cgs_state),
        .status_lane_emb_state(rx_rx_status_lane_emb_state),
        .status_lane_ifs_ready(rx_rx_status_lane_ifs_ready),
        .status_lane_latency(rx_rx_status_lane_latency),
        .sync(rx_sync),
        .sysref(sysref_1));

endmodule
