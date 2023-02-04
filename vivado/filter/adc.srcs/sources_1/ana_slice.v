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
  input wire              reset,

  input wire              start,
  input wire              stop,
  input wire              next,

  input wire [63:0]       coeff,
  input wire [63:0]       in,

  output reg              report,
  output reg [43:0]       sum
);

  reg                    s1;
  reg                    s2;
  reg                    s3;
  reg                    s4;
  reg                    s5;
  
  reg                    run;

  reg  [43:0]            sum_0;
  reg  [43:0]            sum_1;
  reg  [43:0]            sum_2;
  reg  [43:0]            sum_3;

  reg  [43:0]            sum_01;
  reg  [43:0]            sum_23;

  wire [43:0]            p_0;  
  wire [43:0]            p_1;  
  wire [43:0]            p_2;  
  wire [43:0]            p_3;  

  assign p_0[32] = p_0[31];
  assign p_0[33] = p_0[31];
  assign p_0[34] = p_0[31];
  assign p_0[35] = p_0[31];
  assign p_0[36] = p_0[31];
  assign p_0[37] = p_0[31];
  assign p_0[38] = p_0[31];
  assign p_0[39] = p_0[31];
  assign p_0[40] = p_0[31];
  assign p_0[41] = p_0[31];
  assign p_0[42] = p_0[31];
  assign p_0[43] = p_0[31];

  assign p_1[32] = p_1[31];
  assign p_1[33] = p_1[31];
  assign p_1[34] = p_1[31];
  assign p_1[35] = p_1[31];
  assign p_1[36] = p_1[31];
  assign p_1[37] = p_1[31];
  assign p_1[38] = p_1[31];
  assign p_1[39] = p_1[31];
  assign p_1[40] = p_1[31];
  assign p_1[41] = p_1[31];
  assign p_1[42] = p_1[31];
  assign p_1[43] = p_1[31];

  assign p_2[32] = p_2[31];
  assign p_2[33] = p_2[31];
  assign p_2[34] = p_2[31];
  assign p_2[35] = p_2[31];
  assign p_2[36] = p_2[31];
  assign p_2[37] = p_2[31];
  assign p_2[38] = p_2[31];
  assign p_2[39] = p_2[31];
  assign p_2[40] = p_2[31];
  assign p_2[41] = p_2[31];
  assign p_2[42] = p_2[31];
  assign p_2[43] = p_2[31];

  assign p_3[32] = p_3[31];
  assign p_3[33] = p_3[31];
  assign p_3[34] = p_3[31];
  assign p_3[35] = p_3[31];
  assign p_3[36] = p_3[31];
  assign p_3[37] = p_3[31];
  assign p_3[38] = p_3[31];
  assign p_3[39] = p_3[31];
  assign p_3[40] = p_3[31];
  assign p_3[41] = p_3[31];
  assign p_3[42] = p_3[31];
  assign p_3[43] = p_3[31];

  wire [15:0]            coeff_0;
  wire [15:0]            coeff_1;
  wire [15:0]            coeff_2;
  wire [15:0]            coeff_3;

  wire [15:0]            in_0;
  wire [15:0]            in_1;
  wire [15:0]            in_2;
  wire [15:0]            in_3;

  assign coeff_0 = coeff[15:0];
  assign coeff_1 = coeff[31:16];
  assign coeff_2 = coeff[47:32];
  assign coeff_3 = coeff[63:48];

  assign in_0 = in[15:0];
  assign in_1 = in[31:16];
  assign in_2 = in[47:32];
  assign in_3 = in[63:48];

mult_16_16 m_0 (
  .CLK(clk),            // input wire CLK
  .A(in_0),             // input wire [15 : 0] A
  .B(coeff_0),          // input wire [15 : 0] B
  .P(p_0[31:0])         // output wire [31 : 0] P
);

mult_16_16 m_1 (
  .CLK(clk),            // input wire CLK
  .A(in_1),             // input wire [15 : 0] A
  .B(coeff_1),          // input wire [15 : 0] B
  .P(p_1[31:0])         // output wire [31 : 0] P
);

mult_16_16 m_2 (
  .CLK(clk),            // input wire CLK
  .A(in_2),             // input wire [15 : 0] A
  .B(coeff_2),          // input wire [15 : 0] B
  .P(p_2[31:0])         // output wire [31 : 0] P
);

mult_16_16 m_3 (
  .CLK(clk),            // input wire CLK
  .A(in_3),             // input wire [15 : 0] A
  .B(coeff_3),          // input wire [15 : 0] B
  .P(p_3[31:0])         // output wire [31 : 0] P
);

ila_2 ila_2_inst (
  .clk(clk),            // input wire clk
  .probe0(start),       // input wire [0:0]  probe0
  .probe1(stop),        // input wire [0:0]  probe0
  .probe2(in_0),        // input wire [15:0]  probe7
  .probe3(in_1),        // input wire [15:0]  probe2
  .probe4(coeff_0),     // input wire [15:0]  probe5
  .probe5(coeff_1),     // input wire [15:0]  probe6
  .probe6(p_0),         // input wire [31:0]  probe6
  .probe7(p_1),         // input wire [31:0]  probe6
  .probe8(sum_0),       // input wire [43:0]  probe6
  .probe9(sum_1)        // input wire [43:0]  probe6
);

generate
begin : ana_slice_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      s2 <= 0;
      s3 <= 0;
      s4 <= 0;
      s5 <= 0;
    end
    else
    begin
      s2 <= s1;
      s3 <= s2;
      s4 <= s3;
      s5 <= s4;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      run <= 0;
      s1 <= 0;
    end
    else
    begin
      if (start)
      begin
        run <= 1;
        s1 <= 1;
      end
      else
      begin
        if (stop)
        begin
          run <= 0;
          s1 <= 0;
        end
        else
        begin
          if (run)
          begin
            if (next)
              s1 <= 1;
            else
              s1 <= 0;
          end
          else
            s1 <= 0;
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (s4)
      sum_0 <= p_0;
    else
      sum_0 <= sum_0 + p_0;      
  end

  always @ ( posedge clk ) 
  begin
    if (s4)
      sum_1 <= p_1;
    else
      sum_1 <= sum_1 + p_1;      
  end

  always @ ( posedge clk ) 
  begin
    if (s4)
      sum_2 <= p_2;
    else
      sum_2 <= sum_2 + p_2;      
  end

  always @ ( posedge clk ) 
  begin
    if (s4)
      sum_3 <= p_3;
    else
      sum_3 <= sum_3 + p_3;      
  end

  always @ ( posedge clk ) 
  begin
    if (s4)
    begin
      sum_01 <= sum_0 + sum_1;
      sum_23 <= sum_2 + sum_3;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (s5)
    begin
      report <= 1;
      sum <= sum_01 + sum_23;       
    end
    else
      report <= 0;
  end

end

endgenerate

endmodule
