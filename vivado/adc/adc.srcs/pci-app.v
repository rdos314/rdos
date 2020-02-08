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
    cfg_interrupt_msienable
);

  output  [7:0]    pci_exp_txp;
  output  [7:0]    pci_exp_txn;
  input   [7:0]    pci_exp_rxp;
  input   [7:0]    pci_exp_rxn;

  input            sys_clk;
  input            sys_rst_n;
  
  output           user_clk;
  output           user_reset;
  output           user_lnk_up;
  
  output           user_lnk_rate;
  output   [1:0]   user_lnk_width;
  output           cfg_interrupt_msienable;

// Wire Declarations

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

// PCIe -> SDRAM

  wire [1023:0]    sdram_data;
  wire [191:0]     sdram_header;
  reg  [3:0]       sdram_rd_ptr;
  wire [1023:0]    sdram_last_data;
  wire [191:0]     sdram_last_header;
  wire [3:0]       sdram_wr_ptr;
  wire             sdram_wr;

// SDRAM -> PCIe

  reg  [1023:0]    pci_data_in;
  wire [1023:0]    pci_data_out;
  reg  [191:0]     pci_header_in;
  wire [191:0]     pci_header_out;
  wire [3:0]       pci_rd_ptr;
  reg  [3:0]       pci_wr_ptr;
  reg              pci_wr;

  reg  [1023:0]    pci_last_data;
  reg  [191:0]     pci_last_header;
  reg  [3:0]       pci_last_ptr;
  reg              pci_last_wr;

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


bram_data pci_data_inst (
  .clka(user_clock),               // input wire clka
  .wea(pci_wr),                    // input wire [0 : 0] wea
  .addra(pci_wr_ptr),              // input wire [3 : 0] addra
  .dina(pci_data_in),              // input wire [1023 : 0] dina
  .clkb(user_clock),               // input wire clkb
  .addrb(pci_rd_ptr),              // input wire [3 : 0] addrb
  .doutb(pci_data_out)             // output wire [1023 : 0] doutb
);

bram_header pci_header_inst (
  .clka(user_clock),               // input wire clka
  .wea(pci_wr),                    // input wire [0 : 0] wea
  .addra(pci_wr_ptr),              // input wire [3 : 0] addra
  .dina(pci_header_in),            // input wire [191 : 0] dina
  .clkb(user_clock),               // input wire clkb
  .addrb(pci_rd_ptr),              // input wire [3 : 0] addrb
  .doutb(pci_header_out)           // output wire [191 : 0] doutb
);

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

    .bram_data( sdram_data),                    // O
    .bram_header( sdram_header),                // O
    .bram_rd_ptr (sdram_rd_ptr),                // I
    .bram_last_data( sdram_last_data),          // O
    .bram_last_header( sdram_last_header),      // O
    .bram_wr_ptr (sdram_wr_ptr),                // O
    .bram_wr (sdram_wr)                         // O
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
    
    .bram_data( pci_data_out),                  // I
    .bram_header( pci_header_out),              // I
    .bram_rd_ptr (pci_rd_ptr),                  // O
    .bram_last_data (pci_last_data),            // I
    .bram_last_header (pci_last_header),        // I
    .bram_last_ptr( pci_last_ptr),              // I
    .bram_last_wr( pci_last_wr)                 // I
);

