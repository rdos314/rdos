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
// adc_trig.v
// ADC trigger
//
////////////////////////////////////////////////////////////////////////////////

module adc_trig (
  input                   rx_clk,
  input                   rx_adc_wr,
  input [127:0]           rx_adc_data,
  input [17:0]            phase_incr
);

  reg [17:0]              phase_0;
  reg [17:0]              phase_1;
  reg [17:0]              phase_2;
  reg [17:0]              phase_3;

  wire [31:0]             sin_cos_0;
  wire [31:0]             sin_cos_1;
  wire [31:0]             sin_cos_2;
  wire [31:0]             sin_cos_3;

  wire [14:0]             sin_0;
  wire [14:0]             cos_0;
  wire [14:0]             sin_1;
  wire [14:0]             cos_1;
  wire [14:0]             sin_2;
  wire [14:0]             cos_2;
  wire [14:0]             sin_3;
  wire [14:0]             cos_3;

  wire [28:0]             p_sin_A0;
  wire [28:0]             p_cos_A0;
  wire [28:0]             p_sin_B0;
  wire [28:0]             p_cos_B0;

  wire [28:0]             p_sin_A1;
  wire [28:0]             p_cos_A1;
  wire [28:0]             p_sin_B1;
  wire [28:0]             p_cos_B1;

  wire [28:0]             p_sin_A2;
  wire [28:0]             p_cos_A2;
  wire [28:0]             p_sin_B2;
  wire [28:0]             p_cos_B2;

  wire [28:0]             p_sin_A3;
  wire [28:0]             p_cos_A3;
  wire [28:0]             p_sin_B3;
  wire [28:0]             p_cos_B3;

  reg  [28:0]             p_sin_A01;
  reg  [28:0]             p_sin_A23;
  reg  [28:0]             p_sin;

  reg  [28:0]             p_cos_A01;
  reg  [28:0]             p_cos_A23;
  reg  [28:0]             p_cos;

sincos_0 sin_cos_inst_0 (
  .aclk(rx_clk),                                            // input wire aclk
  .s_axis_phase_tvalid(1),                                  // input wire s_axis_phase_tvalid
  .s_axis_phase_tdata({phase_0[17], phase_0[17], phase_0}), // input wire [23 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(),                                    // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(sin_cos_0)                             // output wire [31 : 0] m_axis_dout_tdata
);

sincos_0 sin_cos_inst_1 (
  .aclk(rx_clk),                                            // input wire aclk
  .s_axis_phase_tvalid(1),                                  // input wire s_axis_phase_tvalid
  .s_axis_phase_tdata({phase_1[17], phase_1[17], phase_1}), // input wire [23 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(),                                    // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(sin_cos_1)                             // output wire [31 : 0] m_axis_dout_tdata
);

sincos_0 sin_cos_inst_2 (
  .aclk(rx_clk),                                            // input wire aclk
  .s_axis_phase_tvalid(1),                                  // input wire s_axis_phase_tvalid
  .s_axis_phase_tdata({phase_2[17], phase_2[17], phase_2}), // input wire [23 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(),                                    // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(sin_cos_2)                             // output wire [31 : 0] m_axis_dout_tdata
);

sincos_0 sin_cos_inst_3 (
  .aclk(rx_clk),                                            // input wire aclk
  .s_axis_phase_tvalid(1),                                  // input wire s_axis_phase_tvalid
  .s_axis_phase_tdata({phase_3[17], phase_3[17], phase_3}), // input wire [23 : 0] s_axis_phase_tdata
  .m_axis_dout_tvalid(),                                    // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(sin_cos_3)                             // output wire [31 : 0] m_axis_dout_tdata
);

multiply_0 mul_sin_A0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_0),               // input wire [14 : 0] A
  .B(rx_adc_data[13:0]),   // input wire [13 : 0] B
  .P(p_sin_A0)             // output wire [28 : 0] P
);

multiply_0 mul_cos_A0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_0),               // input wire [14 : 0] A
  .B(rx_adc_data[13:0]),   // input wire [13 : 0] B
  .P(p_cos_A0)             // output wire [28 : 0] P
);

multiply_0 mul_sin_B0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_0),               // input wire [14 : 0] A
  .B(rx_adc_data[29:16]),  // input wire [13 : 0] B
  .P(p_sin_B0)             // output wire [28 : 0] P
);

multiply_0 mul_cos_B0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_0),               // input wire [14 : 0] A
  .B(rx_adc_data[29:16]),  // input wire [13 : 0] B
  .P(p_cos_B0)             // output wire [28 : 0] P
);

multiply_0 mul_sin_A1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_1),               // input wire [14 : 0] A
  .B(rx_adc_data[45:32]),  // input wire [13 : 0] B
  .P(p_sin_A1)             // output wire [28 : 0] P
);

multiply_0 mul_cos_A1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_1),               // input wire [14 : 0] A
  .B(rx_adc_data[45:32]),   // input wire [13 : 0] B
  .P(p_cos_A1)             // output wire [28 : 0] P
);

multiply_0 mul_sin_B1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_1),               // input wire [14 : 0] A
  .B(rx_adc_data[61:48]),  // input wire [13 : 0] B
  .P(p_sin_B1)             // output wire [28 : 0] P
);

multiply_0 mul_cos_B1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_1),               // input wire [14 : 0] A
  .B(rx_adc_data[61:48]),  // input wire [13 : 0] B
  .P(p_cos_B1)             // output wire [28 : 0] P
);

multiply_0 mul_sin_A2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_2),               // input wire [14 : 0] A
  .B(rx_adc_data[76:64]),  // input wire [13 : 0] B
  .P(p_sin_A2)             // output wire [28 : 0] P
);

