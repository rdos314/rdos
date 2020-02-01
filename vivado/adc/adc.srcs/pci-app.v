module pci_app (
    pci_exp_txp,
    pci_exp_txn,
    pci_exp_rxp,
    pci_exp_rxn,

    sys_clk,
    sys_rst
);

  output  [7:0]    pci_exp_txp;
  output  [7:0]    pci_exp_txn;
  input   [7:0]    pci_exp_rxp;
  input   [7:0]    pci_exp_rxn;

  input            sys_clk;
  input            sys_rst;

// Wire Declarations
  wire                                        pipe_mmcm_rst_n;

  wire                                        user_clk;
  wire                                        user_reset;
  wire                                        user_lnk_up;

  // Tx
  wire                                        s_axis_tx_tready;
  wire [3:0]                                  s_axis_tx_tuser;
  wire [127:0]                                s_axis_tx_tdata;
  wire [15:0]                                 s_axis_tx_tkeep;
  wire                                        s_axis_tx_tlast;
  wire                                        s_axis_tx_tvalid;

  // Rx
  wire [127:0]                                m_axis_rx_tdata;
  wire [15:0]                                 m_axis_rx_tkeep;
  wire                                        m_axis_rx_tlast;
  wire                                        m_axis_rx_tvalid;
  wire                                        m_axis_rx_tready;
  wire  [21:0]                                m_axis_rx_tuser;

  //-------------------------------------------------------
  // Configuration (CFG) Interface
  //-------------------------------------------------------
  wire                                        cfg_err_ecrc;
  wire                                        cfg_err_cor;
  wire                                        cfg_err_atomic_egress_blocked;
  wire                                        cfg_err_internal_cor;
  wire                                        cfg_err_malformed;
  wire                                        cfg_err_mc_blocked;
  wire                                        cfg_err_poisoned;
  wire                                        cfg_err_norecovery;
  wire                                        cfg_err_acs;
  wire                                        cfg_err_internal_uncor;
  wire                                        cfg_err_ur;
  wire                                        cfg_err_cpl_timeout;
  wire                                        cfg_err_cpl_abort;
  wire                                        cfg_err_cpl_unexpect;
  wire                                        cfg_err_posted;
  wire                                        cfg_err_locked;
  wire  [47:0]                                cfg_err_tlp_cpl_header;
  wire [127:0]                                cfg_err_aer_headerlog;
  wire   [4:0]                                cfg_aer_interrupt_msgnum;

  wire                                        cfg_interrupt;
  wire                                        cfg_interrupt_assert;
  wire   [7:0]                                cfg_interrupt_di;
  wire                                        cfg_interrupt_stat;
  wire   [4:0]                                cfg_pciecap_interrupt_msgnum;

  //-------------------------------------------------------
  // Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------
  wire                                        pl_directed_link_auton;
  wire [1:0]                                  pl_directed_link_change;
  wire                                        pl_directed_link_speed;
  wire [1:0]                                  pl_directed_link_width;
  wire                                        pl_upstream_prefer_deemph;

  wire                                        sys_rst_n_c;
  wire                                        sys_clk;


pcie_pipe_clock pipe_clock_inst (

          //---------- Input -------------------------------------
          .CLK_TXOUTCLK                   ( pipe_txoutclk_in ),     // Reference clock from lane 0
          .CLK_RXOUTCLK_IN                ( pipe_rxoutclk_in ),
          .CLK_RST_N                      ( pipe_mmcm_rst_n ),      // Allow system reset for error_recovery             
          .CLK_PCLK_SEL                   ( pipe_pclk_sel_in ),
          .CLK_PCLK_SEL_SLAVE             ( pipe_pclk_sel_slave),
          .CLK_GEN3                       ( pipe_gen3_in ),

          //---------- Output ------------------------------------
          .CLK_PCLK                       ( pipe_pclk_out),
          .CLK_PCLK_SLAVE                 ( pipe_pclk_out_slave),
          .CLK_RXUSRCLK                   ( pipe_rxusrclk_out),
          .CLK_RXOUTCLK_OUT               ( pipe_rxoutclk_out),
          .CLK_DCLK                       ( pipe_dclk_out),
          .CLK_OOBCLK                     ( pipe_oobclk_out),
          .CLK_USERCLK1                   ( pipe_userclk1_out),
          .CLK_USERCLK2                   ( pipe_userclk2_out),
          .CLK_MMCM_LOCK                  ( pipe_mmcm_lock_out)

      );

