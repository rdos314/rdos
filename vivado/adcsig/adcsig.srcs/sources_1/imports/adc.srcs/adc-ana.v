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
  input wire              reset,
  input wire              pci_reset,
  input wire              pci_clk,
  input wire              clk,

  input wire [12:0]       rd_address,
  input wire              rd,

  output reg [31:0]       rp_data,
  output reg              rp,

  input wire [12:0]       wr_address,
  input wire [31:0]       wr_data,
  input wire [3:0]        wr_be,
  input wire              wr,

  output wire [15:0]      res_sin_A,
  output wire [15:0]      res_cos_A,
  output wire [15:0]      res_sin_B,
  output wire [15:0]      res_cos_B
);

// Analysis

  reg                    ana_on;
  reg                    ana_off;
  reg                    ana_en;
  reg                    ana_wr;
  reg                    ana_load;
  reg  [10:0]            ana_adr;
  reg  [10:0]            ana_last;
  reg  [12:0]            ana_count;
  reg  [63:0]            ana_sin;
  reg  [63:0]            ana_cos;

  reg                    bram_en;
  reg                    bram_wr;
  reg  [10:0]            bram_adr;
  reg  [10:0]            bram_last;
  reg  [127:0]           bram_data_in;
  wire [127:0]           bram_data_out;

  reg                    pd1;
  reg                    pd2;
  reg                    pd3;
  reg                    pd4;
  
  reg   [4:0]            delay;

  reg  [13:0]            q_A0;
  reg  [13:0]            q_A1;
  reg  [13:0]            q_A2;
  reg  [13:0]            q_A3;

  reg  [13:0]            q_B0;
  reg  [13:0]            q_B1;
  reg  [13:0]            q_B2;
  reg  [13:0]            q_B3;

  wire [15:0]            bram_0;
  wire [15:0]            bram_1;
  wire [15:0]            bram_2;
  wire [15:0]            bram_3;
  wire [15:0]            bram_4;
  wire [15:0]            bram_5;
  wire [15:0]            bram_6;
  wire [15:0]            bram_7;

  assign bram_0 = bram_data_out[15:0];
  assign bram_1 = bram_data_out[31:16];
  assign bram_2 = bram_data_out[47:32];
  assign bram_3 = bram_data_out[63:48];
  assign bram_4 = bram_data_out[79:64];
  assign bram_5 = bram_data_out[95:80];
  assign bram_6 = bram_data_out[111:96];
  assign bram_7 = bram_data_out[127:112];

// PCI domain

  reg                    pci_en;
  reg                    pci_rd;
  reg                    pci_wr;
  reg                    pci_rd_pend;
  reg                    pci_wr_pend;
  reg  [12:0]            pci_adr;
  reg  [31:0]            pci_in;
  wire [31:0]            pci_out;
  reg  [3:0]             pci_be;

bram_coeff bram_coeff_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en),           // input wire ena
  .wea(pci_wr),           // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [10 : 0] addra
  .dina(pci_in),          // input wire [31 : 0] dina
  .douta(pci_out),        // output wire [31 : 0] douta
  .clkb(clk),             // input wire clkb
  .rstb(reset),           // input wire rstb
  .enb(bram_en),          // input wire enb
  .web(bram_wr),          // input wire [0 : 0] web
  .addrb(bram_adr),       // input wire [10 : 0] addrb
  .dinb(bram_data_in),    // input wire [127 : 0] dinb
  .doutb(bram_data_out)   // output wire [127 : 0] doutb
);

