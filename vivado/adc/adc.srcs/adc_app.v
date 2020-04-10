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

  output wire             spi_read,
  output wire             spi_write,
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

  output reg              adc_rst,
  input wire [3:0]        adc_rst_done,

  output reg [2:0]        state
);

  reg [1:0]               req_state;
  reg [2:0]               curr_state;
  reg [7:0]               test_mode;

  reg                     req_start;
  reg                     req_stop;
  reg                     pend_start;

  reg [3:0]               pll_rst_cnt; 
  reg [3:0]               adc_rst_cnt;
  reg [6:0]               user_ready_cnt;  

  assign spi_read = 0;
  assign spi_write = 0;


ila_1 ila_1_inst (
	.clk(clk),                       // input wire clk
	.probe0(rx_control_msg),         // input wire [0:0]  probe0  
	.probe1(rx_control_index),       // input wire [7:0]  probe0  
	.probe2(rx_control_data),        // input wire [7:0]  probe0  
	.probe3(req_state),              // input wire [1:0]  probe0  
	.probe4(state),                  // input wire [2:0]  probe0  
	.probe5(curr_state),             // input wire [2:0]  probe0  
	.probe6(test_mode),              // input wire [7:0]  probe0  
	.probe7(req_start),              // input wire [0:0]  probe0  
	.probe8(req_stop),               // input wire [0:0]  probe0  
	.probe9(pend_start),             // input wire [0:0]  probe0  
	.probe10(qpll_rst),              // input wire [0:0]  probe0  
	.probe11(qpll_locked),           // input wire [0:0]  probe0  
	.probe12(tx_control_msg),        // input wire [0:0]  probe0  
	.probe13(tx_control_index),      // input wire [7:0]  probe0  
	.probe14(tx_control_data)        // input wire [7:0]  probe0  
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
        test_mode <= 7;
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
        state <= 0;
        up_rstn <= 0;
        qpll_rst <= 0;
        pend_start <= 0;
      end
      else
      begin
        if (req_start)
        begin
          up_rstn <= 0;
          qpll_rst <= 1;
          pll_rst_cnt <= 4'h8; 
          adc_rst_cnt <= 4'h8;    
          user_ready_cnt <= 7'h00;  
          pend_start <= 1;
        end
        else
        begin
          qpll_rst <= 0;

          if (req_stop)
          begin
            state <= 0;
            up_rstn <= 0;
          end
          else
          begin
            if (pend_start)
            begin
              state[0] <= 1;
              pend_start <= 0;
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