pci_rx pci_rx_inst (

    .clk(user_clk),                              // I
    .sys_rst(sys_rst),                      // I

    // AXIS RX
    .m_axis_rx_tdata( m_axis_rx_tdata ),    // I
    .m_axis_rx_tkeep( m_axis_rx_tkeep ),    // I
    .m_axis_rx_tlast( m_axis_rx_tlast ),    // I
    .m_axis_rx_tvalid( m_axis_rx_tvalid ),  // I
    .m_axis_rx_tready( m_axis_rx_tready ),  // O
    .m_axis_rx_tuser ( m_axis_rx_tuser )   // I
);

pci_tx pci_tx_inst (

    .clk(user_clk),                                  // I
    .sys_rst(sys_rst),                          // I

    // AXIS Tx
    .s_axis_tx_tready( s_axis_tx_tready ),      // I
    .s_axis_tx_tdata( s_axis_tx_tdata ),        // O
    .s_axis_tx_tkeep( s_axis_tx_tkeep ),        // O
    .s_axis_tx_tlast( s_axis_tx_tlast ),        // O
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),      // O
    .s_axis_tx_tuser( s_axis_tx_tuser )           // I
);


  assign cfg_err_cor = 1'b0;                       // Never report Correctable Error
  assign cfg_err_ur = 1'b0;                        // Never report UR
  assign cfg_err_ecrc = 1'b0;                      // Never report ECRC Error
  assign cfg_err_cpl_timeout = 1'b0;               // Never report Completion Timeout
  assign cfg_err_cpl_abort = 1'b0;                 // Never report Completion Abort
  assign cfg_err_cpl_unexpect = 1'b0;              // Never report unexpected completion
  assign cfg_err_posted = 1'b0;                    // Never qualify cfg_err_* inputs
  assign cfg_err_locked = 1'b0;                    // Never qualify cfg_err_ur or cfg_err_cpl_abort
  assign cfg_err_atomic_egress_blocked = 1'b0;     // Never report Atomic TLP blocked
  assign cfg_err_internal_cor = 1'b0;              // Never report internal error occurred
  assign cfg_err_malformed = 1'b0;                 // Never report malformed error
  assign cfg_err_mc_blocked = 1'b0;                // Never report multi-cast TLP blocked
  assign cfg_err_poisoned = 1'b0;                  // Never report poisoned TLP received
  assign cfg_err_norecovery = 1'b0;                // Never qualify cfg_err_poisoned or cfg_err_cpl_timeout
  assign cfg_err_acs = 1'b0;                       // Never report an ACS violation
  assign cfg_err_internal_uncor = 1'b0;            // Never report internal uncorrectable error
  assign cfg_err_aer_headerlog = 128'h0;           // Zero out the AER Header Log
  assign cfg_aer_interrupt_msgnum = 5'b00000;      // Zero out the AER Root Error Status Register
  assign cfg_err_tlp_cpl_header = 48'h0;           // Zero out the header information

  assign cfg_interrupt_stat = 1'b0;                // Never set the Interrupt Status bit
  assign cfg_pciecap_interrupt_msgnum = 5'b00000;  // Zero out Interrupt Message Number
  assign cfg_interrupt_assert = 1'b0;              // Always drive interrupt de-assert
  assign cfg_interrupt = 1'b0;                     // Never drive interrupt by qualifying cfg_interrupt_assert
  assign cfg_interrupt_di = 8'b0;                  // Do not set interrupt fields

  assign pl_directed_link_change = 2'b00;          // Never initiate link change
  assign pl_directed_link_width = 2'b00;          // Zero out directed link width
  assign pl_directed_link_speed = 1'b0;            // Zero out directed link speed
  assign pl_directed_link_auton = 1'b0;            // Zero out link autonomous input
  assign pl_upstream_prefer_deemph = 1'b1;         // Zero out preferred de-emphasis of upstream port

