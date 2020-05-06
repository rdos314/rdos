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
  input [17:0]            phase_incr,
  input [15:0]            window_size
);

  wire [15:0]             adc_A0;
  wire [15:0]             adc_B0;
  wire [15:0]             adc_A1;
  wire [15:0]             adc_B1;
  wire [15:0]             adc_A2;
  wire [15:0]             adc_B2;
  wire [15:0]             adc_A3;
  wire [15:0]             adc_B3;

  reg [17:0]              phase_0;
  reg [17:0]              phase_1;
  reg [17:0]              phase_2;
  reg [17:0]              phase_3;

  wire [31:0]             sin_cos_0;
  wire [31:0]             sin_cos_1;
  wire [31:0]             sin_cos_2;
  wire [31:0]             sin_cos_3;

  wire [15:0]             sin_0;
  wire [15:0]             cos_0;
  wire [15:0]             sin_1;
  wire [15:0]             cos_1;
  wire [15:0]             sin_2;
  wire [15:0]             cos_2;
  wire [15:0]             sin_3;
  wire [15:0]             cos_3;

  wire [31:0]             p_sin_A0;
  wire [31:0]             p_cos_A0;
  wire [31:0]             p_sin_B0;
  wire [31:0]             p_cos_B0;

  wire [31:0]             p_sin_A1;
  wire [31:0]             p_cos_A1;
  wire [31:0]             p_sin_B1;
  wire [31:0]             p_cos_B1;

  wire [31:0]             p_sin_A2;
  wire [31:0]             p_cos_A2;
  wire [31:0]             p_sin_B2;
  wire [31:0]             p_cos_B2;

  wire [31:0]             p_sin_A3;
  wire [31:0]             p_cos_A3;
  wire [31:0]             p_sin_B3;
  wire [31:0]             p_cos_B3;

  reg  [31:0]             p_sin_A01;
  reg  [31:0]             p_sin_A23;
  reg  [31:0]             p_sin_A;

  reg  [31:0]             p_cos_A01;
  reg  [31:0]             p_cos_A23;
  reg  [31:0]             p_cos_A;

  reg  [31:0]             p_sin_B01;
  reg  [31:0]             p_sin_B23;
  reg  [31:0]             p_sin_B;

  reg  [31:0]             p_cos_B01;
  reg  [31:0]             p_cos_B23;
  reg  [31:0]             p_cos_B;

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
  .A(sin_0),               // input wire [15 : 0] A
  .B(adc_A0),              // input wire [15 : 0] B
  .P(p_sin_A0)             // output wire [31 : 0] P
);

multiply_0 mul_cos_A0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_0),               // input wire [15 : 0] A
  .B(adc_A0),              // input wire [15 : 0] B
  .P(p_cos_A0)             // output wire [31 : 0] P
);

multiply_0 mul_sin_B0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_0),               // input wire [15 : 0] A
  .B(adc_B0),              // input wire [15 : 0] B
  .P(p_sin_B0)             // output wire [31 : 0] P
);

multiply_0 mul_cos_B0_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_0),               // input wire [15 : 0] A
  .B(adc_B0),              // input wire [15 : 0] B
  .P(p_cos_B0)             // output wire [31 : 0] P
);

multiply_0 mul_sin_A1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_1),               // input wire [15 : 0] A
  .B(adc_A1),              // input wire [15 : 0] B
  .P(p_sin_A1)             // output wire [31 : 0] P
);

multiply_0 mul_cos_A1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_1),               // input wire [15 : 0] A
  .B(adc_A1),              // input wire [15 : 0] B
  .P(p_cos_A1)             // output wire [31 : 0] P
);

multiply_0 mul_sin_B1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_1),               // input wire [15 : 0] A
  .B(adc_B1),              // input wire [15 : 0] B
  .P(p_sin_B1)             // output wire [31 : 0] P
);

multiply_0 mul_cos_B1_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_1),               // input wire [15 : 0] A
  .B(adc_B1),              // input wire [15 : 0] B
  .P(p_cos_B1)             // output wire [31 : 0] P
);

multiply_0 mul_sin_A2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_2),               // input wire [15 : 0] A
  .B(adc_A2),              // input wire [15 : 0] B
  .P(p_sin_A2)             // output wire [31 : 0] P
);

multiply_0 mul_cos_A2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_2),               // input wire [15 : 0] A
  .B(adc_A2),              // input wire [15 : 0] B
  .P(p_cos_A2)             // output wire [31 : 0] P
);

multiply_0 mul_sin_B2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_2),               // input wire [15 : 0] A
  .B(adc_B2),              // input wire [15 : 0] B
  .P(p_sin_B2)             // output wire [31 : 0] P
);

multiply_0 mul_cos_B2_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_2),               // input wire [15 : 0] A
  .B(adc_B2),              // input wire [15 : 0] B
  .P(p_cos_B2)             // output wire [31 : 0] P
);

