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
// pci_app.v
// PCIe main module
//
////////////////////////////////////////////////////////////////////////////////

module pci_app (
  output  [7:0]        pci_exp_txp,
  output  [7:0]        pci_exp_txn,
  input   [7:0]        pci_exp_rxp,
  input   [7:0]        pci_exp_rxn,

  input                sys_clk,
  input                sys_rst_n,
  
  output               user_clk,
  output               user_reset,
  output               user_lnk_up,
  
  output               user_lnk_rate,
  output   [1:0]       user_lnk_width,
  output               cfg_interrupt_msixenable,

  input wire [31:0]    control_base,
  output reg           control_rd,

  output reg [9:0]     bar0_rd_address,
  output reg           bar0_rd,

  input wire [31:0]    bar0_rp_data,
  input wire           bar0_rp,

  output reg [9:0]     bar0_wr_address,
  output reg [31:0]    bar0_wr_data,
  output reg [3:0]     bar0_wr_be,
  output reg           bar0_wr,

  output reg [17:0]    bar1_rd_address,
  output reg           bar1_rd,

  input wire [31:0]    bar1_rp_data,
  input wire           bar1_rp,

  output reg [17:0]    bar1_wr_address,
  output reg [31:0]    bar1_wr_data,
  output reg [3:0]     bar1_wr_be,
  output reg           bar1_wr,

  output reg [9:0]     bar2_rd_address,
  output reg           bar2_rd,

  input wire [31:0]    bar2_rp_data,
  input wire           bar2_rp,

  output reg [9:0]     bar2_wr_address,
  output reg [31:0]    bar2_wr_data,
  output reg [3:0]     bar2_wr_be,
  output reg           bar2_wr
);


// Wire Declarations

  reg [31:0]       rd_address;
  reg [7:0]        rd_dw_cnt;
  reg [7:0]        rd_tag;
  reg              rd_req;

  reg [17:0]       poll_cnt;

  wire             req_stop;

  reg              int_req;
  wire             int_ack;
  reg              int_num;
  
  // Tx
  wire [5:0]       tx_buf_av;
  wire             tx_cfg_req;
  wire             tx_err_drop;
  wire             tx_cfg_gnt;

  wire             s_axis_tx_tready;
  wire [3:0]       s_axis_tx_tuser;
  wire [127:0]     s_axis_tx_tdata;
  wire [15:0]      s_axis_tx_tkeep;
  wire             s_axis_tx_tlast;
  wire             s_axis_tx_tvalid;

  // Rx

  wire             rx_np_ok;
  wire             rx_np_req;

  wire [127:0]     m_axis_rx_tdata;
  wire [15:0]      m_axis_rx_tkeep;
  wire             m_axis_rx_tlast;
  wire             m_axis_rx_tvalid;
  wire             m_axis_rx_tready;
  wire [21:0]      m_axis_rx_tuser;

  wire [11:0]      fc_cpld;
  wire [7:0]       fc_cplh;
  wire [11:0]      fc_npd;
  wire [7:0]       fc_nph;
  wire [11:0]      fc_pd;
  wire [7:0]       fc_ph;
  wire [2:0]       fc_sel;

  wire             cfg_trn_pending;
  wire             cfg_pm_halt_aspm_l0s;
  wire             cfg_pm_halt_aspm_l1;
  wire             cfg_pm_force_state_en;
  wire [1:0]       cfg_pm_force_state;
  wire [63:0]      cfg_dsn;
  wire             cfg_pm_wake;
  wire             cfg_pm_send_pme_to;

  wire [7:0]       cfg_bus_number;
  wire [4:0]       cfg_device_number;
  wire [2:0]       cfg_function_number;
  wire             cfg_turnoff_ok;

