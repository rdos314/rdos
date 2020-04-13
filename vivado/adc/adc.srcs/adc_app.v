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
  input                   reset,
  input                   clk,

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

  output reg              adc_clear,
  output reg              adc_next,
  input wire              adc_phys_valid,
  input wire [19:0]       adc_phys_page,

  input wire              adc_in,
  input wire [1023:0]     adc_in_data,

  output reg              adc_out,
  input wire              adc_out_busy,
  output reg [127:0]      adc_out_header,
  output wire [1023:0]    adc_out_data,

  output wire [2:0]       state
);

  reg [1:0]               req_state;
  reg [2:0]               curr_state;
  reg [7:0]               test_mode;

  reg                     req_start;
  reg                     req_stop;
  reg                     pend_start;

  reg                     busy;
  reg [1:0]               delay;
  reg                     next_valid;
  reg [19:0]              next_page;
  reg [13:0]              pkt_index;

  reg                     spi_test_done;
  reg [3:0]               pll_rst_cnt; 
  reg [3:0]               adc_rst_cnt;
  reg [6:0]               adc_user_ready_cnt;  

  wire                    fifo_reset;
  wire                    fifo_full;
  wire                    fifo_empty;
  reg                     fifo_rd;
  reg [1023:0]            fifo_data;

adc_fifo adc_fifo_inst (
  .clk(clk),             // input wire clk
  .srst(fifo_reset),     // input wire srst
  .din(adc_in_data),     // input wire [1023 : 0] din
  .wr_en(adc_in),        // input wire wr_en
  .rd_en(fifo_rd),       // input wire rd_en
  .dout(adc_out_data),   // output wire [1023 : 0] dout
  .full(fifo_full),      // output wire full
  .empty(fifo_empty)     // output wire empty
);

ila_1 ila_1_inst (
    .clk(clk),                        // input wire clk
    .probe0(req_start),               // input wire [0:0]  probe0  
    .probe1(req_stop),                // input wire [0:0]  probe0  
    .probe2(adc_started),             // input wire [0:0]  probe0  
    .probe3(adc_probing),             // input wire [0:0]  probe0  
    .probe4(adc_running),             // input wire [0:0]  probe0  
    .probe5(adc_pll_locked),          // input wire [3:0]  probe0  
    .probe6(adc_rst_done),            // input wire [3:0]  probe0  
    .probe7(adc_sync_ok),             // input wire [0:0]  probe0  
    .probe8(adc_sync_fail),           // input wire [0:0]  probe0  
    .probe9(busy),                    // input wire [0:0]  probe0  
    .probe10(next_valid),              // input wire [0:0]  probe0  
    .probe11(next_page),               // input wire [19:0]  probe0  
    .probe12(adc_in),                  // input wire [0:0]  probe0  
    .probe13(fifo_empty),              // input wire [0:0]  probe0  
    .probe14(fifo_full),               // input wire [0:0]  probe0  
    .probe15(fifo_rd),                 // input wire [0:0]  probe0  
    .probe16(delay),                   // input wire [1:0]  probe0  
    .probe17(adc_out),                 // input wire [0:0]  probe0  
    .probe18(adc_out_header[127:64]),  // input wire [63:0]  probe0  
    .probe19(adc_out_data[15:0]),      // input wire [15:0]  probe0  
    .probe20(adc_out_data[31:16]),     // input wire [15:0]  probe0  
    .probe21(adc_phys_valid),          // input wire [0:0]  probe0  
    .probe22(adc_phys_page)           // input wire [19:0]  probe0  
);

  assign fifo_reset = !adc_started;

  assign adc_rst = adc_rst_cnt[3];
  assign adc_user_ready = adc_user_ready_cnt[6];

  assign state[0] = adc_started;
  assign state[1] = adc_probing;
  assign state[2] = adc_running;

