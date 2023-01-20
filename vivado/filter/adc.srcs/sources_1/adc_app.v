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

  output reg              report,
  output wire [15:0]      power_A,
  output wire [15:0]      power_B,

  output wire [15:0]      phase_A,
  output wire [15:0]      phase_B,

  input wire [7:0]        bar1_rd_address,
  input wire              bar1_rd,

  output reg [31:0]       bar1_rp_data,
  output reg              bar1_rp,

  input wire [7:0]        bar1_wr_address,
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
  reg  [7:0]              pci_adr;
  reg  [31:0]             pci_in;
  wire [31:0]             pci_out;
  reg  [3:0]              pci_be;

  reg                     pci_ana_req;
  reg  [3:0]              pci_ana_chan;

  reg  [15:0]             pci_pend;
  reg  [1:0]              pci_count;

// rx domain

  reg  [15:0]             rx_req;
  reg  [15:0]             rx_init;
  reg  [15:0]             rx_conf;

  reg                     rx_en;
  reg                     rx_wr;
  reg  [7:0]              rx_adr;
  reg  [31:0]             rx_in;
  wire [31:0]             rx_out;

// channel 0

  reg  [13:0]             chan0_count;
  reg  [29:0]             chan0_incr;

  wire                    chan0_run;   
  wire                    chan0_report;
  wire [15:0]             chan0_power_A;
  wire [15:0]             chan0_power_B;
  wire [15:0]             chan0_phase_A;
  wire [15:0]             chan0_phase_B;

// channel 1

  reg  [13:0]             chan1_count;
  reg  [29:0]             chan1_incr;

  wire                    chan1_run;   
  wire                    chan1_report;
  wire [15:0]             chan1_power_A;
  wire [15:0]             chan1_power_B;
  wire [15:0]             chan1_phase_A;
  wire [15:0]             chan1_phase_B;

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

 (* ASYNC_REG="TRUE" *)  reg [15:0]           temp_pend;
 (* ASYNC_REG="TRUE" *)  reg [15:0]           rx_pend;

  assign adc_rst = up_adc_rst_cnt[3];
  assign adc_user_ready = up_adc_user_ready_cnt[6];

  assign state[0] = adc_started;
  assign state[1] = adc_probing;
  assign state[2] = adc_running;

  assign adc_delay = up_test_mode ? 0 : 1;

fifo_signal signal_inst (
  .rst(pci_reset),          // input wire rst
  .wr_clk(rx_clk),          // input wire wr_clk
  .rd_clk(pci_clk),         // input wire rd_clk
  .din(sig_in),             // input wire [63 : 0] din
  .wr_en(report),           // input wire wr_en
  .rd_en(rd),               // input wire rd_en
  .dout(sig_out),           // output wire [63 : 0] dout
  .full(),                  // output wire full
  .empty(empty),            // output wire empty
  .prog_empty()             // output wire empty
);

bram_signal bram_signal_inst (
  .clka(pci_clk),    // input wire clka
  .ena(pci_en),      // input wire ena
  .wea(pci_wr),      // input wire [0 : 0] wea
  .addra(pci_adr),   // input wire [7 : 0] addra
  .dina(pci_in),     // input wire [31 : 0] dina
  .douta(pci_out),   // output wire [31 : 0] douta
  .clkb(rx_clk),     // input wire clkb
  .enb(rx_en),       // input wire enb
  .web(rx_wr),       // input wire [0 : 0] web
  .addrb(rx_adr),    // input wire [7 : 0] addrb
  .dinb(rx_in),      // input wire [31 : 0] dinb
  .doutb(rx_out)     // output wire [31 : 0] doutb
);

