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
// pow.v
// Power calculator
//
////////////////////////////////////////////////////////////////////////////////

module power(
  input wire              clk,
  input wire              reset,

  input wire              start,

  input wire  [15:0]      in_sin,
  input wire  [15:0]      in_cos,

  output reg  [15:0]      res
);

  wire [31:0]             sin_sq;
  wire [31:0]             cos_sq;

  reg  [31:0]             pow_sq;
  reg                     sq_valid;
  reg  [7:0]              sq_cnt;
  wire                    sq_done;
  wire [23:0]             sq_data;

square square_sin (
  .CLK(clk),         // input wire CLK
  .A(in_sin),        // input wire [15 : 0] A
  .B(in_sin),        // input wire [15 : 0] B
  .P(sin_sq)         // output wire [31 : 0] P
);

square square_cos (
  .CLK(clk),         // input wire CLK
  .A(in_cos),        // input wire [15 : 0] A
  .B(in_cos),        // input wire [15 : 0] B
  .P(cos_sq)         // output wire [31 : 0] P
);

sqrt sqrt_inst (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(sq_valid),                // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(pow_sq),                   // input wire [31 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(sq_done),                      // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(sq_data)                        // output wire [23 : 0] m_axis_dout_tdata
);

ila_2 ila_2_inst (
  .clk(clk),              // input wire clk
  .probe0(start),         // input wire [0:0]  probe0
  .probe1(in_sin),        // input wire [15:0]  probe1
  .probe2(in_cos),        // input wire [15:0]  probe2
  .probe3(sin_sq),        // input wire [31:0]  probe3
  .probe4(cos_sq),        // input wire [31:0]  probe3
  .probe5(pow_sq),        // input wire [31:0]  probe3
  .probe6(sq_cnt),        // input wire [7:0]  probe3
  .probe7(sq_valid),      // input wire [0:0]  probe3
  .probe8(sq_done),       // input wire [0:0]  probe3
  .probe9(sq_data),       // input wire [23:0]  probe3
  .probe10(res)           // input wire [15:0]  probe3
);

generate
begin : ana_pow_gen


  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      res <= 0;
    end
    else
    begin
      if (sq_done)
        res <= sq_data[15:0];
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      sq_cnt <= 0;
      sq_valid <= 0;
    end
    else
    begin
      if (start)
      begin
        sq_cnt <= 1;
        sq_valid <= 0;
      end
      else
      begin
        if (sq_cnt)
        begin
          sq_cnt <= sq_cnt + 1;
          
          if (sq_cnt == 8)
            pow_sq <= sin_sq + cos_sq;
            sq_valid <= 1;
        end
        else
          sq_valid <= 0;
      end
    end
  end
  
end

endgenerate

endmodule
