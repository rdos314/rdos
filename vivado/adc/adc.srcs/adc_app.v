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

  output reg [16:0]       phys_index,
  input wire [63:0]       phys,
  input wire              phys_valid,

  input wire              start,
  input wire              stop,

  output reg              started,
  output reg              probing,
  output reg              running
);

  reg                     pend_start;

  assign spi_read = 0;
  assign spi_write = 0;


ila_1 ila_1_inst (
	.clk(clk),             // input wire clk
	.probe0(start),        // input wire [0:0]  probe0  
	.probe1(stop),         // input wire [0:0]  probe0  
	.probe2(started),      // input wire [0:0]  probe0  
	.probe3(probing),      // input wire [0:0]  probe0  
	.probe4(running)       // input wire [0:0]  probe0  
);


generate
begin : adc_app

    always @(posedge clk) 
    begin
      if (reset)
      begin
        started <= 0;
        running <= 0;
      end
      else
      begin
        if (start)
          started <= 1;
        else
        begin
          if (stop)
          begin
            started <= 0;
            probing <= 0;
            running <= 0;
          end
          else
          begin
            if (started)
            begin
              probing <= 1;
              if (probing)
                running <= 1;
            end
          end
        end
      end
    end

end
endgenerate

endmodule
