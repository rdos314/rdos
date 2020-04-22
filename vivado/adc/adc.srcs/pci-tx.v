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
// pci_tx.v
// PCIe transmit interface
//
////////////////////////////////////////////////////////////////////////////////

module pci_tx (
  input                     clk,
  input                     reset,

  input wire                s_axis_tx_tready,
  output reg [127:0]        s_axis_tx_tdata,
  output reg [15:0]         s_axis_tx_tkeep,
  output reg                s_axis_tx_tlast,
  output reg                s_axis_tx_tvalid,
  output wire [3:0]         s_axis_tx_tuser,

  input  wire [127:0]       bar_data,
  input  wire [127:0]       bar_header,
  input  wire               bar_wr,
  output wire               bar_busy,

  output reg                adc_next_address,
  input wire                adc_valid_address,
  input wire [63:0]         adc_address,
  output reg                adc_rd,
  input wire [127:0]        adc_data,
  input wire                adc_almost_full,
  input wire                adc_almost_empty
);



// local

  reg [127:0]               q_bar_header;
  reg [127:0]               q_bar_data;
  reg [127:0]               loaded_bar_data;

  wire [127:0]              bar_pkt_data;
  wire [7:0]                bar_pkt_type;
  wire [9:0]                bar_pkt_len;

  reg                       bar_loaded;
  reg                       bar_pend;
  reg                       bar_start;
  reg [9:0]                 bar_count;

  wire [127:0]              adc_pkt_data;
  reg [2:0]                 adc_count;


