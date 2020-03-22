module pci_app (
    pci_exp_txp,
    pci_exp_txn,
    pci_exp_rxp,
    pci_exp_rxn,

    sys_clk,
    sys_rst_n,
    
    user_clk,
    user_reset,
    user_lnk_up,
    user_lnk_rate,
    user_lnk_width,
    cfg_interrupt_msienable,

    up_clk,    
    spi_cs_clk,
    spi_cs_adc,
    spi_cs_dac,
    spi_clk,
    spi_sdio,
    spi_dir,

    bar_control,
    bar_adc_test_mode,

    adc_start,
    adc_stop,
    adc_running,
    adc_probing,
    adc_valid,
    adc_sysref_cnt,

    adc_sync_fail_cnt,
    adc_sync_ok_cnt,

    adc_wr,
    adc_data,

    adc_spi_read,
    adc_spi_write,
    adc_spi_adr,
    adc_spi_in_data,
    adc_spi_out_data,
    adc_spi_running,
    adc_spi_done
);

  output  [7:0]        pci_exp_txp;
  output  [7:0]        pci_exp_txn;
  input   [7:0]        pci_exp_rxp;
  input   [7:0]        pci_exp_rxn;

  input                sys_clk;
  input                sys_rst_n;
  
  output               user_clk;
  output               user_reset;
  output               user_lnk_up;
  
  output               user_lnk_rate;
  output   [1:0]       user_lnk_width;
  output               cfg_interrupt_msienable;

  input                up_clk;
  output               spi_cs_clk;
  output               spi_cs_adc;
  output               spi_cs_dac;
  output               spi_clk;
  inout                spi_sdio;
  output               spi_dir;

  output reg [7:0]     bar_control;
  output reg [7:0]     bar_adc_test_mode;

  output reg           adc_start;
  output reg           adc_stop;
  input  wire          adc_running;
  input  wire          adc_probing;
  input  wire          adc_valid;
  input wire [63:0]    adc_sysref_cnt;
  input wire [31:0]    adc_sync_fail_cnt;
  input wire [31:0]    adc_sync_ok_cnt;

  input wire           adc_wr;
  input wire [1023:0]  adc_data;

  input                adc_spi_read;
  input                adc_spi_write;
  input      [11:0]    adc_spi_adr;
  output     [7:0]     adc_spi_in_data;
  input      [7:0]     adc_spi_out_data;
  output               adc_spi_running;
  output               adc_spi_done;


// Wire Declarations

  wire             req_stop;
  wire [63:0]      adc_address;

  wire [16:0]      bar1_address;
  wire             bar1_rd;
  wire             bar1_rp;
  wire [31:0]      bar1_rp_data;
  wire             bar1_wr;
  wire [3:0]       bar1_wr_be;
  wire [31:0]      bar1_wr_data;
  wire             bar1_ack;

  wire [16:0]      bar2_address;
  wire             bar2_rd;
  wire             bar2_rp;
  wire [31:0]      bar2_rp_data;
  wire             bar2_wr;
  wire [3:0]       bar2_wr_be;
  wire [31:0]      bar2_wr_data;
  wire             bar2_ack;

  wire             user_clk;
  wire             user_reset;
  wire             user_lnk_up;
  wire             user_lnk_rate;
  wire [1:0]       user_lnk_width;
  wire             cfg_interrupt_msienable;
  
  // Tx
  wire             s_axis_tx_tready;
  wire [3:0]       s_axis_tx_tuser;
  wire [127:0]     s_axis_tx_tdata;
  wire [15:0]      s_axis_tx_tkeep;
  wire             s_axis_tx_tlast;
  wire             s_axis_tx_tvalid;

  // Rx
  wire [127:0]     m_axis_rx_tdata;
  wire [15:0]      m_axis_rx_tkeep;
  wire             m_axis_rx_tlast;
  wire             m_axis_rx_tvalid;
  wire             m_axis_rx_tready;
  wire [21:0]      m_axis_rx_tuser;

// PCIe -> local

  wire [1023:0]    pci_rx_data;
  wire [127:0]     pci_rx_header;
  wire [127:0]     pci_rx_be;
  wire [15:0]      pci_rx_control;
  wire             pci_rx_rd;
  wire             pci_rx_empty;
  wire             pci_rx_full;

// local -> PCIe

  wire [1023:0]    pci_tx_data;
  wire [127:0]     pci_tx_header;
  wire             pci_tx_wr;
  wire             pci_tx_full;


