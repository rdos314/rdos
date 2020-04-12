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
  input wire              adc_wr,

  output reg              adc_started,
  output reg              adc_probing,
  output reg              adc_running,

  output wire [2:0]       state
);

  reg [1:0]               req_state;
  reg [2:0]               curr_state;
  reg [7:0]               test_mode;

  reg                     req_start;
  reg                     req_stop;
  reg                     pend_start;

  reg                     spi_test_done;
  reg [3:0]               pll_rst_cnt; 
  reg [3:0]               adc_rst_cnt;
  reg [6:0]               adc_user_ready_cnt;  

  assign adc_rst = adc_rst_cnt[3];
  assign adc_user_ready = adc_user_ready_cnt[6];

  assign state[0] = adc_started;
  assign state[1] = adc_probing;
  assign state[2] = adc_running;


ila_0 ila_0_inst (
    .clk(clk),                       // input wire clk
    .probe0(adc_started),            // input wire [0:0]  probe0  
    .probe1(adc_probing),            // input wire [0:0]  probe0  
    .probe2(adc_running),            // input wire [0:0]  probe0  
    .probe3(adc_sync_ok),            // input wire [0:0]  probe0  
    .probe4(adc_sync_fail),          // input wire [0:0]  probe0  
    .probe5(adc_wr)                  // input wire [0:0]  probe0  
);


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
              if (adc_wr)
                adc_probing <= 0;
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

end
endgenerate

endmodule
