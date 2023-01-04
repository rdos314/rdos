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
  input wire              stop;

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

  output wire             report,
  output wire [15:0]      power_A,
  output wire [15:0]      power_B,
  output wire [15:0]      phase_A,
  output wire [15:0]      phase_B
);

  reg                     base_run;

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
  .report(report),        // output wire report
  .power_A(power_A),      // output wire [15:0] power_A
  .power_B(power_B),      // output wire [15:0] power_B
  .phase_A(phase_A),      // output wire [15:0] phase_A
  .phase_B(phase_B)       // output wire [15:0] phase_B
);

generate
begin : adc_bar_gen

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
