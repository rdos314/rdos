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
// ana_freq.v
// One frequency analyser 
//
////////////////////////////////////////////////////////////////////////////////

module ana_freq (
  input wire              clk,

  input wire              en,
  input wire              start,
  input wire [12:0]       count,
  output reg [10:0]       adr,

  input wire [15:0]       sin_0,
  input wire [15:0]       sin_1,
  input wire [15:0]       sin_2,
  input wire [15:0]       sin_3,

  input wire [15:0]       cos_0,
  input wire [15:0]       cos_1,
  input wire [15:0]       cos_2,
  input wire [15:0]       cos_3,

  input wire [13:0]       in_A0,
  input wire [13:0]       in_A1,
  input wire [13:0]       in_A2,
  input wire [13:0]       in_A3,

  input wire [13:0]       in_B0,
  input wire [13:0]       in_B1,
  input wire [13:0]       in_B2,
  input wire [13:0]       in_B3
);

  wire [31:0]            sum_sin_A;
  wire [31:0]            sum_cos_A;
  wire [31:0]            sum_sin_B;
  wire [31:0]            sum_cos_B;

  reg  [10:0]            last;
  reg  [3:0]             last_en;

  reg                    skip;
  reg                    pd1;
  reg                    pd2;
  reg                    pd3;
  reg                    pd4;
  reg                    pd5;
  reg                    pd6;
  reg                    pd7;

adc_slice sin_A (
  .clk(clk),            // input wire CLK
  .p5(pd5),             // input wire [0 : 0] p5
  .p6(pd6),             // input wire [0 : 0] p6
  .p7(pd7),             // input wire [0 : 0] p7
  .last(last_en),       // input wire [3 : 0] last
  .in_0(in_A0),         // input wire [13 : 0] in_0
  .in_1(in_A1),         // input wire [13 : 0] in_1
  .in_2(in_A2),         // input wire [13 : 0] in_2
  .in_3(in_A3),         // input wire [13 : 0] in_3
  .coeff_0(sin_0),      // input wire [15 : 0] coeff_0
  .coeff_1(sin_1),      // input wire [15 : 0] coeff_1
  .coeff_2(sin_2),      // input wire [15 : 0] coeff_2
  .coeff_3(sin_3),      // input wire [15 : 0] coeff_3
  .sum(sum_sin_A)       // output wire [31 : 0] sum
);

adc_slice cos_A (
  .clk(clk),            // input wire CLK
  .p5(pd5),             // input wire [0 : 0] p5
  .p6(pd6),             // input wire [0 : 0] p6
  .p7(pd7),             // input wire [0 : 0] p7
  .count(count),        // input wire [12 : 0] count
  .last(last_en),       // input wire [3 : 0] last
  .in_0(in_A0),         // input wire [13 : 0] in_0
  .in_1(in_A1),         // input wire [13 : 0] in_1
  .in_2(in_A2),         // input wire [13 : 0] in_2
  .in_3(in_A3),         // input wire [13 : 0] in_3
  .coeff_0(cos_0),      // input wire [15 : 0] coeff_0
  .coeff_1(cos_1),      // input wire [15 : 0] coeff_1
  .coeff_2(cos_2),      // input wire [15 : 0] coeff_2
  .coeff_3(cos_3),      // input wire [15 : 0] coeff_3
  .sum(sum_cos_A)       // output wire [31 : 0] sum
);

