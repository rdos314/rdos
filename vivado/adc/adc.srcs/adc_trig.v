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
  input [3:0]             window_bits
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

  wire [47:0]             sin_A0;
  wire [47:0]             cos_A0;
  wire [47:0]             sin_B0;
  wire [47:0]             cos_B0;

  wire [47:0]             sin_A1;
  wire [47:0]             cos_A1;
  wire [47:0]             sin_B1;
  wire [47:0]             cos_B1;

  wire [47:0]             sin_A2;
  wire [47:0]             cos_A2;
  wire [47:0]             sin_B2;
  wire [47:0]             cos_B2;

  wire [47:0]             sin_A3;
  wire [47:0]             cos_A3;
  wire [47:0]             sin_B3;
  wire [47:0]             cos_B3;

  reg  [47:0]             sin_A01;
  reg  [47:0]             sin_A23;
  reg  [47:0]             sin_A;

  reg  [47:0]             cos_A01;
  reg  [47:0]             cos_A23;
  reg  [47:0]             cos_A;

  reg  [47:0]             sin_B01;
  reg  [47:0]             sin_B23;
  reg  [47:0]             sin_B;

  reg  [47:0]             cos_B01;
  reg  [47:0]             cos_B23;
  reg  [47:0]             cos_B;

  reg [15:0]              window_size;
  reg [3:0]               start_cnt;
  reg                     started;
  reg [15:0]              remain_0;
  reg [15:0]              remain_1;
  reg                     wr_0;
  reg                     wr_1;

  reg [47:0]              sum_sin_A0;
  reg [47:0]              sum_cos_A0;
  reg [47:0]              sum_sin_B0;
  reg [47:0]              sum_cos_B0;

  reg [47:0]              sum_sin_A1;
  reg [47:0]              sum_cos_A1;
  reg [47:0]              sum_sin_B1;
  reg [47:0]              sum_cos_B1;

  reg                     res_wr;
  reg [19:0]              res_sin_A;
  reg [19:0]              res_cos_A;
  reg [19:0]              res_sin_B;
  reg [19:0]              res_cos_B;

  wire [39:0]             sin_sq_A;
  wire [39:0]             cos_sq_A;
  wire [39:0]             sin_sq_B;
  wire [39:0]             cos_sq_B;

  reg [39:0]              sq_sum_A;
  reg [39:0]              sq_sum_B;
  reg                     sq_en;
  reg [1:0]               sq_delay;  

  wire                    empty;

  reg                     sqrt_en;
  wire                    pow_valid_A;
  wire                    pow_valid_B;
  wire [23:0]             pow_A;
  wire [23:0]             pow_B;

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

mult_square_0 sin_sq_A_inst (
  .CLK(rx_clk),          // input wire CLK
  .A(res_sin_A),         // input wire [19 : 0] A
  .B(res_sin_A),         // input wire [19 : 0] B
  .CE(sq_en),            // input wire CE
  .P(sin_sq_A)           // output wire [39 : 0] P
);

mult_square_0 sin_sq_B_inst (
  .CLK(rx_clk),          // input wire CLK
  .A(res_sin_B),         // input wire [19 : 0] A
  .B(res_sin_B),         // input wire [19 : 0] B
  .CE(sq_en),            // input wire CE
  .P(sin_sq_B)           // output wire [39 : 0] P
);

mult_square_0 cos_sq_A_inst (
  .CLK(rx_clk),          // input wire CLK
  .A(res_cos_A),         // input wire [19 : 0] A
  .B(res_cos_A),         // input wire [19 : 0] B
  .CE(sq_en),            // input wire CE
  .P(cos_sq_A)           // output wire [39 : 0] P
);

mult_square_0 cos_sq_B_inst (
  .CLK(rx_clk),          // input wire CLK
  .A(res_cos_B),         // input wire [19 : 0] A
  .B(res_cos_B),         // input wire [19 : 0] B
  .CE(sq_en),            // input wire CE
  .P(cos_sq_B)           // output wire [39 : 0] P
);

