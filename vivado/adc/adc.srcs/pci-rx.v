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
// pci_rx.v
// PCIe receive interface
//
////////////////////////////////////////////////////////////////////////////////

module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser,
  
  bar_data,
  bar_header,
  bar_be,
  bar_count,
  bar_sel,
  bar_valid,

  dac_data,
  dac_valid
);

  input                          clk;
  input                          reset;

  input       [127:0]            m_axis_rx_tdata;
  input       [15:0]             m_axis_rx_tkeep;
  input                          m_axis_rx_tlast;
  input                          m_axis_rx_tvalid;
  output wire                    m_axis_rx_tready;
  input       [21:0]             m_axis_rx_tuser;

  output reg  [127:0]            bar_data;
  output reg  [127:0]            bar_header;
  output reg  [15:0]             bar_be;
  output reg  [7:0]              bar_count;
  output reg  [7:0]              bar_sel;
  output reg                     bar_valid;

  output reg  [1023:0]           dac_data;
  output reg                     dac_valid;


// wires
  
  wire [63:0]    pkt_header;
  wire [7:0]     pkt_type;
  wire [7:0]     pkt_bar;
  wire [127:0]   pkt_data;
  wire [3:0]     q_bar_first_be;
  wire [3:0]     q_bar_last_be;
  wire [11:0]    q_bar_count;

// bar & dac

  reg  [7:0]     q_bar;
  reg  [7:0]     q_type;
  reg  [9:0]     q_len;

// bar

  reg  [2:0]     q_bar_shift;
  reg  [127:0]   q_bar_data;
  reg  [127:0]   q_bar_header;
  reg            q_bar_done;

// dac

  reg  [2:0]     q_dac_shift;
  reg  [1023:0]  q_dac_data;
  reg  [127:0]   q_dac_header;
  reg            q_dac_done;

	
function [15:0] first_and_last_to_be;
  input [3:0] first_be;
  input [3:0] last_be;
  input [9:0] dw_count;
  reg [4:0] count;
  reg [15:0] res;
  begin
    case (dw_count)
      0: 
      begin
        res = 0;
      end

      1:
      begin
        res[3:0] = first_be;
        res[15:4] = 0;
      end

      2:
      begin
        res[3:0] = first_be;
        res[7:4] = last_be;
        res[15:8] = 0;
      end

      3:
      begin
        res[3:0] = first_be;
        res[7:4] = 4'hf;
        res[11:8] = last_be;
        res[15:12] = 0;
      end

      4:
      begin
        res[3:0] = first_be;
        res[11:4] = 8'hff;
        res[15:12] = last_be;
      end

      default:
      begin
        res[3:0] = first_be;
        res[15:4] = 12'hfff;
      end
    endcase

    first_and_last_to_be = res;
  end
endfunction

function [3:0] count_to_first_be;
  input [1:0] base;
  input [11:0] count;
  reg [3:0] res;
  begin
    case (base)
      2'b00: 
      begin
        case (count)
          1: res = 4'b0001;
          2: res = 4'b0011;
          3: res = 4'b0111;
          default: res = 4'b1111;
        endcase
      end

      2'b01:
      begin
        case (count)
          1: res = 4'b010;
          2: res = 4'b0110;
          default: res = 4'b1110;
        endcase
      end

      2'b10:
      begin
        if (count == 1)
          res = 4'b0100;
        else
          res = 4'b1100;
      end

      2'b11:
      begin
        res = 4'b1000;
      end
    endcase

    count_to_first_be = res;
  end
endfunction

function [3:0] count_to_last_be;
  input [1:0] base;
  input [11:0] count;
  reg [3:0] res;
  reg [1:0] low;
  begin
    low = base + count[1:0];
    case (low)
      2'b00: res = 4'b1111;
      2'b01: res = 4'b0001;
      2'b10: res = 4'b0011;
      2'b11: res = 4'b0111;
    endcase

    count_to_last_be = res;
  end
endfunction

function [15:0] count_to_be;
  input [1:0] base;
  input [11:0] count;
  input [9:0] dw_count;
  reg [3:0] first_be;
  reg [3:0] last_be;
  begin
    first_be = count_to_first_be(base, count);
    last_be = count_to_last_be(base, count);
    count_to_be = first_and_last_to_be(first_be, last_be, dw_count);
  end
endfunction

