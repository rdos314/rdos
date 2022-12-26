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
  input wire              pci_reset,
  input wire              pci_clk,
  input wire              clk,

  input wire [13:0]       rd_address,
  input wire              rd,

  output reg [31:0]       rp_data,
  output reg              rp,

  input wire [13:0]       wr_address,
  input wire [31:0]       wr_data,
  input wire [3:0]        wr_be,
  input wire              wr
);

// Analysis

  reg  [11:0]            ana_adr;

  wire [15:0]            q_sin_0;
  wire [15:0]            q_cos_0;
  wire [15:0]            q_sin_1;
  wire [15:0]            q_cos_1;
  wire [15:0]            q_sin_2;
  wire [15:0]            q_cos_2;
  wire [15:0]            q_sin_3;
  wire [15:0]            q_cos_3;


// PCI domain

  reg   [3:0]            pci_en;
  reg                    pci_rd_pend;
  reg                    pci_rd;
  reg                    pci_wr_pend;
  reg   [3:0]            pci_wr;
  reg   [3:0]            pci_be;
  reg   [1:0]            pci_bank;
  reg  [11:0]            pci_adr;
  reg  [15:0]            pci_sin_in;
  reg  [15:0]            pci_cos_in;

  wire [15:0]            pci_sin_0;
  wire [15:0]            pci_cos_0;
  wire [15:0]            pci_sin_1;
  wire [15:0]            pci_cos_1;
  wire [15:0]            pci_sin_2;
  wire [15:0]            pci_cos_2;
  wire [15:0]            pci_sin_3;
  wire [15:0]            pci_cos_3;

bram_coeff sin_0_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[0]),        // input wire ena
  .wea(pci_wr[0]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_sin_in),      // input wire [15 : 0] dina
  .douta(pci_sin_0),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_sin_0)         // output wire [15 : 0] doutb
);

bram_coeff cos_0_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[0]),        // input wire ena
  .wea(pci_wr[0]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_cos_in),      // input wire [15 : 0] dina
  .douta(pci_cos_0),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_cos_0)         // output wire [15 : 0] doutb
);

bram_coeff sin_1_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[1]),        // input wire ena
  .wea(pci_wr[1]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_sin_in),      // input wire [15 : 0] dina
  .douta(pci_sin_1),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_sin_1)         // output wire [15 : 0] doutb
);

bram_coeff cos_1_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[1]),        // input wire ena
  .wea(pci_wr[1]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_cos_in),      // input wire [15 : 0] dina
  .douta(pci_cos_1),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_cos_1)         // output wire [15 : 0] doutb
);

bram_coeff sin_2_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[2]),        // input wire ena
  .wea(pci_wr[2]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_sin_in),      // input wire [15 : 0] dina
  .douta(pci_sin_2),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_sin_2)         // output wire [15 : 0] doutb
);

bram_coeff cos_2_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[2]),        // input wire ena
  .wea(pci_wr[2]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_cos_in),      // input wire [15 : 0] dina
  .douta(pci_cos_2),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_cos_2)         // output wire [15 : 0] doutb
);

bram_coeff sin_3_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[3]),        // input wire ena
  .wea(pci_wr[3]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_sin_in),      // input wire [15 : 0] dina
  .douta(pci_sin_3),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_sin_3)         // output wire [15 : 0] doutb
);

bram_coeff cos_3_inst (
  .clka(pci_clk),         // input wire clka
  .ena(pci_en[3]),        // input wire ena
  .wea(pci_wr[3]),        // input wire [0 : 0] wea
  .addra(pci_adr),        // input wire [11 : 0] addra
  .dina(pci_cos_in),      // input wire [15 : 0] dina
  .douta(pci_cos_3),      // output wire [15 : 0] douta
  .clkb(clk),             // input wire clkb
  .enb(0),                // input wire enb
  .web(0),                // input wire [0 : 0] web
  .addrb(q_adr),          // input wire [11 : 0] addrb
  .dinb(d0),              // input wire [15 : 0] dinb
  .doutb(q_cos_3)         // output wire [15 : 0] doutb
);

ila_0 ila_0_inst (
  .clk(pci_clk),          // input wire clk
  .probe0(rd_address),    // input wire [13:0]  probe0  
  .probe1(rd),            // input wire [0:0]  probe1 
  .probe2(rp_data),       // input wire [31:0]  probe2 
  .probe3(rp),            // input wire [0:0]  probe3 
  .probe4(wr_address),    // input wire [13:0]  probe4 
  .probe5(wr_data),       // input wire [31:0]  probe5 
  .probe6(wr_be),         // input wire [3:0]  probe6 
  .probe7(wr),            // input wire [0:0]  probe7 
  .probe8(pci_en),        // input wire [3:0]  probe8 
  .probe9(pci_rd_pend),   // input wire [0:0]  probe9 
  .probe10(pci_rd),       // input wire [0:0]  probe10 
  .probe11(pci_wr_pend),  // input wire [0:0]  probe11 
  .probe12(pci_wr),       // input wire [3:0]  probe12 
  .probe13(pci_be),       // input wire [3:0]  probe13 
  .probe14(pci_bank),     // input wire [1:0]  probe14 
  .probe15(pci_adr),      // input wire [11:0]  probe15 
  .probe16(pci_sin_in),   // input wire [15:0]  probe16 
  .probe17(pci_cos_in)    // input wire [15:0]  probe17
);

