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
  input wire [10:0]       last,

  input wire              start,
  input wire              stop,
  output reg              run,
  input wire              validate,

  input wire              wr,
  input wire [10:0]       wr_adr,
  input wire [63:0]       wr_sin,
  input wire [63:0]       wr_cos,
  input wire [47:0]       wr_wnd,

  input wire [13:0]       in_A0,
  input wire [13:0]       in_A1,
  input wire [13:0]       in_A2,
  input wire [13:0]       in_A3,

  input wire [13:0]       in_B0,
  input wire [13:0]       in_B1,
  input wire [13:0]       in_B2,
  input wire [13:0]       in_B3,

  output reg              report,

  output wire [15:0]      amp_sin_A,
  output wire [15:0]      amp_cos_A,
  output wire [15:0]      amp_sin_B,
  output wire [15:0]      amp_cos_B,

  output wire [15:0]      amp_A,
  output wire [15:0]      amp_B,

  output wire [15:0]      phase_A,
  output wire [15:0]      phase_B
);

  reg                    conf;

  wire                   notify_sin_A;
  wire                   notify_cos_A;
  wire                   notify_sin_B;
  wire                   notifycos_B;

  wire [43:0]            out_sin_A;
  wire [43:0]            out_cos_A;
  wire [43:0]            out_sin_B;
  wire [43:0]            out_cos_B;
  
  reg                    sum_notify_A;
  reg                    sum_notify_B;

  reg  [43:0]            in_sin_A;
  reg  [43:0]            in_cos_A;
  reg  [43:0]            in_sin_B;
  reg  [43:0]            in_cos_B;

  wire                   amp_notify_A;
  reg                    amp_done_A;
  wire                   amp_notify_B;
  reg                    amp_done_B;

  wire                   phase_notify_A;
  reg                    phase_done_A;
  wire                   phase_notify_B;
  reg                    phase_done_B;

  reg                    coeff_en;
  reg                    coeff_wr;
  reg  [10:0]            coeff_adr;
  reg  [10:0]            wnd_adr;

  reg                    s1;
  reg                    s2;
  reg                    s3;
  reg                    s4;
  reg                    s5;

  reg                    w1;
  reg                    w2;
  reg                    w3;
  reg                    w4;
  reg                    w5;

  reg                    start_1;
  reg                    start_2;
  reg                    start_3;

  reg                    next_1;
  reg                    next_2;
  reg                    next_3;

  reg                    en_report;

  reg  [63:0]            sin_coeff_in;
  reg  [63:0]            cos_coeff_in;
  reg  [47:0]            wnd_coeff_in;

  wire [63:0]            sin_coeff_out;
  wire [63:0]            cos_coeff_out;
  wire [47:0]            wnd_coeff_out;

  wire [15:0]            sin_0;
  wire [15:0]            sin_1;
  wire [15:0]            sin_2;
  wire [15:0]            sin_3;

  assign sin_0 = sin_coeff_out[15:0];
  assign sin_1 = sin_coeff_out[31:16];
  assign sin_2 = sin_coeff_out[47:32];
  assign sin_3 = sin_coeff_out[63:48];

  wire [15:0]            cos_0;
  wire [15:0]            cos_1;
  wire [15:0]            cos_2;
  wire [15:0]            cos_3;

  assign cos_0 = cos_coeff_out[15:0];
  assign cos_1 = cos_coeff_out[31:16];
  assign cos_2 = cos_coeff_out[47:32];
  assign cos_3 = cos_coeff_out[63:48];

  wire [12:0]            wnd_0;
  wire [12:0]            wnd_1;
  wire [12:0]            wnd_2;
  wire [12:0]            wnd_3;

  assign wnd_0[11:0] = wnd_coeff_out[11:0];
  assign wnd_0[12] = 0;

  assign wnd_1[11:0] = wnd_coeff_out[23:12];
  assign wnd_1[12] = 0;

  assign wnd_2[11:0] = wnd_coeff_out[35:24];
  assign wnd_2[12] = 0;

  assign wnd_3[11:0] = wnd_coeff_out[47:36];
  assign wnd_3[12] = 0;

  wire [26:0]            p_A0;
  wire [26:0]            p_A1;
  wire [26:0]            p_A2;
  wire [26:0]            p_A3;

  wire [26:0]            p_B0;
  wire [26:0]            p_B1;
  wire [26:0]            p_B2;
  wire [26:0]            p_B3;

  reg  [63:0]            wnd_A;
  wire [15:0]            wnd_A0;
  wire [15:0]            wnd_A1;
  wire [15:0]            wnd_A2;
  wire [15:0]            wnd_A3;

  assign wnd_A0 = wnd_A[15:0];
  assign wnd_A1 = wnd_A[31:16];
  assign wnd_A2 = wnd_A[47:32];
  assign wnd_A3 = wnd_A[63:48];

  reg  [63:0]            wnd_B;
  wire [15:0]            wnd_B0;
  wire [15:0]            wnd_B1;
  wire [15:0]            wnd_B2;
  wire [15:0]            wnd_B3;

  assign wnd_B0 = wnd_B[15:0];
  assign wnd_B1 = wnd_B[31:16];
  assign wnd_B2 = wnd_B[47:32];
  assign wnd_B3 = wnd_B[63:48];
    
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

