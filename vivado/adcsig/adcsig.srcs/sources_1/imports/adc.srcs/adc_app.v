////////////////////////////////////////////////////////////////////////////////
// RDOS operating system
// Copyright (C) 1988-2020, Leif Ekblad
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Fouconfig_channelndation; either version 2 of the License, or
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
// adc_app.v
// ADC module
//
////////////////////////////////////////////////////////////////////////////////

module adc_app (
  input                   rx_reset,
  input                   rx_clk,
  input                   pci_reset,
  input                   pci_clk,
  input                   up_reset,
  input                   up_clk,

  output reg              spi_read,
  output reg              spi_write,
  output reg [11:0]       spi_adr,
  input wire [7:0]        spi_in_data,
  output reg [7:0]        spi_out_data,
  input wire              spi_running,
  input wire              spi_done,

  input wire              rx_control_msg,
  input wire [7:0]        rx_control_index,
  input wire [7:0]        rx_control_data,

  output reg              tx_control_msg,
  output reg [7:0]        tx_control_index,
  output reg [7:0]        tx_control_data,

  output reg              up_rstn,
  output reg              qpll_rst,

  output wire             adc_rst,
  output wire             adc_user_ready,
  input wire [3:0]        adc_pll_locked,
  input wire [3:0]        adc_rst_done,

  input wire              adc_sync_ok,
  input wire              adc_sync_fail,

  output reg              adc_started,
  output reg              adc_probing,
  output reg              adc_running,
  output wire             adc_delay,
  output reg              adc_irq,

  output wire [2:0]       state,
    
  input wire              adc_en,
  input wire [13:0]       adc_A0,
  input wire [13:0]       adc_A1,
  input wire [13:0]       adc_A2,
  input wire [13:0]       adc_A3,
  input wire [13:0]       adc_B0,
  input wire [13:0]       adc_B1,
  input wire [13:0]       adc_B2,
  input wire [13:0]       adc_B3,

  output wire [15:0]      power_A,
  output wire [15:0]      power_B,

  output wire [15:0]      phase_A,
  output wire [15:0]      phase_B,

  input wire              config_wr,
  input wire [47:0]       config_data,

  input wire [17:0]       bar1_rd_address,
  input wire              bar1_rd,

  output reg [31:0]       bar1_rp_data,
  output reg              bar1_rp,

  input wire [17:0]       bar1_wr_address,
  input wire [31:0]       bar1_wr_data,
  input wire [3:0]        bar1_wr_be,
  input wire              bar1_wr
);

// up domain

  reg [1:0]               up_req_state;
  reg [2:0]               up_curr_state;
  reg [7:0]               up_test_mode;

  reg [7:0]               irq_state;
  reg [7:0]               up_curr_irq;

  reg [3:0]               up_bar_irq_cnt;
  reg                     up_bar_irq;
  reg                     pci_bar_irq_3;

  reg                     up_req_start;
  reg                     up_req_stop;
  reg                     up_pend_start;

  reg                     up_spi_test_done;
  reg [3:0]               up_pll_rst_cnt; 
  reg [3:0]               up_adc_rst_cnt;
  reg [6:0]               up_adc_user_ready_cnt;  

// pci domain

  reg                     adc_stopped;
  
  reg                     pci_en;
  reg                     pci_rd;
  reg                     pci_wr;
  reg                     pci_rd_pend;
  reg                     pci_wr_pend;
  reg  [9:0]              pci_adr;
  reg  [31:0]             pci_in;
  wire [31:0]             pci_out;
  reg  [3:0]              pci_be;