sqrt_0 sqrt_A_inst (
  .aclk(rx_clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(sqrt_en),                    // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(sq_sum_A),                    // input wire [39 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(pow_valid_A),                     // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(pow_A)                             // output wire [23 : 0] m_axis_dout_tdata
);

sqrt_0 sqrt_B_inst (
  .aclk(rx_clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(sqrt_en),                    // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(sq_sum_B),                    // input wire [39 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(pow_valid_B),                     // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(pow_B)                             // output wire [23 : 0] m_axis_dout_tdata
);

trig_fifo_0 trig_fifo_inst (
  .clk(rx_clk),           // input wire clk
  .din(rx_adc_data),      // input wire [127 : 0] din
  .wr_en(rx_adc_wr),      // input wire wr_en
  .rd_en(!empty),         // input wire rd_en
  .dout(),                // output wire [127 : 0] dout
  .full(),                // output wire full
  .empty(empty)           // output wire empty
);

ila_1 ila_1_inst (
    .clk(rx_clk),                   // input wire clk
    .probe0(rx_adc_wr),             // input wire [0:0]  probe0  
    .probe1(start_cnt),             // input wire [3:0]  probe0  
    .probe2(started),               // input wire [0:0]  probe0  
    .probe3(sum_sin_A0),            // input wire [47:0]  probe0  
    .probe4(sum_cos_A0),            // input wire [47:0]  probe0  
    .probe5(sum_sin_B0),            // input wire [47:0]  probe0  
    .probe6(sum_cos_B0),            // input wire [47:0]  probe0  
    .probe7(sum_sin_A1),            // input wire [47:0]  probe0  
    .probe8(sum_cos_A1),            // input wire [47:0]  probe0  
    .probe9(sum_sin_B1),            // input wire [47:0]  probe0  
    .probe10(sum_cos_B1),           // input wire [47:0]  probe0  
    .probe11(remain_0),             // input wire [15:0]  probe0  
    .probe12(remain_1),             // input wire [15:0]  probe0  
    .probe13(wr_0),                 // input wire [0:0]  probe0  
    .probe14(wr_1),                 // input wire [0:0]  probe0  
    .probe15(res_wr),               // input wire [0:0]  probe0  
    .probe16(res_sin_A),            // input wire [19:0]  probe0  
    .probe17(res_cos_A),            // input wire [19:0]  probe0  
    .probe18(res_sin_B),            // input wire [19:0]  probe0  
    .probe19(res_cos_B),            // input wire [19:0]  probe0  
    .probe20(sin_sq_A),             // input wire [39:0]  probe0  
    .probe21(cos_sq_A),             // input wire [39:0]  probe0  
    .probe22(sin_sq_B),             // input wire [39:0]  probe0  
    .probe23(cos_sq_B),             // input wire [39:0]  probe0  
    .probe24(sq_en),                // input wire [0:0]  probe0  
    .probe25(sq_delay),             // input wire [1:0]  probe0  
    .probe26(sq_sum_A),             // input wire [39:0]  probe0  
    .probe27(sq_sum_B),             // input wire [39:0]  probe0  
    .probe28(sqrt_en),              // input wire [0:0]  probe0  
    .probe29(pow_valid_A),          // input wire [0:0]  probe0  
    .probe30(pow_valid_B),          // input wire [0:0]  probe0  
    .probe31(pow_A),                // input wire [23:0]  probe0  
    .probe32(pow_B)                 // input wire [23:0]  probe0  
 );

  assign sin_0 = {sin_cos_0[30], sin_cos_0[30:16]};
  assign cos_0 = {sin_cos_0[14], sin_cos_0[14:0]};
  assign sin_1 = {sin_cos_1[30], sin_cos_1[30:16]};
  assign cos_1 = {sin_cos_1[14], sin_cos_1[14:0]};
  assign sin_2 = {sin_cos_2[30], sin_cos_2[30:16]};
  assign cos_2 = {sin_cos_2[14], sin_cos_2[14:0]};
  assign sin_3 = {sin_cos_3[30], sin_cos_3[30:16]};
  assign cos_3 = {sin_cos_3[14], sin_cos_3[14:0]};

  assign sin_A0 = {{16{p_sin_A0[31]}}, p_sin_A0};
  assign cos_A0 = {{16{p_cos_A0[31]}}, p_cos_A0};
  assign sin_B0 = {{16{p_sin_B0[31]}}, p_sin_B0};
  assign cos_B0 = {{16{p_cos_B0[31]}}, p_cos_B0};

  assign sin_A1 = {{16{p_sin_A1[31]}}, p_sin_A1};
  assign cos_A1 = {{16{p_cos_A1[31]}}, p_cos_A1};
  assign sin_B1 = {{16{p_sin_B1[31]}}, p_sin_B1};
  assign cos_B1 = {{16{p_cos_B1[31]}}, p_cos_B1};

  assign sin_A2 = {{16{p_sin_A2[31]}}, p_sin_A2};
  assign cos_A2 = {{16{p_cos_A2[31]}}, p_cos_A2};
  assign sin_B2 = {{16{p_sin_B2[31]}}, p_sin_B2};
  assign cos_B2 = {{16{p_cos_B2[31]}}, p_cos_B2};

  assign sin_A3 = {{16{p_sin_A3[31]}}, p_sin_A3};
  assign cos_A3 = {{16{p_cos_A3[31]}}, p_cos_A3};
  assign sin_B3 = {{16{p_sin_B3[31]}}, p_sin_B3};
  assign cos_B3 = {{16{p_cos_B3[31]}}, p_cos_B3};

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

        if (start_cnt)
          start_cnt <= start_cnt - 1;
        else 
          started <= 1;
      end
      else
      begin
        phase_0 <= 0;
        phase_1 <= phase_incr;
        phase_2 <= {phase_incr, 1'b0};
        phase_3 <= {phase_incr, 1'b0} + phase_incr;

        case (window_bits)
          0: window_size <= 16'h0;
          1: window_size <= 16'h2;
          2: window_size <= 16'h4;
          3: window_size <= 16'h8;
          4: window_size <= 16'h10;
          5: window_size <= 16'h20;
          6: window_size <= 16'h40;
          7: window_size <= 16'h80;
          8: window_size <= 16'h100;
          9: window_size <= 16'h200;
          10: window_size <= 16'h400;
          11: window_size <= 16'h800;
          12: window_size <= 16'h1000;
          13: window_size <= 16'h2000;
          14: window_size <= 16'h4000;
          15: window_size <= 16'h8000;
        endcase

        start_cnt <= 7;
        started <= 0;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_adc_wr)
      begin
        sin_A01 <= sin_A0 + sin_A1;
        sin_A23 <= sin_A2 + sin_A3;
        cos_A01 <= cos_A0 + cos_A1;
        cos_A23 <= cos_A2 + cos_A3;

        sin_B01 <= sin_B0 + sin_B1;
        sin_B23 <= sin_B2 + sin_B3;
        cos_B01 <= cos_B0 + cos_B1;
        cos_B23 <= cos_B2 + cos_B3;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (rx_adc_wr)
      begin
        sin_A <= sin_A01 + sin_A23;
        cos_A <= cos_A01 + cos_A23;
        sin_B <= sin_B01 + sin_B23;
        cos_B <= cos_B01 + cos_B23;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (started)
      begin
        if (remain_0)
        begin
          if (remain_0 == 1)
            wr_0 <= 1;
          else
            wr_0 <= 0;
          remain_0 <= remain_0 - 1;
          sum_sin_A0 <= sum_sin_A0 + sin_A0;
          sum_cos_A0 <= sum_cos_A0 + cos_A0;
          sum_sin_B0 <= sum_sin_B0 + sin_B0;
          sum_cos_B0 <= sum_cos_B0 + cos_B0;
        end
        else
        begin
          wr_0 <= 0;
          remain_0 <= window_size;
          sum_sin_A0 <= sin_A0;
          sum_cos_A0 <= cos_A0;
          sum_sin_B0 <= sin_B0;
          sum_cos_B0 <= cos_B0;
        end

        if (remain_1)
        begin
          if (remain_1 == 1)
            wr_1 <= 1;
          else
            wr_1 <= 0;
          remain_1 <= remain_1 - 1;
          sum_sin_A1 <= sum_sin_A1 + sin_A0;
          sum_cos_A1 <= sum_cos_A1 + cos_A0;
          sum_sin_B1 <= sum_sin_B1 + sin_B0;
          sum_cos_B1 <= sum_cos_B1 + cos_B0;
        end
        else
        begin
          wr_1 <= 0;
          remain_1 <= window_size;
          sum_sin_A1 <= sin_A0;
          sum_cos_A1 <= cos_A0;
          sum_sin_B1 <= sin_B0;
          sum_cos_B1 <= cos_B0;
        end
      end
      else
      begin 
        sum_sin_A0 <= 0;
        sum_cos_A0 <= 0;
        sum_sin_B0 <= 0;
        sum_cos_B0 <= 0;
        sum_sin_A1 <= 0;
        sum_cos_A1 <= 0;
        sum_sin_B1 <= 0;
        sum_cos_B1 <= 0;
        wr_0 <= 0;
        wr_1 <= 0;
        remain_0 <= window_size[15:1];
        remain_1 <= window_size;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (wr_0)
      begin
        res_wr <= 1;

        case (window_bits)
          1:
          begin
            res_sin_A <= sum_sin_A0[33:14];
            res_cos_A <= sum_cos_A0[33:14];
            res_sin_B <= sum_sin_B0[33:14];
            res_cos_B <= sum_cos_B0[33:14];
          end

          2:
          begin
            res_sin_A <= sum_sin_A0[34:15];
            res_cos_A <= sum_cos_A0[34:15];
            res_sin_B <= sum_sin_B0[34:15];
            res_cos_B <= sum_cos_B0[34:15];
          end

          3:
          begin
            res_sin_A <= sum_sin_A0[35:16];
            res_cos_A <= sum_cos_A0[35:16];
            res_sin_B <= sum_sin_B0[35:16];
            res_cos_B <= sum_cos_B0[35:16];
          end

          4:
          begin
            res_sin_A <= sum_sin_A0[36:17];
            res_cos_A <= sum_cos_A0[36:17];
            res_sin_B <= sum_sin_B0[36:17];
            res_cos_B <= sum_cos_B0[36:17];
          end

          5:
          begin
            res_sin_A <= sum_sin_A0[37:18];
            res_cos_A <= sum_cos_A0[37:18];
            res_sin_B <= sum_sin_B0[37:18];
            res_cos_B <= sum_cos_B0[37:18];
          end

          6:
          begin
            res_sin_A <= sum_sin_A0[38:19];
            res_cos_A <= sum_cos_A0[38:19];
            res_sin_B <= sum_sin_B0[38:19];
            res_cos_B <= sum_cos_B0[38:19];
          end

          7:
          begin
            res_sin_A <= sum_sin_A0[39:20];
            res_cos_A <= sum_cos_A0[39:20];
            res_sin_B <= sum_sin_B0[39:20];
            res_cos_B <= sum_cos_B0[39:20];
          end

          8:
          begin
            res_sin_A <= sum_sin_A0[40:21];
            res_cos_A <= sum_cos_A0[40:21];
            res_sin_B <= sum_sin_B0[40:21];
            res_cos_B <= sum_cos_B0[40:21];
          end

          9:
          begin
            res_sin_A <= sum_sin_A0[41:22];
            res_cos_A <= sum_cos_A0[41:22];
            res_sin_B <= sum_sin_B0[41:22];
            res_cos_B <= sum_cos_B0[41:22];
          end

          10:
          begin
            res_sin_A <= sum_sin_A0[42:23];
            res_cos_A <= sum_cos_A0[42:23];
            res_sin_B <= sum_sin_B0[42:23];
            res_cos_B <= sum_cos_B0[42:23];
          end

          11:
          begin
            res_sin_A <= sum_sin_A0[43:24];
            res_cos_A <= sum_cos_A0[43:24];
            res_sin_B <= sum_sin_B0[43:24];
            res_cos_B <= sum_cos_B0[43:24];
          end

          12:
          begin
            res_sin_A <= sum_sin_A0[44:25];
            res_cos_A <= sum_cos_A0[44:25];
            res_sin_B <= sum_sin_B0[44:25];
            res_cos_B <= sum_cos_B0[44:25];
          end

          13:
          begin
            res_sin_A <= sum_sin_A0[45:26];
            res_cos_A <= sum_cos_A0[45:26];
            res_sin_B <= sum_sin_B0[45:26];
            res_cos_B <= sum_cos_B0[45:26];
          end

          14:
          begin
            res_sin_A <= sum_sin_A0[46:27];
            res_cos_A <= sum_cos_A0[46:27];
            res_sin_B <= sum_sin_B0[46:27];
            res_cos_B <= sum_cos_B0[46:27];
          end

          15:
          begin
            res_sin_A <= sum_sin_A0[47:28];
            res_cos_A <= sum_cos_A0[47:28];
            res_sin_B <= sum_sin_B0[47:28];
            res_cos_B <= sum_cos_B0[47:28];
          end
        endcase
      end
      else
      begin
        if (wr_1)
        begin
          res_wr <= 1;

          case (window_bits)
            1:
            begin
              res_sin_A <= sum_sin_A1[33:14];
              res_cos_A <= sum_cos_A1[33:14];
              res_sin_B <= sum_sin_B1[33:14];
              res_cos_B <= sum_cos_B1[33:14];
            end

            2:
            begin
              res_sin_A <= sum_sin_A1[34:15];
              res_cos_A <= sum_cos_A1[34:15];
              res_sin_B <= sum_sin_B1[34:15];
              res_cos_B <= sum_cos_B1[34:15];
            end

            3:
            begin
              res_sin_A <= sum_sin_A1[35:16];
              res_cos_A <= sum_cos_A1[35:16];
              res_sin_B <= sum_sin_B1[35:16];
              res_cos_B <= sum_cos_B1[35:16];
            end

            4:
            begin
              res_sin_A <= sum_sin_A1[36:17];
              res_cos_A <= sum_cos_A1[36:17];
              res_sin_B <= sum_sin_B1[36:17];
              res_cos_B <= sum_cos_B1[36:17];
            end

            5:
            begin
              res_sin_A <= sum_sin_A1[37:18];
              res_cos_A <= sum_cos_A1[37:18];
              res_sin_B <= sum_sin_B1[37:18];
              res_cos_B <= sum_cos_B1[37:18];
            end

            6:
            begin
              res_sin_A <= sum_sin_A1[38:19];
              res_cos_A <= sum_cos_A1[38:19];
              res_sin_B <= sum_sin_B1[38:19];
              res_cos_B <= sum_cos_B1[38:19];
            end

            7:
            begin
              res_sin_A <= sum_sin_A1[39:20];
              res_cos_A <= sum_cos_A1[39:20];
              res_sin_B <= sum_sin_B1[39:20];
              res_cos_B <= sum_cos_B1[39:20];
            end

            8:
            begin
              res_sin_A <= sum_sin_A1[40:21];
              res_cos_A <= sum_cos_A1[40:21];
              res_sin_B <= sum_sin_B1[40:21];
              res_cos_B <= sum_cos_B1[40:21];
            end

            9:
            begin
              res_sin_A <= sum_sin_A1[41:22];
              res_cos_A <= sum_cos_A1[41:22];
              res_sin_B <= sum_sin_B1[41:22];
              res_cos_B <= sum_cos_B1[41:22];
            end

            10:
            begin
              res_sin_A <= sum_sin_A1[42:23];
              res_cos_A <= sum_cos_A1[42:23];
              res_sin_B <= sum_sin_B1[42:23];
              res_cos_B <= sum_cos_B1[42:23];
            end

            11:
            begin
              res_sin_A <= sum_sin_A1[43:24];
              res_cos_A <= sum_cos_A1[43:24];
              res_sin_B <= sum_sin_B1[43:24];
              res_cos_B <= sum_cos_B1[43:24];
            end

            12:
            begin
              res_sin_A <= sum_sin_A1[44:25];
              res_cos_A <= sum_cos_A1[44:25];
              res_sin_B <= sum_sin_B1[44:25];
              res_cos_B <= sum_cos_B1[44:25];
            end

            13:
            begin
              res_sin_A <= sum_sin_A1[45:26];
              res_cos_A <= sum_cos_A1[45:26];
              res_sin_B <= sum_sin_B1[45:26];
              res_cos_B <= sum_cos_B1[45:26];
            end

            14:
            begin
              res_sin_A <= sum_sin_A1[46:27];
              res_cos_A <= sum_cos_A1[46:27];
              res_sin_B <= sum_sin_B1[46:27];
              res_cos_B <= sum_cos_B1[46:27];
            end

            15:
            begin
              res_sin_A <= sum_sin_A1[47:28];
              res_cos_A <= sum_cos_A1[47:28];
              res_sin_B <= sum_sin_B1[47:28];
              res_cos_B <= sum_cos_B1[47:28];
            end
          endcase
        end
        else
          res_wr <= 0;
      end
    end

    always @ ( posedge rx_clk ) 
    begin
      if (res_wr)
      begin
        sq_en <= 1;
        sq_delay <= 3;
      end
      else
      begin
        if (sq_delay)
          sq_delay <= sq_delay - 1;
        else
        begin
          if (sq_en)
          begin
            sq_sum_A <= sin_sq_A + cos_sq_A;
            sq_sum_B <= sin_sq_B + cos_sq_B;
            sq_en <= 0;
            sqrt_en <= 1;
          end
          else
            sqrt_en <= 0;
        end
      end
    end


end
endgenerate

endmodule