bram_wnd bram_wnd (
  .clka(clk),           // input wire clka
  .ena(coeff_en),       // input wire ena
  .wea(coeff_wr),       // input wire [0 : 0] wea
  .addra(wnd_adr),      // input wire [10 : 0] addra
  .dina(wnd_coeff_in),  // input wire [47 : 0] dina
  .douta(wnd_coeff_out) // output wire [47 : 0] douta
);

mult_14_13 mul_A0 (
  .CLK(clk),            // input wire CLK
  .A(in_A0),            // input wire [13 : 0] A
  .B(wnd_0),            // input wire [12 : 0] B
  .P(p_A0)              // output wire [26 : 0] P
);

mult_14_13 mul_A1 (
  .CLK(clk),            // input wire CLK
  .A(in_A1),            // input wire [13 : 0] A
  .B(wnd_1),            // input wire [12 : 0] B
  .P(p_A1)              // output wire [26 : 0] P
);

mult_14_13 mul_A2 (
  .CLK(clk),            // input wire CLK
  .A(in_A2),            // input wire [13 : 0] A
  .B(wnd_2),            // input wire [12 : 0] B
  .P(p_A2)              // output wire [26 : 0] P
);

mult_14_13 mul_A3 (
  .CLK(clk),            // input wire CLK
  .A(in_A3),            // input wire [13 : 0] A
  .B(wnd_3),            // input wire [12 : 0] B
  .P(p_A3)              // output wire [26 : 0] P
);

mult_14_13 mul_B0 (
  .CLK(clk),            // input wire CLK
  .A(in_B0),            // input wire [13 : 0] A
  .B(wnd_0),            // input wire [12 : 0] B
  .P(p_B0)              // output wire [26 : 0] P
);

mult_14_13 mul_B1 (
  .CLK(clk),            // input wire CLK
  .A(in_B1),            // input wire [13 : 0] A
  .B(wnd_1),            // input wire [12 : 0] B
  .P(p_B1)              // output wire [26 : 0] P
);

mult_14_13 mul_B2 (
  .CLK(clk),            // input wire CLK
  .A(in_B2),            // input wire [13 : 0] A
  .B(wnd_2),            // input wire [12 : 0] B
  .P(p_B2)              // output wire [26 : 0] P
);

mult_14_13 mul_B3 (
  .CLK(clk),            // input wire CLK
  .A(in_B3),            // input wire [13 : 0] A
  .B(wnd_3),            // input wire [12 : 0] B
  .P(p_B3)              // output wire [26 : 0] P
);

adc_slice sin_A (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(wnd_A),               // input wire [63 : 0] in
  .coeff(sin_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_sin_A),   // output wire [0 : 0] report
  .sum(out_sin_A)          // output wire [43 : 0] sum
);

adc_slice cos_A (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(wnd_A),               // input wire [63 : 0] in
  .coeff(cos_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_cos_A),   // output wire [0 : 0] report
  .sum(out_cos_A)          // output wire [43 : 0] sum
);

adc_slice sin_B (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(wnd_B),               // input wire [63 : 0] in
  .coeff(sin_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_sin_B),   // output wire [0 : 0] report
  .sum(out_sin_B)          // output wire [43 : 0] sum
);