ana_freq base (
  .clk(clk),              // input wire clk
  .reset(reset),          // input wire clk
  .en(ana_en),            // input wire en
  .count(ana_count),      // input wire [12:0] count
  .load(ana_load),        // input wire load
  .wr(ana_wr),            // input wire wr
  .wr_sin(ana_sin),       // input wire [63:0] wr_sin
  .wr_cos(ana_cos),       // input wire [63:0] wr_cos
  .in_A0(q_A0),           // input wire [13:0] in_A0
  .in_A1(q_A1),           // input wire [13:0] in_A1
  .in_A2(q_A2),           // input wire [13:0] in_A2
  .in_A3(q_A3),           // input wire [13:0] in_A3
  .in_B0(q_B0),           // input wire [13:0] in_B0
  .in_B1(q_B1),           // input wire [13:0] in_B1
  .in_B2(q_B2),           // input wire [13:0] in_B2
  .in_B3(q_B3),           // input wire [13:0] in_B3
  .res_sin_A(res_sin_A),  // input wire [15:0] res_sin_A
  .res_cos_A(res_cos_A),  // input wire [15:0] res_cos_A
  .res_sin_B(res_sin_B),  // input wire [15:0] res_sin_B
  .res_cos_B(res_cos_B)  // input wire [15:0] res_cos_B
);


ila_1 ila_1_inst (
  .clk(clk),               // input wire clk
  .probe0(reset),         // input wire [0:0]  probe0
  .probe1(ana_on),         // input wire [0:0]  probe0
  .probe2(ana_off),        // input wire [0:0]  probe1
  .probe3(ana_load),       // input wire [0:0]  probe1
  .probe4(ana_en)         // input wire [0:0]  probe2
);

