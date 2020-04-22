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

  input wire [16:0]       bar_rd_address,
  input wire              bar_rd,

  output wire [31:0]      bar_rp_data,
  output wire             bar_rp,

  input wire [16:0]       bar_wr_address,
  input wire [31:0]       bar_wr_data,
  input wire [3:0]        bar_wr_be,
  input wire              bar_wr,

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

  output reg              bar_irq,
  output reg              block_irq,
  output reg [15:0]       phys_index,

  input wire              adc_wr,
  input wire [127:0]      adc_wr_data,

  input wire              adc_next_address,
  output reg              adc_valid_address,
  output reg [63:0]       adc_address,
  input wire              adc_rd,
  output wire [127:0]     adc_rd_data,
  output reg              adc_almost_full,
  output reg              adc_almost_empty,

  output wire [2:0]       state
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

  reg [13:0]              phys_offset;
  wire [19:0]             phys_page;
  wire                    phys_valid;

// FIFO

  wire                    fifo_reset;
  wire                    fifo_full;
  wire                    fifo_almost_full;
  wire                    fifo_almost_empty;


// clock domain crossings


 (* ASYNC_REG="TRUE" *)  reg                  adc_started_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_started;

 (* ASYNC_REG="TRUE" *)  reg                  adc_probing_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_probing;

 (* ASYNC_REG="TRUE" *)  reg                  adc_running_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_running;

 (* ASYNC_REG="TRUE" *)  reg                  adc_almost_full_1;
 (* ASYNC_REG="TRUE" *)  reg                  adc_almost_full_2;

 (* ASYNC_REG="TRUE" *)  reg                  adc_almost_empty_1;
 (* ASYNC_REG="TRUE" *)  reg                  adc_almost_empty_2;

 (* ASYNC_REG="TRUE" *)  reg                  pci_bar_irq_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_bar_irq_2;

adc_fifo adc_fifo_inst (
  .rst(fifo_reset),                 // input wire rst
  .wr_clk(rx_clk),                  // input wire wr_clk
  .rd_clk(pci_clk),                 // input wire rd_clk
  .din(adc_wr_data),                // input wire [127 : 0] din
  .wr_en(adc_wr),                   // input wire wr_en
  .rd_en(adc_rd),                   // input wire rd_en
  .dout(adc_rd_data),               // output wire [127 : 0] dout
  .full(fifo_full),                 // output wire full
  .almost_full(fifo_almost_full),   // output wire almost full
  .almost_empty(fifo_almost_empty)  // output wire almost empty
);


phys_bar adc_bar_inst (
    .clk(pci_clk),
    .reset(pci_reset),

    .rd_address(bar_rd_address),
    .rd(bar_rd),
    .rp_data(bar_rp_data),
    .rp(bar_rp),

    .wr_address(bar_wr_address),
    .wr_data(bar_wr_data),
    .wr_be(bar_wr_be),
    .wr(bar_wr),

    .index(phys_index),
    .page(phys_page),
    .valid(phys_valid)
);


ila_1 ila_1_inst (
    .clk(pci_clk),                     // input wire clk
    .probe0(pci_adc_started),          // input wire [0:0]  probe0  
    .probe1(pci_adc_probing),          // input wire [0:0]  probe0  
    .probe2(pci_adc_running),          // input wire [0:0]  probe0  
    .probe3(bar_irq),                  // input wire [0:0]  probe0  
    .probe4(block_irq),                // input wire [0:0]  probe0  
    .probe5(phys_index),               // input wire [15:0]  probe0  
    .probe6(phys_valid),               // input wire [0:0]  probe0  
    .probe7(phys_page),                // input wire [19:0]  probe0  
    .probe8(phys_offset),              // input wire [13:0]  probe0  
    .probe9(adc_almost_empty),         // input wire [0:0]  probe0  
    .probe10(adc_almost_full),         // input wire [0:0]  probe0  
    .probe11(adc_next_address),        // input wire [0:0]  probe0  
    .probe12(adc_address),             // input wire [63:0]  probe0  
    .probe13(adc_rd),                  // input wire [0:0]  probe0  
    .probe14(adc_rd_data[15:0]),       // input wire [15:0]  probe0  
    .probe15(adc_rd_data[31:16])       // input wire [15:0]  probe0  
);

  assign fifo_reset = !adc_started;

  assign adc_rst = up_adc_rst_cnt[3];
  assign adc_user_ready = up_adc_user_ready_cnt[6];

  assign state[0] = adc_started;
  assign state[1] = adc_probing;
  assign state[2] = adc_running;

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

          if (up_req_stop)
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
              if (adc_in)
              begin
                adc_probing <= 0;
                if (fifo_full)
                begin
                  adc_started <= 0;
                  adc_running <= 0;
                  irq_state <= irq_state | 8'h10;
                end
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
      adc_almost_full_1 <= fifo_almost_full;
      adc_almost_full_2 <= adc_almost_full_1;
      adc_almost_full <= adc_almost_full_2;
    end

    always @ ( posedge pci_clk ) 
    begin
      adc_almost_empty_1 <= fifo_almost_empty;
      adc_almost_empty_2 <= adc_almost_empty_1;
      adc_almost_empty <= adc_almost_empty_2;
    end

    always @ ( posedge pci_clk ) 
    begin
      pci_bar_irq_1 <= up_bar_irq;
      pci_bar_irq_2 <= pci_bar_irq_1;
      pci_bar_irq_3 <= pci_bar_irq_2;
      
      if (!pci_bar_irq_3 && pci_bar_irq_2)
        bar_irq <= 1;
      else
        bar_irq <= 0;
    end

    always @ ( posedge pci_clk ) 
    begin
      if (pci_adc_started)
      begin
        if (adc_next_address)
        begin
          phys_offset <= phys_offset + 1;
          if (phys_page)
          begin
            if (phys_offset == 14'b11111111111111)
            begin
              phys_index <= phys_index + 1;
              block_irq <= 1;
            end
            else
              block_irq <= 0;
          end
          else
            block_irq <= 0;
        end
        else
        begin
          block_irq <= 0;
          adc_valid_address <= phys_valid;
          adc_address[6:0] <= 0;
          adc_address[20:7] <= phys_offset;
          adc_address[40:21] <= phys_page;
          adc_address[63:41] <= 0;
        end
      end
      else
      begin
        phys_index <= 0;
        phys_offset <= 0;
        block_irq <= 0;
      end
    end


end
endgenerate

endmodule
