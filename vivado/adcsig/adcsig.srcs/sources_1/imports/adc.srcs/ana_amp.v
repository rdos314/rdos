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
// ana_amp.v
// Amplitude calculator
//
////////////////////////////////////////////////////////////////////////////////

module ana_amp (
  input wire              clk,
  input wire              reset,

  input wire              start,
  input wire [12:0]       count,
  input wire [42:0]       sin_sum,
  input wire [42:0]       cos_sum,

  output wire             report,
  output wire [15:0]      amp
);

  reg                    run_div;
  reg                    save_div;
  
  reg                    sqrt_start;
  
  reg  [15:0]            amp_sin;
  reg  [15:0]            amp_cos;

  wire [31:0]            sin_2;
  wire [31:0]            cos_2;
  reg  [31:0]            amp_2;

  reg                    p1;
  reg                    p2;
  reg                    p3;
  reg                    p4;
  reg                    p5;

  reg  [17:0]            mask;
  reg  [29:0]            curr;

  reg                    sign_sin;
  reg  [29:0]            divend_sin;
  reg  [17:0]            quot_sin;

  reg                    sign_cos;
  reg  [29:0]            divend_cos;
  reg  [17:0]            quot_cos;

square square_sin_inst (
  .CLK(clk),         // input wire CLK
  .A(amp_sin),       // input wire [15 : 0] A
  .B(amp_sin),       // input wire [15 : 0] B
  .P(sin_2)          // output wire [31 : 0] P
);

square square_cos_inst (
  .CLK(clk),         // input wire CLK
  .A(amp_cos),       // input wire [15 : 0] A
  .B(amp_cos),       // input wire [15 : 0] B
  .P(cos_2)          // output wire [31 : 0] P
);

ana_sqrt sqrt_inst (
  .aclk(clk),                                        // input wire aclk
  .s_axis_cartesian_tvalid(sqrt_start),              // input wire s_axis_cartesian_tvalid
  .s_axis_cartesian_tdata(amp_2),                    // input wire [31 : 0] s_axis_cartesian_tdata
  .m_axis_dout_tvalid(report),                       // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(amp)                            // output wire [15 : 0] m_axis_dout_tdata
);

/*
ila_0 ila_0_inst (
  .clk(clk),              // input wire clk
  .probe0(start),         // input wire [0:0]  probe0
  .probe1(count),         // input wire [12:0]  probe1
  .probe2(sin_sum),       // input wire [42:0]  probe2
  .probe3(cos_sum),       // input wire [42:0]  probe3
  .probe4(report),        // input wire [0:0]  probe3
  .probe5(run_div),       // input wire [0:0]  probe3
  .probe6(save_div),      // input wire [0:0]  probe3
  .probe7(amp),           // input wire [15:0]  probe3
  .probe8(amp_sin),       // input wire [15:0]  probe3
  .probe9(amp_cos),       // input wire [15:0]  probe3
  .probe10(sin_2),         // input wire [31:0]  probe3
  .probe11(cos_2),         // input wire [31:0]  probe3
  .probe12(amp_2),        // input wire [31:0]  probe3
  .probe13(p1),           // input wire [0:0]  probe3
  .probe14(p2),           // input wire [0:0]  probe3
  .probe15(p3),           // input wire [0:0]  probe3
  .probe16(p4),           // input wire [0:0]  probe3
  .probe17(p5),           // input wire [0:0]  probe3
  .probe18(mask),         // input wire [17:0]  probe3
  .probe19(curr),         // input wire [29:0]  probe3
  .probe20(sign_sin),     // input wire [0:0]  probe3
  .probe21(divend_sin),   // input wire [29:0]  probe3
  .probe22(quot_sin),     // input wire [17:0]  probe3
  .probe23(sign_cos),     // input wire [0:0]  probe3
  .probe24(divend_cos),   // input wire [29:0]  probe3
  .probe25(quot_cos)      // input wire [17:0]  probe3
);
*/

generate
begin : ana_amp_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      run_div <= 0;
      save_div <= 0;
    end
    else
    begin
      if (start)
      begin
        run_div <= 1;

        mask[17] <= 1;
        mask[16:0] <= 0;

        curr[29:17] <= count;
        curr[16:0] <= 0;

        quot_sin[16:0] <= 0;

        if (sin_sum[42])
        begin
          sign_sin <= 1;
          divend_sin <= (~sin_sum[41:12]) + 1;
        end
        else
        begin
          sign_sin <= 0;
          divend_sin <= sin_sum[41:12];
        end

        quot_cos[16:0] <= 0;

        if (cos_sum[42])
        begin
          sign_cos <= 1;
          divend_cos <= (~cos_sum[41:12]) + 1;
        end
        else
        begin
          sign_cos <= 0;
          divend_cos <= cos_sum[41:12];
        end
      end
      else
      begin
        if (run_div)
        begin
          save_div <= 0;

          if (mask)
          begin
            if (divend_sin >= curr)
            begin
              divend_sin <= divend_sin - curr;
              quot_sin <= quot_sin | mask;
            end

            if (divend_cos >= curr)
            begin
              divend_cos <= divend_cos - curr;
              quot_cos <= quot_cos | mask;
            end

            curr <= curr >> 1;
            mask <= mask >> 1;
          end
          else
          begin
            run_div <= 0;
            save_div <= 1;
          end
        end
        else
          save_div <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      p1 <= 0;      
    else
    begin
      if (save_div)
      begin
        p1 <= 1;
        amp_sin[15] <= sign_sin;

        if (sign_sin)
        begin
          if (quot_sin[0])
            amp_sin[14:0] <= ~quot_sin[15:1];
          else
            amp_sin[14:0] <= (~quot_sin[15:1]) + 1;
        end
        else
        begin
          if (quot_sin[0])
            amp_sin[14:0] <= quot_sin[15:1] + 1;
          else
            amp_sin[14:0] <= quot_sin[15:1];
        end

        amp_cos[15] <= sign_cos;

        if (sign_cos)
        begin
          if (quot_cos[0])
            amp_cos[14:0] <= ~quot_cos[15:1];
          else
            amp_cos[14:0] <= (~quot_cos[15:1]) + 1;
        end
        else
        begin
          if (quot_cos[0])
            amp_cos[14:0] <= quot_cos[15:1] + 1;
          else
            amp_cos[14:0] <= quot_cos[15:1];
        end
      end
      else
        p1 <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    p2 <= p1;
    p3 <= p2;
    p4 <= p3;
    p5 <= p4;
  end

  always @ ( posedge clk ) 
  begin
    if (p5)
    begin
      sqrt_start <= 1;
      amp_2 <= sin_2 + cos_2;
    end
    else
      sqrt_start <= 0;
  end

end

endgenerate

endmodule