generate
begin : adc_bar_gen

  always @ ( posedge pci_clk ) 
  begin
    if (pci_rd)
    begin
      rp_data <= pci_out;
      rp <= 1;
    end
    else
      rp <= 0;

    pci_rd <= pci_rd_pend;
  end

  always @ ( posedge pci_clk ) 
  begin
    if (pci_reset)
    begin
      pci_en <= 0;
      pci_rd_pend <= 0;
      pci_wr_pend <= 0;
      pci_wr <= 0;
    end
    else
    begin
      if (wr)
      begin
        pci_adr <= wr_address;
        pci_in <= wr_data;

        if (wr_be == 4'b1111)
        begin
          pci_en <= 1;
          pci_rd_pend <= 0;
          pci_wr_pend <= 0;
          pci_wr <= 1;
        end
        else
        begin
          pci_en <= 1;
          pci_rd_pend <= 0;
          pci_wr_pend <= 1;
          pci_wr <= 0;
          pci_be <= wr_be;
        end
      end
      else
      begin
        if (rd)
        begin
          pci_adr <= rd_address;
          pci_en <= 1;
          pci_rd_pend <= 1;
          pci_wr_pend <= 0;
          pci_wr <= 0;
        end
        else
        begin
          if (pci_wr_pend)
          begin
            if (!pci_be[0])
              pci_in[7:0] <= pci_out[7:0];
              
            if (!pci_be[1])
              pci_in[15:8] <= pci_out[15:8];
            
            if (!pci_be[2])
              pci_in[23:16] <= pci_out[23:16];
            
            if (!pci_be[3])
              pci_in[31:24] <= pci_out[31:24];
              
            pci_en <= 1;
            pci_rd_pend <= 0;
            pci_wr_pend <= 0;
            pci_wr <= 1;
          end
          else
          begin
            pci_en <= 0;
            pci_rd_pend <= 0;
            pci_wr_pend <= 0;
            pci_wr <= 0;
          end
        end
      end
    end
  end

  always @ ( posedge clk ) 
  begin
    if (ana_on)
    begin
      if (delay)
        delay <= delay - 1;
      else
      begin
        if (q_A0[13])
        begin
          delay <= 3;
          q_A0 <= 14'b01111111111111;
          q_A1 <= 14'b01111111111111;
          q_A2 <= 14'b01111111111111;
          q_A3 <= 14'b01111111111111;

          q_B0 <= 14'b10000000000001;
          q_B1 <= 14'b10000000000001;
          q_B2 <= 14'b10000000000001;
          q_B3 <= 14'b10000000000001;
        end
        else
        begin
          if (q_A3[13])
          begin
            delay <= 3;
            q_A0 <= 14'b10000000000001;
            q_A1 <= 14'b10000000000001;
            q_A2 <= 14'b10000000000001;
            q_A3 <= 14'b10000000000001;

            q_B0 <= 14'b01111111111111;
            q_B1 <= 14'b01111111111111;
            q_B2 <= 14'b01111111111111;
            q_B3 <= 14'b01111111111111;
          end
          else
          begin
            delay <= 0;
            q_A0 <= 14'b01111111111111;
            q_A1 <= 14'b01111111111111;
            q_A2 <= 14'b10000000000001;
            q_A3 <= 14'b10000000000001;

            q_B0 <= 14'b10000000000001;
            q_B1 <= 14'b10000000000001;
            q_B2 <= 14'b01111111111111;
            q_B3 <= 14'b01111111111111;
          end
        end
      end
    end
    else
    begin
      q_A0 <= 14'b01111111111111;
      q_A1 <= 14'b01111111111111;
      q_A2 <= 14'b01111111111111;
      q_A3 <= 14'b01111111111111;

      q_B0 <= 14'b10000000000001;
      q_B1 <= 14'b10000000000001;
      q_B2 <= 14'b10000000000001;
      q_B3 <= 14'b10000000000001;
      
      delay <= 3;
    end
  end

  always @ ( posedge clk ) 
  begin
    if (reset)
    begin
      bram_en <= 0;
      bram_wr <= 0;
      ana_en <= 0;
      ana_load <= 0;
      ana_on <= 0;
      ana_off <= 0;
      ana_count <= 0;
      bram_adr <= 0;
      pd1 <= 0;
    end
    else
    begin
      bram_en <= 1;
      bram_wr <= 0;

      if (ana_load)
      begin
        ana_en <= 1;

        if (pd3)
        begin
          ana_sin[15:0] <= bram_0;
          ana_cos[15:0] <= bram_1;
          ana_sin[31:16] <= bram_2;
          ana_cos[31:16] <= bram_3;
          ana_sin[47:32] <= bram_4;
          ana_cos[47:32] <= bram_5;
          ana_sin[63:48] <= bram_6;
          ana_cos[63:48] <= bram_7;

          if (ana_adr == ana_last)
            bram_adr <= 0;
          else
            bram_adr <= bram_adr + 1;
     
          pd1 <= 1;
          ana_wr <= 1;
        end
        else
        begin
          pd1 <= 0;
          ana_wr <= 0;
        end

        if (pd4)
        begin
          ana_adr <= ana_adr + 1;
          if (ana_adr == ana_last)
            ana_load <= 0;
        end

      end
      else
      begin
        ana_wr <= 0;

        if (ana_on)
        begin
          pd1 <= 0;

          if (ana_count != bram_data_out[12:0])
          begin
            ana_en <= 0;
            ana_on <= 0;
            ana_off <= 1;
          end
        end
        else
        begin
          ana_adr <= 0;

          if (ana_off)
          begin
            ana_en <= 0;

            ana_count <= bram_data_out[12:0];
            if (ana_count[12:4] != 0)
            begin
              if (ana_count[1:0] == 0)
                ana_last <= ana_count[12:2] - 1;
              else
                ana_last <= ana_count[12:2];

              ana_off <= 0;
              bram_adr <= 1;
              ana_load <= 1;
              pd1 <= 1;
            end
            else
              pd1 <= 0;
          end
          else
          begin
            bram_adr <= 0;

            if (pd3)
            begin
              if (ana_en)
                ana_on <= 1;
              else
                ana_off <= 1;
            end
            else
            begin
              if (pd1 || pd2)
                pd1 <= 0;
              else
                pd1 <= 1;
            end
          end
        end
      end
    end

    pd2 <= pd1;
    pd3 <= pd2;
    pd4 <= pd3;
  end

end

endgenerate

endmodule