// analyser config

  reg                     config_rd;
  wire                    config_empty;
  wire [47:0]             config_out;

  reg  [4:0]              config_channel;
  reg  [29:0]             config_incr;
  reg  [13:0]             config_count;
  reg  [13:0]             config_adr;

  reg                     config_init;
  reg                     config_start;
  reg                     config_stop;
  reg                     config_raw_coeff;
  reg                     config_has_coeff;
  reg                     config_validate;
  reg                     config_done;

  reg  [23:0]             config_l_sin;
  reg  [23:0]             config_l_cos;

  reg  [15:0]             config_sin;
  reg  [15:0]             config_cos;
  
  reg                     synt_start;
  wire                    synt_done;
  reg                     synt_prev;

  reg  [29:0]             synt_phase;
  wire [31:0]             cordic_phase;

  assign cordic_phase[29:0] = synt_phase[29:0];
  assign cordic_phase[30]   = synt_phase[29];
  assign cordic_phase[31]   = synt_phase[29];

  wire [47:0]             synt_data;
  wire [23:0]             synt_raw_sin;
  wire [23:0]             synt_raw_cos;
  wire [23:0]             synt_comp_sin;
  wire [23:0]             synt_comp_cos;

  assign synt_raw_cos       = synt_data[23:0];
  assign synt_raw_sin       = synt_data[47:24];

  assign synt_comp_cos[23]  = synt_raw_cos[23];
  assign synt_comp_cos[22]  = synt_raw_cos[23];
  assign synt_comp_cos[21]  = synt_raw_cos[23];
  assign synt_comp_cos[20]  = synt_raw_cos[23];
  assign synt_comp_cos[19]  = synt_raw_cos[23];
  assign synt_comp_cos[18]  = synt_raw_cos[23];
  assign synt_comp_cos[17]  = synt_raw_cos[23];
  assign synt_comp_cos[16]  = synt_raw_cos[23];
  assign synt_comp_cos[15]  = synt_raw_cos[23];
  assign synt_comp_cos[14]  = synt_raw_cos[23];
  assign synt_comp_cos[13]  = synt_raw_cos[23];
  assign synt_comp_cos[12]  = synt_raw_cos[23];
  assign synt_comp_cos[11]  = synt_raw_cos[23];
  assign synt_comp_cos[10]  = synt_raw_cos[23];
  assign synt_comp_cos[9]   = synt_raw_cos[23];
  assign synt_comp_cos[8]   = synt_raw_cos[23];
  assign synt_comp_cos[7]   = synt_raw_cos[22];
  assign synt_comp_cos[6]   = synt_raw_cos[21];
  assign synt_comp_cos[5]   = synt_raw_cos[20];
  assign synt_comp_cos[4]   = synt_raw_cos[19];
  assign synt_comp_cos[3]   = synt_raw_cos[18];
  assign synt_comp_cos[2]   = synt_raw_cos[17];
  assign synt_comp_cos[1]   = synt_raw_cos[16];
  assign synt_comp_cos[0]   = synt_raw_cos[15];

  assign synt_comp_sin[23]  = synt_raw_sin[23];
  assign synt_comp_sin[22]  = synt_raw_sin[23];
  assign synt_comp_sin[21]  = synt_raw_sin[23];
  assign synt_comp_sin[20]  = synt_raw_sin[23];
  assign synt_comp_sin[19]  = synt_raw_sin[23];
  assign synt_comp_sin[18]  = synt_raw_sin[23];
  assign synt_comp_sin[17]  = synt_raw_sin[23];
  assign synt_comp_sin[16]  = synt_raw_sin[23];
  assign synt_comp_sin[15]  = synt_raw_sin[23];
  assign synt_comp_sin[14]  = synt_raw_sin[23];
  assign synt_comp_sin[13]  = synt_raw_sin[23];
  assign synt_comp_sin[12]  = synt_raw_sin[23];
  assign synt_comp_sin[11]  = synt_raw_sin[23];
  assign synt_comp_sin[10]  = synt_raw_sin[23];
  assign synt_comp_sin[9]   = synt_raw_sin[23];
  assign synt_comp_sin[8]   = synt_raw_sin[23];
  assign synt_comp_sin[7]   = synt_raw_sin[22];
  assign synt_comp_sin[6]   = synt_raw_sin[21];
  assign synt_comp_sin[5]   = synt_raw_sin[20];
  assign synt_comp_sin[4]   = synt_raw_sin[19];
  assign synt_comp_sin[3]   = synt_raw_sin[18];
  assign synt_comp_sin[2]   = synt_raw_sin[17];
  assign synt_comp_sin[1]   = synt_raw_sin[16];
  assign synt_comp_sin[0]   = synt_raw_sin[15];


