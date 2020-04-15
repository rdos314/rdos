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
  input wire              qpll_locked,

  output wire             adc_rst,
  output wire             adc_user_ready,
  input wire [3:0]        adc_pll_locked,
  input wire [3:0]        adc_rst_done,

  input wire              adc_sync_ok,
  input wire              adc_sync_fail,

  output reg              adc_started,
  output reg              adc_probing,
  output reg              adc_running,

  input wire              adc_in,
  input wire [127:0]      adc_in_data,

  output reg              adc_out,
  input wire              adc_out_ack,
  output reg [127:0]      adc_out_header,
  output reg [1023:0]     adc_out_data,

  output wire [2:0]       state
);

// up domain

  reg [1:0]               up_req_state;
  reg [2:0]               up_curr_state;
  reg [7:0]               up_test_mode;

  reg                     up_req_start;
  reg                     up_req_stop;
  reg                     up_pend_start;

  reg                     up_spi_test_done;
  reg [3:0]               up_pll_rst_cnt; 
  reg [3:0]               up_adc_rst_cnt;
  reg [6:0]               up_adc_user_ready_cnt;  

// pci domain

  reg [19:0]              pci_page;
  reg [13:0]              pci_index;
  reg [2:0]               pci_adc_cnt;
  reg                     pci_busy;
  reg                     pci_pend;
  reg                     pci_has_data;
  reg [1023:0]            pci_data;

  reg                     phys_clear;
  reg                     phys_next;
  wire [16:0]             phys_index;
  wire [19:0]             phys_page;
  wire                    phys_valid;

// FIFO

  wire                    fifo_want_data;
  wire                    fifo_rd;

  wire                    fifo_reset;
  wire                    fifo_full;
  wire                    fifo_empty;
  reg [127:0]             fifo_data;


// clock domain crossings


 (* ASYNC_REG="TRUE" *)  reg                  adc_started_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_started;

 (* ASYNC_REG="TRUE" *)  reg                  adc_probing_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_probing;

 (* ASYNC_REG="TRUE" *)  reg                  adc_running_1;
 (* ASYNC_REG="TRUE" *)  reg                  pci_adc_running;


adc_fifo adc_fifo_inst (
  .rd_clk(pci_clk),      // input wire read clk
  .wr_clk(rx_clk),       // input wire write clk
  .srst(fifo_reset),     // input wire srst
  .din(adc_in_data),     // input wire [127 : 0] din
  .wr_en(adc_in),        // input wire wr_en
  .rd_en(fifo_rd),       // input wire rd_en
  .dout(fifo_data),      // output wire [127 : 0] dout
  .full(fifo_full),      // output wire full
  .empty(fifo_empty)     // output wire empty
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

    .clear(phys_clear),
    .next(phys_next),
    .index(phys_index),
    .page(phys_page),
    .valid(phys_valid)
);


