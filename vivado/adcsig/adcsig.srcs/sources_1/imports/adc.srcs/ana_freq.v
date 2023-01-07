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
  input wire              reset,

  input wire              init,
  input wire [12:0]       count,
  input wire              start,
  input wire              stop,
  input wire              run,

  input wire              wr,
  input wire [10:0]       wr_adr,
  input wire [63:0]       wr_sin,
  input wire [63:0]       wr_cos,

  input wire [13:0]       in_A0,
  input wire [13:0]       in_A1,
  input wire [13:0]       in_A2,
  input wire [13:0]       in_A3,

  input wire [13:0]       in_B0,
  input wire [13:0]       in_B1,
  input wire [13:0]       in_B2,
  input wire [13:0]       in_B3,

  output reg              report,

  output wire [15:0]      power_A,
  output wire [15:0]      power_B,

  output reg  [15:0]      phase_A,
  output reg  [15:0]      phase_B
);

  reg                    start_1;
  reg                    start_2;
  reg                    start_3;
  reg                    last_1;
  reg                    last_2;
  reg                    last_3;

  reg  [12:0]            coeff_count;
  reg                    coeff_en;
  reg                    coeff_wr;
  reg  [10:0]            coeff_adr;
  reg  [63:0]            sin_coeff_in;
  reg  [63:0]            cos_coeff_in;
  wire [63:0]            sin_coeff_out;
  wire [63:0]            cos_coeff_out;

  wire [15:0]            sin_coeff_0;
  wire [15:0]            sin_coeff_1;
  wire [15:0]            sin_coeff_2;
  wire [15:0]            sin_coeff_3;

  assign sin_coeff_0 = sin_coeff_out[15:0];
  assign sin_coeff_1 = sin_coeff_out[31:16];
  assign sin_coeff_2 = sin_coeff_out[47:32];
  assign sin_coeff_3 = sin_coeff_out[63:48];

  wire [15:0]            cos_coeff_0;
  wire [15:0]            cos_coeff_1;
  wire [15:0]            cos_coeff_2;
  wire [15:0]            cos_coeff_3;

  assign cos_coeff_0 = cos_coeff_out[15:0];
  assign cos_coeff_1 = cos_coeff_out[31:16];
  assign cos_coeff_2 = cos_coeff_out[47:32];
  assign cos_coeff_3 = cos_coeff_out[63:48];


  wire [15:0]            pow_sin_A;
  wire [15:0]            pow_cos_A;
  wire [15:0]            pow_sin_B;
  wire [15:0]            pow_cos_B;
  
  wire [31:0]            sin_A2;
  wire [31:0]            cos_A2;
  wire [31:0]            sin_B2;
  wire [31:0]            cos_B2;

  wire [42:0]            sum_sin_A;
  wire [42:0]            sum_cos_A;
  wire [42:0]            sum_sin_B;
  wire [42:0]            sum_cos_B;

  wire [23:0]            cordic_phase_A;
  wire [23:0]            cordic_phase_B;

  wire [55:0]            in_A;
  wire [55:0]            in_B;

  reg  [10:0]            last;
  reg  [3:0]             last_en;
  
  reg                    input_done;
  
  reg                    skip;
  reg                    pd1;
  reg                    pd2;
  reg                    pd3;
  reg                    pd4;
  reg                    pd5;
  reg                    pd6;
  reg                    pd7;
  reg                    pd8;
  
  reg                    pd_start;
  reg                    pd_running;
  reg                    pd_post;
  reg  [4:0]             div_delay;
  reg  [2:0]             mul_delay;

  reg  [31:0]            pow_sq_A;
  reg  [31:0]            pow_sq_B;
  reg                    conv_start;
  wire                   power_done_A;
  wire                   power_done_B;
  wire                   phase_done_A;
  wire                   phase_done_B;

  wire [47:0]            phase_sin_cos_A;
  wire [47:0]            phase_sin_cos_B;
  
  wire                   shift_sin_A;
  wire                   shift_cos_A;
  wire                   shift_sin_B;
  wire                   shift_cos_B;

  wire                   do_shift_A;
  wire                   do_shift_B;

  assign in_A[13:0] = in_A0;
  assign in_A[27:14] = in_A1;
  assign in_A[41:28] = in_A2;
  assign in_A[55:42] = in_A3;

  assign in_B[13:0] = in_B0;
  assign in_B[27:14] = in_B1;
  assign in_B[41:28] = in_B2;
  assign in_B[55:42] = in_B3;
  
  assign do_shift_A = shift_sin_A & shift_cos_A;
  assign do_shift_B = shift_sin_B & shift_cos_B;

bram_freq bram_sin (
  .clka(clk),           // input wire clka
  .ena(coeff_en),       // input wire ena
  .wea(coeff_wr),       // input wire [0 : 0] wea
  .addra(coeff_adr),    // input wire [10 : 0] addra
  .dina(sin_coeff_in),  // input wire [63 : 0] dina
  .douta(sin_coeff_out) // output wire [63 : 0] douta
);