adc_slice cos_B (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(wnd_B),              // input wire [63 : 0] in
  .coeff(cos_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_cos_B),   // output wire [0 : 0] report
  .sum(out_cos_B)          // output wire [43 : 0] sum
);

ana_amp amp_A_inst (
  .clk(clk),
  .reset(reset),
  .start(sum_notify_A),
  .count(count),
  .sin_sum(in_sin_A),
  .cos_sum(in_cos_A),
  .report(amp_notify_A),
  .amp_sin(amp_sin_A),
  .amp_cos(amp_cos_A),
  .amp(amp_A)
);

ana_amp amp_B_inst (
  .clk(clk),
  .reset(reset),
  .start(sum_notify_B),
  .count(count),
  .sin_sum(in_sin_B),
  .cos_sum(in_cos_B),
  .report(amp_notify_B),
  .amp_sin(amp_sin_B),
  .amp_cos(amp_cos_B),
  .amp(amp_B)
);

ana_phase ana_phase_A (
  .clk(clk),
  .reset(reset),
  .start(sum_notify_A),
  .sin_sum(in_sin_A),
  .cos_sum(in_cos_A),
  .report(phase_notify_A),
  .phase(phase_A)
);

ana_phase ana_phase_B (
  .clk(clk),
  .reset(reset),
  .start(sum_notify_B),
  .sin_sum(in_sin_B),
  .cos_sum(in_cos_B),
  .report(phase_notify_B),
  .phase(phase_B)
);

/*
ila_1 ila_1_inst (
  .clk(clk),                 // input wire clk
  .probe0(coeff_en),         // input wire [0:0]   probe
  .probe1(coeff_wr),         // input wire [0:0]   probe
  .probe2(coeff_adr),        // input wire [10:0]  probe
  .probe3(wnd_adr),          // input wire [10:0]  probe
  .probe4(validate),         // input wire [0:0]   probe
  .probe5(report),           // input wire [0:0]   probe
  .probe6(amp_sin_A),        // input wire [15:0]   probe
  .probe7(amp_cos_A),        // input wire [15:0]   probe
  .probe8(amp_A),            // input wire [15:0]   probe
  .probe9(amp_sin_B),        // input wire [15:0]   probe
  .probe10(amp_cos_B),       // input wire [15:0]   probe
  .probe11(amp_B),           // input wire [15:0]   probe
  .probe12(phase_A),         // input wire [15:0]   probe
  .probe13(phase_B)          // input wire [15:0]   probe
);
*/