multiply_0 mul_sin_A3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_3),               // input wire [15 : 0] A
  .B(adc_A3),              // input wire [15 : 0] B
  .P(p_sin_A3)             // output wire [31 : 0] P
);

multiply_0 mul_cos_A3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_3),               // input wire [15 : 0] A
  .B(adc_A3),              // input wire [15 : 0] B
  .P(p_cos_A3)             // output wire [31 : 0] P
);

multiply_0 mul_sin_B3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(sin_3),               // input wire [15 : 0] A
  .B(adc_B3),              // input wire [15 : 0] B
  .P(p_sin_B3)             // output wire [31 : 0] P
);

multiply_0 mul_cos_B3_inst (
  .CLK(rx_clk),            // input wire CLK
  .A(cos_3),               // input wire [15 : 0] A
  .B(adc_B3),              // input wire [15 : 0] B
  .P(p_cos_B3)             // output wire [31 : 0] P
);

ila_1 ila_1_inst (
    .clk(rx_clk),                   // input wire clk
    .probe0(rx_adc_wr),             // input wire [0:0]  probe0  
    .probe1(phase_0),               // input wire [17:0]  probe0  
    .probe2(phase_1),               // input wire [17:0]  probe0  
    .probe3(phase_2),               // input wire [17:0]  probe0  
    .probe4(phase_3),               // input wire [17:0]  probe0  
    .probe5(sin_0),                 // input wire [15:0]  probe0  
    .probe6(sin_1),                 // input wire [15:0]  probe0  
    .probe7(sin_2),                 // input wire [15:0]  probe0  
    .probe8(sin_3),                 // input wire [15:0]  probe0  
    .probe9(cos_0),                 // input wire [15:0]  probe0  
    .probe10(cos_1),                // input wire [15:0]  probe0  
    .probe11(cos_2),                // input wire [15:0]  probe0  
    .probe12(cos_3),                // input wire [15:0]  probe0  
    .probe13(adc_A0),               // input wire [15:0]  probe0  
    .probe14(adc_B0),               // input wire [15:0]  probe0  
    .probe15(adc_A1),               // input wire [15:0]  probe0  
    .probe16(adc_B1),               // input wire [15:0]  probe0  
    .probe17(p_sin_A0),             // input wire [31:0]  probe0  
    .probe18(p_sin_B0),             // input wire [31:0]  probe0  
    .probe19(p_cos_A0),             // input wire [31:0]  probe0  
    .probe20(p_cos_B0),             // input wire [31:0]  probe0  
    .probe21(p_sin_A1),             // input wire [31:0]  probe0  
    .probe22(p_sin_B1),             // input wire [31:0]  probe0  
    .probe23(p_cos_A1),             // input wire [31:0]  probe0  
    .probe24(p_cos_B1),             // input wire [31:0]  probe0  
    .probe25(p_sin_A01),            // input wire [31:0]  probe0  
    .probe26(p_cos_A01),            // input wire [31:0]  probe0  
    .probe27(p_sin_A),              // input wire [31:0]  probe0  
    .probe28(p_cos_A)               // input wire [31:0]  probe0  
 );

  assign sin_0 = {sin_cos_0[30], sin_cos_0[30:16]};
  assign cos_0 = {sin_cos_0[14], sin_cos_0[14:0]};
  assign sin_1 = {sin_cos_1[30], sin_cos_1[30:16]};
  assign cos_1 = {sin_cos_1[14], sin_cos_1[14:0]};
  assign sin_2 = {sin_cos_2[30], sin_cos_2[30:16]};
  assign cos_2 = {sin_cos_2[14], sin_cos_2[14:0]};
  assign sin_3 = {sin_cos_3[30], sin_cos_3[30:16]};
  assign cos_3 = {sin_cos_3[14], sin_cos_3[14:0]};

  assign adc_A0 = rx_adc_data[15:0];
  assign adc_B0 = rx_adc_data[31:16];
  assign adc_A1 = rx_adc_data[47:32];
  assign adc_B1 = rx_adc_data[63:48];
  assign adc_A2 = rx_adc_data[79:64];
  assign adc_B2 = rx_adc_data[95:80];
  assign adc_A3 = rx_adc_data[111:96];
  assign adc_B3 = rx_adc_data[127:112];


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
        phase_2 <= {phase_incr, 1'b0};
        phase_3 <= {phase_incr, 1'b0} + phase_incr;
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

        p_sin_B01 <= p_sin_B0 + p_sin_B1;
        p_sin_B23 <= p_sin_B2 + p_sin_B3;
        p_cos_B01 <= p_cos_B0 + p_cos_B1;
        p_cos_B23 <= p_cos_B2 + p_cos_B3;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_adc_wr) 
      begin
        p_sin_A <= p_sin_A01 + p_sin_A23;
        p_cos_A <= p_cos_A01 + p_cos_A23;
        p_sin_B <= p_sin_B01 + p_sin_B23;
        p_cos_B <= p_cos_B01 + p_cos_B23;
      end
    end


end
endgenerate

endmodule
