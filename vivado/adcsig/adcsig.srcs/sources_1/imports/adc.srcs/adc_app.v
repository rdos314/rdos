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
// adc_app.v
// ADC module
//
////////////////////////////////////////////////////////////////////////////////

module adc_app (
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

  input wire [17:0]       bar1_rd_address,
  input wire              bar1_rd,

  output reg [31:0]       bar1_rp_data,
  output reg              bar1_rp,

  input wire [17:0]       bar1_wr_address,
  input wire [31:0]       bar1_wr_data,
  input wire [3:0]        bar1_wr_be,
  input wire              bar1_wr,

  input wire [9:0]        bar2_rd_address,
  input wire              bar2_rd,

  output reg [31:0]       bar2_rp_data,
  output reg              bar2_rp,

  input wire [9:0]        bar2_wr_address,
  input wire [31:0]       bar2_wr_data,
  input wire [3:0]        bar2_wr_be,
  input wire              bar2_wr  
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
  
  reg  [13:0]             ana_rd_adr;
  reg  [15:0]             ana_rd;
  reg   [3:0]             ana_rd_chan;
  reg                     ana_missing_rp;

  reg  [13:0]             ana_wr_adr;
  reg  [31:0]             ana_wr_data;
  reg   [3:0]             ana_wr_be;
  reg  [15:0]             ana_wr;

  wire  [0:0]             ana_rp;
  wire [31:0]             ana_0_rp_data;

  reg                     pci2_en;
  reg                     pci2_rd;
  reg                     pci2_wr;
  reg                     pci2_rd_pend;
  reg                     pci2_wr_pend;
  reg  [9:0]              pci2_adr;
  reg  [31:0]             pci2_in;
  wire [31:0]             pci2_out;
  reg  [3:0]              pci2_be;

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

bram_msix bram_msix_inst (
  .clka(pci_clk),    // input wire clka
  .ena(pci2_en),     // input wire ena
  .wea(pci2_wr),     // input wire [0 : 0] wea
  .addra(pci2_adr),  // input wire [9 : 0] addra
  .dina(pci2_in),    // input wire [31 : 0] dina
  .douta(pci2_out),  // output wire [31 : 0] douta
  .clkb(rx_clk),     // input wire clkb
  .enb(0),           // input wire enb
  .web(0),           // input wire [0 : 0] web
  .addrb(0),         // input wire [9 : 0] addrb
  .dinb(0),          // input wire [31 : 0] dinb
  .doutb(0)          // output wire [31 : 0] doutb
);

adc_ana adc_ana_0_inst (
    .pci_reset (pci_reset),
    .pci_clk (pci_clk),
    .clk (rx_clk),

    .rd_address(ana_rd_adr),
    .rd(ana_rd[0]),
    .rp_data(ana_0_rp_data),
    .rp(ana_rp[0]),
    .wr_address(ana_wr_adr),
    .wr_data(ana_wr_data),
    .wr_be(ana_wr_be),
    .wr(ana_wr[0])
);


ila_2 ila_2_inst (
  .clk(pci_clk),             // input wire clk
  .probe0(bar1_rd_address),  // input wire [17:0]  probe0  
  .probe1(bar1_rd),          // input wire [0:0]  probe1 
  .probe2(bar1_rp_data),     // input wire [31:0]  probe2 
  .probe3(bar1_rp),          // input wire [0:0]  probe3 
  .probe4(bar1_wr_address),  // input wire [17:0]  probe4 
  .probe5(bar1_wr_data),     // input wire [31:0]  probe5 
  .probe6(bar1_wr_be),       // input wire [3:0]  probe6 
  .probe7(bar1_wr),          // input wire [0:0]  probe7 
  .probe8(ana_rd_adr),       // input wire [13:0]  probe8 
  .probe9(ana_rd),           // input wire [15:0]  probe9 
  .probe10(ana_rd_chan),     // input wire [3:0]  probe10 
  .probe11(ana_missing_rp),  // input wire [0:0]  probe11 
  .probe12(ana_wr_adr),      // input wire [13:0]  probe12 
  .probe13(ana_wr_data),     // input wire [31:0]  probe13 
  .probe14(ana_wr_be),       // input wire [3:0]  probe14
  .probe15(ana_wr),          // input wire [15:0]  probe15 
  .probe16(ana_rp),          // input wire [0:0]  probe16
  .probe17(ana_0_rp_data)    // input wire [31:0]  probe17
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
    if (pci2_rd)
    begin
      bar2_rp_data <= pci2_out;
      bar2_rp <= 1;
    end
    else
      bar2_rp <= 0;

    pci2_rd <= pci2_rd_pend;
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      pci2_en <= 0;
      pci2_rd_pend <= 0;
      pci2_wr_pend <= 0;
      pci2_wr <= 0;
    end
    else
    begin
      if (bar2_wr)
      begin
        pci2_adr <= bar2_wr_address;
        pci2_in <= bar2_wr_data;

        if (bar2_wr_be == 4'b1111)
        begin
          pci2_en <= 1;
          pci2_rd_pend <= 0;
          pci2_wr_pend <= 0;
          pci2_wr <= 1;
        end
        else
        begin
          pci2_en <= 1;
          pci2_rd_pend <= 0;
          pci2_wr_pend <= 1;
          pci2_wr <= 0;
          pci2_be <= bar2_wr_be;
        end
      end
      else
      begin
        if (bar2_rd)
        begin
          pci2_adr <= bar2_rd_address;
          pci2_en <= 1;
          pci2_rd_pend <= 1;
          pci2_wr_pend <= 0;
          pci2_wr <= 0;
        end
        else
        begin
          if (pci2_wr_pend)
          begin
            if (!pci2_be[0])
              pci2_in[7:0] <= pci2_out[7:0];
              
            if (!pci2_be[1])
              pci2_in[15:8] <= pci2_out[15:8];
            
            if (!pci2_be[2])
              pci2_in[23:16] <= pci2_out[23:16];
            
            if (!pci2_be[3])
              pci2_in[31:24] <= pci2_out[31:24];
              
            pci2_en <= 1;
            pci2_rd_pend <= 0;
            pci2_wr_pend <= 0;
            pci2_wr <= 1;
          end
          else
          begin
            pci2_en <= 0;
            pci2_rd_pend <= 0;
            pci2_wr_pend <= 0;
            pci2_wr <= 0;
          end
        end
      end
    end
  end

  always @ ( posedge pci_clk ) 
  begin
    if (ana_missing_rp)
    begin
      bar1_rp_data <= 32'hFFFFFFFF;
      bar1_rp <= 1;
    end
    else
    begin
      if (ana_rp)
      begin
        case (ana_rd_chan)
          4'h0 : bar1_rp_data <= ana_0_rp_data;
        endcase        
        bar1_rp <= 1;
      end
      else
        bar1_rp <= 0;
    end
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      ana_missing_rp <= 0;
      ana_rd <= 16'h0000;
      ana_wr <= 16'h0000;
    end
    else
    begin
      if (bar1_wr)
      begin
        ana_missing_rp <= 0;
        ana_rd <= 16'h0000;
        ana_wr_adr <= bar1_wr_address[13:0];
        ana_wr_data <= bar1_wr_data;
        ana_wr <= 1 << bar1_wr_address[17:14];
      end
      else
      begin
        if (bar1_rd)
        begin
          ana_rd_adr <= bar1_rd_address[13:0];
          ana_rd_chan <= bar1_rd_address[17:14];
          ana_rd <= 1 << bar1_rd_address[17:14];
          ana_wr <= 16'h0000;

          case (bar1_rd_address[17:14])
            4'h0 : ana_missing_rp <= 0;
            4'h1 : ana_missing_rp <= 1;
            4'h2 : ana_missing_rp <= 1;
            4'h3 : ana_missing_rp <= 1;
            4'h4 : ana_missing_rp <= 1;
            4'h5 : ana_missing_rp <= 1;
            4'h6 : ana_missing_rp <= 1;
            4'h7 : ana_missing_rp <= 1;
            4'h8 : ana_missing_rp <= 1;
            4'h9 : ana_missing_rp <= 1;
            4'hA : ana_missing_rp <= 1;
            4'hB : ana_missing_rp <= 1;
            4'hC : ana_missing_rp <= 1;
            4'hD : ana_missing_rp <= 1;
            4'hE : ana_missing_rp <= 1;
            4'hF : ana_missing_rp <= 1;
          endcase          
        end
        else
          ana_missing_rp <= 0;
          ana_rd <= 16'h0000;
          ana_wr <= 16'h0000;
      end
    end
  end

end
endgenerate

endmodule
