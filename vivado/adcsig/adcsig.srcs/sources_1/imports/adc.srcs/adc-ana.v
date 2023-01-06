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

module adc_ana (
  input wire              clk,
  input wire              reset,

  input wire              init,
  input wire [12:0]       count,
  input wire              start,
  input wire              stop,

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
  output reg [15:0]       power_A,
  output reg [15:0]       power_B,
  output reg [15:0]       phase_A,
  output reg [15:0]       phase_B
);

  wire                    b_report;
  wire [15:0]             b_power_A;
  wire [15:0]             b_power_B;
  wire [15:0]             b_phase_A;
  wire [15:0]             b_phase_B;

  wire                    d_report;
  wire [15:0]             d_power_A;
  wire [15:0]             d_power_B;
  wire [15:0]             d_phase_A;
  wire [15:0]             d_phase_B;

  reg                     base_run;
  reg  [9:0]              delay_count;
  reg  [9:0]              curr_count;
  reg                     delay_run;

  reg  [15:0]             phase_incr;

  reg                     base_wait;
  reg                     base_sync;
  reg                     base_update;
  reg  [15:0]             base_curr_phase_A;
  reg  [15:0]             base_curr_phase_B;

  reg                     delay_sync;
  reg                     delay_update;
  reg  [15:0]             delay_curr_phase_A;
  reg  [15:0]             delay_curr_phase_B;

ana_freq base (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(init),            // input wire init
  .count(count),          // input wire [12:0] count
  .run(base_run),         // input wire run
  .wr(wr),                // input wire wr
  .wr_adr(wr_adr),        // input wire [12:0] wr_adr
  .wr_sin(wr_sin),        // input wire [63:0] wr_sin
  .wr_cos(wr_cos),        // input wire [63:0] wr_cos
  .in_A0(in_A0),          // input wire [13:0] in_A0
  .in_A1(in_A1),          // input wire [13:0] in_A1
  .in_A2(in_A2),          // input wire [13:0] in_A2
  .in_A3(in_A3),          // input wire [13:0] in_A3
  .in_B0(in_B0),          // input wire [13:0] in_B0
  .in_B1(in_B1),          // input wire [13:0] in_B1
  .in_B2(in_B2),          // input wire [13:0] in_B2
  .in_B3(in_B3),          // input wire [13:0] in_B3
  .report(b_report),      // output wire report
  .power_A(b_power_A),    // output wire [15:0] power_A
  .power_B(b_power_B),    // output wire [15:0] power_B
  .phase_A(b_phase_A),    // output wire [15:0] phase_A
  .phase_B(b_phase_B)     // output wire [15:0] phase_B
);

ana_freq delayed (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(init),            // input wire init
  .count(count),          // input wire [12:0] count
  .run(delay_run),        // input wire run
  .wr(wr),                // input wire wr
  .wr_adr(wr_adr),        // input wire [12:0] wr_adr
  .wr_sin(wr_sin),        // input wire [63:0] wr_sin
  .wr_cos(wr_cos),        // input wire [63:0] wr_cos
  .in_A0(in_A0),          // input wire [13:0] in_A0
  .in_A1(in_A1),          // input wire [13:0] in_A1
  .in_A2(in_A2),          // input wire [13:0] in_A2
  .in_A3(in_A3),          // input wire [13:0] in_A3
  .in_B0(in_B0),          // input wire [13:0] in_B0
  .in_B1(in_B1),          // input wire [13:0] in_B1
  .in_B2(in_B2),          // input wire [13:0] in_B2
  .in_B3(in_B3),          // input wire [13:0] in_B3
  .report(d_report),      // output wire report
  .power_A(d_power_A),    // output wire [15:0] power_A
  .power_B(d_power_B),    // output wire [15:0] power_B
  .phase_A(d_phase_A),    // output wire [15:0] phase_A
  .phase_B(d_phase_B)     // output wire [15:0] phase_B
);

generate
begin : adc_bar_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      power_A <= 0;
      power_B <= 0;
      phase_A <= 0;
      phase_B <= 0;
      report <= 0;
      phase_incr <= 0;
      base_wait <= 0;
      base_sync <= 0;
      delay_sync <= 0;
      base_update <= 0;
      delay_update <= 0;
      base_curr_phase_A <= 0;
      base_curr_phase_B <= 0;
      delay_curr_phase_A <= 0;      
      delay_curr_phase_B <= 0;      
    end
    else
    begin
      if (start)
      begin
        base_wait <= 1;
        base_sync <= 0;
        delay_sync <= 1;
        base_update <= 0;
        delay_update <= 0;
      end
      else
      begin
        if (b_report)
        begin
          report <= 1;
          power_A <= b_power_A;
          power_B <= b_power_B;

          if (base_wait)
          begin
            base_curr_phase_A <= b_phase_A;
            base_curr_phase_B <= b_phase_B;
            base_wait <= 0;
            base_sync <= 1;
            phase_A <= 0;
            phase_B <= 0;
          end
          else
          begin
            base_update <= 1;
            base_wait <= 0;
            base_sync <= 0;

            if (base_sync)
            begin
              phase_incr <= b_phase_A - base_curr_phase_A;
              base_curr_phase_A <= b_phase_A;
              base_curr_phase_B <= b_phase_B;
              phase_A <= b_phase_A - base_curr_phase_A;
              phase_B <= b_phase_B - base_curr_phase_B;
            end 
            else
            begin         
              base_update <= 1;
              phase_A <= b_phase_A - base_curr_phase_A;
              phase_B <= b_phase_B - base_curr_phase_B;
            end
          end
        end
        else
        begin
          if (d_report)
          begin
            report <= 1;
            power_A <= d_power_A;
            power_B <= d_power_B;

            if (delay_sync)
            begin
              delay_sync <= 0;
              delay_curr_phase_A <= d_phase_A;
              delay_curr_phase_B <= d_phase_B;
              phase_A <= 0;
              phase_B <= 0;
            end 
            else
            begin         
              delay_update <= 1;
              phase_A <= d_phase_A - delay_curr_phase_A;
              phase_B <= d_phase_B - delay_curr_phase_B;
            end
          end
          else
          begin
            if (base_update)
            begin
              base_update <= 0;
              base_curr_phase_A <= base_curr_phase_A + phase_incr;
              base_curr_phase_B <= base_curr_phase_B + phase_incr;
            end
            if (delay_update)
            begin
              delay_update <= 0;
              delay_curr_phase_A <= delay_curr_phase_A + phase_incr;
              delay_curr_phase_B <= delay_curr_phase_B + phase_incr;
            end
          end 
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      delay_count <= 0;
      delay_run <= 0;
      curr_count <= 0;
    end
    else
    begin
      if (init)
      begin
        delay_run <= 0;
        curr_count <= 0;
        if (count[2])
          delay_count <= count[12:3] + 1;
        else
          delay_count <= count[12:3];          
      end
      else
      begin
        if (start)
        begin
          curr_count <= delay_count;
          delay_run <= 0;
        end
        else
        begin
          if (stop)
          begin
            curr_count <= 0;
            delay_run <= 0;
          end
          else
          begin
            if (curr_count)
            begin
              if (curr_count == 1)
                delay_run <= 1;
              else
                curr_count <= curr_count - 1;
            end
          end
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      base_run <= 0;
    else
    begin
      if (init)
        base_run <= 0;
      else
      begin
        if (start)
          base_run <= 1;
        else
        begin
          if (stop)
            base_run <= 0;
        end
      end
    end
  end


end

endgenerate

endmodule