function [7:0] first_be_to_count;
  input [3:0] be;
  reg [7:0] res;
  begin
    casex (be)
      4'b1xx1 : res = 4;
      4'b01x1 : res = 3;
      4'b1x10 : res = 3;
      4'b0011 : res = 2;
      4'b0110 : res = 2;
      4'b1100 : res = 2;
      4'b0001 : res = 1;
      4'b0010 : res = 1;
      4'b0100 : res = 1;
      4'b1000 : res = 1;
      4'b0000 : res = 1;
    endcase

    first_be_to_count = res;
  end
endfunction

function [7:0] last_be_to_count;
  input [3:0] be;
  reg [7:0] res;
  begin
    case (be)
      4'b1111 : res = 4;
      4'b0111 : res = 3;
      4'b0011 : res = 2;
      4'b0001 : res = 1;
      4'b0000 : res = 0;
      default: res = 4;
    endcase

    last_be_to_count = res;
  end
endfunction

function [7:0] first_and_last_to_count;
  input [3:0] first_be;
  input [3:0] last_be;
  input [9:0] dw_count;
  reg [7:0] res;
  begin
    case (dw_count)
      0: res = 0;
      1: res = first_be_to_count(first_be);
      2: res = first_be_to_count(first_be) + last_be_to_count(last_be);
      3: res = 4 + first_be_to_count(first_be) + last_be_to_count(last_be);
      4: res = 8 + first_be_to_count(first_be) + last_be_to_count(last_be);
      default: res = 0;
    endcase

    first_and_last_to_count = res;
  end
endfunction