ila_1 ila_1_inst (
	.clk(user_clk),                        // input wire clk
	.probe0(sdram_header[63:0]),           // input wire [63:0]  probe0  
	.probe1(sdram_last_header[63:0]),       // input wire [63:0]  probe0  
	.probe2(sdram_header[127:64]),         // input wire [63:0]  probe0  
	.probe3(sdram_last_header[127:64]),     // input wire [63:0]  probe0  
	.probe4(sdram_rd_ptr),                 // input wire [3:0]  probe1 
	.probe5(sdram_wr_ptr),                 // input wire [3:0]  probe1 
	.probe6(sdram_wr),                     // input wire [0:0]  probe2
	.probe7(pci_header_in[63:0]),          // input wire [63:0]  probe0  
	.probe8(pci_last_header[63:0]),         // input wire [63:0]  probe0  
	.probe9(pci_header_in[127:64]),        // input wire [63:0]  probe0  
	.probe10(pci_last_header[127:64]),      // input wire [63:0]  probe0  
	.probe11(pci_data_in[31:0]),            // input wire [31:0]  probe0  
	.probe12(pci_data_out[31:0]),          // input wire [31:0]  probe0  
	.probe13(pci_rd_ptr),                  // input wire [3:0]  probe1 
	.probe14(pci_wr_ptr),                  // input wire [3:0]  probe1 
	.probe15(pci_wr)                       // input wire [0:0]  probe2
);


// local

  reg  [63:0]      req_address;
  reg  [31:0]      req_header   [1:0];
  reg  [1023:0]    req_data;
  reg  [9:0]       req_len;
  reg  [7:0]       req_type;
  reg              use_last;
  reg              has_data;

  generate
    begin : pci_app

      always @ ( posedge user_clk ) 
      begin
        if (pci_wr)
        begin
          pci_wr_ptr = pci_wr_ptr + 1;
          pci_wr = 0;
        end

        if (user_reset)
        begin
          sdram_rd_ptr = 0;
          pci_wr_ptr = 0;
          pci_wr = 0;
        end
        else
        begin
          if (sdram_wr)
          begin
            has_data = 1;

            if (sdram_wr_ptr == sdram_rd_ptr)
              use_last = 1;
            else
              use_last = 0;
          end
          else
          begin
            use_last = 0;

            if (sdram_wr_ptr == sdram_rd_ptr)
              has_data = 0;
            else
              has_data = 1;                
          end

          if (has_data)
          begin
            if (use_last)
            begin
              req_data = sdram_last_data;
              req_header[0] = sdram_last_header[31:0];
              req_header[1] = sdram_last_header[63:32];
              req_address = sdram_last_header[127:64];
            end
            else
            begin
              req_data = sdram_data;
              req_header[0] = sdram_header[31:0];
              req_header[1] = sdram_header[63:32];
              req_address = sdram_header[127:64];
            end

            sdram_rd_ptr = sdram_rd_ptr + 1;

            req_len = req_header[0][9:0];
            req_type = req_header[0][31:24];

            if (req_type[6] == 0)
            begin
              req_header[0][11:10] = 2'b0;                   // AT
              req_header[0][19:16] = 4'b0;                   // TH, AttrH, R
              req_header[0][23] = 1'b0;                      // R
 
              if (req_len)
                  req_header[0][31:25] = 6'b10_0101;         // Type + Fmt (data)
              else
                  req_header[0][31:25] = 6'b00_0101;         // Type + Fmt (no data)
              
              req_header[1][7] = 0;    
              pci_header_in[31:0] = req_header[0];
              pci_header_in[95:64] = req_header[1];
              
              req_header[1][31:16] = 16'b0;                  // completer ID
              req_header[1][15:13] = 3'b0;                   // completion code = 000
              req_header[1][12] = 1'b0;                      // BCM
              req_header[1][11:2] = req_len;                 // byte count
              req_header[1][1:0] = 2'b0;                     // dword aligned
              pci_header_in[63:32] = req_header[1];

              pci_data_in[1:0] = 0;
              pci_data_in[18:2] = req_address[18:2];
              pci_data_in[1023:19] = 0;

              pci_wr = 1;
            end
          end
        end
      end

      always @ ( posedge user_clk ) 
      begin
        pci_last_data <= pci_data_in;
        pci_last_header <= pci_header_in;
        pci_last_ptr <= pci_wr_ptr;
        pci_last_wr <= pci_wr;
      end

    end
  endgenerate

endmodule