bram_freq bram_cos (
  .clka(clk),           // input wire clka
  .ena(coeff_en),       // input wire ena
  .wea(coeff_wr),       // input wire [0 : 0] wea
  .addra(coeff_adr),    // input wire [10 : 0] addra
  .dina(cos_coeff_in),  // input wire [63 : 0] dina
  .douta(cos_coeff_out) // output wire [63 : 0] douta
);

adc_slice sin_A (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(last_3),           // input wire [0 : 0] next
  .in(in_A),               // input wire [55 : 0] in
  .coeff(sin_coeff_out),   // input wire [63 : 0] coeff
  .report(),               // output wire [0 : 0] report
  .sum(sum_sin_A)          // output wire [42 : 0] sum
);

adc_slice cos_A (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(last_3),           // input wire [0 : 0] next
  .in(in_A),               // input wire [55 : 0] in
  .coeff(cos_coeff_out),   // input wire [63 : 0] coeff
  .report(),               // output wire [0 : 0] report
  .sum(sum_cos_A)          // output wire [42 : 0] sum
);

adc_slice sin_B (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(last_3),           // input wire [0 : 0] next
  .in(in_B),               // input wire [55 : 0] in
  .coeff(sin_coeff_out),   // input wire [63 : 0] coeff
  .report(),               // output wire [0 : 0] report
  .sum(sum_sin_B)          // output wire [42 : 0] sum
);

adc_slice cos_B (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(last_3),           // input wire [0 : 0] next
  .in(in_B),               // input wire [55 : 0] in
  .coeff(cos_coeff_out),   // input wire [63 : 0] coeff
  .report(),               // output wire [0 : 0] report
  .sum(sum_cos_A)          // output wire [42 : 0] sum
);

/*
square square_sin_A (
  .CLK(clk),         // input wire CLK
  .A(pow_sin_A),     // input wire [15 : 0] A
  .B(pow_sin_A),     // input wire [15 : 0] B
  .P(sin_A2)         // output wire [31 : 0] P
);

square square_cos_A (
  .CLK(clk),         // input wire CLK
  .A(pow_cos_A),     // input wire [15 : 0] A
  .B(pow_cos_A),     // input wire [15 : 0] B
  .P(cos_A2)         // output wire [31 : 0] P
);

square square_sin_B (
  .CLK(clk),         // input wire CLK
  .A(pow_sin_B),     // input wire [15 : 0] A
  .B(pow_sin_B),     // input wire [15 : 0] B
  .P(sin_B2)         // output wire [31 : 0] P
);

square square_cos_B (
  .CLK(clk),         // input wire CLK
  .A(pow_cos_B),     // input wire [15 : 0] A
  .B(pow_cos_B),     // input wire [15 : 0] B
  .P(cos_B2)         // output wire [31 : 0] P
);
*/

/*
ana_sqrt sqrt_A (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(conv_start),              // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(pow_sq_A),                 // input wire [31 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(power_done_A),                   // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(power_A)                        // output wire [15 : 0] m_axis_dout_tdata
);

ana_sqrt sqrt_B (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(conv_start),              // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(pow_sq_B),                 // input wire [31 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(power_done_B),                 // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(power_B)                        // output wire [15 : 0] m_axis_dout_tdata
);
*/

/*
ana_atan atan_A (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(conv_start),              // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tready(),                        // output wire s_axis_cartesian_tready
  .s_axis_cartesian_tdata(phase_sin_cos_A),          // input wire [47 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(phase_done_A),                 // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(cordic_phase_A)                 // output wire [23 : 0] m_axis_dout_tdata
);

ana_atan atan_B (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(conv_start),              // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tready(),                        // output wire s_axis_cartesian_tready
  .s_axis_cartesian_tdata(phase_sin_cos_B),          // input wire [47 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(phase_done_B),                 // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(cordic_phase_B)                 // output wire [23 : 0] m_axis_dout_tdata
);
*/

/*
ila_0 ila_0_inst (
  .clk(clk),              // input wire clk
  .probe0(init),          // input wire [0:0]  probe0
  .probe1(run),           // input wire [0:0]  probe1
  .probe2(in_A0),         // input wire [13:0]  probe2
  .probe3(in_A1),         // input wire [13:0]  probe3
  .probe4(in_A2),         // input wire [13:0]  probe3
  .probe5(in_A3),         // input wire [13:0]  probe3
  .probe6(sin_coeff_0),   // input wire [15:0]  probe3
  .probe7(sin_coeff_1),   // input wire [15:0]  probe3
  .probe8(sin_coeff_2),   // input wire [15:0]  probe3
  .probe9(sin_coeff_3),   // input wire [15:0]  probe3
  .probe10(report),       // input wire [0:0]  probe3
  .probe11(power_A),      // input wire [15:0]  probe3
  .probe12(power_B),      // input wire [15:0]  probe3
  .probe13(phase_A),      // input wire [15:0]  probe3
  .probe14(phase_B)       // input wire [15:0]  probe3
);
*/