// PCIe -> local

  wire [127:0]     rx_bar_data;
  wire [127:0]     rx_bar_header;
  wire [15:0]      rx_bar_be;
  wire [7:0]       rx_bar_count;
  wire [7:0]       rx_bar_sel;
  wire             rx_bar_valid;

  wire [9:0]       rx_bar_len;
  wire [7:0]       rx_bar_type;
  wire [63:0]      rx_bar_address;

  wire [1023:0]    rx_dac_data;
  wire             rx_dac_valid;

// local -> PCIe

  reg [127:0]      tx_bar_data;
  reg [127:0]      tx_bar_header;
  reg              tx_bar_wr;
  wire             tx_bar_busy;

// local memory

  reg              spi_clk_valid;
  reg              spi_adc_valid;
  reg              spi_dac_valid;

  reg [31:0]       bar_spi_clk;
  reg [31:0]       bar_spi_adc;
  reg [31:0]       bar_spi_dac;

// PCIe send

  reg  [95:0]      q_bar0_rp_header;
  reg  [31:0]      q_bar0_data;
  reg              q_bar0_send;
  reg              bar0_ack;

  reg  [95:0]      q_bar1_rp_header;
  reg  [31:0]      q_bar1_data;
  reg              q_bar1_send;
  reg              bar1_ack;

  reg  [95:0]      q_bar2_rp_header;
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

// pcie_pcie2_top pcie_i
pcie_7x_0 pcie_i
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

  .tx_buf_av                                 ( tx_buf_av), 
  .tx_cfg_req                                ( tx_cfg_req),
  .tx_err_drop                               ( tx_err_drop),
  .tx_cfg_gnt                                ( tx_cfg_gnt),

  // Rx
  .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
  .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
  .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
  .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
  .m_axis_rx_tready                          ( m_axis_rx_tready ),
  .m_axis_rx_tuser                           ( m_axis_rx_tuser ),

  .rx_np_ok                                  ( rx_np_ok),
  .rx_np_req                                 ( rx_np_req),

  .fc_cpld                                   ( fc_cpld),
  .fc_cplh                                   ( fc_cplh),
  .fc_npd                                    ( fc_npd),
  .fc_nph                                    ( fc_nph),
  .fc_pd                                     ( fc_pd),
  .fc_ph                                     ( fc_ph),
  .fc_sel                                    ( fc_sel), 

  .cfg_bus_number                            ( cfg_bus_number),
  .cfg_device_number                         ( cfg_device_number),
  .cfg_function_number                       ( cfg_function_number),
  .cfg_turnoff_ok                            ( cfg_turnoff_ok),

  .cfg_trn_pending                           ( cfg_trn_pending),                                                        // input wire cfg_trn_pending
  .cfg_pm_halt_aspm_l0s                      ( cfg_pm_halt_aspm_l0s),
  .cfg_pm_halt_aspm_l1                       ( cfg_pm_halt_aspm_l1),
  .cfg_pm_force_state_en                     ( cfg_pm_force_state_en),
  .cfg_pm_force_state                        ( cfg_pm_force_state),
  .cfg_dsn                                   ( cfg_dsn),
  .cfg_pm_wake                               ( cfg_pm_wake),
  .cfg_pm_send_pme_to                        ( cfg_pm_send_pme_to),

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
  .cfg_interrupt                             ( int_req ),
  .cfg_interrupt_rdy                         ( int_ack ),
  .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
  .cfg_interrupt_di                          ( int_num ),
  .cfg_interrupt_do                          ( ),
  .cfg_interrupt_mmenable                    ( ),
  .cfg_interrupt_msienable                   ( ),
  .cfg_interrupt_msixenable                  ( cfg_interrupt_msixenable ),
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

  assign rx_np_ok = 1'b1;
  assign rx_np_req = 1'b1;

  assign tx_cfg_gnt = 1'b1;
  assign cfg_turnoff_ok = 1'b1;

  assign cfg_trn_pending = 1'b0;
  assign cfg_pm_halt_aspm_l0s = 1'b0;
  assign cfg_pm_halt_aspm_l1 = 1'b0;
  assign cfg_pm_force_state_en = 1'b0;
  assign cfg_pm_force_state = 2'b0;
  assign cfg_dsn = 64'h123456789abcdef;
  assign cfg_pm_wake = 1'b0;
  assign cfg_pm_send_pme_to = 1'b0;

  assign fc_sel = 3'b100;

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

    .bar_data( rx_bar_data),                // O
    .bar_header( rx_bar_header),            // O
    .bar_be( rx_bar_be),                    // O
    .bar_count( rx_bar_count),              // O
    .bar_sel (rx_bar_sel),                  // O
    .bar_valid (rx_bar_valid),              // O

    .dac_data( rx_dac_data),                // O
    .dac_valid (rx_dac_valid)               // O
);