pcie pcie_inst (
  .pci_exp_txp(pci_exp_txp),                                        // output wire [7 : 0] pci_exp_txp
  .pci_exp_txn(pci_exp_txn),                                        // output wire [7 : 0] pci_exp_txn
  .pci_exp_rxp(pci_exp_rxp),                                        // input wire [7 : 0] pci_exp_rxp
  .pci_exp_rxn(pci_exp_rxn),                                        // input wire [7 : 0] pci_exp_rxn

  .pipe_pclk_in(pipe_pclk_out),                                     // input wire pipe_pclk_in
  .pipe_rxusrclk_in(pipe_rxusrclk_out),                             // input wire pipe_rxusrclk_in
  .pipe_rxoutclk_in(pipe_rxoutclk_out),                             // input wire [7 : 0] pipe_rxoutclk_in
  .pipe_dclk_in(pipe_dclk_out),                                     // input wire pipe_dclk_in
  .pipe_userclk1_in(pipe_userclk1_out),                             // input wire pipe_userclk1_in
  .pipe_userclk2_in(pipe_userclk2_out),                             // input wire pipe_userclk2_in
  .pipe_oobclk_in(pipe_oobclk_out),                                 // input wire pipe_oobclk_in
  .pipe_mmcm_lock_in(pipe_mmcm_lock_out),                           // input wire pipe_mmcm_lock_in
  .pipe_txoutclk_out(pipe_txoutclk_in),                             // output wire pipe_txoutclk_out
  .pipe_rxoutclk_out(pipe_rxoutclk_in),                             // output wire [7 : 0] pipe_rxoutclk_out
  .pipe_pclk_sel_out(pipe_pclk_sel_in),                             // output wire [7 : 0] pipe_pclk_sel_out
  .pipe_gen3_out(pipe_gen3_in),                                     // output wire pipe_gen3_out

  .user_clk_out(user_clk),                                          // output wire user_clk_out
  .user_reset_out(user_reset),                                      // output wire user_reset_out
  .user_lnk_up(user_lnk_up),                                        // output wire user_lnk_up
  .user_app_rdy(),                                                  // output wire user_app_rdy

  .s_axis_tx_tready(s_axis_tx_tready),                              // output wire s_axis_tx_tready
  .s_axis_tx_tdata(s_axis_tx_tdata),                                // input wire [127 : 0] s_axis_tx_tdata
  .s_axis_tx_tkeep(s_axis_tx_tkeep),                                // input wire [15 : 0] s_axis_tx_tkeep
  .s_axis_tx_tlast(s_axis_tx_tlast),                                // input wire s_axis_tx_tlast
  .s_axis_tx_tvalid(s_axis_tx_tvalid),                              // input wire s_axis_tx_tvalid
  .s_axis_tx_tuser(s_axis_tx_tuser),                                // input wire [3 : 0] s_axis_tx_tuser

  .m_axis_rx_tdata(m_axis_rx_tdata),                                // output wire [127 : 0] m_axis_rx_tdata
  .m_axis_rx_tkeep(m_axis_rx_tkeep),                                // output wire [15 : 0] m_axis_rx_tkeep
  .m_axis_rx_tlast(m_axis_rx_tlast),                                // output wire m_axis_rx_tlast
  .m_axis_rx_tvalid(m_axis_rx_tvalid),                              // output wire m_axis_rx_tvalid
  .m_axis_rx_tready(m_axis_rx_tready),                              // input wire m_axis_rx_tready
  .m_axis_rx_tuser(m_axis_rx_tuser),                                // output wire [21 : 0] m_axis_rx_tuser

  .cfg_err_ecrc(cfg_err_ecrc),                                      // input wire cfg_err_ecrc
  .cfg_err_ur(cfg_err_ur),                                          // input wire cfg_err_ur
  .cfg_err_cpl_timeout(cfg_err_cpl_timeout),                        // input wire cfg_err_cpl_timeout
  .cfg_err_cpl_unexpect(cfg_err_cpl_unexpect),                      // input wire cfg_err_cpl_unexpect
  .cfg_err_cpl_abort(cfg_err_cpl_abort),                            // input wire cfg_err_cpl_abort
  .cfg_err_posted(cfg_err_posted),                                  // input wire cfg_err_posted
  .cfg_err_cor(cfg_err_cor),                                        // input wire cfg_err_cor
  .cfg_err_atomic_egress_blocked(cfg_err_atomic_egress_blocked),    // input wire cfg_err_atomic_egress_blocked
  .cfg_err_internal_cor(cfg_err_internal_cor),                      // input wire cfg_err_internal_cor
  .cfg_err_malformed(cfg_err_malformed),                            // input wire cfg_err_malformed
  .cfg_err_mc_blocked(cfg_err_mc_blocked),                          // input wire cfg_err_mc_blocked
  .cfg_err_poisoned(cfg_err_poisoned),                              // input wire cfg_err_poisoned
  .cfg_err_norecovery(cfg_err_norecovery),                          // input wire cfg_err_norecovery
  .cfg_err_tlp_cpl_header(cfg_err_tlp_cpl_header),                  // input wire [47 : 0] cfg_err_tlp_cpl_header
  .cfg_err_cpl_rdy(),                                               // output wire cfg_err_cpl_rdy
  .cfg_err_locked(cfg_err_locked),                                  // input wire cfg_err_locked
  .cfg_err_acs(cfg_err_acs),                                        // input wire cfg_err_acs
  .cfg_err_internal_uncor(cfg_err_internal_uncor),                  // input wire cfg_err_internal_uncor

  .cfg_interrupt(cfg_interrupt),                                    // input wire cfg_interrupt
  .cfg_interrupt_rdy(),                                             // output wire cfg_interrupt_rdy
  .cfg_interrupt_assert(cfg_interrupt_assert),                      // input wire cfg_interrupt_assert
  .cfg_interrupt_di(cfg_interrupt_di),                              // input wire [7 : 0] cfg_interrupt_di
  .cfg_interrupt_do(),                                              // output wire [7 : 0] cfg_interrupt_do
  .cfg_interrupt_mmenable(),                                        // output wire [2 : 0] cfg_interrupt_mmenable
  .cfg_interrupt_msienable(),                                       // output wire cfg_interrupt_msienable
  .cfg_interrupt_msixenable(),                                      // output wire cfg_interrupt_msixenable
  .cfg_interrupt_msixfm(),                                          // output wire cfg_interrupt_msixfm
  .cfg_interrupt_stat(cfg_interrupt_stat),                          // input wire cfg_interrupt_stat
  .cfg_pciecap_interrupt_msgnum(cfg_pciecap_interrupt_msgnum),      // input wire [4 : 0] cfg_pciecap_interrupt_msgnum

  .pl_directed_link_change(pl_directed_link_change),                // input wire [1 : 0] pl_directed_link_change
  .pl_directed_link_width(pl_directed_link_width),                  // input wire [1 : 0] pl_directed_link_width
  .pl_directed_link_speed(pl_directed_link_speed),                  // input wire pl_directed_link_speed
  .pl_directed_link_auton(pl_directed_link_auton),                  // input wire pl_directed_link_auton
  .pl_upstream_prefer_deemph(pl_upstream_prefer_deemph),            // input wire pl_upstream_prefer_deemph
  .pl_sel_lnk_rate(),                                               // output wire pl_sel_lnk_rate
  .pl_sel_lnk_width(),                                              // output wire [1 : 0] pl_sel_lnk_width
  .pl_ltssm_state(),                                                // output wire [5 : 0] pl_ltssm_state
  .pl_lane_reversal_mode(),                                         // output wire [1 : 0] pl_lane_reversal_mode
  .pl_phy_lnk_up(),                                                 // output wire pl_phy_lnk_up
  .pl_tx_pm_state(),                                                // output wire [2 : 0] pl_tx_pm_state
  .pl_rx_pm_state(),                                                // output wire [1 : 0] pl_rx_pm_state
  .pl_link_upcfg_cap(),                                             // output wire pl_link_upcfg_cap
  .pl_link_gen2_cap(),                                              // output wire pl_link_gen2_cap
  .pl_link_partner_gen2_supported(),                                // output wire pl_link_partner_gen2_supported
  .pl_initial_link_width(),                                         // output wire [2 : 0] pl_initial_link_width
  .pl_directed_change_done(),                                       // output wire pl_directed_change_done
  .pl_received_hot_rst(),                                           // output wire pl_received_hot_rst
  .pl_transmit_hot_rst(1'b0),                                       // input wire pl_transmit_hot_rst
  .pl_downstream_deemph_source(1'b0),                               // input wire pl_downstream_deemph_source

  .cfg_err_aer_headerlog(cfg_err_aer_headerlog),                    // input wire [127 : 0] cfg_err_aer_headerlog
  .cfg_aer_interrupt_msgnum(cfg_aer_interrupt_msgnum),              // input wire [4 : 0] cfg_aer_interrupt_msgnum
  .cfg_err_aer_headerlog_set(),                                     // output wire cfg_err_aer_headerlog_set
  .cfg_aer_ecrc_check_en(),                                         // output wire cfg_aer_ecrc_check_en
  .cfg_aer_ecrc_gen_en(),                                           // output wire cfg_aer_ecrc_gen_en

  .sys_clk(sys_clk),                                                // input wire sys_clk
  .sys_rst_n(!sys_rst),                                             // input wire sys_rst_n
  .pipe_mmcm_rst_n(pipe_mmcm_rst_n)                                 // input wire pipe_mmcm_rst_n
  );

endmodule
