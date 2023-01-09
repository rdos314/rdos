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
  input wire [15:0]       wr_sin_0,
  input wire [15:0]       wr_cos_0,
  input wire [15:0]       wr_sin_1,
  input wire [15:0]       wr_cos_1,
  input wire [15:0]       wr_sin_2,
  input wire [15:0]       wr_cos_2,
  input wire [15:0]       wr_sin_3,
  input wire [15:0]       wr_cos_3,

  input wire [13:0]       in_A0,
  input wire [13:0]       in_A1,
  input wire [13:0]       in_A2,
  input wire [13:0]       in_A3,

  input wire [13:0]       in_B0,
  input wire [13:0]       in_B1,
  input wire [13:0]       in_B2,
  input wire [13:0]       in_B3,

  output reg              report,

  output wire [15:0]      amp_A,
  output wire [15:0]      amp_B,

  output wire [15:0]      phase_A,
  output wire [15:0]      phase_B
);

  reg                    start_1;
  reg                    start_2;
  reg                    start_3;
  reg                    next_1;
  reg                    next_2;
  reg                    next_3;

  reg  [10:0]            last;
  reg  [3:0]             last_en;

  wire                   notify_sin_A;
  wire                   notify_cos_A;
  wire                   notify_sin_B;
  wire                   notify_cos_B;

  wire [42:0]            out_sin_A;
  wire [42:0]            out_cos_A;
  wire [42:0]            out_sin_B;
  wire [42:0]            out_cos_B;
  
  reg                    sum_notify_A;
  reg                    sum_notify_B;

  reg  [42:0]            in_sin_A;
  reg  [42:0]            in_cos_A;
  reg  [42:0]            in_sin_B;
  reg  [42:0]            in_cos_B;

  wire                   amp_notify_A;
  reg                    amp_done_A;
  wire                   amp_notify_B;
  reg                    amp_done_B;

  wire                   phase_notify_A;
  reg                    phase_done_A;
  wire                   phase_notify_B;
  reg                    phase_done_B;

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

  wire [55:0]            in_A;
  wire [55:0]            in_B;
  
  assign in_A[13:0] = in_A0;
  assign in_A[27:14] = in_A1;
  assign in_A[41:28] = in_A2;
  assign in_A[55:42] = in_A3;

  assign in_B[13:0] = in_B0;
  assign in_B[27:14] = in_B1;
  assign in_B[41:28] = in_B2;
  assign in_B[55:42] = in_B3;
  
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
  .next(next_3),           // input wire [0 : 0] next
  .in(in_A),               // input wire [55 : 0] in
  .coeff(sin_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_sin_A),   // output wire [0 : 0] report
  .sum(out_sin_A)          // output wire [42 : 0] sum
);

adc_slice cos_A (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(in_A),               // input wire [55 : 0] in
  .coeff(cos_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_cos_A),   // output wire [0 : 0] report
  .sum(out_cos_A)          // output wire [42 : 0] sum
);

adc_slice sin_B (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(in_B),               // input wire [55 : 0] in
  .coeff(sin_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_sin_B),   // output wire [0 : 0] report
  .sum(out_sin_B)          // output wire [42 : 0] sum
);

adc_slice cos_B (
  .clk(clk),               // input wire CLK
  .reset(reset),           // input wire [0 : 0] reset
  .start(start_3),         // input wire [0 : 0] start
  .stop(stop),             // input wire [0 : 0] stop
  .next(next_3),           // input wire [0 : 0] next
  .in(in_B),               // input wire [55 : 0] in
  .coeff(cos_coeff_out),   // input wire [63 : 0] coeff
  .report(notify_cos_B),   // output wire [0 : 0] report
  .sum(out_cos_B)          // output wire [42 : 0] sum
);