pci_tx pci_tx_inst (

    .clk(user_clk),                             // I
    .reset(user_reset),                         // I

    // AXIS Tx
    .tx_buf_av( tx_buf_av),                     // O
    .s_axis_tx_tready( s_axis_tx_tready ),      // I
    .s_axis_tx_tdata( s_axis_tx_tdata ),        // O
    .s_axis_tx_tkeep( s_axis_tx_tkeep ),        // O
    .s_axis_tx_tlast( s_axis_tx_tlast ),        // O
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),      // O
    .s_axis_tx_tuser( s_axis_tx_tuser ),        // I
    
    .cfg_bus_number( cfg_bus_number),
    .cfg_device_number( cfg_device_number),
    .cfg_function_number( cfg_function_number),

    .tx_cfg_req( tx_cfg_req),
    .tx_err_drop( tx_err_drop),

    .fc_npd( fc_npd),
    .fc_nph( fc_nph),
    .fc_pd( fc_pd),
    .fc_ph( fc_ph),

    .rd_address( rd_address),
    .rd_dw_cnt( rd_dw_cnt),
    .rd_tag( rd_tag),
    .rd_req( rd_req),
    
    .bar_data( tx_bar_data),                 // I
    .bar_header( tx_bar_header),             // I
    .bar_wr (tx_bar_wr),                     // I
    .bar_busy (tx_bar_busy)                 // O
);

 
generate
  begin : pci_app

    assign rx_bar_len = rx_bar_header[9:0];
    assign rx_bar_type = rx_bar_header[31:24];
    assign rx_bar_address = rx_bar_header[95:64];

    always @ ( posedge user_clk ) 
    begin
      if (control_base)
      begin
        if (poll_cnt == 249999)
        begin
          poll_cnt <= 0;
          control_rd <= 1;
        end
        else
        begin
          poll_cnt <= poll_cnt + 1;
          control_rd <= 0;
        end
      end
      else
      begin
        poll_cnt <= 0;
        control_rd <= 0;
      end
    end       

    always @ ( posedge user_clk ) 
    begin
      if (control_rd)
      begin
        rd_address <= control_base;
        rd_dw_cnt <= 1;
        rd_tag <= 1;
        rd_req <= 1;
      end
      else
        rd_req <= 0;
    end

    always @ ( posedge user_clk ) 
    begin
      if (rx_bar_valid)
      begin
        if (rx_bar_sel[0])
        begin
          case (rx_bar_type)
            8'b000_00000, 
            8'b001_00000,
            8'b000_00001,
            8'b001_00001: 
            begin
              bar0_rd_address <= rx_bar_address[11:2];

              q_bar0_rp_header[95:72] <= rx_bar_header[63:40];
              q_bar0_rp_header[71] <= 0;
              q_bar0_rp_header[70:66] <= rx_bar_header[70:66];

              casex (rx_bar_be[3:0])
                4'b0000 : q_bar0_rp_header[65:64] <= 0;
                4'bxxx1 : q_bar0_rp_header[65:64] <= 0;
                4'bxx10 : q_bar0_rp_header[65:64] <= 1;
                4'bx100 : q_bar0_rp_header[65:64] <= 2;
                4'b1000 : q_bar0_rp_header[65:64] <= 3;
              endcase

              q_bar0_rp_header[63:48] <= 16'b0;                  // completer ID
              q_bar0_rp_header[47:45] <= 3'b0;                   // completion code = 000
              q_bar0_rp_header[44] <= 1'b0;                      // BCM
              q_bar0_rp_header[39:32] <= rx_bar_count;           // byte count
              q_bar0_rp_header[43:40] <= 0;                      // high byte count = 0

              if (rx_bar_count)
                q_bar0_rp_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
              else
                q_bar0_rp_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

              q_bar0_rp_header[24] <= rx_bar_header[24];
              q_bar0_rp_header[23] <= 1'b0;                      // R
              q_bar0_rp_header[22:20] <= rx_bar_header[22:20];
              q_bar0_rp_header[19:16] <= 4'b0;                   // TH, AttrH, R
              q_bar0_rp_header[15:12] <= rx_bar_header[15:12];
              q_bar0_rp_header[11:10] <= 2'b0;                   // AT
              q_bar0_rp_header[9:0] <= rx_bar_header[9:0];

              bar0_rd <= 1;
              bar0_wr <= 0;
            end

            8'b010_00000,
            8'b011_00000:
            begin       
              bar0_wr_address <= rx_bar_address[11:2];
              bar0_wr_data <= rx_bar_data[31:0];
              bar0_wr_be <= rx_bar_be[3:0];
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

          if (rx_bar_sel[1])
          begin
            case (rx_bar_type)
              8'b000_00000, 
              8'b001_00000,
              8'b000_00001,
              8'b001_00001: 
              begin
                bar1_rd_address <= rx_bar_address[19:2];

                q_bar1_rp_header[95:72] <= rx_bar_header[63:40];
                q_bar1_rp_header[71] <= 0;
                q_bar1_rp_header[70:66] <= rx_bar_header[70:66];

                casex (rx_bar_be[3:0])
                  4'b0000 : q_bar1_rp_header[65:64] <= 0;
                  4'bxxx1 : q_bar1_rp_header[65:64] <= 0;
                  4'bxx10 : q_bar1_rp_header[65:64] <= 1;
                  4'bx100 : q_bar1_rp_header[65:64] <= 2;
                  4'b1000 : q_bar1_rp_header[65:64] <= 3;
                endcase

                q_bar1_rp_header[63:48] <= 16'b0;                  // completer ID
                q_bar1_rp_header[47:45] <= 3'b0;                   // completion code = 000
                q_bar1_rp_header[44] <= 1'b0;                      // BCM
                q_bar1_rp_header[39:32] <= rx_bar_count;           // byte count
                q_bar1_rp_header[43:40] <= 0;                      // high byte count = 0

                if (rx_bar_count)
                  q_bar1_rp_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
                 else
                  q_bar1_rp_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

                q_bar1_rp_header[24] <= rx_bar_header[24];
                q_bar1_rp_header[23] <= 1'b0;                      // R
                q_bar1_rp_header[22:20] <= rx_bar_header[22:20];
                q_bar1_rp_header[19:16] <= 4'b0;                   // TH, AttrH, R
                q_bar1_rp_header[15:12] <= rx_bar_header[15:12];
                q_bar1_rp_header[11:10] <= 2'b0;                   // AT
                q_bar1_rp_header[9:0] <= rx_bar_header[9:0];

                bar1_rd <= 1;
                bar1_wr <= 0;
              end

              8'b010_00000,
              8'b011_00000:
              begin       
                bar1_wr_address <= rx_bar_address[19:2];
                bar1_wr_data <= rx_bar_data[31:0];
                bar1_wr_be <= rx_bar_be[3:0];
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

            if (rx_bar_sel[2])
            begin
              case (rx_bar_type)
                8'b000_00000, 
                8'b001_00000,
                8'b000_00001,
                8'b001_00001: 
                begin
                  bar2_rd_address <= rx_bar_address[11:2];

                  q_bar2_rp_header[95:72] <= rx_bar_header[63:40];
                  q_bar2_rp_header[71] <= 0;
                  q_bar2_rp_header[70:66] <= rx_bar_header[70:66];

                  casex (rx_bar_be[3:0])
                    4'b0000 : q_bar2_rp_header[65:64] <= 0;
                    4'bxxx1 : q_bar2_rp_header[65:64] <= 0;
                    4'bxx10 : q_bar2_rp_header[65:64] <= 1;
                    4'bx100 : q_bar2_rp_header[65:64] <= 2;
                    4'b1000 : q_bar2_rp_header[65:64] <= 3;
                  endcase

                  q_bar2_rp_header[63:48] <= 16'b0;                  // completer ID
                  q_bar2_rp_header[47:45] <= 3'b0;                   // completion code = 000
                  q_bar2_rp_header[44] <= 1'b0;                      // BCM
                  q_bar2_rp_header[39:32] <= rx_bar_count;           // byte count
                  q_bar2_rp_header[43:40] <= 0;                      // high byte count = 0

                  if (rx_bar_count)
                    q_bar2_rp_header[31:25] <= 6'b10_0101;           // Type + Fmt (data)
                   else
                    q_bar2_rp_header[31:25] <= 6'b00_0101;           // Type + Fmt (no data)

                  q_bar2_rp_header[24] <= rx_bar_header[24];
                  q_bar2_rp_header[23] <= 1'b0;                      // R
                  q_bar2_rp_header[22:20] <= rx_bar_header[22:20];
                  q_bar2_rp_header[19:16] <= 4'b0;                   // TH, AttrH, R
                  q_bar2_rp_header[15:12] <= rx_bar_header[15:12];
                  q_bar2_rp_header[11:10] <= 2'b0;                   // AT
                  q_bar2_rp_header[9:0] <= rx_bar_header[9:0];

                  bar2_rd <= 1;
                  bar2_wr <= 0;
                end

                8'b010_00000,
                8'b011_00000:
                begin       
                  bar2_wr_address <= rx_bar_address[11:2];
                  bar2_wr_data <= rx_bar_data[31:0];
                  bar2_wr_be <= rx_bar_be[3:0];
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
      if (user_reset)
      begin
        bar0_ack <= 0;
        bar1_ack <= 0;
        bar2_ack <= 0;
      end
      else
      begin
        if (tx_bar_busy)
        begin
          tx_bar_wr <= 0;
          bar0_ack <= 0;
          bar1_ack <= 0;
          bar2_ack <= 0;
        end
        else
        begin
          if (q_bar0_send && !bar0_ack)
          begin
            tx_bar_data <= q_bar0_data;
            tx_bar_header <= q_bar0_rp_header;
            tx_bar_wr <= 1;
            bar0_ack <= 1;
            bar1_ack <= 0;
            bar2_ack <= 0;
          end
          else
          begin
            bar0_ack <= 0;

            if (q_bar1_send && !bar1_ack)
            begin
              tx_bar_data <= q_bar1_data;
              tx_bar_header <= q_bar1_rp_header;
              tx_bar_wr <= 1;
              bar1_ack <= 1;
              bar2_ack <= 0;
            end
            else
            begin
              bar1_ack <= 0;

              if (q_bar2_send && !bar2_ack)
              begin
                tx_bar_data <= q_bar2_data;
                tx_bar_header <= q_bar2_rp_header;
                tx_bar_wr <= 1;
                bar2_ack <= 1;
              end
              else
              begin
                tx_bar_wr <= 0;
                bar2_ack <= 0;
              end
            end
          end
        end
      end
    end
   

    always @ ( posedge user_clk ) 
    begin
        int_req <= 0;
        int_num <= 0;
      end
    end

endgenerate

endmodule