// local memory

  wire [9:0]       bar0_address;
  wire             bar0_rd;
  reg              bar0_rp;
  reg  [31:0]      bar0_rp_data;
  wire             bar0_wr;
  wire [3:0]       bar0_wr_be;
  wire [31:0]      bar0_wr_data;
  reg              bar0_ack;
  
  reg [31:0]       bar_spi_clk;
  reg [31:0]       bar_spi_adc;
  reg [31:0]       bar_spi_dac;
  
  reg              spi_wr;
  reg [31:0]       spi_fifo_req_in;
  wire [31:0]      spi_fifo_req_out;
  wire             spi_fifo_req_empty;

  wire             spi_rp_empty;
  wire [29:0]      spi_rp_data;
  reg              spi_rp_ack;
  
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

  wire                                        sys_rst_n;
  wire                                        sys_clk;

pcie pcie_i
 (

  //----------------------------------------------------------------------------------------------------------------//
  // PCI Express (pci_exp) Interface                                                                                //
  //----------------------------------------------------------------------------------------------------------------//
  // Tx
  .pci_exp_txn                               ( pci_exp_txn ),
  .pci_exp_txp                               ( pci_exp_txp ),

  // Rx
  .pci_exp_rxn                               ( pci_exp_rxn ),
  .pci_exp_rxp                               ( pci_exp_rxp ),


  //----------------------------------------------------------------------------------------------------------------//
  // Shared Logic Internal                                                                                          //
  //----------------------------------------------------------------------------------------------------------------//
  .int_pclk_out_slave                        ( ),
  .int_pipe_rxusrclk_out                     ( ),
  .int_rxoutclk_out                          ( ),
  .int_dclk_out                              ( ),
  .int_userclk1_out                          ( ),
  .int_userclk2_out                          ( ),
  .int_oobclk_out                            ( ),
  .int_qplllock_out                          ( ),
  .int_qplloutclk_out                        ( ),
  .int_qplloutrefclk_out                     ( ),
  .int_pclk_sel_slave                        ( 8'b0),
  .int_mmcm_lock_out                         ( ),

  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//
  // Common
  .user_clk_out                              ( user_clk ),
  .user_reset_out                            ( user_reset ),
  .user_lnk_up                               ( user_lnk_up ),
  .user_app_rdy                              ( ),

  // TX
  .s_axis_tx_tready                          ( s_axis_tx_tready ),
  .s_axis_tx_tdata                           ( s_axis_tx_tdata ),
  .s_axis_tx_tkeep                           ( s_axis_tx_tkeep ),
  .s_axis_tx_tuser                           ( s_axis_tx_tuser ),
  .s_axis_tx_tlast                           ( s_axis_tx_tlast ),
  .s_axis_tx_tvalid                          ( s_axis_tx_tvalid ),

  // Rx
  .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
  .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
  .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
  .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
  .m_axis_rx_tready                          ( m_axis_rx_tready ),
  .m_axis_rx_tuser                           ( m_axis_rx_tuser ),





  // Error Reporting Interface
  .cfg_err_ecrc                              ( cfg_err_ecrc ),
  .cfg_err_ur                                ( cfg_err_ur ),
  .cfg_err_cpl_timeout                       ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_unexpect                      ( cfg_err_cpl_unexpect ),
  .cfg_err_cpl_abort                         ( cfg_err_cpl_abort ),
  .cfg_err_posted                            ( cfg_err_posted ),
  .cfg_err_cor                               ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked             ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor                      ( cfg_err_internal_cor ),
  .cfg_err_malformed                         ( cfg_err_malformed ),
  .cfg_err_mc_blocked                        ( cfg_err_mc_blocked ),
  .cfg_err_poisoned                          ( cfg_err_poisoned ),
  .cfg_err_norecovery                        ( cfg_err_norecovery ),
  .cfg_err_tlp_cpl_header                    ( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy                           ( ),
  .cfg_err_locked                            ( cfg_err_locked ),
  .cfg_err_acs                               ( cfg_err_acs ),
  .cfg_err_internal_uncor                    ( cfg_err_internal_uncor ),
  //----------------------------------------------------------------------------------------------------------------//
  // AER Interface                                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog                     ( cfg_err_aer_headerlog ),
  .cfg_aer_interrupt_msgnum                  ( cfg_aer_interrupt_msgnum ),
  .cfg_err_aer_headerlog_set                 ( ),
  .cfg_aer_ecrc_check_en                     ( ),
  .cfg_aer_ecrc_gen_en                       ( ),

  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .cfg_interrupt                             ( cfg_interrupt ),
  .cfg_interrupt_rdy                         ( ),
  .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
  .cfg_interrupt_di                          ( cfg_interrupt_di ),
  .cfg_interrupt_do                          ( ),
  .cfg_interrupt_mmenable                    ( ),
  .cfg_interrupt_msienable                   ( cfg_interrupt_msienable ),
  .cfg_interrupt_msixenable                  ( ),
  .cfg_interrupt_msixfm                      ( ),
  .cfg_interrupt_stat                        ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum              ( cfg_pciecap_interrupt_msgnum ),


  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_change                   ( pl_directed_link_change ),
  .pl_directed_link_width                    ( pl_directed_link_width ),
  .pl_directed_link_speed                    ( pl_directed_link_speed ),
  .pl_directed_link_auton                    ( pl_directed_link_auton ),
  .pl_upstream_prefer_deemph                 ( pl_upstream_prefer_deemph ),

  .pl_sel_lnk_rate                           ( user_lnk_rate),
  .pl_sel_lnk_width                          ( user_lnk_width),
  .pl_ltssm_state                            ( ),
  .pl_lane_reversal_mode                     ( ),

  .pl_phy_lnk_up                             ( ),
  .pl_tx_pm_state                            ( ),
  .pl_rx_pm_state                            ( ),

  .pl_link_upcfg_cap                         ( ),
  .pl_link_gen2_cap                          ( ),
  .pl_link_partner_gen2_supported            ( ),
  .pl_initial_link_width                     ( ),

  .pl_directed_change_done                   ( ),

  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .pl_received_hot_rst                       ( ),

  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .pl_transmit_hot_rst                       ( 1'b0 ),
  .pl_downstream_deemph_source               ( 1'b0 ),




  //----------------------------------------------------------------------------------------------------------------//
  // System  (SYS) Interface                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//
  .sys_clk                                    ( sys_clk ),
  .sys_rst_n                                  ( sys_rst_n )

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

pci_rx pci_rx_inst (

    .clk(user_clk),                             // I
    .reset(user_reset),                         // I

    // AXIS RX
    .m_axis_rx_tdata( m_axis_rx_tdata ),        // I
    .m_axis_rx_tkeep( m_axis_rx_tkeep ),        // I
    .m_axis_rx_tlast( m_axis_rx_tlast ),        // I
    .m_axis_rx_tvalid( m_axis_rx_tvalid ),      // I
    .m_axis_rx_tready( m_axis_rx_tready ),      // O
    .m_axis_rx_tuser ( m_axis_rx_tuser ),       // I

    .pci_rx_data( pci_rx_data),                    // O
    .pci_rx_header( pci_rx_header),                // O
    .pci_rx_be( pci_rx_be),                        // O
    .pci_rx_control( pci_rx_control),              // O
    .pci_rx_rd (pci_rx_rd),                        // I
    .pci_rx_empty (pci_rx_empty),                   // O
    .pci_rx_full (pci_rx_full)                   // O
);

pci_tx pci_tx_inst (

    .clk(user_clk),                             // I
    .reset(user_reset),                         // I

    // AXIS Tx
    .s_axis_tx_tready( s_axis_tx_tready ),      // I
    .s_axis_tx_tdata( s_axis_tx_tdata ),        // O
    .s_axis_tx_tkeep( s_axis_tx_tkeep ),        // O
    .s_axis_tx_tlast( s_axis_tx_tlast ),        // O
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),      // O
    .s_axis_tx_tuser( s_axis_tx_tuser ),        // I
    
    .pci_tx_data( pci_tx_data),                 // I
    .pci_tx_header( pci_tx_header),             // I
    .pci_tx_wr (pci_tx_wr),                     // I
    .pci_tx_full (pci_tx_full)                  // O
);

adc_mem adc_mem_inst (

    .clk(user_clk),                             // I
    .reset(user_reset),                         // I

    .pci_rx_data( pci_rx_data),                 // I
    .pci_rx_header( pci_rx_header),             // I
    .pci_rx_be( pci_rx_be),                     // I
    .pci_rx_control( pci_rx_control),           // I
    .pci_rx_rd (pci_rx_rd),                     // O
    .pci_rx_empty (pci_rx_empty),               // I

    .pci_tx_data( pci_tx_data),                 // O
    .pci_tx_header( pci_tx_header),             // O
    .pci_tx_wr( pci_tx_wr),                     // O
    .pci_tx_full( pci_tx_full),                 // I

    .adc_send( 0),                              // I
    .adc_address( adc_address),                 // I
    .adc_data( adc_data),                       // I

    .bar0_address( bar0_address),               // O
    .bar0_rd( bar0_rd),                         // O
    .bar0_rp( bar0_rp),                         // I
    .bar0_rp_data( bar0_rp_data),               // I
    .bar0_wr( bar0_wr),                         // O
    .bar0_wr_be( bar0_wr_be),                   // O
    .bar0_wr_data( bar0_wr_data),               // O
    .bar0_ack( bar0_ack),                       // I

    .bar1_address( bar1_address),               // O
    .bar1_rd( bar1_rd),                         // O
    .bar1_rp( bar1_rp),                         // I
    .bar1_rp_data( bar1_rp_data),               // I
    .bar1_wr( bar1_wr),                         // O
    .bar1_wr_be( bar1_wr_be),                   // O
    .bar1_wr_data( bar1_wr_data),               // O
    .bar1_ack( bar1_ack),                       // I

    .bar2_address( bar2_address),               // O
    .bar2_rd( bar2_rd),                         // O
    .bar2_rp( bar2_rp),                         // I
    .bar2_rp_data( bar2_rp_data),               // I
    .bar2_wr( bar2_wr),                         // O
    .bar2_wr_be( bar2_wr_be),                   // O
    .bar2_wr_data( bar2_wr_data),               // O
    .bar2_ack( bar2_ack)                        // I
);

  daq2_spi daq2_spi_inst (
    .clk (user_clk),
    .reset (user_reset),
    .up_clk (up_clk),

    .spi_rq_rd (spi_fifo_req_out[31]),
    .spi_rq_cs (spi_fifo_req_out[30:29]),
    .spi_rq_word (spi_fifo_req_out[28]),
    .spi_rq_adr (spi_fifo_req_out[27:16]),
    .spi_rq_empty (spi_fifo_req_empty),
    .spi_rq_data (spi_fifo_req_out[15:0]),
    .spi_rq_ack (spi_rq_ack),

    .adc_read(adc_spi_read),
    .adc_write(adc_spi_write),
    .adc_adr(adc_spi_adr),
    .adc_in_data(adc_spi_in_data),
    .adc_out_data(adc_spi_out_data),
    .adc_running(adc_spi_running),
    .adc_done(adc_spi_done),

    .spi_rp_empty (spi_rp_empty),
    .spi_rp_data (spi_rp_data),
    .spi_rp_ack (spi_rp_ack),

    .spi_cs_clk (spi_cs_clk),
    .spi_cs_adc (spi_cs_adc),
    .spi_cs_dac (spi_cs_dac),
    .spi_clk (spi_clk),
    .spi_sdio (spi_sdio),
    .spi_dir (spi_dir));

spi_fifo_rq spi_fifo_rq_inst (
  .rst(user_reset),             // input wire rst
  .wr_clk(user_clk),            // input wire wr_clk
  .rd_clk(up_clk),              // input wire rd_clk
  .din(spi_fifo_req_in),        // input wire [31 : 0] din
  .wr_en(spi_wr),               // input wire wr_en
  .rd_en(spi_rq_ack),           // input wire rd_en
  .dout(spi_fifo_req_out),      // output wire [31 : 0] dout
  .full(),                      // output wire full
  .empty(spi_fifo_req_empty)    // output wire empty
);

adc_app adc_app_inst (
    .clk(user_clk),
    .reset(user_reset),

    .running(adc_running),
    .probing(1),
    .req_stop(req_stop),
    .adc_wr(adc_wr),
    .adc_address(adc_address),

    .address(bar1_address),
    .rd(bar1_rd),
    .rp(bar1_rp),
    .rp_data(bar1_rp_data),
    .wr(bar1_wr),
    .wr_be(bar1_wr_be),
    .wr_data(bar1_wr_data),
    .ack(bar1_ack)
);

ila_3 ila3_inst (
   .clk ( user_clk ),                      // I
   .probe0(adc_wr),                   // input wire [0:0]  probe1 
   .probe1(adc_probing),              // input wire [0:0]  probe1 
   .probe2(adc_address),              // input wire [63:0]  probe1 
   .probe3(adc_data[31:0]),           // input wire [31:0]  probe1 
   .probe4(adc_data[63:32]),          // input wire [31:0]  probe1 
   .probe5(adc_data[95:64]),          // input wire [31:0]  probe1 
   .probe6(adc_data[127:96])          // input wire [31:0]  probe1 
);

generate
  begin : pci_app

    always @ ( posedge user_clk ) 
    begin
      if (bar0_wr && !bar0_ack)
      begin
        case (bar0_address)            
          1:
          begin
            if (bar0_wr_be[0])
              spi_fifo_req_in[7:0] = bar0_wr_data[7:0];
            else 
              spi_fifo_req_in[7:0] = bar_spi_clk[7:0];
 
            if (bar0_wr_be[1])
              spi_fifo_req_in[15:8] = bar0_wr_data[15:8];
            else 
              spi_fifo_req_in[15:8] = bar_spi_clk[15:8];
 
            if (bar0_wr_be[2])
              spi_fifo_req_in[23:16] = bar0_wr_data[23:16];
            else 
              spi_fifo_req_in[23:16] = bar_spi_clk[23:16];

            if (bar0_wr_be[3])
              spi_fifo_req_in[30:29] = 0;
          end

          2:
          begin
            if (bar0_wr_be[0])
              spi_fifo_req_in[7:0] = bar0_wr_data[7:0];
            else 
              spi_fifo_req_in[7:0] = bar_spi_adc[7:0];
 
            if (bar0_wr_be[1])
              spi_fifo_req_in[15:8] = bar0_wr_data[15:8];
            else 
              spi_fifo_req_in[15:8] = bar_spi_adc[15:8];
 
            if (bar0_wr_be[2])
              spi_fifo_req_in[23:16] = bar0_wr_data[23:16];
            else 
              spi_fifo_req_in[23:16] = bar_spi_adc[23:16];

            if (bar0_wr_be[3])
              spi_fifo_req_in[30:29] = 1;
          end

          3:
          begin
            if (bar0_wr_be[0])
              spi_fifo_req_in[7:0] = bar0_wr_data[7:0];
            else 
              spi_fifo_req_in[7:0] = bar_spi_dac[7:0];
 
            if (bar0_wr_be[1])
              spi_fifo_req_in[15:8] = bar0_wr_data[15:8];
            else 
              spi_fifo_req_in[15:8] = bar_spi_dac[15:8];
 
            if (bar0_wr_be[2])
              spi_fifo_req_in[23:16] = bar0_wr_data[23:16];
            else 
              spi_fifo_req_in[23:16] = bar_spi_dac[23:16];

            if (bar0_wr_be[3])
              spi_fifo_req_in[30:29] = 2;
          end
        endcase

        if (bar0_wr_be[3])
        begin
          spi_fifo_req_in[27:24] = bar0_wr_data[27:24];

          case (bar0_wr_data[31:28])
            12:
            begin
              spi_fifo_req_in[31] = 1;
              spi_fifo_req_in[28] = 1;
              spi_wr = 1;
            end

            2:
            begin
              spi_fifo_req_in[31] = 0;
              spi_fifo_req_in[28] = 1;
              spi_wr = 1;
            end

            1:
            begin
              spi_fifo_req_in[31] = 0;
              spi_fifo_req_in[28] = 0;
              spi_wr = 1;
            end

            default:
            begin
              spi_wr = 0;
            end
          endcase
        end
        else
          spi_wr = 0;
      end
      else
        spi_wr = 0;
    end

    always @ ( posedge user_clk ) 
    begin
      if (user_reset)
      begin
        bar_control <= 0;
        bar_adc_test_mode <= 7;
        adc_start <= 0;
        adc_stop <= 0;
        spi_rp_ack <= 0;
      end
      else
      begin
        bar_control[0] <= pci_rx_full;
        bar_control[1] <= pci_tx_full;

        bar_control[6] <= adc_valid;
        bar_control[7] <= adc_running;

        if (bar0_rd)
        begin
          case (bar0_address)
            0: bar0_rp_data <= {16'h0, bar_adc_test_mode, bar_control};
            1: bar0_rp_data <= bar_spi_clk;
            2: bar0_rp_data <= bar_spi_adc;
            3: bar0_rp_data <= bar_spi_dac;
            4: bar0_rp_data <= adc_sysref_cnt[31:0];
            5: bar0_rp_data <= adc_sysref_cnt[63:32];
            6: bar0_rp_data <= adc_sync_fail_cnt;
            7: bar0_rp_data <= adc_sync_ok_cnt;
            default: bar0_rp_data <= 31'hffffffff;
          endcase     
          bar0_rp <= 1;
        end
        else
          bar0_rp <= 0;

        if (bar0_wr)
        begin
          case (bar0_address)
            0: 
            begin
              if (bar0_wr_be[0])
              begin
                bar_control[6:2] <= bar0_wr_data[6:2];
                if (bar_control[7] != bar0_wr_data[7])
                begin
                  if (bar0_wr_data[7])
                  begin
                    if (adc_address != 0)
                      adc_start <= 1;
                  end 
                  else
                    adc_stop <= 1;
                end      
              end

              if (bar0_wr_be[1])
                bar_adc_test_mode[7:0] <= bar0_wr_data[15:8]; 
            end
            
            1:
            begin
              if (bar0_wr_be[0])
                bar_spi_clk[7:0] <= bar0_wr_data[7:0];
 
              if (bar0_wr_be[1])
                bar_spi_clk[15:8] <= bar0_wr_data[15:8];
 
              if (bar0_wr_be[2])
                bar_spi_clk[23:16] <= bar0_wr_data[23:16];

              if (bar0_wr_be[3])
              begin
                bar_spi_clk[27:24] <= bar0_wr_data[27:24];

                case (bar0_wr_data[31:28])
                  12:      bar_spi_clk[31:28] <= 15;
                  1, 2:    bar_spi_clk[31:28] <= 0;
                  default: bar_spi_clk[31:28] <= 0;
                endcase
              end
            end

            2:
            begin
              if (bar0_wr_be[0])
                bar_spi_adc[7:0] <= bar0_wr_data[7:0];
 
              if (bar0_wr_be[1])
                bar_spi_adc[15:8] <= bar0_wr_data[15:8];
 
              if (bar0_wr_be[2])
                bar_spi_adc[23:16] <= bar0_wr_data[23:16];

              if (bar0_wr_be[3])
              begin
                bar_spi_adc[27:24] <= bar0_wr_data[27:24];

                case (bar0_wr_data[31:28])
                  12:      bar_spi_adc[31:28] <= 15;
                  1, 2:    bar_spi_adc[31:28] <= 0;
                  default: bar_spi_adc[31:28] <= 0;
                endcase
              end
            end

            3:
            begin
              if (bar0_wr_be[0])
                bar_spi_dac[7:0] <= bar0_wr_data[7:0];
 
              if (bar0_wr_be[1])
                bar_spi_dac[15:8] <= bar0_wr_data[15:8];
 
              if (bar0_wr_be[2])
                bar_spi_dac[23:16] <= bar0_wr_data[23:16];

              if (bar0_wr_be[3])
              begin
                bar_spi_dac[27:24] <= bar0_wr_data[27:24];

                case (bar0_wr_data[31:28])
                  12:      bar_spi_dac[31:28] <= 15;
                  1, 2:    bar_spi_dac[31:28] <= 0;
                  default: bar_spi_dac[31:28] <= 0;
                endcase
              end
            end
            
            default:
            begin
              adc_start <= 0;
              adc_stop <= 0;
            end
          endcase
          bar0_ack <= 1;
          spi_rp_ack <= 0;
        end
        else
        begin
          adc_start <= 0;

          if (req_stop)
            adc_stop <= 1;
          else
            adc_stop <= 0;

          bar0_ack <= 0;

          if (spi_rp_empty)
            spi_rp_ack <= 0;
          else
          begin
            spi_rp_ack <= 1;

            case (spi_rp_data[29:28])
              0:
              begin
                if (bar_spi_clk[31:28] == 15)
                begin
                  if (bar_spi_clk[27:16] == spi_rp_data[27:16])
                  begin
                    bar_spi_clk[15:0] <= spi_rp_data[15:0];
                    bar_spi_clk[31:28] <= 0;
                  end
                end
              end

              1:
              begin
                if (bar_spi_adc[31:28] == 15)
                begin
                  if (bar_spi_adc[27:16] == spi_rp_data[27:16])
                  begin
                    bar_spi_adc[15:0] <= spi_rp_data[15:0];
                    bar_spi_adc[31:28] <= 0;
                  end
                end
              end

              2:
              begin
                if (bar_spi_dac[31:28] == 15)
                begin
                  if (bar_spi_dac[27:16] == spi_rp_data[27:16])
                  begin
                    bar_spi_dac[15:0] <= spi_rp_data[15:0];
                    bar_spi_dac[31:28] <= 0;
                  end
                end
              end
            endcase
          end
        end
      end
    end
  end
endgenerate

endmodule