generate
begin : ana_freq_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
      sum_notify_A <= 0;
    else
    begin
      if (en_report)
      begin
        if (notify_sin_A | notify_cos_A)
          sum_notify_A <= 1;
        else
          sum_notify_A <= 0;
      end
      else
        sum_notify_A <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      sum_notify_B <= 0;
    else
    begin
      if (en_report)
      begin
        if (notify_sin_B | notify_cos_B)
          sum_notify_B <= 1;
        else
          sum_notify_B <= 0;
      end
      else
        sum_notify_B <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      in_sin_A <= 0;
    else
      if (notify_sin_A)
        in_sin_A <= out_sin_A;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      in_cos_A <= 0;
    else
      if (notify_cos_A)
        in_cos_A <= out_cos_A;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      in_sin_B <= 0;
    else
      if (notify_sin_B)
        in_sin_B <= out_sin_B;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      in_cos_B <= 0;
    else
      if (notify_cos_B)
        in_cos_B <= out_cos_B;
  end

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      amp_done_A <= 0;
    else
    begin
      if (en_report)
      begin
        if (amp_notify_A)
          amp_done_A <= 1;
        else
          if (report)
            amp_done_A <= 0;
      end
      else
        amp_done_A <= 0;
    end
  end 

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      amp_done_B <= 0;
    else
    begin
      if (en_report)
      begin
        if (amp_notify_B)
          amp_done_B <= 1;
        else
          if (report)
            amp_done_B <= 0;
      end
      else
        amp_done_B <= 0;
    end
  end 

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      phase_done_A <= 0;
    else
    begin
      if (en_report)
      begin
        if (phase_notify_A)
          phase_done_A <= 1;
        else
          if (report)
            phase_done_A <= 0;
      end
      else
        phase_done_A <= 0;
    end    
  end 

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      phase_done_B <= 0;
    else
    begin
      if (en_report)
      begin
        if (phase_notify_B)
          phase_done_B <= 1;
        else
          if (report)
            phase_done_B <= 0;
      end
      else
        phase_done_B <= 0;
    end
  end 

  always @ ( posedge clk ) 
  begin
    if (amp_done_A & amp_done_B & phase_done_A & phase_done_B & !report)
      report <= 1;
    else
      report <= 0;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      coeff_wr <= 0;
    else
      coeff_wr <= wr;
  end

  always @ ( posedge clk ) 
  begin
    sin_coeff_in <= wr_sin;
    cos_coeff_in <= wr_cos;
    wnd_coeff_in <= wr_wnd;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      wnd_adr <= 0;
      w1 <= 0;
      s1 <= 0;
      en_report <= 0;
    end
    else
    begin
      if (start)
      begin
        wnd_adr <= 0;
        s1 <= 1;
        w1 <= 0;
        en_report <= 0;
      end
      else
      begin
        s1 <= 0;

        if (run)
        begin
          if (wnd_adr == last)
          begin
            wnd_adr <= 0;
            w1 <= 1;
            en_report <= 1;
          end
          else
          begin
            w1 <= 0;
            wnd_adr <= wnd_adr + 1;
          end
        end
        else
        begin
          w1 <= 0;

          if (conf)
            wnd_adr <= wr_adr;
          else
            wnd_adr <= 0;
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      coeff_en <= 0;
      coeff_adr <= 0;
    end
    else
    begin
      if (w5 | s5)
      begin
        coeff_adr <= 0;
        coeff_en <= 1;
      end
      else
      begin
        if (run)
          coeff_adr <= coeff_adr + 1;
        else
        begin
          if (conf)
          begin
            coeff_en <= 1;
            coeff_adr <= wr_adr;
          end
          else
          begin
            coeff_adr <= 0;
            coeff_en <= 0;
          end
        end
      end
    end
  end

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
      w2 <= 0;
      w3 <= 0;
      w4 <= 0;
      w5 <= 0;
    end
    else
    begin
      w2 <= w1;
      w3 <= w2;
      w4 <= w3;
      w5 <= w4;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (p_A0[9])
      wnd_A[15:0] <= p_A0[25:10] + 1;
    else
      wnd_A[15:0] <= p_A0[25:10];

    if (p_A1[9])
      wnd_A[31:16] <= p_A1[25:10] + 1;
    else
      wnd_A[31:16] <= p_A1[25:10];

    if (p_A2[9])
      wnd_A[47:32] <= p_A2[25:10] + 1;
    else
      wnd_A[47:32] <= p_A2[25:10];

    if (p_A3[9])
      wnd_A[63:48] <= p_A3[25:10] + 1;
    else
      wnd_A[63:48] <= p_A3[25:10];

    if (p_B0[9])
      wnd_B[15:0] <= p_B0[25:10] + 1;
    else
      wnd_B[15:0] <= p_B0[25:10];

    if (p_B1[9])
      wnd_B[31:16] <= p_B1[25:10] + 1;
    else
      wnd_B[31:16] <= p_B1[25:10];

    if (p_B2[9])
      wnd_B[47:32] <= p_B2[25:10] + 1;
    else
      wnd_B[47:32] <= p_B2[25:10];

    if (p_B3[9])
      wnd_B[63:48] <= p_B3[25:10] + 1;
    else
      wnd_B[63:48] <= p_B3[25:10];
  end

  always @ ( posedge clk ) 
  begin
    start_1 <= s5;
    start_2 <= start_1;
    start_3 <= start_2;
  end

  always @ ( posedge clk ) 
  begin
    next_1 <= w5;
    next_2 <= next_1;
    next_3 <= next_2;
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      run <= 0;
      conf <= 0;
    end
    else
    begin
      if (init)
      begin
        run <= 0;
        conf <= 1;
      end
      else
      begin
        if (start)
        begin
          run <= 1;
          conf <= 0;
        end
        else
        begin
          if (stop)
          begin
            run <= 0;
            conf <= 0;
          end
        end
      end
    end
  end

end

endgenerate

endmodule