// test sequence

  reg                     bram_en;
  reg                     bram_wr;
  reg  [11:0]             bram_adr;

  reg  [55:0]             bram_in;
  wire [13:0]             bram_in_0;
  wire [13:0]             bram_in_1;
  wire [13:0]             bram_in_2;
  wire [13:0]             bram_in_3;

  assign bram_in_0 = bram_in[13:0];
  assign bram_in_1 = bram_in[27:14];
  assign bram_in_2 = bram_in[41:28];
  assign bram_in_3 = bram_in[55:42];

  wire [55:0]             bram_out;

  wire [11:0]             coeff_adr;
  
  assign coeff_adr = bram_adr;

  reg  [63:0]             coeff_sin;
  reg  [63:0]             coeff_cos;

  wire [15:0]             coeff_sin_0;
  wire [15:0]             coeff_sin_1;
  wire [15:0]             coeff_sin_2;
  wire [15:0]             coeff_sin_3;

  wire [15:0]             coeff_cos_0;
  wire [15:0]             coeff_cos_1;
  wire [15:0]             coeff_cos_2;
  wire [15:0]             coeff_cos_3;

  assign coeff_sin_0 = coeff_sin[15:0];
  assign coeff_sin_1 = coeff_sin[31:16];
  assign coeff_sin_2 = coeff_sin[47:32];
  assign coeff_sin_3 = coeff_sin[63:48];

  assign coeff_cos_0 = coeff_cos[15:0];
  assign coeff_cos_1 = coeff_cos[31:16];
  assign coeff_cos_2 = coeff_cos[47:32];
  assign coeff_cos_3 = coeff_cos[63:48];

// analyser freq blocks

  wire [31:0]             start;
  wire [31:0]             stop;
  wire [31:0]             wr;
  wire [31:0]             chan_report;
 
  wire                    is_chan_wr; 
  
  assign is_chan_count = config_adr < config_count;
  
  wire                    chan_0;

  assign chan_0 = config_channel == 0;
  
  assign start[0] = config_start & chan_0;
  
  assign stop[0] = config_stop & chan_0;
  
  assign wr[0] = is_chan_count & bram_wr & chan_0;

  reg                     chan0_config;
  reg                     chan0_init;

  reg  [13:0]             chan0_A0;
  reg  [13:0]             chan0_A1;
  reg  [13:0]             chan0_A2;
  reg  [13:0]             chan0_A3;
  reg  [13:0]             chan0_B0;
  reg  [13:0]             chan0_B1;
  reg  [13:0]             chan0_B2;
  reg  [13:0]             chan0_B3;

  wire [15:0]             chan0_power_A;
  wire [15:0]             chan0_power_B;
  wire [15:0]             chan0_phase_A;
  wire [15:0]             chan0_phase_B;

// temporary fix to avoid removal of code

  assign power_A = chan0_power_A;
  assign power_B = chan0_power_B;
  assign phase_A = chan0_phase_A;
  assign phase_B = chan0_phase_B;