ana_amp amp_A_inst (
  .clk(clk),
  .reset(reset),
  .start(sum_notify_A),
  .count(count),
  .sin_sum(in_sin_A),
  .cos_sum(in_cos_A),
  .report(amp_notify_A),
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


ila_0 ila_0_inst (
  .clk(clk),                 // input wire clk
  .probe0(start_1),          // input wire [0:0]  probe3
  .probe1(start_2),          // input wire [0:0]  probe3
  .probe2(start_3),          // input wire [0:0]  probe3
  .probe3(next_1),           // input wire [0:0]  probe3
  .probe4(next_2),           // input wire [0:0]  probe3
  .probe5(next_3),           // input wire [0:0]  probe3
  .probe6(notify_sin_A),     // input wire [0:0]  probe3
  .probe7(notify_cos_A),     // input wire [0:0]  probe3
  .probe8(notify_sin_B),     // input wire [0:0]  probe3
  .probe9(notify_cos_B),     // input wire [0:0]  probe3
  .probe10(amp_notify_A),    // input wire [0:0]  probe3
  .probe11(amp_notify_B),    // input wire [0:0]  probe3
  .probe12(amp_done_A),      // input wire [0:0]  probe3
  .probe13(amp_done_B),      // input wire [0:0]  probe3
  .probe14(phase_notify_A),  // input wire [0:0]  probe3
  .probe15(phase_notify_B),  // input wire [0:0]  probe3
  .probe16(phase_done_A),    // input wire [0:0]  probe3
  .probe17(phase_done_B),    // input wire [0:0]  probe3
  .probe18(amp_A),           // input wire [15:0]  probe3
  .probe19(amp_B),           // input wire [15:0]  probe3
  .probe20(phase_A),         // input wire [15:0]  probe3
  .probe21(phase_B),         // input wire [15:0]  probe3
  .probe22(report)           // input wire [0:0]  probe3
);

generate
begin : ana_freq_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
      sum_notify_A <= 0;
    else
    begin
      if (notify_sin_A | notify_cos_A)
        sum_notify_A <= 1;
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
      if (notify_sin_B | notify_cos_B)
        sum_notify_B <= 1;
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
      if (amp_notify_A)
        amp_done_A <= 1;
      else
        if (report)
          amp_done_A <= 0;
  end 

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      amp_done_B <= 0;
    else
      if (amp_notify_B)
        amp_done_B <= 1;
      else
        if (report)
          amp_done_B <= 0;
  end 

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      phase_done_A <= 0;
    else
      if (phase_notify_A)
        phase_done_A <= 1;
      else
        if (report)
          phase_done_A <= 0;
  end 

  always @ ( posedge clk ) 
  begin
    if (reset | start_3 | next_3)
      phase_done_B <= 0;
    else
      if (phase_notify_B)
        phase_done_B <= 1;
      else
        if (report)
          phase_done_B <= 0;
  end 

  always @ ( posedge clk ) 
  begin
    if (amp_done_A & amp_done_B & phase_done_A & phase_done_B)
      report <= 1;
    else
      report <= 0;
  end

  always @ ( posedge clk ) 
  begin
    start_1 <= start;
    start_2 <= start_1;
    start_3 <= start_2;
  end

  always @ ( posedge clk ) 
  begin
    if (coeff_adr == last)
      next_1 <= 1;
    else
      next_1 <= 0;

    next_2 <= next_1;
    next_3 <= next_2;
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
            sin_coeff_in[15:0] <= wr_sin_0;
            cos_coeff_in[15:0] <= wr_cos_0;
          end
          else            
          begin
            sin_coeff_in[15:0] <= 0;
            cos_coeff_in[15:0] <= 0;
          end

          if (last_en[1])
          begin
            sin_coeff_in[31:16] <= wr_sin_1;
            cos_coeff_in[31:16] <= wr_cos_1;
          end
          else            
          begin
            sin_coeff_in[31:16] <= 0;
            cos_coeff_in[31:16] <= 0;
          end

          if (last_en[2])
          begin
            sin_coeff_in[47:32] <= wr_sin_2;
            cos_coeff_in[47:32] <= wr_cos_2;
          end
          else            
          begin
            sin_coeff_in[47:32] <= 0;
            cos_coeff_in[47:32] <= 0;
          end

          if (last_en[3])
          begin
            sin_coeff_in[63:48] <= wr_sin_3;
            cos_coeff_in[63:48] <= wr_cos_3;
          end
          else            
          begin
            sin_coeff_in[63:48] <= 0;
            cos_coeff_in[63:48] <= 0;
          end
        end
        else
        begin
          sin_coeff_in[15:0] <= wr_sin_0;
          cos_coeff_in[15:0] <= wr_cos_0;
          sin_coeff_in[31:16] <= wr_sin_1;
          cos_coeff_in[31:16] <= wr_cos_1;
          sin_coeff_in[47:32] <= wr_sin_2;
          cos_coeff_in[47:32] <= wr_cos_2;
          sin_coeff_in[63:48] <= wr_sin_3;
          cos_coeff_in[63:48] <= wr_cos_3;
        end
      end
      else
      begin
        if (run)
        begin
          coeff_en <= 1;
          coeff_wr <= 0;

          if (start)
            coeff_adr <= 0;
          else
          begin
            if (coeff_adr == last)
              coeff_adr <= 0;
            else
              coeff_adr <= coeff_adr + 1;
          end
        end
        else
        begin
          coeff_en <= 0;
          coeff_wr <= 0;
          coeff_adr <= 0;
        end
      end
    end
  end
  
end

endgenerate

endmodule
