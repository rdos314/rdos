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
  clk,
  reset,
  s_axis_tx_tready,
  s_axis_tx_tdata,
  s_axis_tx_tkeep,
  s_axis_tx_tlast,
  s_axis_tx_tvalid,
  s_axis_tx_tuser,

  bar_data,
  bar_header,
  bar_wr,
  bar_busy,

  adc_full,
  adc_data,
  adc_header,
  adc_wr,
  adc_ack
);

  input                     clk;
  input                     reset;

  input                     s_axis_tx_tready;
  output wire [127:0]       s_axis_tx_tdata;
  output wire [15:0]        s_axis_tx_tkeep;
  output wire               s_axis_tx_tlast;
  output wire               s_axis_tx_tvalid;
  output wire [3:0]         s_axis_tx_tuser;

  input  wire [127:0]       bar_data;
  input  wire [127:0]       bar_header;
  input  wire               bar_wr;
  output reg                bar_busy;

  input  wire               adc_full;
  input  wire [1023:0]      adc_data;
  input  wire [127:0]       adc_header;
  input  wire               adc_wr;
  output reg                adc_ack;


// local

  reg [127:0]               q_bar_header;
  reg [127:0]               q_bar_data;
  reg [127:0]               q_adc_header;
  reg [1023:0]              q_adc_data;
  reg [1023:0]              pend_adc_data;

  wire [127:0]              bar_pkt_data;
  wire [7:0]                bar_pkt_type;
  wire [9:0]                bar_pkt_len;

  wire [127:0]              adc_pkt_data;
  wire [7:0]                adc_pkt_type;
  wire [9:0]                adc_pkt_len;

  reg                       bar_start;
  reg [9:0]                 bar_count;
  reg [127:0]               bar_tx_tdata;
  reg [15:0]                bar_tx_tkeep;
  reg                       bar_tx_tlast;
  reg                       bar_tx_tvalid;

  reg                       adc_pend_ack;
  reg                       adc_loaded;
  reg                       adc_start;
  reg [9:0]                 adc_count;
  reg [127:0]               adc_tx_tdata;
  reg [15:0]                adc_tx_tkeep;
  reg                       adc_tx_tlast;
  reg                       adc_tx_tvalid;


ila_2 ila_2_inst (
    .clk(clk),                           // input wire clk
    .probe0(adc_wr),                     // input wire [0:0]  probe0  
    .probe1(adc_ack),                    // input wire [0:0]  probe0  
    .probe2(adc_loaded),                 // input wire [0:0]  probe0  
    .probe3(adc_start),                  // input wire [0:0]  probe0  
    .probe4(adc_count),                  // input wire [9:0]  probe0  
    .probe5(adc_full),                   // input wire [0:0]  probe0  
    .probe6(s_axis_tx_tready),           // input wire [0:0]  probe0  
    .probe7(s_axis_tx_tvalid),           // input wire [0:0]  probe0  
    .probe8(s_axis_tx_tlast),            // input wire [0:0]  probe0  
    .probe9(bar_tx_tvalid),              // input wire [0:0]  probe0  
    .probe10(bar_tx_tlast),              // input wire [0:0]  probe0  
    .probe11(bar_start)                  // input wire [0:0]  probe0  
 );