ila_1 ila_1_inst (
    .clk(pci_clk),                     // input wire clk
    .probe0(pci_adc_started),          // input wire [0:0]  probe0  
    .probe1(pci_adc_probing),          // input wire [0:0]  probe0  
    .probe2(pci_adc_running),          // input wire [0:0]  probe0  
    .probe3(pci_page),                 // input wire [19:0]  probe0  
    .probe4(pci_index),                // input wire [13:0]  probe0  
    .probe5(pci_adc_cnt),              // input wire [2:0]  probe0  
    .probe6(pci_busy),                 // input wire [0:0]  probe0  
    .probe7(pci_pend),                 // input wire [0:0]  probe0  
    .probe8(pci_has_data),             // input wire [0:0]  probe0  
    .probe9(fifo_empty),               // input wire [0:0]  probe0  
    .probe10(fifo_full),               // input wire [0:0]  probe0  
    .probe11(fifo_rd),                 // input wire [0:0]  probe0  
    .probe12(adc_out),                 // input wire [0:0]  probe0  
    .probe13(adc_out_header[127:64]),  // input wire [63:0]  probe0  
    .probe14(adc_out_data[15:0]),      // input wire [15:0]  probe0  
    .probe15(adc_out_data[31:16])      // input wire [15:0]  probe0  
);

  assign fifo_reset = !adc_started;

  assign adc_rst = up_adc_rst_cnt[3];
  assign adc_user_ready = up_adc_user_ready_cnt[6];

  assign state[0] = adc_started;
  assign state[1] = adc_probing;
  assign state[2] = adc_running;

  assign fifo_want_data = pci_page ? !fifo_empty : 1'b0;
  assign fifo_rd = pci_pend ? 1'b0 : fifo_want_data;

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
      end
      else
      begin
        if (up_req_start)
        begin
          up_rstn <= 0;
          qpll_rst <= 1;
          up_pll_rst_cnt <= 4'h8; 
          up_adc_rst_cnt <= 4'h8;    
          up_adc_user_ready_cnt <= 7'h00;  
          up_pend_start <= 1;
        end
        else
        begin
          qpll_rst <= 0;

          if (up_req_stop)
          begin
            adc_started <= 0;
            up_rstn <= 0;
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
                  if (qpll_locked)
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
                end
                else
                begin
                  if (spi_done)
                    spi_write <= 0;

                  if (adc_sync_fail)
                  begin
                    adc_started <= 0;
                    adc_probing <= 0;
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
          tx_control_msg <= 0;
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
      if (pci_adc_started)
      begin
        phys_clear <= 0;

        if (phys_valid)
          pci_page <= phys_page;

        if (adc_out)
        begin
          pci_index <= pci_index + 1;
          if (pci_page)
          begin
            if (pci_index == 14'b11111111111111)
            begin
              phys_next <= 1;
              pci_page <= 0;
            end
            else
              phys_next <= 0;
          end
          else
            phys_next <= 0;
        end
      end
      else
      begin
        phys_next <= 0;
        phys_clear <= 1;
        pci_page <= 0;
        pci_index <= 0;
      end
    end


    always @ ( posedge pci_clk ) 
    begin
      if (pci_started)
      begin
        pci_has_data <= fifo_rd;

        if (pci_has_data)
        begin
          adc_out <= 0;

          if (adc_out_ack)
            pci_busy <= 0;

          pci_data[1023:896] <= fifo_data;
          pci_data[895:0] <= adc_data[1023:128];
          pci_adc_cnt <= pci_adc_cnt + 1;

          if (pci_adc_cnt == 3'b111)
          begin
            pci_pend <= 1;
            adc_out_data <= pci_data;

            adc_out_header[63:48] <= 0;                      // Requester ID
            adc_out_header[47:40] <= 0;                      // tag
            adc_out_header[39:36] <= 4'b1111;                // last be
            adc_out_header[35:32] <= 4'b1111;                // 1st be

            if (pci_page[19:11] == 0)
            begin
              adc_out_header[31:24] <= 8'b010_00000;         // Type + Fmt (32-bit)
              adc_out_header[70:64] <= 0;
              adc_out_header[84:71] <= pci_index;
              adc_out_header[95:85] <= pci_page[10:0];
            end
            else
            begin
              adc_out_header[31:24] <= 8'b011_00000;         // Type + Fmt (64-bit)
              adc_out_header[72:64] <= pci_page[19:11];
              adc_out_header[102:96] <= 0;
              adc_out_header[116:103] <= pci_index;
              adc_out_header[127:117] <= pci_page[10:0];
            end

            adc_out_header[23] <= 1'b0;                      // R
            adc_out_header[22:20] <= 3'b000;                 // TC
            adc_out_header[19:16] <= 4'b0000;                // TH, AttrH, R
            adc_out_header[15:12] <= 4'b0000;                // TD, EP, Attr
            adc_out_header[11:10] <= 2'b0;                   // AT
            adc_out_header[9:8] <= 2'b0;                     // len high
            adc_out_header[7:0] <= 8'h20;                    // 128 byte size
          end
        end
        else
        begin
          if (pci_page)
          begin
            if (adc_out_ack)
            begin
              adc_out <= 1;
              pci_busy <= 1;
              pci_pend <= 0;
            end
            else
            begin
              if (pci_busy)
                adc_out <= 0;
              else
              begin
                adc_out <= 1;
                pci_busy <= 1;
                pci_pend <= 0;
              end
            end
          end
          else
          begin
            adc_out <= 0;
            if (adc_out_ack)
              pci_busy <= 0;
          end
        end
      end
      else
      begin
        adc_out <= 0;
        pci_busy <= 0;
        pci_pend <= 0;
        pci_has_data <= 0;
        pci_adc_cnt <= 0;
      end
    end

end
endgenerate

endmodule