adc_ana ana_0 (
    .clk (rx_clk),
    .reset (rx_reset),

    .conf(rx_conf[0]),
    .incr(chan0_incr),
    .count(chan0_count),
    .stop(0),

    .in_A0(adc_A0),
    .in_A1(adc_A1),
    .in_A2(adc_A2),
    .in_A3(adc_A3),
    .in_B0(adc_B0),
    .in_B1(adc_B1),
    .in_B2(adc_B2),
    .in_B3(adc_B3),
    
    .run(chan0_run),
    .report(chan0_report),
    .amp_A(chan0_power_A),
    .amp_B(chan0_power_B),
    .phase_A(chan0_phase_A),
    .phase_B(chan0_phase_B)
);

adc_ana ana_1 (
    .clk (rx_clk),
    .reset (rx_reset),

    .conf(rx_conf[1]),
    .incr(chan1_incr),
    .count(chan1_count),
    .stop(0),

    .in_A0(adc_A0),
    .in_A1(adc_A1),
    .in_A2(adc_A2),
    .in_A3(adc_A3),
    .in_B0(adc_B0),
    .in_B1(adc_B1),
    .in_B2(adc_B2),
    .in_B3(adc_B3),
    
    .run(chan1_run),
    .report(chan1_report),
    .amp_A(chan1_power_A),
    .amp_B(chan1_power_B),
    .phase_A(chan1_phase_A),
    .phase_B(chan1_phase_B)
);


ila_1 ila_1_inst (
  .clk(pci_clk),                 // input wire clk
  .probe0(pci_ana_req),          // input wire [0:0]
  .probe1(pci_ana_chan),         // input wire [3:0]
  .probe2(pci_pend),             // input wire [15:0]
  .probe3(pci_count)             // input wire [1:0]
);