generate
  begin : gen_pci_tx

    assign s_axis_tx_tdata = adc_tx_tvalid ? adc_tx_tdata : (bar_tx_tvalid ? bar_tx_tdata : 0);
    assign s_axis_tx_tkeep = adc_tx_tvalid ? adc_tx_tkeep : (bar_tx_tvalid ? bar_tx_tkeep : 0);
    assign s_axis_tx_tlast = adc_tx_tvalid ? adc_tx_tlast : (bar_tx_tvalid ? bar_tx_tlast : 0);
    assign s_axis_tx_tvalid = adc_tx_tvalid || bar_tx_tvalid;
    assign s_axis_tx_tuser = 0;

    assign bar_pkt_type = q_bar_header[31:24];
    assign bar_pkt_len = q_bar_header[9:0];

    assign adc_pkt_type = q_adc_header[31:24];
    assign adc_pkt_len = q_adc_header[9:0];

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

    assign adc_pkt_data[31:24] = q_adc_data[7:0];
    assign adc_pkt_data[23:16] = q_adc_data[15:8];
    assign adc_pkt_data[15:8] = q_adc_data[23:16];
    assign adc_pkt_data[7:0] = q_adc_data[31:24];

    assign adc_pkt_data[63:56] = q_adc_data[39:32];
    assign adc_pkt_data[55:48] = q_adc_data[47:40];
    assign adc_pkt_data[47:40] = q_adc_data[55:48];
    assign adc_pkt_data[39:32] = q_adc_data[63:56];

    assign adc_pkt_data[95:88] = q_adc_data[71:64];
    assign adc_pkt_data[87:80] = q_adc_data[79:72];
    assign adc_pkt_data[79:72] = q_adc_data[87:80];
    assign adc_pkt_data[71:64] = q_adc_data[95:88];

    assign adc_pkt_data[127:120] = q_adc_data[103:96];
    assign adc_pkt_data[119:112] = q_adc_data[111:104];
    assign adc_pkt_data[111:104] = q_adc_data[119:112];
    assign adc_pkt_data[103:96] = q_adc_data[127:120];

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        bar_tx_tvalid <= 0;
        bar_tx_tlast <= 0;
        bar_tx_tkeep <= 0;
        bar_count <= 0;
        bar_start <= 0;
        bar_busy <= 0;
      end
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (bar_tx_tvalid && !bar_tx_tlast)
          begin
            bar_tx_tdata <= bar_pkt_data;
            bar_tx_tlast <= 1;
            bar_busy <= 0;
 
            case (bar_count)
              0: bar_tx_tkeep[15:0] <= 16'h0000;
              1: bar_tx_tkeep[15:0] <= 16'h000f;
              2: bar_tx_tkeep[15:0] <= 16'h00ff;
              3: bar_tx_tkeep[15:0] <= 16'h0fff;
              default: bar_tx_tkeep[15:0] <= 16'hffff;
            endcase
          end
          else
          begin
            if (bar_start && !adc_tx_tvalid)
            begin
              bar_tx_tvalid <= 1;
              bar_start <= 0;

              if (bar_pkt_type[5] == 0)  // 3 DW header
              begin
                if (bar_pkt_type[6] && bar_pkt_len)
                begin
                  bar_tx_tdata[127:96] <= bar_pkt_data[31:0];
                  bar_tx_tkeep[15:12] <= 4'b1111;
                  bar_tx_tdata[95:0] <= q_bar_header[95:0];
                  bar_tx_tkeep[11:0] <= 12'hfff;

                  if (bar_pkt_len > 1)
                  begin
                    bar_tx_tlast <= 0;
                    bar_count <= bar_pkt_len - 1;
                    q_bar_data[95:0] <= q_bar_data[127:32];
                  end
                  else
                  begin
                    bar_tx_tlast <= 1;
                    bar_busy <= 0;
                  end
                end
                else
                begin
                  bar_tx_tdata[127:96] <= 0;
                  bar_tx_tkeep[15:12] <= 4'b0000;
                  bar_tx_tdata[95:0] <= q_bar_header[95:0];
                  bar_tx_tkeep[11:0] <= 12'hfff;
                  bar_tx_tlast <= 1;
                  bar_busy <= 0;
                end
              end
              else
              begin
                bar_tx_tdata[127:0] <= q_bar_header;
                bar_tx_tkeep[15:0] <= 16'hffff;
    
                if (bar_pkt_type[6])
                begin
                  bar_count <= bar_pkt_len;
                  if (bar_pkt_len)
                    bar_tx_tlast <= 0;
                  else
                  begin
                    bar_tx_tlast <= 1;
                    bar_busy <= 0;
                  end
                end
                else
                begin
                  bar_tx_tlast <= 1;
                  bar_busy <= 0;
                end
              end
            end
            else
            begin
              bar_tx_tvalid <= 0;
              if (bar_wr)
              begin
                q_bar_header <= bar_header;
                q_bar_data <= bar_data;
                bar_busy <= 1;
                bar_start <= 1;
              end
            end
          end                
        end
      end
    end

    always @ ( posedge clk ) 
    begin
      if (reset)
      begin
        adc_tx_tvalid <= 0;
        adc_tx_tlast <= 0;
        adc_tx_tkeep <= 0;
        adc_count <= 0;
        adc_start <= 0;
        adc_loaded <= 0;
        adc_pend_ack <= 0;
        adc_ack <= 0;
      end
      else
      begin
        if (s_axis_tx_tready)
        begin
          if (adc_tx_tvalid && !adc_tx_tlast)
          begin
            adc_pend_ack <= 0;
            if (adc_pend_ack)
              adc_ack <= 1;
            else
              adc_ack <= 0;

            adc_tx_tdata <= adc_pkt_data;

            if (adc_count > 4)
            begin
              adc_tx_tlast <= 0;
              adc_count <= adc_count - 4;
              q_adc_data[895:0] <= q_adc_data[1023:128];

              if (adc_wr)
              begin
                q_adc_header <= adc_header;
                pend_adc_data <= adc_data;
                adc_loaded <= 1;
              end
            end
            else
            begin
              adc_tx_tlast <= 1;
              adc_loaded <= 0;

              if (adc_wr)
              begin
                q_adc_header <= adc_header;
                q_adc_data <= adc_data;
                adc_start <= 1;
              end
              else
              begin
                if (adc_loaded)
                begin
                  q_adc_data <= pend_adc_data;
                  adc_start <= 1;
                end
              end
            end

            case (adc_count)
              0: adc_tx_tkeep[15:0] <= 16'h0000;
              1: adc_tx_tkeep[15:0] <= 16'h000f;
              2: adc_tx_tkeep[15:0] <= 16'h00ff;
              3: adc_tx_tkeep[15:0] <= 16'h0fff;
              default: adc_tx_tkeep[15:0] <= 16'hffff;
            endcase
          end
          else
          begin
            adc_ack <= 0;

            if (adc_start && !bar_start && !bar_tx_tvalid)
            begin
              adc_pend_ack <= 1;
              adc_start <= 0;

              if (adc_wr)
              begin
                q_adc_header <= adc_header;
                pend_adc_data <= adc_data;
                adc_loaded <= 1;
              end

              adc_tx_tvalid <= 1;
              adc_tx_tkeep[15:0] <= 16'hffff;
              adc_tx_tlast <= 0;

              if (adc_pkt_type[5] == 0)  // 3 DW header
              begin
                adc_tx_tdata[127:96] <= adc_pkt_data[31:0];
                adc_tx_tdata[95:0] <= q_adc_header[95:0];
                adc_count <= adc_pkt_len - 1;
                q_adc_data[991:0] <= q_adc_data[1023:32];
              end
              else
              begin
                adc_tx_tdata[127:0] <= q_adc_header;
                adc_count <= adc_pkt_len;
              end
            end
            else
            begin
              adc_tx_tvalid <= 0;
              adc_loaded <= 0;

              if (adc_wr)
              begin
                q_adc_header <= adc_header;
                q_adc_data <= adc_data;
                adc_start <= 1;
              end
              else
              begin
                if (adc_loaded)
                begin
                  q_adc_data <= pend_adc_data;
                  adc_start <= 1;
                end
              end
            end
          end                
        end
        else
        begin
          adc_ack <= 0;

          if (adc_wr)
          begin
            q_adc_header <= adc_header;
            pend_adc_data <= adc_data;
            adc_loaded <= 1;
          end
        end
      end
    end

  end
endgenerate

endmodule
