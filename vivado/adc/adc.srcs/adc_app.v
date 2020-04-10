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
  output reg [7:0]        tx_control_data
);

  reg [7:0]               state;
  reg [7:0]               test_mode;

  reg                     send_state;
  reg                     send_test_mode;

  assign spi_read = 0;
  assign spi_write = 0;


generate
begin : adc_app

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        state <= 0;
        test_mode <= 7;
        send_state <= 0;
        send_test_mode <= 0;
      end
      else
      begin
        if (rx_control_msg)
        begin
          case (rx_control_index)
            0:
            begin
              state <= rx_control_data;
              send_state <= 1;
              send_test_mode <= 0;
            end

            1:
            begin
              test_mode <= rx_control_data;
              send_state <= 0;
              send_test_mode <= 1;
            end

            default:
            begin
              send_state <= 0;
              send_test_mode <= 0;
            end
          endcase
        end
        else
        begin
          send_state <= 0;
          send_test_mode <= 0;
        end
      end
     end

    always @ ( posedge clk ) 
    begin
      if (send_state)
      begin
        tx_control_index <= 0;
        tx_control_data <= state;
        tx_control_msg <= 1;
      end
      else
      begin
        if (send_test_mode)
        begin
          tx_control_index <= 1;
          tx_control_data <= test_mode;
          tx_control_msg <= 1;
        end
        else
          tx_control_msg <= 0;
      end
    end


end
endgenerate

endmodule
