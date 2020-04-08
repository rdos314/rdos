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
// dac_app.v
// D/A module
//
////////////////////////////////////////////////////////////////////////////////

module dac_app (
  clk,
  reset,
  sample_clk,

  address,
  rd,
  rp,
  rp_address,
  rp_data,
  wr,
  wr_be,
  wr_data,
  ack
);

  input wire             clk;
  input wire             reset;
  input wire             sample_clk;

  input wire [16:0]      address;
  input wire             rd;
  output reg             rp;
  output reg [4:0]       rp_address;
  output reg [31:0]      rp_data;
  input wire             wr;
  input wire [3:0]       wr_be;
  input wire [31:0]      wr_data;
  output reg             ack;

// FF
  reg                    dac_wr;
  reg  [15:0]            dac_wr_adr;
  reg  [19:0]            dac_wr_data;
  reg  [15:0]            dac_rd_adr;

// local
  wire [19:0]            dac_rd_data;
  reg  [63:0]            curr_data;

bram_dac bram_dac_inst (
  .clka(clk),          // input wire clka
  .wea(dac_wr),        // input wire [0 : 0] wea
  .addra(dac_wr_adr),  // input wire [15 : 0] addra
  .dina(dac_wr_data),  // input wire [19 : 0] dina
  .clkb(clk),          // input wire clkb
  .addrb(dac_rd_adr),  // input wire [15 : 0] addrb
  .doutb(dac_rd_data)  // output wire [19 : 0] doutb
);

generate
begin : dac_app

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      ack <= 0;
      rp <= 0;
      dac_wr <= 0;
    end
    else
    begin
      if (wr)
      begin
        if (dac_rd_adr == address[16:1])
        begin
          curr_data[20:0] = 0;
          curr_data[40:21] = dac_rd_data;
          curr_data[63:41] = 0;

          if (address[0])
          begin
            if (wr_be[0])
              curr_data[39:32] = wr_data[7:0];

            if (wr_be[1])
              curr_data[47:40] = wr_data[15:8];
 
            if (wr_be[2])
              curr_data[55:48] = wr_data[23:16];

            if (wr_be[3])
              curr_data[63:56] = wr_data[31:24];
          end
          else
          begin
            if (wr_be[0])
              curr_data[7:0] = wr_data[7:0];

            if (wr_be[1])
              curr_data[15:8] = wr_data[15:8];
 
            if (wr_be[2])
              curr_data[23:16] = wr_data[23:16];

            if (wr_be[3])
              curr_data[31:24] = wr_data[31:24];
          end
        end
      end

      if (rd)
      begin
        if (dac_rd_adr == address[16:1])
        begin
          rp <= 1;

          if (address[0])
          begin
            rp_data[8:0] <= dac_rd_data[19:11];
            rp_data[31:9] <= 0;
          end
          else
          begin
            rp_data[20:0] <= 0;
            rp_data[31:21] <= dac_rd_data[10:0];
          end
        end
        else
        begin
          rp <= 0;
          dac_rd_adr <= address[16:1];
        end
      end
      else
        rp <= 0;

      if (wr)
      begin
        if (dac_rd_adr == address[16:1])
        begin
          dac_wr_data <= curr_data[40:21];
          dac_wr_adr = address[16:1];
          dac_wr <= 1;
          ack <= 1;
        end
        else
        begin
          dac_wr <= 0;
          ack <= 0;
          dac_rd_adr <= address[16:1];
        end
      end
      else
      begin
        ack <= 0;
        dac_wr <= 0;
      end
    end
  end
end
endgenerate

endmodule