// clock domain crossings


 (* ASYNC_REG="TRUE" *)  reg                  adc_started_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_started;

 (* ASYNC_REG="TRUE" *)  reg                  adc_probing_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_probing;

 (* ASYNC_REG="TRUE" *)  reg                  adc_running_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_running;

 (* ASYNC_REG="TRUE" *)  reg                  adc_full_1;
 (* ASYNC_REG="TRUE" *)  reg                  adc_full_2;

 (* ASYNC_REG="TRUE" *)  reg                  adc_almost_full_1;
 (* ASYNC_REG="TRUE" *)  reg                  adc_almost_full_2;

 (* ASYNC_REG="TRUE" *)  reg                  pci_bar_irq_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_bar_irq_2;

 (* ASYNC_REG="TRUE" *)  reg                  up_adc_started_1;
 (* ASYNC_REG="TRUE" *)  reg                  up_adc_started;

 (* ASYNC_REG="TRUE" *)  reg                  up_adc_stopped_1;
 (* ASYNC_REG="TRUE" *)  reg                  up_adc_stopped;

  assign adc_rst = up_adc_rst_cnt[3];
  assign adc_user_ready = up_adc_user_ready_cnt[6];

  assign state[0] = adc_started;
  assign state[1] = adc_probing;
  assign state[2] = adc_running;

  assign adc_delay = up_test_mode ? 0 : 1;


ana_fifo ana_fifo_inst (
  .rst(pci_reset),             // input wire rst
  .wr_clk(pci_clk),            // input wire wr_clk
  .rd_clk(rx_clk),             // input wire rd_clk
  .din(config_data),           // input wire [47 : 0] din
  .wr_en(config_wr),           // input wire wr_en
  .rd_en(config_rd),           // input wire rd_en
  .dout(config_out),           // output wire [47 : 0] dout
  .full(),                     // output wire full
  .empty(config_empty)         // output wire empty
);

ana_synt ana_synt_inst (
  .aclk(rx_clk),                       // input wire aclk
  .s_axis_phase_tvalid(synt_start),    // input wire s_axis_phase_tvalid
  .s_axis_phase_tready(),              // output wire s_axis_phase_tready
  .s_axis_phase_tdata(cordic_phase),   // input wire [31 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(synt_done),      // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(synt_data)        // output wire [47 : 0] m_axis_dout_tdata
);

bram_sample bram_sample_inst (
  .clka(rx_clk),            // input wire clka
  .ena(bram_en),            // input wire ena
  .wea(bram_wr),            // input wire [0 : 0] wea
  .addra(bram_adr),         // input wire [11 : 0] addra
  .dina(bram_in),           // input wire [55 : 0] dina
  .douta(bram_out)          // output wire [55 : 0] douta
);

bram_msix bram_msix_inst (
  .clka(pci_clk),    // input wire clka
  .ena(pci_en),      // input wire ena
  .wea(pci_wr),      // input wire [0 : 0] wea
  .addra(pci_adr),   // input wire [9 : 0] addra
  .dina(pci_in),     // input wire [31 : 0] dina
  .douta(pci_out),   // output wire [31 : 0] douta
  .clkb(rx_clk),     // input wire clkb
  .enb(0),           // input wire enb
  .web(0),           // input wire [0 : 0] web
  .addrb(0),         // input wire [9 : 0] addrb
  .dinb(0),          // input wire [31 : 0] dinb
  .doutb()           // output wire [31 : 0] doutb
);

adc_ana adc_ana_0_inst (
    .clk (rx_clk),
    .reset (rx_reset),

    .init(chan0_init),
    .count(config_count[12:0]),
    .start(start[0]),
    .stop(stop[0]),

    .wr(wr[0]),
    .wr_adr(bram_adr),
    .wr_sin(coeff_sin),
    .wr_cos(coeff_cos),

    .in_A0(chan0_A0),
    .in_A1(chan0_A1),
    .in_A2(chan0_A2),
    .in_A3(chan0_A3),
    .in_B0(chan0_B0),
    .in_B1(chan0_B1),
    .in_B2(chan0_B2),
    .in_B3(chan0_B3),

    .report(chan_report[0]),
    .power_A(chan0_power_A),
    .power_B(chan0_power_B),
    .phase_A(chan0_phase_A),
    .phase_B(chan0_phase_B) 
);

