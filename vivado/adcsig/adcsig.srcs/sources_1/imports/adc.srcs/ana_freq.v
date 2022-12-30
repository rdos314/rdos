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

  input wire              en,
  input wire [12:0]       count,
  input wire              load,
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
  input wire [13:0]       in_B3
);

  reg                    start;
  reg                    running;
  reg                    coeff_en;
  reg                    coeff_wr;
  reg  [10:0]            coeff_adr;
  reg  [63:0]            sin_coeff_in;
  reg  [63:0]            cos_coeff_in;
  wire [63:0]            sin_coeff_out;
  wire [63:0]            cos_coeff_out;

  reg  [55:0]            in_A;
  reg  [55:0]            in_B;

  wire [42:0]            sum_sin_A;
  reg  [42:0]            prev_sin_A;

  reg  [10:0]            last;
  reg  [3:0]             last_en;

  reg  [10:0]            curr_count;
  reg                    skip;
  reg                    pd1;
  reg                    pd2;
  reg                    pd3;
  reg                    pd4;
  reg                    pd5;
  reg                    pd6;
  reg                    pd7;
  reg                    pd8;

  reg  [15:0]            errors;

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
  .clk(clk),             // input wire CLK
  .p7(pd7),              // input wire [0 : 0] p7
  .p8(pd8),              // input wire [0 : 0] p8
  .count(count),         // input wire [12 : 0] count
  .in(in_A),             // input wire [55 : 0] in
  .coeff(sin_coeff_out), // input wire [63 : 0] coeff
  .sum(sum_sin_A)        // output wire [42 : 0] sum
);

ila_0 ila_0_inst (
  .clk(clk),              // input wire clk
  .probe0(en),            // input wire [0:0]  probe0
  .probe1(load),          // input wire [0:0]  probe1
  .probe2(wr),            // input wire [0:0]  probe2
  .probe3(wr_adr),        // input wire [10:0]  probe3
  .probe4(wr_sin),        // input wire [63:0]  probe4
  .probe5(wr_cos),        // input wire [63:0]  probe5
  .probe6(start),         // input wire [0:0]  probe6
  .probe7(running),       // input wire [0:0]  probe7
  .probe8(coeff_en),      // input wire [0:0]  probe8
  .probe9(coeff_wr),      // input wire [0:0]  probe9
  .probe10(coeff_adr),    // input wire [10:0]  probe10
  .probe11(sin_coeff_in), // input wire [63:0]  probe11
  .probe12(cos_coeff_in), // input wire [63:0]  probe12
  .probe13(sin_coeff_out), // input wire [63:0]  probe13
  .probe14(cos_coeff_out), // input wire [63:0]  probe14
  .probe15(count),         // input wire [12:0]  probe15
  .probe16(last_en),       // input wire [3:0]  probe16
  .probe17(sum_sin_A),     // input wire [42:0]  probe17 
  .probe18(errors),        // input wire [15:0]  probe18
  .probe19(skip),          // input wire [0:0]  probe19
  .probe20(pd1),          // input wire [0:0]  probe20
  .probe21(pd2),          // input wire [0:0]  probe21
  .probe22(pd3),          // input wire [0:0]  probe22
  .probe23(pd4),          // input wire [0:0]  probe23
  .probe24(pd5),          // input wire [0:0]  probe24
  .probe25(pd6),          // input wire [0:0]  probe25
  .probe26(pd7)           // input wire [0:0]  probe26
);


generate
begin : ana_freq_gen


  always @ ( posedge clk ) 
  begin
    if (running)
    begin
      pd2 <= pd1;
      pd3 <= pd2;
      pd4 <= pd3;
      pd5 <= pd4;
      pd6 <= pd5;
      pd7 <= pd6;
      pd8 <= pd7;

      in_A[13:0] <= in_A0;
      in_A[27:14] <= in_A1;
      in_A[41:28] <= in_A2;
      in_A[55:42] <= in_A3;

      in_B[13:0] <= in_B0;
      in_B[27:14] <= in_B1;
      in_B[41:28] <= in_B2;
      in_B[55:42] <= in_B3;

      if (pd6)
         skip <= 0;
    end
    else
      skip <= 1;
  end

  always @ ( posedge clk ) 
  begin
    if (load)
    begin
      coeff_en <= 1;

      if (wr)
      begin
        coeff_adr <= wr_adr;
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

          start <= 1;
          running <= 1;
        end
        else
        begin
          sin_coeff_in <= wr_sin;
          cos_coeff_in <= wr_cos;
          start <= 0;
          running <= 0;
        end
      end
      else
      begin
        coeff_wr <= 0;
        start <= 0;
        running <= 0;
      end
    end
    else
    begin
      start <= 0;

      if (running)
      begin
        if (en)
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
          running <= 0;
          coeff_en <= 0;
          coeff_wr <= 0;
        end
      end
      else
      begin
        coeff_en <= 0;
        coeff_wr <= 0;

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
  
end

endgenerate

endmodule
