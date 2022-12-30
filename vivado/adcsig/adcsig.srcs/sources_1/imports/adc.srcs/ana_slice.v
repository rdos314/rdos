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
// ana_slice.v
// Multiplier slice 
//
////////////////////////////////////////////////////////////////////////////////

module adc_slice (
  input wire              clk,

  input wire              p7,
  input wire              p8,
  input wire [12:0]       count,

  input wire [63:0]       coeff,
  input wire [55:0]       in,

  output reg [15:0]       res
);

  reg  [42:0]            sum_0;
  reg  [42:0]            sum_1;
  reg  [42:0]            sum_2;
  reg  [42:0]            sum_3;

  reg  [42:0]            sum_01;
  reg  [42:0]            sum_23;

  reg  [42:0]            sum;

  wire [42:0]            p_0;  
  wire [42:0]            p_1;  
  wire [42:0]            p_2;  
  wire [42:0]            p_3;  

  wire [15:0]            coeff_0;
  wire [15:0]            coeff_1;
  wire [15:0]            coeff_2;
  wire [15:0]            coeff_3;

  wire [13:0]            in_0;
  wire [13:0]            in_1;
  wire [13:0]            in_2;
  wire [13:0]            in_3;

  reg                    start;
  reg                    running;
  reg                    sign;
  reg  [29:0]            divend;
  reg  [29:0]            curr;
  reg  [16:0]            mask;
  reg  [16:0]            quot;


  assign coeff_0 = coeff[15:0];
  assign coeff_1 = coeff[31:16];
  assign coeff_2 = coeff[47:32];
  assign coeff_3 = coeff[63:48];

  assign in_0 = in[13:0];
  assign in_1 = in[27:14];
  assign in_2 = in[41:28];
  assign in_3 = in[55:42];


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


ila_2 ila_2_inst (
  .clk(clk),            // input wire clk
  .probe0(start),       // input wire [0:0]  probe0
  .probe1(running),     // input wire [0:0]  probe1
  .probe2(sign),        // input wire [0:0]  probe2
  .probe3(divend),      // input wire [29:0]  probe3
  .probe4(curr),        // input wire [29:0]  probe4
  .probe5(mask),        // input wire [16:0]  probe5
  .probe6(quot),        // input wire [16:0]  probe6
  .probe7(sum)          // input wire [42:0]  probe7
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
    if (start)
    begin
      mask[16] <= 1;
      mask[15:0] <= 0;
      curr[29:17] <= count;
      curr[16:0] <= 0;
      quot[16:0] <= 0;

      if (sum[42])
      begin
        sign <= 1;
        divend <= !sum[41:12];
      end
      else
      begin
        sign <= 0;
        divend <= sum[41:12];
      end

      running <= 1;
    end
    else
    begin
      if (running)
      begin
        if (mask == 0)
        begin
          res[15] <= sign;

          if (sign)
            res[14:0] <= !quot[16:2];
          else
            res[14:0] <= quot[16:2];

          running <= 0;
        end
        else
        begin
           if (divend >= curr)
           begin
            divend <= divend - curr;
            quot <= quot | mask;
          end

          mask <= mask >> 1;
          curr <= curr >> 1;
        end
      end
    end
  end


  always @ ( posedge clk ) 
  begin
    if (p7)
    begin
      sum_01 <= sum_0 + sum_1;
      sum_23 <= sum_2 + sum_3;
    end

    if (p8)
    begin
      sum <= sum_01 + sum_23;
      start <= 1;
    end
    else
      start <= 0;
  end

  always @ ( posedge clk ) 
  begin
    if (p7)
      sum_0 <= p_0;
    else
      sum_0 <= sum_0 + p_0;      
  end

  always @ ( posedge clk ) 
  begin
    if (p7)
      sum_1 <= p_1;
    else
      sum_1 <= sum_1 + p_1;      
  end

  always @ ( posedge clk ) 
  begin
    if (p7)
      sum_2 <= p_2;
    else
      sum_2 <= sum_2 + p_2;      
  end

  always @ ( posedge clk ) 
  begin
    if (p7)
      sum_3 <= p_3;
    else
      sum_3 <= sum_3 + p_3;      
  end

end

endgenerate

endmodule
