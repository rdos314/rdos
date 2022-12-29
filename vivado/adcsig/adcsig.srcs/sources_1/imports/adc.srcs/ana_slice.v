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
// adc_ana.v
// ADC analyser 
//
////////////////////////////////////////////////////////////////////////////////

module adc_slice (
  input wire              clk,

  input wire [15:0]       coeff_0,
  input wire [15:0]       coeff_1,
  input wire [15:0]       coeff_2,
  input wire [15:0]       coeff_3,

  input wire [13:0]       in_0,
  input wire [13:0]       in_1,
  input wire [13:0]       in_2,
  input wire [13:0]       in_3,

  output reg [42:0]       sum,

  input wire              done
);

  reg  [42:0]            sum_0;
  reg  [42:0]            sum_1;
  reg  [42:0]            sum_2;
  reg  [42:0]            sum_3;

  wire [42:0]            p_0;  
  wire [42:0]            p_1;  
  wire [42:0]            p_2;  
  wire [42:0]            p_3;  


multiply m_0 (
  .CLK(clk),            // input wire CLK
  .A(in_0),             // input wire [13 : 0] A
  .B(coeff_0),          // input wire [15 : 0] B
  .P(p_0[29:0])         // output wire [29 : 0] P
);

multiply m_1 (
  .CLK(clk),            // input wire CLK
  .A(in_1),             // input wire [13 : 0] A
  .B(coeff_1),          // input wire [15 : 0] B
  .P(p_1[29:0])         // output wire [29 : 0] P
);

multiply m_2 (
  .CLK(clk),            // input wire CLK
  .A(in_2),             // input wire [13 : 0] A
  .B(coeff_2),          // input wire [15 : 0] B
  .P(p_2[29:0])         // output wire [29 : 0] P
);

multiply m_3 (
  .CLK(clk),            // input wire CLK
  .A(in_3),             // input wire [13 : 0] A
  .B(coeff_3),          // input wire [15 : 0] B
  .P(p_3[29:0])         // output wire [29 : 0] P
);

  assign p_0[30] = p_0[29];
  assign p_0[31] = p_0[29];
  assign p_0[32] = p_0[29];
  assign p_0[33] = p_0[29];
  assign p_0[34] = p_0[29];
  assign p_0[35] = p_0[29];
  assign p_0[36] = p_0[29];
  assign p_0[37] = p_0[29];
  assign p_0[38] = p_0[29];
  assign p_0[39] = p_0[29];
  assign p_0[40] = p_0[29];
  assign p_0[41] = p_0[29];
  assign p_0[42] = p_0[29];

  assign p_1[30] = p_1[29];
  assign p_1[31] = p_1[29];
  assign p_1[32] = p_1[29];
  assign p_1[33] = p_1[29];
  assign p_1[34] = p_1[29];
  assign p_1[35] = p_1[29];
  assign p_1[36] = p_1[29];
  assign p_1[37] = p_1[29];
  assign p_1[38] = p_1[29];
  assign p_1[39] = p_1[29];
  assign p_1[40] = p_1[29];
  assign p_1[41] = p_1[29];
  assign p_1[42] = p_1[29];

  assign p_2[30] = p_2[29];
  assign p_2[31] = p_2[29];
  assign p_2[32] = p_2[29];
  assign p_2[33] = p_2[29];
  assign p_2[34] = p_2[29];
  assign p_2[35] = p_2[29];
  assign p_2[36] = p_2[29];
  assign p_2[37] = p_2[29];
  assign p_2[38] = p_2[29];
  assign p_2[39] = p_2[29];
  assign p_2[40] = p_2[29];
  assign p_2[41] = p_2[29];
  assign p_2[42] = p_2[29];

  assign p_3[30] = p_3[29];
  assign p_3[31] = p_3[29];
  assign p_3[32] = p_3[29];
  assign p_3[33] = p_3[29];
  assign p_3[34] = p_3[29];
  assign p_3[35] = p_3[29];
  assign p_3[36] = p_3[29];
  assign p_3[37] = p_3[29];
  assign p_3[38] = p_3[29];
  assign p_3[39] = p_3[29];
  assign p_3[40] = p_3[29];
  assign p_3[41] = p_3[29];
  assign p_3[42] = p_3[29];

generate
begin : ana_slice_gen

  always @ ( posedge clk ) 
  begin
    if (done)
      sum <= sum_0 + sum_1 + sum_2 + sum_3;
  end

  always @ ( posedge clk ) 
  begin
    if (done)
      sum_0 <= p_0;
    else
      sum_0 <= sum_0 + p_0;      
  end

  always @ ( posedge clk ) 
  begin
    if (done)
      sum_1 <= p_1;
    else
      sum_1 <= sum_1 + p_1;      
  end

  always @ ( posedge clk ) 
  begin
    if (done)
      sum_2 <= p_2;
    else
      sum_2 <= sum_2 + p_2;      
  end

  always @ ( posedge clk ) 
  begin
    if (done)
      sum_3 <= p_3;
    else
      sum_3 <= sum_3 + p_3;      
  end

end

endgenerate

endmodule
