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

    bar0_rd_address,
    bar0_rd,

    bar0_rp_data,
    bar0_rp,

    bar0_wr_address,
    bar0_wr_data,
    bar0_wr_be,
    bar0_wr,

    bar1_rd_address,
    bar1_rd,

    bar1_rp_data,
    bar1_rp,

    bar1_wr_address,
    bar1_wr_data,
    bar1_wr_be,
    bar1_wr,

    bar2_rd_address,
    bar2_rd,

    bar2_rp_data,
    bar2_rp,

    bar2_wr_address,
    bar2_wr_data,
    bar2_wr_be,
    bar2_wr,

    adc_wr,
    adc_address,
    adc_data
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

  output reg [9:0]     bar0_rd_address;
  output reg           bar0_rd;

  input wire [31:0]    bar0_rp_data;
  input wire           bar0_rp;

  output reg [9:0]     bar0_wr_address;
  output reg [31:0]    bar0_wr_data;
  output reg [3:0]     bar0_wr_be;
  output reg           bar0_wr;

  output reg [16:0]    bar1_rd_address;
  output reg           bar1_rd;

  input wire [31:0]    bar1_rp_data;
  input wire           bar1_rp;

  output reg [16:0]    bar1_wr_address;
  output reg [31:0]    bar1_wr_data;
  output reg [3:0]     bar1_wr_be;
  output reg           bar1_wr;

  output reg [16:0]    bar2_rd_address;
  output reg           bar2_rd;

  input wire [31:0]    bar2_rp_data;
  input wire           bar2_rp;

  output reg [16:0]    bar2_wr_address;
  output reg [31:0]    bar2_wr_data;
  output reg [3:0]     bar2_wr_be;
  output reg           bar2_wr;

  input wire           adc_wr;
  input wire [63:0]    adc_address;
  input wire [1023:0]  adc_data;

// Wire Declarations

  wire             req_stop;
  wire [63:0]      adc_address;

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
  wire [7:0]       pci_rx_count;
  wire [7:0]       pci_rx_bar;
  wire             pci_rx_valid;

  wire [9:0]       pci_rx_len;
  wire [7:0]       pci_rx_type;
  wire [63:0]      pci_rx_address;

// local -> PCIe

  wire [1023:0]    pci_tx_data;
  wire [127:0]     pci_tx_header;
  wire             pci_tx_wr;
  wire             pci_tx_full;

// local memory

  reg              spi_clk_valid;
  reg              spi_adc_valid;
  reg              spi_dac_valid;

  reg [31:0]       bar_spi_clk;
  reg [31:0]       bar_spi_adc;
  reg [31:0]       bar_spi_dac;

// PCIe send

  reg  [127:0]     q_adc_header;
  reg  [1023:0]    q_adc_data;
  reg              q_adc_send;
  reg              adc_send_ack;

  reg  [95:0]      q_bar0_rp_header;
  reg  [31:0]      q_bar0_data;
  reg              q_bar0_send;
  reg              bar0_ack;

  reg  [95:0]      q_bar1_rp_header;
  reg  [31:0]      q_bar1_data;
  reg              q_bar1_send;
  reg              bar1_ack;

  reg  [95:0]      bar2_rp_header;
  reg  [31:0]      q_bar2_data;
  reg              q_bar2_send;
  reg              bar2_ack;

  
  
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

  wire                                        cfg_interrupt_assert;
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
  .cfg_interrupt                             ( 0 ),
  .cfg_interrupt_rdy                         ( int_ack ),
  .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
  .cfg_interrupt_di                          ( 0 ),
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

    .pci_rx_data( pci_rx_data),                // O
    .pci_rx_header( pci_rx_header),            // O
    .pci_rx_be( pci_rx_be),                    // O
    .pci_rx_count( pci_rx_count),              // O
    .pci_rx_bar (pci_rx_bar),                  // O
    .pci_rx_valid (pci_rx_valid)               // O
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