ila_2 ila_2_inst (
  .clk(rx_clk),                 // input wire clk
  .probe0(config_rd),           // input wire [0:0]
  .probe1(config_empty),        // input wire [0:0]
  .probe2(bram_en),             // input wire [0:0]
  .probe3(bram_wr),             // input wire [0:0]
  .probe4(bram_adr),            // input wire [13:0]
  .probe5(config_incr),         // input wire [29:0]
  .probe6(config_count),        // input wire [13:0]
  .probe7(bram_in_0),           // input wire [13:0]
  .probe8(bram_in_1),           // input wire [13:0]
  .probe9(bram_in_2),           // input wire [13:0]
  .probe10(bram_in_3),           // input wire [13:0]
  .probe11(bram_out[13:0]),          // input wire [13:0]
  .probe12(bram_out[27:14]),          // input wire [13:0]
  .probe13(bram_out[41:28]),          // input wire [13:0]
  .probe14(bram_out[55:42]),          // input wire [13:0]
  .probe15(wr[0]),               // input wire [0:0]
  .probe16(coeff_sin_0),            // input wire [15:0]
  .probe17(coeff_sin_1),            // input wire [15:0]
  .probe18(coeff_sin_2),            // input wire [15:0]
  .probe19(coeff_sin_3),            // input wire [15:0]
  .probe20(coeff_cos_0),            // input wire [15:0]
  .probe21(coeff_cos_1),            // input wire [15:0]
  .probe22(coeff_cos_2),            // input wire [15:0]
  .probe23(coeff_cos_3),            // input wire [15:0]
  .probe24(config_validate)      // input wire [0:0]
);