generate
  begin : gen_pci_tx

    assign s_axis_tx_tuser = 0;
    assign bar_busy = bar_start | bar_pend | bar_loaded;

    assign bar_pkt_type = q_bar_header[31:24];
    assign bar_pkt_len = q_bar_header[9:0];

    assign bar_pkt_data[31:24] = q_bar_data[7:0];
    assign bar_pkt_data[23:16] = q_bar_data[15:8];
    assign bar_pkt_data[15:8] = q_bar_data[23:16];
    assign bar_pkt_data[7:0] = q_bar_data[31:24];

    assign bar_pkt_data[63:56] = q_bar_data[39:32];
    assign bar_pkt_data[55:48] = q_bar_data[47:40];
    assign bar_pkt_data[47:40] = q_bar_data[55:48];
    assign bar_pkt_data[39:32] = q_bar_data[63:56];

    assign bar_pkt_data[95:88] = q_bar_data[71:64];
    assign bar_pkt_data[87:80] = q_bar_data[79:72];
    assign bar_pkt_data[79:72] = q_bar_data[87:80];
    assign bar_pkt_data[71:64] = q_bar_data[95:88];

    assign bar_pkt_data[127:120] = q_bar_data[103:96];
    assign bar_pkt_data[119:112] = q_bar_data[111:104];
    assign bar_pkt_data[111:104] = q_bar_data[119:112];
    assign bar_pkt_data[103:96] = q_bar_data[127:120];

    assign adc_pkt_data[31:24] = adc_data[7:0];
    assign adc_pkt_data[23:16] = adc_data[15:8];
    assign adc_pkt_data[15:8] = adc_data[23:16];
    assign adc_pkt_data[7:0] = adc_data[31:24];

    assign adc_pkt_data[63:56] = adc_data[39:32];
    assign adc_pkt_data[55:48] = adc_data[47:40];
    assign adc_pkt_data[47:40] = adc_data[55:48];
    assign adc_pkt_data[39:32] = adc_data[63:56];

    assign adc_pkt_data[95:88] = adc_data[71:64];
    assign adc_pkt_data[87:80] = adc_data[79:72];
    assign adc_pkt_data[79:72] = adc_data[87:80];
    assign adc_pkt_data[71:64] = adc_data[95:88];

    assign adc_pkt_data[127:120] = adc_data[103:96];
    assign adc_pkt_data[119:112] = adc_data[111:104];
    assign adc_pkt_data[111:104] = adc_data[119:112];
    assign adc_pkt_data[103:96] = adc_data[127:120];


    always @ ( posedge clk ) 
    begin
      if (reset)
        bar_loaded <= 0;
      else
      begin
        if (bar_wr)
        begin
          q_bar_header <= bar_header;
          loaded_bar_data <= bar_data;
          bar_loaded <= 1;
        end
        else
          if (bar_start)
            bar_loaded <= 0;
      end
    end


    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        s_axis_tx_tdata <= 0;
        s_axis_tx_tvalid <= 0;
        s_axis_tx_tlast <= 0;
        s_axis_tx_tkeep <= 0;
        bar_count <= 0;
        bar_pend <= 0;
        bar_start <= 0;
        adc_next_address <= 0;
      end
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (adc_rd)
          begin
            adc_next_address <= 0;
            adc_count <= adc_count + 1;

            s_axis_tx_tdata <= adc_pkt_data;
            s_axis_tx_tkeep[15:0] <= 16'hffff;

            if (adc_count == 3'b111)
            begin
              s_axis_tx_tlast <= 1;
              adc_rd <= 0;
            end
            else
              s_axis_tx_tlast <= 0;
          end
          else
          begin
            if (bar_pend)
            begin
              bar_pend <= 0;
              adc_next_address <= 0;

              s_axis_tx_tdata  <= bar_pkt_data;
              s_axis_tx_tlast <= 1;
 
              case (bar_count)
                0: s_axis_tx_tkeep[15:0] <= 16'h0000;
                1: s_axis_tx_tkeep[15:0] <= 16'h000f;
                2: s_axis_tx_tkeep[15:0] <= 16'h00ff;
                3: s_axis_tx_tkeep[15:0] <= 16'h0fff;
                default: s_axis_tx_tkeep[15:0] <= 16'hffff;
              endcase
            end
            else
            begin
              if (bar_start && !adc_almost_full)
              begin
                bar_start <= 0;
                adc_next_address <= 0;

                s_axis_tx_tvalid <= 1;

                if (bar_pkt_type[5] == 0)  // 3 DW header
                begin
                  if (bar_pkt_type[6] && bar_pkt_len)
                  begin
                    s_axis_tx_tdata[127:96] <= bar_pkt_data[31:0];
                    s_axis_tx_tdata[15:12] <= 4'b1111;
                    s_axis_tx_tdata[95:0] <= q_bar_header[95:0];
                    s_axis_tx_tkeep[11:0] <= 12'hfff;

                    if (bar_pkt_len > 1)
                    begin
                      s_axis_tx_tlast <= 0;
                      bar_pend <= 1;
                      bar_count <= bar_pkt_len - 1;
                      q_bar_data[95:0] <= q_bar_data[127:32];
                    end
                    else
                      s_axis_tx_tlast <= 1;
                  end
                  else
                  begin
                    s_axis_tx_tlast <= 1;
                    s_axis_tx_tdata[127:96] <= 0;
                    s_axis_tx_tkeep[15:12] <= 4'b0000;
                    s_axis_tx_tdata[95:0] <= q_bar_header[95:0];
                    s_axis_tx_tkeep[11:0] <= 12'hfff;
                  end
                end
                else
                begin
                  s_axis_tx_tdata[127:0] <= q_bar_header;
                  s_axis_tx_tkeep[15:0] <= 16'hffff;
    
                  if (bar_pkt_type[6])
                  begin
                    bar_count <= bar_pkt_len;
                    if (bar_pkt_len)
                    begin
                      s_axis_tx_tlast <= 0;
                      bar_pend <= 1;
                    end
                    else
                      s_axis_tx_tlast <= 1;
                  end
                  else
                    s_axis_tx_tlast <= 1;
                end
              end
              else
              begin
                if (!adc_almost_empty && adc_valid_address)
                begin
                  adc_rd <= 1;
                  adc_count <= 0;
                  adc_next_address <= 1;

                  s_axis_tx_tvalid <= 1;
                  s_axis_tx_tkeep[15:0] <= 16'hffff;
                  s_axis_tx_tlast <= 0;

                  s_axis_tx_tdata[127:96] <= adc_address[31:0];     // address low
                  s_axis_tx_tdata[95:64] <= adc_address[63:32];     // address high
                  s_axis_tx_tdata[63:48] <= 0;                      // Requester ID
                  s_axis_tx_tdata[47:40] <= 0;                      // tag
                  s_axis_tx_tdata[39:36] <= 4'b1111;                // last be
                  s_axis_tx_tdata[35:32] <= 4'b1111;                // 1st be
                  s_axis_tx_tdata[31:24] <= 8'b011_00000;           // Type + 64-bit FMT
                  s_axis_tx_tdata[23] <= 1'b0;                      // R
                  s_axis_tx_tdata[22:20] <= 3'b000;                 // TC
                  s_axis_tx_tdata[19:16] <= 4'b0000;                // TH, AttrH, R
                  s_axis_tx_tdata[15:12] <= 4'b0000;                // TD, EP, Attr
                  s_axis_tx_tdata[11:10] <= 2'b0;                   // AT
                  s_axis_tx_tdata[9:8] <= 2'b0;                     // len high
                  s_axis_tx_tdata[7:0] <= 8'h20;                    // 128 byte size
                end
                else
                begin
                  s_axis_tx_tvalid <= 0;
                  s_axis_tx_tdata <= 0;
                  s_axis_tx_tkeep <= 0;
                  s_axis_tx_tlast <= 0;

                  if (bar_loaded)
                  begin
                    bar_start <= 1;
                    q_bar_data <= loaded_bar_data;
                  end
                end
              end
            end
          end
        end
      end
    end


  end
endgenerate

endmodule
