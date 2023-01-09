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
// ana_phase.v
// Phase slice 
//
////////////////////////////////////////////////////////////////////////////////

module ana_phase (
  input wire              clk,
  input wire              reset,

  input wire              start,
  input wire [42:0]       sin_sum,
  input wire [42:0]       cos_sum,

  output reg              report,
  output reg [15:0]       phase
);

  reg                     run_rot;
  reg                     rot_done;
  reg                     run_atan;
  reg                     pend_atan;
  reg                     start_atan;
  wire                    phase_done;
  reg  [42:0]             phase_sin;
  reg  [42:0]             phase_cos;
  reg  [47:0]             phase_atan;
  wire [23:0]             cordic_phase;

ana_atan atan (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(start_atan),              // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tready(),                        // output wire s_axis_cartesian_tready
  .s_axis_cartesian_tdata(phase_atan),               // input wire [47 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(phase_done),                   // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(cordic_phase)                   // output wire [23 : 0] m_axis_dout_tdata
);

generate
begin : ana_phase_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
      rot_done <= 0;
    else
    begin
      if (start)
      begin
        phase_sin <= sin_sum;
        phase_cos <= cos_sum;
        rot_done <= 0;
      end
      else
      begin
        if (phase_sin[42] == phase_sin[41])
        begin
          if (phase_cos[42] == phase_cos[41])
          begin
            phase_sin[42:1] <= phase_sin[41:0];
            phase_sin[0] <= 0;
            phase_cos[42:1] <= phase_cos[41:0];
            phase_cos[0] <= 0;
          end
          else
            rot_done <= 1;
        end
        else
          rot_done <= 1;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      run_rot <= 0;
      pend_atan <= 0;
    end
    else
    begin
      if (start)
      begin
        run_rot <= 1;
        pend_atan <= 0;
      end
      else
      begin
        if (run_rot & rot_done)
        begin
          run_rot <= 0;
          pend_atan <= 1;
        end
        else
          pend_atan <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      run_atan <= 0;
      start_atan <= 0;
      report <= 0;
    end
    else
    begin
      if (pend_atan)
      begin
        phase_atan[22:0] <= phase_sin[42:20];
        phase_atan[23] <= phase_sin[42];
        phase_atan[46:24] <= phase_cos[42:20];
        phase_atan[47] <= phase_cos[42];
        start_atan <= 1;
        run_atan <= 1;
        report <= 0;
      end
      else
      begin
        if (run_atan)
        begin
          start_atan <= 0;
          if (phase_done)
          begin
            run_atan <= 0;
            report <= 1;
            phase <= cordic_phase[21:6];
          end
        end
        else
          report <= 0;
      end
    end
  end

end

endgenerate

endmodule