generate
begin : adc_app

    always @ ( posedge up_clk ) 
    begin
      if (up_reset)
      begin
        up_req_start <= 0;
        up_req_stop <= 0;
        up_req_state <= 0;
        up_test_mode <= 0;
      end
      else
      begin
        if (rx_control_msg)
        begin
          case (rx_control_index)
            0:
            begin
              up_req_state <= rx_control_data[1:0];
              if (up_req_state[1] != rx_control_data[1])
              begin
                if (rx_control_data[1])
                begin
                  up_req_start <= 1;
                  up_req_stop <= 0;
                end
                else
                begin
                  up_req_start <= 0;
                  up_req_stop <= 1;
                end
              end
              else
              begin
                up_req_start <= 0;
                up_req_stop <= 0;
              end
            end

            1:
            begin
              up_req_start <= 0;
              up_req_stop <= 0;
              up_test_mode <= rx_control_data;
            end

            default:
            begin
              up_req_start <= 0;
              up_req_stop <= 0;
            end
          endcase
        end
        else
        begin
          up_req_start <= 0;
          up_req_stop <= 0;
        end
      end
     end

    always @ ( posedge up_clk ) 
    begin
      if (up_reset)
      begin
        spi_write <= 0;
        adc_started <= 0;
        adc_probing <= 0;
        adc_running <= 0;
        up_rstn <= 0;
        qpll_rst <= 0;
        up_pend_start <= 0;
        up_spi_test_done <= 0;
        irq_state <= 0;
      end
      else
      begin
        if (up_req_start)
        begin
          adc_started <= 0;
          adc_probing <= 0;
          adc_running <= 0;
          up_spi_test_done <= 0;
          up_rstn <= 0;
          qpll_rst <= 1;
          up_pll_rst_cnt <= 4'h8; 
          up_adc_rst_cnt <= 4'h8;    
          up_adc_user_ready_cnt <= 7'h00;  
          up_pend_start <= 1;
          irq_state <= 0;
        end
        else
        begin
          qpll_rst <= 0;

          if (up_req_stop | up_adc_stopped)
          begin
            adc_started <= 0;
            up_rstn <= 0;
            irq_state <= irq_state | 8'h80;
          end
          else
          begin
            up_rstn <= 1;

            if (up_pend_start)
            begin
              if (adc_started)
              begin
                if (spi_done)
                begin
                  up_spi_test_done <= 1;
                  spi_write <= 0;
                end

                if (up_spi_test_done)
                begin
                  if (up_pll_rst_cnt[3] == 1'b1) 
                    up_pll_rst_cnt <= up_pll_rst_cnt + 1'b1;

                  if ((up_pll_rst_cnt[3] == 1'b1) || (adc_pll_locked != 4'b1111))
                    up_adc_rst_cnt <= 4'h8; 
                  else 
                    if (up_adc_rst_cnt[3] == 1'b1) 
                      up_adc_rst_cnt <= up_adc_rst_cnt + 1'b1;
 
                  if (up_adc_rst_cnt[3] == 1'b1) 
                    up_adc_user_ready_cnt <= 7'h00;   
                  else 
                  begin
                    if (up_adc_user_ready_cnt[6] == 1'b0) 
                      up_adc_user_ready_cnt <= up_adc_user_ready_cnt + 1'b1;
                    else
                    begin
                      if (adc_rst_done == 4'b1111)
                      begin
                        up_pend_start <= 0;
                        adc_probing <= 1;
                        irq_state <= irq_state | 8'h1;
                      end
                    end
                  end
                end
              end
              else
              begin
                spi_adr <= 12'h550;
                spi_out_data <= 8'h37;
                spi_write <= 1;
                adc_started <= 1;
                irq_state <= irq_state | 8'h2;
              end
            end
            else
            begin
              if (up_adc_started)
              begin
                adc_probing <= 0;
                end
              else
              begin
                if (adc_sync_ok)
                begin
                  spi_adr <= 12'h550;
                  spi_out_data <= up_test_mode;
                  spi_write <= 1;
                  adc_running <= 1;
                  irq_state <= irq_state | 8'h20;
                end
                else
                begin
                  if (spi_done)
                    spi_write <= 0;
 
                  if (adc_sync_fail)
                  begin
                    adc_started <= 0;
                    adc_probing <= 0;
                    irq_state <= irq_state | 8'h40;
                  end
                end
              end
            end
          end
        end
      end
    end


    always @ ( posedge up_clk ) 
    begin
      if (up_reset)
      begin
        tx_control_msg <= 0;
        up_curr_state <= 0;
        up_curr_irq <= 0;
        up_bar_irq <= 0;
      end
      else
      begin
        up_curr_irq <= irq_state;
        if (up_curr_irq != irq_state)
        begin
          tx_control_index <= 1;
          tx_control_data <= irq_state;
          tx_control_msg <= 1;
          up_bar_irq <= 1;
          up_bar_irq_cnt <= 0;
        end
        else
        begin
          up_curr_state <= state;
          if (up_curr_state != state)
          begin
            tx_control_index <= 0;
            tx_control_data <= state;
            tx_control_msg <= 1;
          end
          else
          begin
            tx_control_msg <= 0;

            if (up_bar_irq)
            begin
              if (up_bar_irq_cnt[3])
                up_bar_irq <= 0;
              else
                up_bar_irq_cnt <= up_bar_irq_cnt + 1;
            end
          end
        end
      end
    end

    always @ ( posedge up_clk ) 
    begin
      up_adc_started_1 <= adc_en;
      up_adc_started <= up_adc_started_1;
    end

    always @ ( posedge up_clk ) 
    begin
      up_adc_stopped_1 <= adc_stopped;
      up_adc_stopped <= up_adc_stopped_1;
    end

    always @ ( posedge pci_clk ) 
    begin
      adc_started_1 <= adc_started;
      pci_adc_started <= adc_started_1;
    end

    always @ ( posedge pci_clk ) 
    begin
      adc_probing_1 <= adc_probing;
      pci_adc_probing <= adc_probing_1;
    end

    always @ ( posedge pci_clk ) 
    begin
      adc_running_1 <= adc_running;
      pci_adc_running <= adc_running_1;
    end

    always @ ( posedge pci_clk ) 
    begin
      pci_bar_irq_1 <= up_bar_irq;
      pci_bar_irq_2 <= pci_bar_irq_1;
      pci_bar_irq_3 <= pci_bar_irq_2;
      
      if (!pci_bar_irq_3 && pci_bar_irq_2)
        adc_irq <= 1;
      else
        adc_irq <= 0;
    end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_rd)
    begin
      bar1_rp_data <= pci_out;
      bar1_rp <= 1;
    end
    else
      bar1_rp <= 0;

    pci_rd <= pci_rd_pend;
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      pci_en <= 0;
      pci_rd_pend <= 0;
      pci_wr_pend <= 0;
      pci_wr <= 0;
    end
    else
    begin
      if (bar1_wr)
      begin
        pci_adr <= bar1_wr_address;
        pci_in <= bar1_wr_data;

        if (bar1_wr_be == 4'b1111)
        begin
          pci_en <= 1;
          pci_rd_pend <= 0;
          pci_wr_pend <= 0;
          pci_wr <= 1;
        end
        else
        begin
          pci_en <= 1;
          pci_rd_pend <= 0;
          pci_wr_pend <= 1;
          pci_wr <= 0;
          pci_be <= bar1_wr_be;
        end
      end
      else
      begin
        if (bar1_rd)
        begin
          pci_adr <= bar1_rd_address;
          pci_en <= 1;
          pci_rd_pend <= 1;
          pci_wr_pend <= 0;
          pci_wr <= 0;
        end
        else
        begin
          if (pci_wr_pend)
          begin
            if (!pci_be[0])
              pci_in[7:0] <= pci_out[7:0];
              
            if (!pci_be[1])
              pci_in[15:8] <= pci_out[15:8];
            
            if (!pci_be[2])
              pci_in[23:16] <= pci_out[23:16];
            
            if (!pci_be[3])
              pci_in[31:24] <= pci_out[31:24];
              
            pci_en <= 1;
            pci_rd_pend <= 0;
            pci_wr_pend <= 0;
            pci_wr <= 1;
          end
          else
          begin
            pci_en <= 0;
            pci_rd_pend <= 0;
            pci_wr_pend <= 0;
            pci_wr <= 0;
          end
        end
      end
    end
  end


  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
      config_rd <= 0;
    else
    begin
      if (config_empty || bram_en)
        config_rd <= 0;
      else
        config_rd <= 1;
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
    begin
      config_init <= 0;
      bram_en <= 0;
    end
    else
    begin
      if (config_rd)
      begin
        config_channel <= config_out[4:0];
        config_incr[29:3] <= config_out[31:5];
        config_incr[2:0] <= 0;
        config_count <= config_out[47:32];
        config_init <= 1;
        bram_en <= 1;
      end
      else
      begin
        if (config_done)
          bram_en <= 0;
        config_init <= 0;
      end
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
      config_raw_coeff <= 0;
    else
    begin
      if (config_init)
      begin
        config_raw_coeff <= 0;
        synt_prev <= synt_done;
      end
      else
      begin
        if (bram_en)
        begin
          if (synt_prev != synt_done)
          begin
            synt_prev <= synt_done;

            if (synt_done)
            begin
              config_l_sin <= synt_raw_sin - synt_comp_sin;
              config_l_cos <= synt_raw_cos - synt_comp_cos;
              config_raw_coeff <= 1;
            end
            else
              config_raw_coeff <= 0;
          end
          else
            config_raw_coeff <= 0;
        end
        else
          config_raw_coeff <= 0;
      end
    end
  end


  always @ ( posedge rx_clk ) 
  begin
    if (config_raw_coeff)
    begin
      if (config_l_sin[6])
        config_sin <= config_l_sin[22:7] + 1;
      else
        config_sin <= config_l_sin[22:7];

      if (config_l_cos[6])
        config_cos <= config_l_cos[22:7] + 1;
      else
        config_cos <= config_l_cos[22:7];

      config_has_coeff <= 1;
    end
    else
      config_has_coeff <= 0;
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
    begin
      synt_start <= 0;
      config_start <= 0;
      config_validate <= 0;
      config_done <= 0;
      config_adr <= 0;
      bram_adr <= 0;
      bram_wr <= 0;
    end
    else
    begin
      if (config_init)
      begin
        synt_start <= 1;
        config_start <= 0;
        config_done <= 0;
        config_validate <= 0;
        bram_wr <= 0;
        config_adr <= 0;
        bram_adr <= 0;
      end
      else
      begin
        if (config_start)
        begin
          synt_start <= 0;
          config_start <= 0;
          config_done <= 0;
          bram_wr <= 0;
          bram_adr <= 0;
        end
        else
        begin
          if (config_validate)
          begin
            config_start <= 0;
            bram_wr <= 0;
            synt_start <= 0;

            if (bram_adr == 12'hFFF)
            begin
              config_validate <= 0;
              config_done <= 1;
            end
            else
            begin
              config_done <= 0;
              bram_adr <= bram_adr + 1;
            end
          end
          else
          begin
            if (config_has_coeff)
            begin
              case (config_adr[1:0])
                2'b00 :
                  begin
                    bram_in[13:0] <= config_sin[15:2];
                    coeff_sin[15:0] <= config_sin;
                    coeff_cos[15:0] <= config_cos;
                    bram_wr <= 0;
                  end
                2'b01 : 
                  begin
                    bram_in[27:14] <= config_sin[15:2];
                    coeff_sin[31:16] <= config_sin;
                    coeff_cos[31:16] <= config_cos;
                    bram_wr <= 0;
                  end
                2'b10 : 
                  begin
                    bram_in[41:28] <= config_sin[15:2];
                    coeff_sin[47:32] <= config_sin;
                    coeff_cos[47:32] <= config_cos;
                    bram_wr <= 0;
                  end
                2'b11 :
                  begin
                    bram_in[55:42] <= config_sin[15:2];
                    coeff_sin[63:48] <= config_sin;
                    coeff_cos[63:48] <= config_cos;
                    bram_wr <= 1;
                  end
              endcase
              
              if (config_adr == 14'h3FFF)
              begin
                config_done <= 0;
                config_start <= 1;
                config_validate <= 1;
                synt_start <= 0;
              end
              else
              begin
                config_done <= 0;
                config_start <= 0;
                config_validate <= 0;
                config_adr <= config_adr + 1;
                synt_phase <= synt_phase + config_incr;
                synt_start <= 1;
              end
            end
            else
            begin
              if (bram_wr)
                bram_adr <= config_adr[13:2];
               
              config_done <= 0;
              config_start <= 0;
              synt_start <= 0;
              bram_wr <= 0;
            end
          end
        end
      end
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (config_init && (config_channel == 5'h00))
      chan0_init <= 1;
    else
      chan0_init <= 0;
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
      chan0_config <= 0;
    else
    begin
      if (chan0_config)
      begin
        if (config_done)
          chan0_config <= 0;
      end
      else
      if (chan0_init)
        chan0_config <= 1;
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (chan0_config)
    begin
      chan0_A0 <= bram_out[13:0];      
      chan0_A1 <= bram_out[27:14];      
      chan0_A2 <= bram_out[41:28];      
      chan0_A3 <= bram_out[55:42];      
      chan0_B0 <= -bram_out[13:0];      
      chan0_B1 <= -bram_out[27:14];      
      chan0_B2 <= -bram_out[41:28];      
      chan0_B3 <= -bram_out[55:42];      
    end
    else
    begin
      if (adc_en)
      begin
        chan0_A0 <= adc_A0;
        chan0_A1 <= adc_A1;
        chan0_A2 <= adc_A2;
        chan0_A3 <= adc_A3;
        chan0_B0 <= adc_B0;
        chan0_B1 <= adc_B1;
        chan0_B2 <= adc_B2;
        chan0_B3 <= adc_B3;
      end
      else
      begin
        chan0_A0 <= 0;
        chan0_A1 <= 0;
        chan0_A2 <= 0;
        chan0_A3 <= 0;
        chan0_B0 <= 0;
        chan0_B1 <= 0;
        chan0_B2 <= 0;
        chan0_B3 <= 0;
      end
    end
  end


end
endgenerate

endmodule
