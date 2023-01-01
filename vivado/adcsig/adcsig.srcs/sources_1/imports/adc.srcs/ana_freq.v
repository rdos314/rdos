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

  input wire              en,
  input wire [12:0]       count,
  input wire              load,
  input wire              wr,
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

  output wire [15:0]      pow_A,
  output wire [15:0]      pow_B

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
  
  wire [31:0]            sin_A2;
  wire [31:0]            cos_A2;
  wire [31:0]            sin_B2;
  wire [31:0]            cos_B2;

  reg  [55:0]            in_A;
  reg  [55:0]            in_B;

  reg  [10:0]            adr;
  reg  [10:0]            last;
  reg  [3:0]             last_en;
  
  reg [4:0]              delay;
  
  reg                    input_done;
  
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
  .res(res_sin_A)        // output wire [15 : 0] sum
);

adc_slice cos_A (
  .clk(clk),             // input wire CLK
  .p7(pd7),              // input wire [0 : 0] p7
  .p8(pd8),              // input wire [0 : 0] p8
  .count(count),         // input wire [12 : 0] count
  .in(in_A),             // input wire [55 : 0] in
  .coeff(cos_coeff_out), // input wire [63 : 0] coeff
  .res(res_cos_A)        // output wire [15 : 0] sum
);

adc_slice sin_B (
  .clk(clk),             // input wire CLK
  .p7(pd7),              // input wire [0 : 0] p7
  .p8(pd8),              // input wire [0 : 0] p8
  .count(count),         // input wire [12 : 0] count
  .in(in_B),             // input wire [55 : 0] in
  .coeff(sin_coeff_out), // input wire [63 : 0] coeff
  .res(res_sin_B)        // output wire [15 : 0] sum
);

adc_slice cos_B (
  .clk(clk),             // input wire CLK
  .p7(pd7),              // input wire [0 : 0] p7
  .p8(pd8),              // input wire [0 : 0] p8
  .count(count),         // input wire [12 : 0] count
  .in(in_B),             // input wire [55 : 0] in
  .coeff(cos_coeff_out), // input wire [63 : 0] coeff
  .res(res_cos_B)        // output wire [15 : 0] sum
);

power power_A(
  .clk(clk),             // input wire clk
  .reset(reset),         // input wire reset
  .start(input_done),    // input wire start
  .in_sin(res_sin_A),    // input wire [15 : 0] sin
  .in_cos(res_cos_A),    // input wire [15 : 0] cos
  .res(pow_A)            // output wire [15:0] res
);

power power_B(
  .clk(clk),             // input wire clk
  .reset(reset),         // input wire reset
  .start(input_done),    // input wire start
  .in_sin(res_sin_B),    // input wire [15 : 0] sin
  .in_cos(res_cos_B),    // input wire [15 : 0] cos
  .res(pow_B)            // output wire [15:0] res
);

ila_0 ila_0_inst (
  .clk(clk),              // input wire clk
  .probe0(en),            // input wire [0:0]  probe0
  .probe1(load),          // input wire [0:0]  probe1
  .probe2(start),         // input wire [0:0]  probe2
  .probe3(running),       // input wire [0:0]  probe3
  .probe4(coeff_en),      // input wire [0:0]  probe3
  .probe5(coeff_adr),     // input wire [10:0]  probe3
  .probe6(last),          // input wire [0:0]  probe3
  .probe7(done),          // input wire [0:0]  probe3
  .probe8(delay),         // input wire [4:0]  probe3
  .probe9(res_sin_A),     // input wire [15:0]  probe3
  .probe10(res_cos_A),    // input wire [15:0]  probe3
  .probe11(res_sin_B),    // input wire [15:0]  probe3
  .probe12(res_cos_B),    // input wire [15:0]  probe3
  .probe13(pow_A),        // input wire [15:0]  probe3
  .probe14(pow_B)         // input wire [15:0]  probe3
);

generate
begin : ana_freq_gen

  always @ ( posedge clk ) 
  begin
    if (running)
    begin
      if (pd7)
      begin
        delay <= 5'b11000;
        input_done <= 0;
      end
      else
      begin
        if (delay)
        begin
          delay <= delay - 1;
          if (delay == 1)
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
      delay <= 0;
      input_done <= 0;
      skip <= 1;
    end
  end

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
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      coeff_en <= 0;
      coeff_wr <= 0;
      adr <= 0;
      last <= 0;
      start <= 0;
      running <= 0;
      pd1 <= 0;
    end
    else
    begin
      if (load)
      begin
        coeff_en <= 1;

        if (wr)
        begin
          adr <= adr + 1;
          coeff_adr <= adr;
          coeff_wr <= 1;

          if (adr == last)
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
        adr <= 0;

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
  
end

endgenerate

endmodule
