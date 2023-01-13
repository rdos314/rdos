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
  input wire              pci_clk,

  input wire              init,
  input wire [12:0]       count,
  input wire [10:0]       last,

  input wire              start,
  input wire [15:0]       phase_incr,
  input wire [9:0]        delay_count,
  input wire [15:0]       delay_phase,

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

  output wire             empty,
  input wire              rd,
  output wire [15:0]      amp_A,
  output wire [15:0]      amp_B,
  output wire [15:0]      phase_A,
  output wire [15:0]      phase_B
);

// pci domain

  wire [63:0]             sig_out;

  assign amp_A = sig_out[15:0];
  assign amp_B = sig_out[31:16];
  assign phase_A = sig_out[47:32];
  assign phase_B = sig_out[63:48];

// rx domain

  reg                     report;
  reg  [63:0]             sig_in;

  wire [15:0]             sig_amp_A;
  wire [15:0]             sig_amp_B;
  wire [15:0]             sig_phase_A;
  wire [15:0]             sig_phase_B;

  assign sig_amp_A = sig_in[15:0];
  assign sig_amp_B = sig_in[31:16];
  assign sig_phase_A = sig_in[47:32];
  assign sig_phase_B = sig_in[63:48];

  wire                    b_report;
  wire [15:0]             b_amp_A;
  wire [15:0]             b_amp_B;
  wire [15:0]             b_phase_A;
  wire [15:0]             b_phase_B;

  wire                    d_report;
  wire [15:0]             d_amp_A;
  wire [15:0]             d_amp_B;
  wire [15:0]             d_phase_A;
  wire [15:0]             d_phase_B;

  reg                     base_start;
  reg  [9:0]              curr_count;
  reg                     delay_start;

  reg                     base_update;
  reg  [15:0]             base_curr_phase;

  reg                     delay_update;
  reg  [15:0]             delay_curr_phase;


fifo_signal signal_inst (
  .rst(reset),              // input wire rst
  .wr_clk(rx_clk),          // input wire wr_clk
  .rd_clk(pci_clk),         // input wire rd_clk
  .din(sig_in),             // input wire [63 : 0] din
  .wr_en(report),           // input wire wr_en
  .rd_en(rd),               // input wire rd_en
  .dout(sig_out),           // output wire [63 : 0] dout
  .full(),                  // output wire full
  .empty(),                 // output wire empty
  .prog_empty(empty)        // output wire empty
);


ana_freq base (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(init),            // input wire init
  .count(count),          // input wire [12:0] count
  .last(last),            // input wire [10:0] last
  .start(base_start),     // input wire start
  .stop(stop),            // input wire stop
  .wr(wr),                // input wire wr
  .wr_adr(wr_adr),        // input wire [10:0] wr_adr
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
  .amp_A(b_amp_A),        // output wire [15:0] amp_A
  .amp_B(b_amp_B),        // output wire [15:0] amp_B
  .phase_A(b_phase_A),    // output wire [15:0] phase_A
  .phase_B(b_phase_B)     // output wire [15:0] phase_B
);

ana_freq delayed (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .init(init),            // input wire init
  .count(count),          // input wire [12:0] count
  .last(last),            // input wire [10:0] last
  .start(delay_start),    // input wire start
  .stop(stop),            // input wire stop
  .wr(wr),                // input wire wr
  .wr_adr(wr_adr),        // input wire [10:0] wr_adr
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
  .amp_A(d_amp_A),        // output wire [15:0] amp_A
  .amp_B(d_amp_B),        // output wire [15:0] amp_B
  .phase_A(d_phase_A),    // output wire [15:0] phase_A
  .phase_B(d_phase_B)     // output wire [15:0] phase_B
);

ila_0 ila_0_inst (
  .clk(clk),                 // input wire clk
  .probe0(report),           // input wire [0:0]  probe3
  .probe1(sig_amp_A),        // input wire [15:0]  probe3
  .probe2(sig_amp_B),        // input wire [15:0]  probe3
  .probe3(sig_phase_A),      // input wire [15:0]  probe3
  .probe4(sig_phase_B),      // input wire [15:0]  probe3
  .probe5(b_report),         // input wire [0:0]  probe3
  .probe6(b_amp_A),          // input wire [15:0]  probe3
  .probe7(b_amp_B),          // input wire [15:0]  probe3
  .probe8(b_phase_A),        // input wire [15:0]  probe3
  .probe9(b_phase_B),        // input wire [15:0]  probe3
  .probe10(d_report),        // input wire [0:0]  probe3
  .probe11(d_amp_A),         // input wire [15:0]  probe3
  .probe12(d_amp_B),         // input wire [15:0]  probe3
  .probe13(d_phase_A),       // input wire [15:0]  probe3
  .probe14(d_phase_B),       // input wire [15:0]  probe3
  .probe15(base_start),      // input wire [0:0]  probe3
  .probe16(curr_count),      // input wire [9:0]  probe3
  .probe17(delay_start),     // input wire [0:0]  probe3
  .probe18(base_update),     // input wire [0:0]  probe3
  .probe19(base_curr_phase), // input wire [15:0]  probe3
  .probe20(delay_update),    // input wire [0:0]  probe3
  .probe21(delay_curr_phase) // input wire [15:0]  probe3
);

generate
begin : adc_ana_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
      base_curr_phase <= 0;
    else
    begin
      if (base_update)
        base_curr_phase <= base_curr_phase + phase_incr;
      else
      begin
        if (start)
          base_curr_phase <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      delay_curr_phase <= 0;      
    else
    begin
      if (delay_update)
        delay_curr_phase <= delay_curr_phase + phase_incr;
      else
      begin
        if (start)
          delay_curr_phase <= delay_phase;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      report <= 0;
      base_update <= 0;
      delay_update <= 0;
    end
    else
    begin
      if (b_report)
      begin
        base_update <= 1;
        delay_update <= 0;
        report <= 1;

        sig_in[15:0] <= b_amp_A;
        sig_in[31:16] <= b_amp_B;

        sig_in[47:32] <= b_phase_A - base_curr_phase;
        sig_in[63:48] <= b_phase_B - base_curr_phase;
      end
      else
      begin
        if (d_report)
        begin
          base_update <= 0;
          delay_update <= 1;
          report <= 1;

          sig_in[15:0] <= d_amp_A;
          sig_in[31:16] <= d_amp_B;
        
          sig_in[47:32] <= d_phase_A - delay_curr_phase;
          sig_in[63:48] <= d_phase_B - delay_curr_phase;
        end
        else
        begin
          base_update <= 0;
          delay_update <= 0;
          report <= 0;
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      delay_start <= 0;
      curr_count <= 0;
    end
    else
    begin
      if (start)
      begin
        curr_count <= delay_count;
        delay_start <= 0;
      end
      else
      begin
        if (curr_count)
        begin
          curr_count <= curr_count - 1;
          if (curr_count == 1)
            delay_start <= 1;
          else
            delay_start <= 0;
        end
        else
          delay_start <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (start)
      base_start <= 1;
    else
      base_start <= 0;
  end

end

endgenerate

endmodule