generate
begin : ana_freq_gen

  always @ ( posedge clk ) 
  begin
    start_1 <= start;
    start_2 <= start_1;
    start_3 <= start_2;
  end

  always @ ( posedge clk ) 
  begin
    if (coeff_adr == last)
      last_1 <= 1;
    else
      last_1 <= 0;

    last_2 <= last_1;
    last_3 <= last_2;
  end

  always @ ( posedge clk ) 
  begin
    if (phase_done_A & !skip)
       report <= 1;
    else
       report <= 0;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      phase_A <= 0;
    else
    begin
      if (phase_done_A)
        phase_A <= cordic_phase_A[21:6];
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      phase_B <= 0;
    else
    begin
      if (phase_done_B)
        phase_B <= cordic_phase_B[21:6];
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      mul_delay <= 0;
      conv_start <= 0;
    end
    else
    begin
      if (input_done)
      begin
        mul_delay <= 5;
        conv_start <= 0;
      end
      else
      begin
        if (mul_delay)
        begin
          mul_delay <= mul_delay - 1;
          if (mul_delay == 1)
          begin
            pow_sq_A <= sin_A2 + cos_A2;
            pow_sq_B <= sin_B2 + cos_B2;
            conv_start <= 1;
          end
        end
        else
          conv_start <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (run)
    begin
      if (pd7)
      begin
        div_delay <= 5'b11111;
        input_done <= 0;
      end
      else
      begin
        if (div_delay)
        begin
          div_delay <= div_delay - 1;
          if (div_delay == 1)
          begin
            if (skip)
            begin
              skip <= 0;
              input_done <= 0;
            end
            else
              input_done <= 1;
          end
          else
            input_done <= 0;
        end
        else
          input_done <= 0;
      end
    end
    else
    begin
      div_delay <= 0;
      input_done <= 0;
      skip <= 1;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (pd_start)
    begin
      pd_running <= 1;
      pd_post <= 0;
    end
    else
    begin
      if (pd_running)
      begin
        if (div_delay == 2)
        begin
          pd_running <= 0;
          pd_post <= 1;
        end
      end
      else
        pd_post <= 0;
    end
  end


  always @ ( posedge clk ) 
  begin
    if (run)
    begin
      pd2 <= pd1;
      pd3 <= pd2;
      pd4 <= pd3;
      pd5 <= pd4;
      pd6 <= pd5;
      pd7 <= pd6;
      pd8 <= pd7;
      pd_start <= pd8;
    end
  end


  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      coeff_count <= 0;
      last <= 0;
    end
    else
    begin
      if (init)
      begin
        coeff_count <= count;

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
    end
  end


  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      coeff_en <= 0;
      coeff_wr <= 0;
      pd1 <= 0;
    end
    else
    begin
      if (wr)
      begin
        coeff_adr <= wr_adr;
        coeff_en <= 1;
        coeff_wr <= 1;

        if (wr_adr == last)
        begin
          if (last_en[0])
          begin
            sin_coeff_in[15:0] <= wr_sin[15:0];
            cos_coeff_in[15:0] <= wr_cos[15:0];
          end
          else            
          begin
            sin_coeff_in[15:0] <= 0;
            cos_coeff_in[15:0] <= 0;
          end

          if (last_en[1])
          begin
            sin_coeff_in[31:16] <= wr_sin[31:16];
            cos_coeff_in[31:16] <= wr_cos[31:16];
          end
          else            
          begin
            sin_coeff_in[31:16] <= 0;
            cos_coeff_in[31:16] <= 0;
          end

          if (last_en[2])
          begin
            sin_coeff_in[47:32] <= wr_sin[47:32];
            cos_coeff_in[47:32] <= wr_cos[47:32];
          end
          else            
          begin
            sin_coeff_in[47:32] <= 0;
            cos_coeff_in[47:32] <= 0;
          end

          if (last_en[3])
          begin
            sin_coeff_in[63:48] <= wr_sin[63:48];
            cos_coeff_in[63:48] <= wr_cos[63:48];
          end
          else            
          begin
            sin_coeff_in[63:48] <= 0;
            cos_coeff_in[63:48] <= 0;
          end
        end
        else
        begin
          sin_coeff_in <= wr_sin;
          cos_coeff_in <= wr_cos;
        end
      end
      else
      begin
        if (run)
        begin
          coeff_en <= 1;
          coeff_wr <= 0;

          if (start)
          begin
            coeff_adr <= 0;
            pd1 <= 1;
          end
          else
          begin
            if (coeff_adr == last)
            begin
              coeff_adr <= 0;
              pd1 <= 1;
            end
            else
            begin
              coeff_adr <= coeff_adr + 1;
              pd1 <= 0;
            end
          end
        end
        else
        begin
          coeff_en <= 0;
          coeff_wr <= 0;
          coeff_adr <= 0;
          pd1 <= 0;
        end
      end
    end
  end
  
end

endgenerate

endmodule