ila_2 ila_2_inst (
  .clk(rx_clk),                  // input wire clk
  .probe0(rx_req),               // input wire [15:0]
  .probe1(rx_init),              // input wire [15:0]
  .probe2(rx_conf),              // input wire [15:0]
  .probe3(rx_en),                // input wire [0:0]
  .probe4(rx_adr),               // input wire [7:0]
  .probe5(rx_out),               // input wire [31:0]
  .probe6(chan0_incr),           // input wire [29:0]
  .probe7(chan0_count),          // input wire [13:0]
  .probe8(chan0_run),            // input wire [0:0]
  .probe9(chan0_report),         // input wire [0:0]
  .probe10(chan0_power_A),       // input wire [15:0]
  .probe11(chan0_power_B),       // input wire [15:0]
  .probe12(chan0_phase_A),       // input wire [15:0]
  .probe13(chan0_phase_B),       // input wire [15:0]
  .probe14(chan1_incr),          // input wire [29:0]
  .probe15(chan1_count),         // input wire [13:0]
  .probe16(chan1_run),           // input wire [0:0]
  .probe17(chan1_report),        // input wire [0:0]
  .probe18(chan1_power_A),       // input wire [15:0]
  .probe19(chan1_power_B),       // input wire [15:0]
  .probe20(chan1_phase_A),       // input wire [15:0]
  .probe21(chan1_phase_B)        // input wire [15:0]
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

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
      pci_ana_req <= 0;
    else
    begin
      if (pci_wr)
      begin
        if ((pci_adr[2:0]) == 6 && (pci_adr[7] == 0))
        begin
          pci_ana_req <= 1;
          pci_ana_chan <= pci_adr[6:3];
        end
        else
          pci_ana_req <= 0;
      end
      else
        pci_ana_req <= 0;
    end
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      pci_pend <= 0;
      pci_count <= 0;
    end
    else
    begin
      if (pci_ana_req)
      begin
        pci_count <= 2'b11;

        case (pci_ana_chan)
          4'h0: pci_pend[0] <= 1;
          4'h1: pci_pend[1] <= 1;
          4'h2: pci_pend[2] <= 1;
          4'h3: pci_pend[3] <= 1;
          4'h4: pci_pend[4] <= 1;
          4'h5: pci_pend[5] <= 1;
          4'h6: pci_pend[6] <= 1;
          4'h7: pci_pend[7] <= 1;
          4'h8: pci_pend[8] <= 1;
          4'h9: pci_pend[9] <= 1;
          4'hA: pci_pend[10] <= 1;
          4'hB: pci_pend[11] <= 1;
          4'hC: pci_pend[12] <= 1;
          4'hD: pci_pend[13] <= 1;
          4'hE: pci_pend[14] <= 1;
          4'hF: pci_pend[15] <= 1;
        endcase     
      end
      else
      begin
        if (pci_count)
          pci_count <= pci_count - 1;
        else
          pci_pend <= 0;
      end
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    temp_pend <= pci_pend;
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
    begin
      rx_req <= 0;
      rx_pend <= 0;
    end
    else
    begin
      if (rx_conf)
        rx_req <= rx_req & !rx_conf;
      else
      begin
        rx_pend <= temp_pend;
        rx_req <= rx_req | (rx_pend & (rx_pend ^ temp_pend));
      end
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
    begin
      rx_en <= 0;
      rx_wr <= 0;
      rx_init <= 0;
    end
    else
    begin
      if (rx_en)
      begin
        if (rx_adr[2] == 1)
        begin
          rx_en <= 0;
          rx_init <= 0;
        end
        else
          rx_adr <= rx_adr + 1;
      end
      else
      begin
        casex (rx_req)
          16'b0000000000000000 : 
            begin
              rx_en <= 0;
              rx_init <= 0;
            end

          16'bxxxxxxxxxxxxxxx1 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h00;
              rx_init[0] <= 1;
            end

          16'bxxxxxxxxxxxxxx10 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h08;
              rx_init[1] <= 1;
            end

          16'bxxxxxxxxxxxxx100 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h10;
              rx_init[2] <= 1;
            end

          16'bxxxxxxxxxxxx1000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h18;
              rx_init[3] <= 1;
            end

            16'bxxxxxxxxxxx10000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h20;
              rx_init[4] <= 1;
            end

            16'bxxxxxxxxxx100000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h28;
              rx_init[5] <= 1;
            end

            16'bxxxxxxxxx1000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h30;
              rx_init[6] <= 1;
            end

            16'bxxxxxxxx10000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h38;
              rx_init[7] <= 1;
            end

            16'bxxxxxxx100000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h40;
              rx_init[8] <= 1;
            end

            16'bxxxxxx1000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h48;
              rx_init[9] <= 1;
            end

            16'bxxxxx10000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h50;
              rx_init[10] <= 1;
            end

            16'bxxxx100000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h58;
              rx_init[11] <= 1;
            end

            16'bxxx1000000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h60;
              rx_init[12] <= 1;
            end

            16'bxx10000000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h68;
              rx_init[13] <= 1;
            end

            16'bx100000000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h70;
              rx_init[14] <= 1;
            end

            16'b1000000000000000 :
            begin
              rx_en <= 1;
              rx_adr <= 8'h78;
              rx_init[15] <= 1;
            end
          endcase
        end
      end
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
      rx_conf[0] <= 0;
    else
    begin
      if (rx_init[0])
      begin
        case (rx_adr[2:0])
          1 : chan0_count <= rx_out[15:0];
          2 : chan0_incr <= rx_out;
          3 : rx_conf[0] <= 1;
          default: rx_conf[0] <= 0;
        endcase
      end
      else
        rx_conf[0] <= 0;
    end
  end

  always @ ( posedge rx_clk ) 
  begin
    if (rx_reset)
      rx_conf[1] <= 0;
    else
    begin
      if (rx_init[1])
      begin
        case (rx_adr[2:0])
          1 : chan1_count <= rx_out[15:0];
          2 : chan1_incr <= rx_out;
          3 : rx_conf[1] <= 1;
          default: rx_conf[1] <= 0;
        endcase
      end
      else
        rx_conf[1] <= 0;
    end
  end


endgenerate

endmodule