multiply_0 mul_cos_A2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_2),               // input wire [14 : 0] A
  .B(rx_adc_data[76:64]),   // input wire [13 : 0] B
  .P(p_cos_A2)             // output wire [28 : 0] P
);

multiply_0 mul_sin_B2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_2),               // input wire [14 : 0] A
  .B(rx_adc_data[93:80]),  // input wire [13 : 0] B
  .P(p_sin_B2)             // output wire [28 : 0] P
);

multiply_0 mul_cos_B2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_2),               // input wire [14 : 0] A
  .B(rx_adc_data[93:80]),  // input wire [13 : 0] B
  .P(p_cos_B2)             // output wire [28 : 0] P
);

multiply_0 mul_sin_A3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_3),               // input wire [14 : 0] A
  .B(rx_adc_data[109:96]), // input wire [13 : 0] B
  .P(p_sin_A3)             // output wire [28 : 0] P
);

multiply_0 mul_cos_A3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_3),               // input wire [14 : 0] A
  .B(rx_adc_data[109:96]), // input wire [13 : 0] B
  .P(p_cos_A3)             // output wire [28 : 0] P
);

multiply_0 mul_sin_B3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_3),               // input wire [14 : 0] A
  .B(rx_adc_data[125:112]), // input wire [13 : 0] B
  .P(p_sin_B3)             // output wire [28 : 0] P
);

multiply_0 mul_cos_B3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_3),               // input wire [14 : 0] A
  .B(rx_adc_data[125:112]), // input wire [13 : 0] B
  .P(p_cos_B3)             // output wire [28 : 0] P
);

ila_1 ila_1_inst (
    .clk(rx_clk),                   // input wire clk
    .probe0(phase_0),               // input wire [17:0]  probe0  
    .probe1(phase_1),               // input wire [17:0]  probe0  
    .probe2(phase_2),               // input wire [17:0]  probe0  
    .probe3(phase_3),               // input wire [17:0]  probe0  
    .probe4(p_sin_A0),              // input wire [28:0]  probe0  
    .probe5(p_sin_B0),              // input wire [28:0]  probe0  
    .probe6(p_cos_A0),              // input wire [28:0]  probe0  
    .probe7(p_cos_B0),              // input wire [28:0]  probe0  
    .probe8(p_sin_A1),              // input wire [28:0]  probe0  
    .probe9(p_sin_B1),              // input wire [28:0]  probe0  
    .probe10(p_cos_A1),             // input wire [28:0]  probe0  
    .probe11(p_cos_B1),             // input wire [28:0]  probe0  
    .probe12(p_sin_A2),             // input wire [28:0]  probe0  
    .probe13(p_sin_B2),             // input wire [28:0]  probe0  
    .probe14(p_cos_A2),             // input wire [28:0]  probe0  
    .probe15(p_cos_B2),             // input wire [28:0]  probe0  
    .probe16(p_sin_A3),             // input wire [28:0]  probe0  
    .probe17(p_sin_B3),             // input wire [28:0]  probe0  
    .probe18(p_cos_A3),             // input wire [28:0]  probe0  
    .probe19(p_cos_B3),             // input wire [28:0]  probe0  
    .probe20(p_sin_A01),            // input wire [28:0]  probe0  
    .probe21(p_sin_B01),            // input wire [28:0]  probe0  
    .probe22(p_cos_A01),            // input wire [28:0]  probe0  
    .probe23(p_cos_B01),            // input wire [28:0]  probe0  
    .probe24(p_sin_A23),            // input wire [28:0]  probe0  
    .probe25(p_sin_B23),            // input wire [28:0]  probe0  
    .probe26(p_cos_A23),            // input wire [28:0]  probe0  
    .probe27(p_cos_B23),            // input wire [28:0]  probe0  
    .probe28(p_sin),                // input wire [28:0]  probe0  
    .probe29(p_cos)                // input wire [28:0]  probe0  
 );

  assign sin_0 = sin_cos_0[30:16];
  assign cos_0 = sin_cos_0[14:0];
  assign sin_1 = sin_cos_1[30:16];
  assign cos_1 = sin_cos_1[14:0];
  assign sin_2 = sin_cos_2[30:16];
  assign cos_2 = sin_cos_2[14:0];
  assign sin_3 = sin_cos_3[30:16];
  assign cos_3 = sin_cos_3[14:0];


generate
begin : adc_trig

    always @ ( posedge rx_clk ) 
    begin
      if (rx_adc_wr)
      begin
        phase_0[17:2] <= phase_0[17:2] + phase_incr[15:0];
        phase_1[17:2] <= phase_1[17:2] + phase_incr[15:0];
        phase_2[17:2] <= phase_2[17:2] + phase_incr[15:0];
        phase_3[17:2] <= phase_3[17:2] + phase_incr[15:0];
      end
      else
      begin
        phase_0 <= 0;
        phase_1 <= phase_incr;
        phase_2 <= phase_incr[17:1];
        phase_3 <= phase_incr[17:1] + phase_incr;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_adc_wr) 
      begin
        p_sin_A01 <= p_sin_A0 + p_sin_A1;
        p_sin_A23 <= p_sin_A2 + p_sin_A3;
        p_cos_A01 <= p_cos_A0 + p_cos_A1;
        p_cos_A23 <= p_cos_A2 + p_cos_A3;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_adc_wr) 
      begin
        p_sin <= p_sin_A01 + p_sin_A23;
        p_cos <= p_cos_A01 + p_cos_A23;
      end
    end


end
endgenerate

endmodule
