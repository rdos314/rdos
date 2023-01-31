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
  input wire [43:0]       sin_sum,
  input wire [43:0]       cos_sum,

  output wire             report,
  output wire [15:0]      amp
);

  reg                    run_div;
  reg                    save_div;
  reg                    temp_div;
  reg                    pend_div;
  
  reg                    sqrt_start;
  
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

  reg  [29:0]            divend_sin;
  reg  [17:0]            quot_sin;
  reg                    incr_sin;
  reg  [29:0]            div_sin;
  reg  [15:0]            temp_sin;
  reg                    temp_incr_sin;
  reg  [15:0]            amp_sin;

  reg  [29:0]            divend_cos;
  reg  [17:0]            quot_cos;
  reg                    incr_cos;
  reg  [29:0]            div_cos;
  reg  [15:0]            temp_cos;
  reg                    temp_incr_cos;
  reg  [15:0]            amp_cos;


mult_16_16 square_sin_inst (
  .CLK(clk),         // input wire CLK
  .A(amp_sin),       // input wire [15 : 0] A
  .B(amp_sin),       // input wire [15 : 0] B
  .P(sin_2)          // output wire [31 : 0] P
);

mult_16_16 square_cos_inst (
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
  .probe2(sin_sum),       // input wire [43:0]  probe2
  .probe3(cos_sum),       // input wire [43:0]  probe3
  .probe4(report),        // input wire [0:0]  probe3
  .probe5(run_div),       // input wire [0:0]  probe3
  .probe6(save_div),      // input wire [0:0]  probe3
  .probe7(temp_div),      // input wire [0:0]  probe3
  .probe8(pend_div),      // input wire [0:0]  probe3
  .probe9(sqrt_start),    // input wire [0:0]  probe3
  .probe10(amp),          // input wire [15:0]  probe3
  .probe11(amp_sin),      // input wire [15:0]  probe3
  .probe12(amp_cos),      // input wire [15:0]  probe3
  .probe13(sin_2),        // input wire [31:0]  probe3
  .probe14(cos_2),        // input wire [31:0]  probe3
  .probe15(amp_2),        // input wire [31:0]  probe3
  .probe16(p1),           // input wire [0:0]  probe3
  .probe17(p2),           // input wire [0:0]  probe3
  .probe18(p3),           // input wire [0:0]  probe3
  .probe19(p4),           // input wire [0:0]  probe3
  .probe20(p5),           // input wire [0:0]  probe3
  .probe21(mask),         // input wire [17:0]  probe3
  .probe22(curr),         // input wire [29:0]  probe3
  .probe23(sign_sin),     // input wire [0:0]  probe3
  .probe24(divend_sin),   // input wire [29:0]  probe3
  .probe25(quot_sin),     // input wire [17:0]  probe3
  .probe26(incr_sin),     // input wire [0:0]  probe3
  .probe27(div_sin),      // input wire [29:0]  probe3
  .probe28(temp_sin),     // input wire [15:0]  probe3
  .probe29(temp_incr_sin), // input wire [0:0]  probe3
  .probe30(sign_cos),     // input wire [0:0]  probe3
  .probe31(divend_cos),   // input wire [29:0]  probe3
  .probe32(quot_cos),     // input wire [17:0]  probe3
  .probe33(incr_cos),     // input wire [0:0]  probe3
  .probe34(div_cos),      // input wire [29:0]  probe3
  .probe35(temp_cos),     // input wire [15:0]  probe3
  .probe36(temp_incr_cos) // input wire [0:0]  probe3
);
*/

generate
begin : ana_amp_gen

  always @ ( posedge clk ) 
  begin
    if (reset)
      pend_div <= 0;
    else
    begin
      if (start)
      begin
        pend_div <= 1;

        if (sin_sum[43])
        begin
          incr_sin <= ~sin_sum[12];
          div_sin <= ~sin_sum[42:13];
        end
        else
        begin
          incr_sin <= sin_sum[12];
          div_sin <= sin_sum[42:13];
        end

        if (cos_sum[43])
        begin
          incr_cos <= ~sin_sum[12];
          div_cos <= ~cos_sum[42:13];
        end
        else
        begin
          incr_cos <= cos_sum[12];
          div_cos <= cos_sum[42:13];
        end
      end
      else
        pend_div <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      run_div <= 0;
      save_div <= 0;
    end
    else
    begin
      if (run_div)
      begin
        if (mask)
        begin
          save_div <= 0;

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
          save_div <= 1;
          run_div <= 0;
        end
      end
      else
      begin
        save_div <= 0;

        if (pend_div)
        begin
          run_div <= 1;

          mask[17] <= 1;
          mask[16:0] <= 0;

          curr[29:17] <= count;
          curr[16:0] <= 0;

          quot_sin[16:0] <= 0;
          quot_cos[16:0] <= 0;

          if (incr_sin)
            divend_sin <= div_sin + 1;
          else
            divend_sin <= div_sin;

          if (incr_cos)
            divend_cos <= div_cos + 1;
          else
            divend_cos <= div_cos;
        end
        else
          run_div <= 0;
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      temp_div <= 0;      
    else
    begin
      if (save_div)
      begin
        temp_div <= 1;

        temp_sin[15] <= 0;
        temp_sin[14:0] <= quot_sin[15:1];
        temp_incr_sin <= quot_sin[0];

        temp_cos[15] <= 0;  
        temp_cos[14:0] <= quot_cos[15:1];
        temp_incr_cos <= quot_cos[0];
      end
      else
        temp_div <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
      p1 <= 0;      
    else
    begin
      if (temp_div)
      begin
        p1 <= 1;
        
        if (temp_incr_sin)
          amp_sin <= temp_sin + 1;
        else
          amp_sin <= temp_sin;
        
        if (temp_incr_cos)
          amp_cos <= temp_cos + 1;
        else
          amp_cos <= temp_cos;
      end
      else
        p1 <= 0;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      p2 <= 0;
      p3 <= 0;
      p4 <= 0;
      p5 <= 0;
    end
    else
    begin
      p2 <= p1;
      p3 <= p2;
      p4 <= p3;
      p5 <= p4;
    end
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