generate
  begin : pci_rx_128

    assign m_axis_rx_tready = reset ? 0 : 1;

    assign pkt_header = m_axis_rx_tuser[13] ? m_axis_rx_tdata[127:64] : m_axis_rx_tdata[63:0];
    assign pkt_type = pkt_header[31:24];

    assign pkt_bar = m_axis_rx_tuser[14] ? m_axis_rx_tuser[9:2] : q_bar;

    assign pkt_data[31:24] = m_axis_rx_tdata[7:0];
    assign pkt_data[23:16] = m_axis_rx_tdata[15:8];
    assign pkt_data[15:8] = m_axis_rx_tdata[23:16];
    assign pkt_data[7:0] = m_axis_rx_tdata[31:24];

    assign pkt_data[63:56] = m_axis_rx_tdata[39:32];
    assign pkt_data[55:48] = m_axis_rx_tdata[47:40];
    assign pkt_data[47:40] = m_axis_rx_tdata[55:48];
    assign pkt_data[39:32] = m_axis_rx_tdata[63:56];

    assign pkt_data[95:88] = m_axis_rx_tdata[71:64];
    assign pkt_data[87:80] = m_axis_rx_tdata[79:72];
    assign pkt_data[79:72] = m_axis_rx_tdata[87:80];
    assign pkt_data[71:64] = m_axis_rx_tdata[95:88];

    assign pkt_data[127:120] = m_axis_rx_tdata[103:96];
    assign pkt_data[119:112] = m_axis_rx_tdata[111:104];
    assign pkt_data[111:104] = m_axis_rx_tdata[119:112];
    assign pkt_data[103:96] = m_axis_rx_tdata[127:120];

    assign q_bar_first_be = q_bar_header[35:32];
    assign q_bar_last_be = q_bar_header[39:36];
    assign q_bar_count = q_bar_header[43:32];


    always @ ( posedge clk ) 
    begin
      if (m_axis_rx_tvalid && m_axis_rx_tready)
      begin
        if (m_axis_rx_tuser[14])
        begin
          q_bar <= m_axis_rx_tuser[9:2];
          q_type <= pkt_type;
          q_len <= pkt_header[9:0];

          if (q_bar)
          begin
            if (m_axis_rx_tuser[13])  // dword 2
            begin
              case (q_bar_shift)
                2: q_bar_data[127:64] <= pkt_data[63:0];
                3: q_bar_data[127:96] <= pkt_data[31:0];
              endcase
            end
          end

          if (pkt_bar)
          begin
            q_bar_header[63:0] <= pkt_header;

            if (m_axis_rx_tuser[13])  // dword 2
              q_bar_shift <= 0;
            else
            begin
              if (pkt_type[5] == 0)
              begin
                q_bar_header[95:64] <= m_axis_rx_tdata[95:64];
                q_bar_header[127:96] <= 32'b0;
                q_bar_data[31:0] <= pkt_data[127:96];
                q_bar_shift <= 1;
              end
              else
              begin
                q_bar_header[127:64] <= m_axis_rx_tdata[127:64];
                q_bar_shift <= 4;
              end
            end
          end
        end
        else
        begin
          if (q_bar)
          begin
            case (q_bar_shift)
              0:
              begin
                if (q_type[5] == 0)
                begin
                  q_bar_header[95:64] <= m_axis_rx_tdata[31:0];
                  q_bar_header[127:96] <= 32'b0;
                  q_bar_data[95:0] <= pkt_data[127:32];
                  q_bar_shift <= 3;
                end
                else
                begin
                  q_bar_header[127:64] <= m_axis_rx_tdata[63:0];
                  q_bar_data[63:0] <= pkt_data[127:64];
                  q_bar_shift <= 2;
                end
              end
 
              1: q_bar_data[127:32] <= pkt_data[95:0];
              2: q_bar_data[127:64] <= pkt_data[63:0];
              3: q_bar_data[127:96] <= pkt_data[31:0];
              4: q_bar_data <= pkt_data;
            endcase
          end
        end

        if (m_axis_rx_tuser[21])
          q_bar_done <= 1;
        else
          q_bar_done <= 0;
      end
      else
      begin
        q_bar_shift <= 0;
        q_bar_done <= 0;
      end
    end


    always @ ( posedge clk ) 
    begin
      if (q_bar_done)
      begin
        if (q_type[3])
        begin
          bar_be <= count_to_be(q_bar_header[65:64], q_bar_count, q_len);
          bar_count <= q_bar_count[7:0];
        end
        else
        begin
          bar_be <= first_and_last_to_be(q_bar_first_be, q_bar_last_be, q_len);
          bar_count = first_and_last_to_count(q_bar_first_be, q_bar_last_be, q_len);
        end

        bar_sel <= q_bar;
        bar_header <= q_bar_header;
        bar_data <= q_bar_data;

        bar_valid <= 1;
      end
      else
        bar_valid <= 0;
    end


    always @ ( posedge clk ) 
    begin
      if (m_axis_rx_tvalid && m_axis_rx_tready)
      begin
        if (m_axis_rx_tuser[14])
        begin
          if (q_bar == 0)
          begin
            if (m_axis_rx_tuser[13])
            begin
              q_dac_shift <= 0;
  
              case (q_dac_shift)
                2:
                begin
                  q_dac_data[831:0] <= q_dac_data[959:128];
                  q_dac_data[959:832] <= pkt_data;
                end

                3:
                begin
                  q_dac_data[863:0] <= q_dac_data[991:128];
                  q_dac_data[991:864] <= pkt_data;
                end
              endcase
            end
          end

          if (pkt_bar == 0)
          begin
            q_dac_header[63:0] <= pkt_header;

            if (pkt_type[5] == 0)
            begin
              q_dac_header[95:64] <= m_axis_rx_tdata[95:64];
              q_dac_header[127:96] <= 32'b0;
              q_dac_data[927:896] <= pkt_data[127:96];
              q_dac_shift <= 1;
            end
            else
            begin
              q_dac_header[127:64] <= m_axis_rx_tdata[127:64];
              q_dac_shift <= 4;
            end
          end
        end
        else
        begin
          if (q_bar == 0)
          begin
            case (q_dac_shift)
              0:
              begin
                if (q_type[5] == 0)
                begin
                  q_dac_header[95:64] <= m_axis_rx_tdata[31:0];
                  q_dac_header[127:96] <= 32'b0;
                  q_dac_data[991:896] <= pkt_data[127:32];
                  q_dac_shift <= 3;
                end
                else
                begin
                  q_dac_header[127:64] <= m_axis_rx_tdata[63:0];
                  q_dac_data[959:896] <= pkt_data[127:64];
                  q_dac_shift <= 2;
                end
              end
 
              1:
              begin
                q_dac_data[799:0] <= q_dac_data[927:128];
                q_dac_data[927:800] <= pkt_data;
              end

              2:
              begin
                q_dac_data[831:0] <= q_dac_data[959:128];
                q_dac_data[959:832] <= pkt_data;
              end

              3:
              begin
                q_dac_data[863:0] <= q_dac_data[991:128];
                q_dac_data[991:864] <= pkt_data;
              end

              4:
              begin
                q_dac_data[895:0] <= q_dac_data[1023:128];
                q_dac_data[1023:896] <= pkt_data;
              end
            endcase
          end
        end

        if (m_axis_rx_tuser[21])
          q_dac_done <= 1;
        else
          q_dac_done <= 0;
      end
      else
      begin
        q_dac_shift <= 0;
        q_dac_done <= 0;
      end
    end

    always @ ( posedge clk ) 
    begin
      if (q_dac_done)
      begin
        dac_data <= q_dac_data;
        dac_valid <= 1;
      end
      else
        dac_valid <= 0;
    end

  end    
endgenerate

endmodule
