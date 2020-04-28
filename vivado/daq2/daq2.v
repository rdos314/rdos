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
// adc.v
// Top-level DAQ2 module
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module adc (
  output  [7:0]           pci_exp_txp,
  output  [7:0]           pci_exp_txn,
  input   [7:0]           pci_exp_rxp,
  input   [7:0]           pci_exp_rxn,

  input                   sw_w,
  input                   sw_e,

  output                  led_0,
  output                  led_1,
  output                  led_2,
  output                  led_3,
  output                  led_4,
  output                  led_5,
  output                  led_6,
  output                  led_7,

  input                   pci_ref_clk_p,
  input                   pci_ref_clk_n,
  input                   pci_rst_n
);


  wire                    pcie_ref_clk;
  wire                    pcie_rst_n;

  reg                     first;
  reg [1:0]               skip;
  reg                     started;
  reg [31:0]              adr;


  input wire                s_axis_tx_tready,
  output reg [127:0]        s_axis_tx_tdata,
  output reg [15:0]         s_axis_tx_tkeep,
  output reg                s_axis_tx_tlast,
  output reg                s_axis_tx_tvalid,
  output wire [3:0]         s_axis_tx_tuser,


  IBUF   pci_reset_n_ibuf (.O(pcie_rst_n), .I(pci_rst_n));
  IBUFDS_GTE2 pci_refclk_ibuf (.O(pcie_ref_clk), .ODIV2(), .I(pci_ref_clk_p), .CEB(1'b0), .IB(pci_ref_clk_n));


 //-----------------------------I/O BUFFERS------------------------//


  OBUF   led_0_obuf (.O(led_0), .I(started));
  OBUF   led_1_obuf (.O(led_1), .I(0));
  OBUF   led_2_obuf (.O(led_2), .I(0));
  OBUF   led_3_obuf (.O(led_3), .I(0));
  OBUF   led_4_obuf (.O(led_4), .I(0));
  OBUF   led_5_obuf (.O(led_5), .I(0));
  OBUF   led_6_obuf (.O(led_6), .I(0));
  OBUF   led_7_obuf (.O(led_7), .I(0));


generate
  begin : daq2

    always @ ( posedge pcie_ref_clk ) 
    begin
      if (pcie_rst_n)
      begin
        if (started)
        begin
          if (adr)
          begin
            if (first)
            begin
              first <= 0;
              skip <= skip + 1;

              if (skip == 2'b11)
              begin
                s_axis_tx_tvalid <= 0;
                s_axis_tx_tkeep <= 0;
                s_axis_tx_tlast <= 0;
                s_axis_tx_tdata <= 0;
              end
              else
              begin
                s_axis_tx_tvalid <= 1;
                s_axis_tx_tkeep[15:0] <= 16'hffff;
                s_axis_tx_tlast <= 0;

                s_axis_tx_tdata[127:96] <= adr;                   // address low
                s_axis_tx_tdata[95:64] <= 2;                      // address high
                s_axis_tx_tdata[63:48] <= 0;                      // Requester ID
                s_axis_tx_tdata[47:40] <= 0;                      // tag
                s_axis_tx_tdata[39:36] <= 4'b1111;                // last be
                s_axis_tx_tdata[35:32] <= 4'b1111;                // 1st be
                s_axis_tx_tdata[31:24] <= 8'b011_00000;           // Type + 64-bit FMT
                s_axis_tx_tdata[23] <= 1'b0;                      // R
                s_axis_tx_tdata[22:20] <= 3'b000;                 // TC
                s_axis_tx_tdata[19:16] <= 4'b0000;                // TH, AttrH, R
                s_axis_tx_tdata[15:12] <= 4'b0010;                // TD, EP, Attr
                s_axis_tx_tdata[11:10] <= 2'b0;                   // AT
                s_axis_tx_tdata[9:8] <= 2'b0;                     // len high
                s_axis_tx_tdata[7:0] <= 8'h20;                    // 128 byte size
              end
            end
            else
            begin
              adr[31:4] <= adr[31:4] + 1;

              if (skip != 2'b11)
              begin
                s_axis_tx_tdata <= 128'h0123456789abcdef0123456789abcdef;
                s_axis_tx_tkeep <= 16'hffff;
                s_axis_tx_tvalid <= 1;

                if (adr[6:4] == 3'b111)
                begin
                  first <= 1;
                  s_axis_tx_tlast <= 1;
                end
                else
                  s_axis_tx_tlast <= 0;
              end
            end
          end
          else
            started <= 0; 
        end
        else
        begin
          if (sw_w)
          begin
            started <= 1;
            adr <= 0;
            skip <= 0;
            first <= 1;
          end
        end
      end
      else
        started <= 0;
    end

  end

endgenerate
endmodule