adc_slice sin_B (
  .clk(clk),            // input wire CLK
  .p5(pd5),             // input wire [0 : 0] p5
  .p6(pd6),             // input wire [0 : 0] p6
  .p7(pd7),             // input wire [0 : 0] p7
  .count(count),        // input wire [12 : 0] count
  .last(last_en),       // input wire [3 : 0] last
  .in_0(in_B0),         // input wire [13 : 0] in_0
  .in_1(in_B1),         // input wire [13 : 0] in_1
  .in_2(in_B2),         // input wire [13 : 0] in_2
  .in_3(in_B3),         // input wire [13 : 0] in_3
  .coeff_0(sin_0),      // input wire [15 : 0] coeff_0
  .coeff_1(sin_1),      // input wire [15 : 0] coeff_1
  .coeff_2(sin_2),      // input wire [15 : 0] coeff_2
  .coeff_3(sin_3),      // input wire [15 : 0] coeff_3
  .sum(sum_sin_b)       // output wire [31 : 0] sum
);

adc_slice cos_B (
  .clk(clk),            // input wire CLK
  .p5(pd5),             // input wire [0 : 0] p5
  .p6(pd6),             // input wire [0 : 0] p6
  .p7(pd7),             // input wire [0 : 0] p7
  .count(count),        // input wire [12 : 0] count
  .last(last_en),       // input wire [3 : 0] last
  .in_0(in_B0),         // input wire [13 : 0] in_0
  .in_1(in_B1),         // input wire [13 : 0] in_1
  .in_2(in_B2),         // input wire [13 : 0] in_2
  .in_3(in_B3),         // input wire [13 : 0] in_3
  .coeff_0(cos_0),      // input wire [15 : 0] coeff_0
  .coeff_1(cos_1),      // input wire [15 : 0] coeff_1
  .coeff_2(cos_2),      // input wire [15 : 0] coeff_2
  .coeff_3(cos_3),      // input wire [15 : 0] coeff_3
  .sum(sum_cos_B)       // output wire [31 : 0] sum
);

ila_0 ila_0_inst (
  .clk(clk),              // input wire clk
  .probe0(en),            // input wire [0:0]  probe0
  .probe1(start),         // input wire [0:0]  probe1
  .probe2(skip),          // input wire [0:0]  probe2
  .probe3(adr),           // input wire [10:0]  probe3
  .probe4(count),         // input wire [12:0]  probe4
  .probe5(last_en),       // input wire [3:0]  probe5
  .probe6(sum_sin_A),     // input wire [31:0]  probe6 
  .probe7(sum_cos_A),     // input wire [31:0]  probe7
  .probe8(sum_sin_B),     // input wire [31:0]  probe8 
  .probe9(sum_cos_B),     // input wire [31:0]  probe9 
  .probe10(pd1),           // input wire [0:0]  probe10
  .probe11(pd2),          // input wire [0:0]  probe11
  .probe12(pd3),          // input wire [0:0]  probe12
  .probe13(pd4),          // input wire [0:0]  probe13
  .probe14(pd5),          // input wire [0:0]  probe14
  .probe15(pd6),          // input wire [0:0]  probe15
  .probe16(pd7)           // input wire [0:0]  probe16
);

generate
begin : ana_freq_gen

  always @ ( posedge clk ) 
  begin
    if (en)
    begin
      if (pdone)
         skip <= 0;
    end
    else
      skip <= 1;
  end

  always @ ( posedge clk ) 
  begin
    if (en)
    begin
      if (start)
      begin
        adr <= 0;
        pd1 <= 1;
      end
      else
      begin
        if (adr == last)
        begin
          adr <= 0;
          pd1 <= 1;
        end
        else
        begin
           adr <= adr + 1;
           pd1 <= 0;
         end
      end
    end
    else
    begin
      case (count[1:0])
        2'b00 : last_en <= 4'b1111;
        2'b01 : last_en <= 4'b0001;
        2'b10 : last_en <= 4'b0011;
        2'b11 : last_en <= 4'b0111;
      endcase

      if (count[1:0] == 2'b00)
        last <= count[12:2] - 1;
      else
        last <= count[12:2];

    end

    pd2 <= pd1;
    pd3 <= pd2;
    pd4 <= pd3;
    pd5 <= pd4;
    pd6 <= pd5;
    pd7 <= pd6;
  end
  
end

endgenerate

endmodule