generate
begin : adc_app

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        req_start <= 0;
        req_stop <= 0;
        req_state <= 0;
        test_mode <= 0;
      end
      else
      begin
        if (rx_control_msg)
        begin
          case (rx_control_index)
            0:
            begin
              req_state <= rx_control_data[1:0];
              if (req_state[1] != rx_control_data[1])
              begin
                if (rx_control_data[1])
                begin
                  req_start <= 1;
                  req_stop <= 0;
                end
                else
                begin
                  req_start <= 0;
                  req_stop <= 1;
                end
              end
              else
              begin
                req_start <= 0;
                req_stop <= 0;
              end
            end

            1:
            begin
              req_start <= 0;
              req_stop <= 0;
              test_mode <= rx_control_data;
            end

            default:
            begin
              req_start <= 0;
              req_stop <= 0;
            end
          endcase
        end
        else
        begin
          req_start <= 0;
          req_stop <= 0;
        end
      end
     end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        spi_write <= 0;
        adc_started <= 0;
        adc_probing <= 0;
        adc_running <= 0;
        up_rstn <= 0;
        qpll_rst <= 0;
        pend_start <= 0;
        spi_test_done <= 0;
      end
      else
      begin
        if (req_start)
        begin
          up_rstn <= 0;
          qpll_rst <= 1;
          pll_rst_cnt <= 4'h8; 
          adc_rst_cnt <= 4'h8;    
          adc_user_ready_cnt <= 7'h00;  
          pend_start <= 1;
        end
        else
        begin
          qpll_rst <= 0;

          if (req_stop)
          begin
            adc_started <= 0;
            up_rstn <= 0;
          end
          else
          begin
            up_rstn <= 1;

            if (pend_start)
            begin
              if (adc_started)
              begin
                if (spi_done)
                begin
                  spi_test_done <= 1;
                  spi_write <= 0;
                end

                if (spi_test_done)
                begin
                  if (qpll_locked)
                    if (pll_rst_cnt[3] == 1'b1) 
                      pll_rst_cnt <= pll_rst_cnt + 1'b1;

                  if ((pll_rst_cnt[3] == 1'b1) || (adc_pll_locked != 4'b1111))
                    adc_rst_cnt <= 4'h8; 
                  else 
                    if (adc_rst_cnt[3] == 1'b1) 
                      adc_rst_cnt <= adc_rst_cnt + 1'b1;

                  if (adc_rst_cnt[3] == 1'b1) 
                    adc_user_ready_cnt <= 7'h00;   
                  else 
                  begin
                    if (adc_user_ready_cnt[6] == 1'b0) 
                      adc_user_ready_cnt <= adc_user_ready_cnt + 1'b1;
                    else
                    begin
                      if (adc_rst_done == 4'b1111)
                      begin
                        pend_start <= 0;
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
                  spi_out_data <= test_mode;
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

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        tx_control_msg <= 0;
        curr_state <= 0;
      end
      else
      begin
        curr_state <= state;
        if (curr_state != state)
        begin
          tx_control_index <= 0;
          tx_control_data <= state;
          tx_control_msg <= 1;
        end
        else
          tx_control_msg <= 0;
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
        next_valid <= 0;
      else
      begin
        if (adc_phys_valid)
        begin
          next_valid <= 1;
          next_page <= adc_phys_page;
        end
        else
        begin
          if (adc_clear || adc_next)
            next_valid <= 0;
        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        adc_clear <= 1;
        adc_next <= 0;
        pkt_index <= 0;
      end
      else
      begin
        if (adc_started)
        begin
          adc_clear <= 0;

          if (fifo_rd)
          begin
            pkt_index <= pkt_index + 1;
            if (next_page)
            begin
              if (pkt_index == 14'b11111111111111)
                adc_next <= 1;
              else
                adc_next <= 0;
            end
            else
              adc_next <= 0;
          end
        end
        else
        begin
          if (req_start)
            adc_clear <= 1;
        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        delay <= 0;
        adc_out <= 0;
        busy <= 0;
        fifo_rd <= 0;
      end
      else
      begin
        if (busy)
        begin
          if (delay)
            delay <= delay - 1;
          else
          begin
            fifo_rd <= adc_out;
            busy <= adc_out_busy;
            adc_out <= 0;
          end
        end
        else
        begin
          fifo_rd <= 0;

          if (fifo_empty || next_page == 0)
            adc_out <= 0;
          else
          begin
            adc_out_header[63:48] <= 0;                      // Requester ID
            adc_out_header[47:40] <= 0;                      // tag
            adc_out_header[39:36] <= 4'b1111;                // last be
            adc_out_header[35:32] <= 4'b1111;                // 1st be

            if (next_page[19:11] == 0)
            begin
              adc_out_header[31:24] <= 8'b010_00000;         // Type + Fmt (32-bit)
              adc_out_header[70:64] <= 0;
              adc_out_header[84:71] <= pkt_index;
              adc_out_header[95:85] <= next_page[10:0];
            end
            else
            begin
              adc_out_header[31:24] <= 8'b011_00000;         // Type + Fmt (64-bit)
              adc_out_header[72:64] <= next_page[19:11];
              adc_out_header[102:96] <= 0;
              adc_out_header[116:103] <= pkt_index;
              adc_out_header[127:117] <= next_page[10:0];
            end

            adc_out_header[23] <= 1'b0;                      // R
            adc_out_header[22:20] <= 3'b000;                 // TC
            adc_out_header[19:16] <= 4'b0000;                // TH, AttrH, R
            adc_out_header[15:12] <= 4'b0000;                // TD, EP, Attr
            adc_out_header[11:10] <= 2'b0;                   // AT
            adc_out_header[9:8] <= 2'b0;                     // len high
            adc_out_header[7:0] <= 8'h20;                    // 128 byte size
            adc_out <= 1;
            delay <= 2;
            busy <= 1;
          end
        end
      end
    end

end
endgenerate

endmodule