generate
begin : adc_bar_gen

  always @ ( posedge pci_clk ) 
  begin
    if (pci_rd)
    begin
      case (pci_bank)
        2'b00 : rp_data[15:0] <= pci_sin_0;
        2'b01 : rp_data[15:0] <= pci_sin_1;
        2'b10 : rp_data[15:0] <= pci_sin_2;
        2'b11 : rp_data[15:0] <= pci_sin_3;
      endcase

      case (pci_bank)
        2'b00 : rp_data[31:16] <= pci_cos_0;
        2'b01 : rp_data[31:16] <= pci_cos_1;
        2'b10 : rp_data[31:16] <= pci_cos_2;
        2'b11 : rp_data[31:16] <= pci_cos_3;
      endcase
      
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
      pci_en <= 4'b0000;
      pci_rd_pend <= 0;
      pci_wr_pend <= 0;
      pci_wr <= 4'b0000;
    end
    else
    begin    
      if (wr)
      begin
        pci_adr <= wr_address;
        pci_sin_in <= wr_data[15:0];
        pci_cos_in <= wr_data[31:16];
        pci_bank <= wr_address[1:0];

        case (wr_address[1:0])
          2'b00 : pci_en <= 4'b0001;
          2'b01 : pci_en <= 4'b0010;
          2'b10 : pci_en <= 4'b0100;
          2'b11 : pci_en <= 4'b1000;
        endcase
        
        if (wr_be == 4'b1111)
        begin
          pci_rd_pend <= 0;
          pci_wr_pend <= 0;
  
          case (wr_address[1:0])
            2'b00 : pci_wr <= 4'b0001;
            2'b01 : pci_wr <= 4'b0010;
            2'b10 : pci_wr <= 4'b0100;
            2'b11 : pci_wr <= 4'b1000;
          endcase
        end
        else
        begin
          pci_rd_pend <= 0;
          pci_wr_pend <= 1;
          pci_wr <= 4'b0000;
          pci_be <= wr_be;
        end
      end
      else
      begin
        if (rd)
        begin
          pci_bank <= rd_address[1:0];
          pci_wr <= 4'b0000;
          pci_adr <= rd_address;
          pci_rd_pend <= 1;
          pci_wr_pend <= 0;
  
          case (rd_address[1:0])
            2'b00 : pci_en <= 4'b0001;
            2'b01 : pci_en <= 4'b0010;
            2'b10 : pci_en <= 4'b0100;
            2'b11 : pci_en <= 4'b1000;
          endcase
        end
        else
        begin
          if (pci_wr_pend)
          begin
            if (!pci_be[0])
              case (pci_bank)
                2'b00 : pci_sin_in[7:0] <= pci_sin_0[7:0];
                2'b01 : pci_sin_in[7:0] <= pci_sin_1[7:0];
                2'b10 : pci_sin_in[7:0] <= pci_sin_2[7:0];
                2'b11 : pci_sin_in[7:0] <= pci_sin_3[7:0];
              endcase
      
            if (!pci_be[1])
              case (pci_bank)
                2'b00 : pci_sin_in[15:8] <= pci_sin_0[15:8];
                2'b01 : pci_sin_in[15:8] <= pci_sin_1[15:8];
                2'b10 : pci_sin_in[15:8] <= pci_sin_2[15:8];
                2'b11 : pci_sin_in[15:8] <= pci_sin_3[15:8];
              endcase
            
            if (!pci_be[2])
              case (pci_bank)
                2'b00 : pci_cos_in[7:0] <= pci_cos_0[7:0];
                2'b01 : pci_cos_in[7:0] <= pci_cos_1[7:0];
                2'b10 : pci_cos_in[7:0] <= pci_cos_2[7:0];
                2'b11 : pci_cos_in[7:0] <= pci_cos_3[7:0];
              endcase
            
            if (!pci_be[3])
              case (pci_bank)
                2'b00 : pci_cos_in[15:8] <= pci_cos_0[15:8];
                2'b01 : pci_cos_in[15:8] <= pci_cos_1[15:8];
                2'b10 : pci_cos_in[15:8] <= pci_cos_2[15:8];
                2'b11 : pci_cos_in[15:8] <= pci_cos_3[15:8];
              endcase
              
            pci_rd_pend <= 0;
            pci_wr_pend <= 0;

            case (pci_bank)
              2'b00 : pci_en <= 4'b0001;
              2'b01 : pci_en <= 4'b0010;
              2'b10 : pci_en <= 4'b0100;
              2'b11 : pci_en <= 4'b1000;
            endcase

            case (pci_bank)
              2'b00 : pci_wr <= 4'b0001;
              2'b01 : pci_wr <= 4'b0010;
              2'b10 : pci_wr <= 4'b0100;
              2'b11 : pci_wr <= 4'b1000;
            endcase
          end
          else
          begin
            pci_en <= 4'b0000;
            pci_rd_pend <= 0;
            pci_wr_pend <= 0;
            pci_wr <= 4'b0000;
          end
        end
      end
    end
  end

end

endgenerate

endmodule