generate
  begin : pci_app

    assign pci_rx_len = pci_rx_header[9:0];
    assign pci_rx_type = pci_rx_header[31:24];
    assign pci_rx_address = pci_rx_header[95:64];

    assign bar2_rp = 0;

    always @ ( posedge user_clk ) 
    begin
      if (pci_rx_valid)
      begin
        if (pci_rx_bar[0])
        begin
          case (pci_rx_type)
            8'b000_00000, 
            8'b001_00000,
            8'b000_00001,
            8'b001_00001: 
            begin
              bar0_rd_address <= pci_rx_address[9:0];

              q_bar0_rp_header[95:72] <= pci_rx_header[63:40];
              q_bar0_rp_header[71] <= 0;
              q_bar0_rp_header[70:66] <= pci_rx_header[70:66];

              casex (pci_rx_be[3:0])
                4'b0000 : q_bar0_rp_header[65:64] <= 0;
                4'bxxx1 : q_bar0_rp_header[65:64] <= 0;
                4'bxx10 : q_bar0_rp_header[65:64] <= 1;
                4'bx100 : q_bar0_rp_header[65:64] <= 2;
                4'b1000 : q_bar0_rp_header[65:64] <= 3;
              endcase

              q_bar0_rp_header[63:48] <= 16'b0;                  // completer ID
              q_bar0_rp_header[47:45] <= 3'b0;                   // completion code = 000
              q_bar0_rp_header[44] <= 1'b0;                      // BCM
              q_bar0_rp_header[39:32] <= pci_rx_count;           // byte count
              q_bar0_rp_header[43:40] <= 0;                      // high byte count = 0

              if (pci_rx_count)
                q_bar0_rp_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
              else
                q_bar0_rp_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

              q_bar0_rp_header[24] <= pci_rx_header[24];
              q_bar0_rp_header[23] <= 1'b0;                      // R
              q_bar0_rp_header[22:20] <= pci_rx_header[22:20];
              q_bar0_rp_header[19:16] <= 4'b0;                   // TH, AttrH, R
              q_bar0_rp_header[15:12] <= pci_rx_header[15:12];
              q_bar0_rp_header[11:10] <= 2'b0;                   // AT
              q_bar0_rp_header[9:0] <= pci_rx_header[9:0];

              bar0_rd <= 1;
              bar0_wr <= 0;
            end

            8'b010_00000,
            8'b011_00000:
            begin       
              bar0_wr_address <= pci_rx_address[9:0];
              bar0_wr_data <= pci_rx_data[31:0];
              bar0_wr_be <= pci_rx_be[3:0];
              bar0_wr <= 1;
              bar0_rd <= 0;
            end

            default:
            begin
              bar0_rd <= 0;
              bar0_wr <= 0;
            end
          endcase
        end
        else
        begin
          bar0_rd <= 0;
          bar0_wr <= 0;

          if (pci_rx_bar[1])
          begin
            case (pci_rx_type)
              8'b000_00000, 
              8'b001_00000,
              8'b000_00001,
              8'b001_00001: 
              begin
                bar1_rd_address <= pci_rx_address[16:0];

                q_bar1_rp_header[95:72] <= pci_rx_header[63:40];
                q_bar1_rp_header[71] <= 0;
                q_bar1_rp_header[70:66] <= pci_rx_header[70:66];

                casex (pci_rx_be[3:0])
                  4'b0000 : q_bar1_rp_header[65:64] <= 0;
                  4'bxxx1 : q_bar1_rp_header[65:64] <= 0;
                  4'bxx10 : q_bar1_rp_header[65:64] <= 1;
                  4'bx100 : q_bar1_rp_header[65:64] <= 2;
                  4'b1000 : q_bar1_rp_header[65:64] <= 3;
                endcase

                q_bar1_rp_header[63:48] <= 16'b0;                  // completer ID
                q_bar1_rp_header[47:45] <= 3'b0;                   // completion code = 000
                q_bar1_rp_header[44] <= 1'b0;                      // BCM
                q_bar1_rp_header[39:32] <= pci_rx_count;           // byte count
                q_bar1_rp_header[43:40] <= 0;                      // high byte count = 0

                if (pci_rx_count)
                  q_bar1_rp_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
                 else
                  q_bar1_rp_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

                q_bar1_rp_header[24] <= pci_rx_header[24];
                q_bar1_rp_header[23] <= 1'b0;                      // R
                q_bar1_rp_header[22:20] <= pci_rx_header[22:20];
                q_bar1_rp_header[19:16] <= 4'b0;                   // TH, AttrH, R
                q_bar1_rp_header[15:12] <= pci_rx_header[15:12];
                q_bar1_rp_header[11:10] <= 2'b0;                   // AT
                q_bar1_rp_header[9:0] <= pci_rx_header[9:0];

                bar1_rd <= 1;
                bar1_wr <= 0;
              end

              8'b010_00000,
              8'b011_00000:
              begin       
                bar1_wr_address <= pci_rx_address[16:0];
                bar1_wr_data <= pci_rx_data[31:0];
                bar1_wr_be <= pci_rx_be[3:0];
                bar1_wr <= 1;
                bar1_rd <= 0;
              end

              default:
              begin
                bar1_rd <= 0;
                bar1_wr <= 0;
              end
            endcase
          end
          else
          begin
            bar1_rd <= 0;
            bar1_wr <= 0;

            if (pci_rx_bar[2])
            begin
              case (pci_rx_type)
                8'b000_00000, 
                8'b001_00000,
                8'b000_00001,
                8'b001_00001: 
                begin
                  bar2_rd_address <= pci_rx_address[16:0];

                  q_bar2_rp_header[95:72] <= pci_rx_header[63:40];
                  q_bar2_rp_header[71] <= 0;
                  q_bar2_rp_header[70:66] <= pci_rx_header[70:66];

                  casex (pci_rx_be[3:0])
                    4'b0000 : q_bar2_rp_header[65:64] <= 0;
                    4'bxxx1 : q_bar2_rp_header[65:64] <= 0;
                    4'bxx10 : q_bar2_rp_header[65:64] <= 1;
                    4'bx100 : q_bar2_rp_header[65:64] <= 2;
                    4'b1000 : q_bar2_rp_header[65:64] <= 3;
                  endcase

                  q_bar2_rp_header[63:48] <= 16'b0;                  // completer ID
                  q_bar2_rp_header[47:45] <= 3'b0;                   // completion code = 000
                  q_bar2_rp_header[44] <= 1'b0;                      // BCM
                  q_bar2_rp_header[39:32] <= pci_rx_count;           // byte count
                  q_bar2_rp_header[43:40] <= 0;                      // high byte count = 0

                  if (pci_rx_count)
                    q_bar2_rp_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
                   else
                    q_bar2_rp_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

                  q_bar2_rp_header[24] <= pci_rx_header[24];
                  q_bar2_rp_header[23] <= 1'b0;                      // R
                  q_bar2_rp_header[22:20] <= pci_rx_header[22:20];
                  q_bar2_rp_header[19:16] <= 4'b0;                   // TH, AttrH, R
                  q_bar2_rp_header[15:12] <= pci_rx_header[15:12];
                  q_bar2_rp_header[11:10] <= 2'b0;                   // AT
                  q_bar2_rp_header[9:0] <= pci_rx_header[9:0];

                  bar2_rd <= 1;
                  bar2_wr <= 0;
                end

                8'b010_00000,
                8'b011_00000:
                begin       
                  bar2_wr_address <= pci_rx_address[16:0];
                  bar2_wr_data <= pci_rx_data[31:0];
                  bar2_wr_be <= pci_rx_be[3:0];
                  bar2_wr <= 1;
                  bar2_rd <= 0;
                end

                default:
                begin
                  bar2_rd <= 0;
                  bar2_wr <= 0;
                end
              endcase
            end
            else
            begin
              bar2_rd <= 0;
              bar2_wr <= 0;
            end
          end
        end
      end
      else
      begin
        bar0_rd <= 0;
        bar0_wr <= 0;
        bar1_rd <= 0;
        bar1_wr <= 0;
        bar2_rd <= 0;
        bar2_wr <= 0;
      end
    end


    always @ ( posedge user_clk ) 
    begin
      if (user_reset)
        adc_send <= 0;
      else
      begin
        if (adc_send)
        begin
          q_adc_data <= adc_data;

          q_adc_header[63:48] <= 0;                      // Requester ID
          q_adc_header[47:40] <= 0;                      // tag
          q_adc_header[39:36] <= 4'b1111;                // last be
          q_adc_header[35:32] <= 4'b1111;                // 1st be

          if (adc_address[63:32] == 0)
          begin
            q_adc_header[31:24] <= 8'b010_00000;         // Type + Fmt (32-bit)
            q_adc_header[95:64] <= adc_address[31:0];
          end
          else
          begin
            q_adc_header[31:24] <= 8'b011_00000;         // Type + Fmt (64-bit)
            q_adc_header[95:64] <= adc_address[63:32];
            q_adc_header[127:96] <= adc_address[31:0];
          end

          q_adc_header[23] <= 1'b0;                      // R
          q_adc_header[22:20] <= 3'b000;                 // TC
          q_adc_header[19:16] <= 4'b0000;                // TH, AttrH, R
          q_adc_header[15:12] <= 4'b0000;                // TD, EP, Attr
          q_adc_header[11:10] <= 2'b0;                   // AT
          q_adc_header[9:8] <= 2'b0;                     // len high
          q_adc_header[7:0] <= 8'h20;                    // 128 byte size
          q_adc_send <= 1;
        end
        else
          if (adc_send_ack)
            q_adc_send <= 0;
      end
    end

    always @ ( posedge user_clk ) 
    begin
      if (user_reset)
      begin
        q_bar0_send <= 0;
        q_bar1_send <= 0;
        q_bar2_send <= 0;
      end
      else
      begin
        if (bar0_rp)
        begin
          q_bar0_data <= bar0_rp_data;
          q_bar0_send <= 1;
        end
        else
          if (bar0_ack)
            q_bar0_send <= 0;

        if (bar1_rp)
        begin
          q_bar1_data <= bar1_rp_data;
          q_bar1_send <= 1;
        end
        else
          if (bar1_ack)
            q_bar1_send <= 0;

        if (bar2_rp)
        begin
          q_bar2_data <= bar2_rp_data;
          q_bar2_send <= 1;
        end
        else
          if (bar2_ack)
            q_bar2_send <= 0;
      end
    end


    always @ ( posedge user_clk ) 
    begin
      if (reset)
      begin
        adc_send_ack <= 0;
        bar0_ack <= 0;
        bar1_ack <= 0;
        bar2_ack <= 0;
      end
      else
      begin
        if (pci_tx_full)
        begin
          pci_tx_wr <= 0;
          adc_send_ack <= 0;
          bar0_ack <= 0;
          bar1_ack <= 0;
          bar2_ack <= 0;
        end
        else
        begin
          if (q_adc_send && !adc_send_ack)
          begin
            pci_tx_data <= q_adc_data;
            pci_tx_header <= q_adc_header;
            pci_tx_wr <= 1;
            adc_send_ack <= 1;
            bar0_ack <= 0;
            bar1_ack <= 0;
            bar2_ack <= 0;
          end
          else
          begin
            adc_send_ack <= 0;
 
            if (q_bar0_send && !bar0_ack)
            begin
              pci_tx_data <= q_bar0_data;
              pci_tx_header <= q_bar0_rp_header;
              pci_tx_wr <= 1;
              bar0_ack <= 1;
              bar1_ack <= 0;
              bar2_ack <= 0;
            end
            else
            begin
              bar0_ack <= 0;

              if (q_bar1_send && !bar1_ack)
              begin
                pci_tx_data <= q_bar1_data;
                pci_tx_header <= q_bar1_rp_header;
                pci_tx_wr <= 1;
                bar1_ack <= 1;
                bar2_ack <= 0;
              end
              else
              begin
                bar1_ack <= 0;

                if (q_bar2_send && !bar2_ack)
                begin
                  pci_tx_data <= q_bar2_data;
                  pci_tx_header <= q_bar2_rp_header;
                  pci_tx_wr <= 1;
                  bar2_ack <= 1;
                end
                else
                begin
                  pci_tx_wr <= 0;
                  bar2_ack <= 0;
                end
              end
            end
          end
        end
      end
    end
   

  end
endgenerate

endmodule
