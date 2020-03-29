module pci_rx (
  clk,
  reset,
  m_axis_rx_tdata,
  m_axis_rx_tkeep,
  m_axis_rx_tlast,
  m_axis_rx_tvalid,
  m_axis_rx_tready,
  m_axis_rx_tuser,
  
  pci_rx_data,
  pci_rx_header,
  pci_rx_be,
  pci_rx_control,
  pci_rx_rd,
  pci_rx_empty,
  pci_rx_full
);

  input                          clk;
  input                          reset;

  input       [127:0]            m_axis_rx_tdata;
  input       [15:0]             m_axis_rx_tkeep;
  input                          m_axis_rx_tlast;
  input                          m_axis_rx_tvalid;
  output reg                     m_axis_rx_tready;
  input       [21:0]             m_axis_rx_tuser;

  output wire [1023:0]           pci_rx_data;
  output wire [127:0]            pci_rx_header;
  output wire [127:0]            pci_rx_be;
  output wire [15:0]             pci_rx_control;
  input  wire                    pci_rx_rd;
  output wire                    pci_rx_empty;
  output wire                    pci_rx_full;

// FF

  reg  [1023:0]  q_pkt_data;
  reg  [2:0]     q_shift_pos;
  reg            q_pkt_done;
  reg  [3:0]     q_count;
  reg  [127:0]   q_pkt_header;
  reg  [7:0]     q_pkt_type;
  reg  [9:0]     q_pkt_len;

  reg            q_rx_wr;
  reg  [127:0]   q_rx_be;
  reg  [15:0]    q_rx_control;
  reg  [1023:0]  q_rx_data;

  wire [127:0]   pkt_data;
  wire [63:0]    pkt_header;
  wire [7:0]     pkt_type;
  wire [3:0]     q_pkt_first_be;
  wire [3:0]     q_pkt_last_be;
  wire [11:0]    q_pkt_count;

fifo_data pci_rx_data_inst (
  .clk(clk),             // input wire clk
  .din(q_rx_data),       // input wire [1023 : 0] din
  .wr_en(q_rx_wr),       // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_data),    // output wire [1023 : 0] dout
  .full(pci_rx_full),    // output wire full
  .empty(pci_rx_empty)   // output wire empty
);

fifo_header pci_rx_header_inst (
  .clk(clk),             // input wire clk
  .din(q_pkt_header),    // input wire [127 : 0] din
  .wr_en(q_rx_wr),       // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_header),  // output wire [127 : 0] dout
  .full(),               // output wire full
  .empty()               // output wire empty
);

fifo_be pci_rx_be_inst (
  .clk(clk),             // input wire clk
  .din(q_rx_be),         // input wire [127 : 0] din
  .wr_en(q_rx_wr),       // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_be),      // output wire [127 : 0] dout
  .full(),               // output wire full
  .empty()               // output wire empty
);

fifo_control pci_rx_control_inst (
  .clk(clk),             // input wire clk
  .din(q_rx_control),    // input wire [15 : 0] din
  .wr_en(q_rx_wr),       // input wire wr_en
  .rd_en(pci_rx_rd),     // input wire rd_en
  .dout(pci_rx_control), // output wire [15 : 0] dout
  .full(),               // output wire full
  .empty()               // output wire empty
);

ila_0 ila_0_inst (
	.clk(clk),                         // input wire clk
	.probe0(m_axis_rx_tvalid),         // input wire [0:0]  probe0  
	.probe1(m_axis_rx_tready),         // input wire [0:0]  probe0  
	.probe2(m_axis_rx_tuser[13]),      // input wire [0:0]  probe0  
	.probe3(m_axis_rx_tuser[14]),      // input wire [0:0]  probe0  
	.probe4(m_axis_rx_tuser[21]),      // input wire [0:0]  probe0  
	.probe5(m_axis_rx_tdata[63:0]),    // input wire [63:0]  probe0  
	.probe6(m_axis_rx_tdata[127:64]),  // input wire [63:0]  probe0  
	.probe7(q_shift_pos),              // input wire [2:0]  probe0  
	.probe8(q_pkt_done),               // input wire [0:0]  probe0  
	.probe9(q_rx_wr),                  // input wire [0:0]  probe0  
	.probe10(q_pkt_header),            // input wire [127:0]  probe0  
	.probe11(q_pkt_type),              // input wire [7:0]  probe0  
	.probe12(q_pkt_len),               // input wire [9:0]  probe0  
	.probe13(q_rx_be[63:0]),           // input wire [63:0]  probe0  
	.probe14(q_rx_control),            // input wire [15:0]  probe0  
	.probe15(q_rx_data[63:0]),         // input wire [63:0]  probe0  
	.probe16(q_rx_data[127:64]),       // input wire [63:0]  probe0  
	.probe17(q_pkt_data[895:768]),     // input wire [127:0]  probe0  
	.probe18(q_pkt_data[1023:896]),    // input wire [127:0]  probe0  
	.probe19(pci_rx_data[63:0]),       // input wire [63:0]  probe0  
	.probe20(pci_rx_data[127:64]),     // input wire [63:0]  probe0  
	.probe21(pci_rx_header[63:0]),     // input wire [63:0]  probe0  
	.probe22(pci_rx_header[127:64]),   // input wire [63:0]  probe0  
	.probe23(pci_rx_be[63:0]),         // input wire [63:0]  probe0  
	.probe24(pci_rx_control[15:0]),    // input wire [15:0]  probe0  
	.probe25(pci_rx_rd),               // input wire [0:0]  probe0  
	.probe26(pci_rx_empty)             // input wire [0:0]  probe0  
);
	
function [127:0] first_and_last_to_be;
  input [3:0] first_be;
  input [3:0] last_be;
  input [9:0] dw_count;
  reg [4:0] count;
  reg [127:0] res;
  begin
    case (dw_count)
      0: 
      begin
        res = 0;
      end

      1:
      begin
        res[3:0] = first_be;
        res[127:4] = 0;
      end

      2:
      begin
        res[3:0] = first_be;
        res[7:4] = last_be;
        res[127:8] = 0;
      end

      3:
      begin
        res[3:0] = first_be;
        res[7:4] = {4{1'b1}};
        res[11:8] = last_be;
        res[127:12] = 0;
      end

      4:
      begin
        res[3:0] = first_be;
        res[11:4] = {8{1'b1}};
        res[15:8] = last_be;
        res[127:16] = 0;
      end

      5:
      begin
        res[3:0] = first_be;
        res[15:4] = {12{1'b1}};
        res[19:16] = last_be;
        res[127:20] = 0;
      end

      6:
      begin
        res[3:0] = first_be;
        res[20:4] = {16{1'b1}};
        res[23:20] = last_be;
        res[127:24] = 0;
      end

      7:
      begin
        res[3:0] = first_be;
        res[23:4] = {20{1'b1}};
        res[27:24] = last_be;
        res[127:28] = 0;
      end

      8:
      begin
        res[3:0] = first_be;
        res[27:4] = {24{1'b1}};
        res[31:28] = last_be;
        res[127:32] = 0;
      end

      9:
      begin
        res[3:0] = first_be;
        res[31:4] = {28{1'b1}};
        res[35:32] = last_be;
        res[127:36] = 0;
      end

      10:
      begin
        res[3:0] = first_be;
        res[35:4] = {32{1'b1}};
        res[39:36] = last_be;
        res[127:40] = 0;
      end

      11:
      begin
        res[3:0] = first_be;
        res[39:4] = {36{1'b1}};
        res[43:40] = last_be;
        res[127:44] = 0;
      end

      12:
      begin
        res[3:0] = first_be;
        res[43:4] = {40{1'b1}};
        res[47:44] = last_be;
        res[127:48] = 0;
      end

      13:
      begin
        res[3:0] = first_be;
        res[47:4] = {44{1'b1}};
        res[51:48] = last_be;
        res[127:52] = 0;
      end

      14:
      begin
        res[3:0] = first_be;
        res[51:4] = {48{1'b1}};
        res[55:52] = last_be;
        res[127:56] = 0;
      end

      15:
      begin
        res[3:0] = first_be;
        res[55:4] = {52{1'b1}};
        res[59:56] = last_be;
        res[127:60] = 0;
      end

      16:
      begin
        res[3:0] = first_be;
        res[59:4] = {56{1'b1}};
        res[63:60] = last_be;
        res[127:64] = 0;
      end

      17:
      begin
        res[3:0] = first_be;
        res[63:4] = {60{1'b1}};
        res[67:64] = last_be;
        res[127:68] = 0;
      end

      18:
      begin
        res[3:0] = first_be;
        res[67:4] = {64{1'b1}};
        res[71:68] = last_be;
        res[127:72] = 0;
      end

      19:
      begin
        res[3:0] = first_be;
        res[71:4] = {68{1'b1}};
        res[75:72] = last_be;
        res[127:76] = 0;
      end

      20:
      begin
        res[3:0] = first_be;
        res[75:4] = {72{1'b1}};
        res[79:76] = last_be;
        res[127:80] = 0;
      end

      21:
      begin
        res[3:0] = first_be;
        res[79:4] = {76{1'b1}};
        res[83:80] = last_be;
        res[127:84] = 0;
      end
      
      22:
      begin
        res[3:0] = first_be;
        res[83:4] = {80{1'b1}};
        res[87:84] = last_be;
        res[127:88] = 0;
      end
      
      23:
      begin
        res[3:0] = first_be;
        res[87:4] = {84{1'b1}};
        res[91:88] = last_be;
        res[127:92] = 0;
      end
      
      24:
      begin
        res[3:0] = first_be;
        res[91:4] = {88{1'b1}};
        res[95:92] = last_be;
        res[127:96] = 0;
      end
      
      25:
      begin
        res[3:0] = first_be;
        res[95:4] = {92{1'b1}};
        res[99:96] = last_be;
        res[127:100] = 0;
      end
      
      26:
      begin
        res[3:0] = first_be;
        res[99:4] = {96{1'b1}};
        res[103:100] = last_be;
        res[127:104] = 0;
      end
      
      27:
      begin
        res[3:0] = first_be;
        res[103:4] = {100{1'b1}};
        res[107:104] = last_be;
        res[127:108] = 0;
      end
      
      28:
      begin
        res[3:0] = first_be;
        res[107:4] = {104{1'b1}};
        res[111:108] = last_be;
        res[127:112] = 0;
      end
      
      29:
      begin
        res[3:0] = first_be;
        res[111:4] = {108{1'b1}};
        res[115:112] = last_be;
        res[127:116] = 0;
      end
      
      30:
      begin
        res[3:0] = first_be;
        res[115:4] = {112{1'b1}};
        res[119:116] = last_be;
        res[127:120] = 0;
      end
      
      31:
      begin
        res[3:0] = first_be;
        res[119:4] = {116{1'b1}};
        res[123:120] = last_be;
        res[127:124] = 0;
      end
      
      32:
      begin
        res[3:0] = first_be;
        res[123:4] = {120{1'b1}};
        res[127:124] = last_be;
      end

      default:
      begin
        res[3:0] = first_be;
        res[127:4] = {124{1'b1}};
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

function [127:0] count_to_be;
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
      default:
      begin
        if (dw_count < 32)
          res = first_be_to_count(first_be) + last_be_to_count(last_be) + 4 * (dw_count[5:0] - 2);
        else
          res = first_be_to_count(first_be) + 4 * (dw_count[5:0] - 1);
      end
    endcase

    first_and_last_to_count = res;
  end
endfunction

generate
  begin : pci_rx_128

    always @ (reset or pci_rx_full ) 
    begin
      if (reset )
        m_axis_rx_tready = 0;
      else
      begin      
        if (pci_rx_full)
          m_axis_rx_tready = 0;
        else
          m_axis_rx_tready = 1;
      end
    end

    assign pkt_header = m_axis_rx_tuser[13] ? m_axis_rx_tdata[127:64] : m_axis_rx_tdata[63:0];
    assign pkt_type = pkt_header[31:24];
    assign q_pkt_first_be = q_pkt_header[35:32];
    assign q_pkt_last_be = q_pkt_header[39:36];
    assign q_pkt_count = q_pkt_header[43:32];

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

    always @ ( posedge clk ) 
    begin
      if (m_axis_rx_tvalid && m_axis_rx_tready && !reset)
      begin
        if (m_axis_rx_tuser[14])
        begin
          q_pkt_header[63:0] <= pkt_header;
          q_pkt_type <= pkt_type;
          q_pkt_len <= pkt_header[9:0];
          q_rx_control[15:8] <= m_axis_rx_tuser[9:2];

          if (m_axis_rx_tuser[13])
          begin
            q_shift_pos <= 0;

            case (q_shift_pos)
              2:
              begin
                q_pkt_data[831:0] <= q_pkt_data[959:128];
                q_pkt_data[959:832] <= pkt_data;
                q_count <= q_count + 1;
              end

              3:
              begin
                q_pkt_data[863:0] <= q_pkt_data[991:128];
                q_pkt_data[991:864] <= pkt_data;
                q_count <= q_count + 1;
              end
            endcase
          end
          else
          begin
            if (pkt_type[5] == 0)
            begin
              q_pkt_header[95:64] <= m_axis_rx_tdata[95:64];
              q_pkt_header[127:96] <= 32'b0;
              q_pkt_data[927:896] <= pkt_data[127:96];
              q_shift_pos <= 1;
              q_count <= 1;
            end
            else
            begin
              q_pkt_header[127:64] <= m_axis_rx_tdata[127:64];
              q_shift_pos <= 4;
              q_count <= 0;
            end
          end
        end
        else
        begin
          case (q_shift_pos)
            0:
            begin
              if (q_pkt_type[5] == 0)
              begin
                q_pkt_header[95:64] <= m_axis_rx_tdata[31:0];
                q_pkt_header[127:96] <= 32'b0;
                q_pkt_data[991:896] <= pkt_data[127:32];
                q_shift_pos <= 3;
                q_count <= 1;
              end
              else
              begin
                q_pkt_header[127:64] <= m_axis_rx_tdata[63:0];
                q_pkt_data[959:896] <= pkt_data[127:64];
                q_shift_pos <= 2;
                q_count <= 1;
              end
            end
 
            1:
            begin
              q_pkt_data[799:0] <= q_pkt_data[927:128];
              q_pkt_data[927:800] <= pkt_data;
              q_count <= q_count + 1;
            end

            2:
            begin
              q_pkt_data[831:0] <= q_pkt_data[959:128];
              q_pkt_data[959:832] <= pkt_data;
              q_count <= q_count + 1;
            end

            3:
            begin
              q_pkt_data[863:0] <= q_pkt_data[991:128];
              q_pkt_data[991:864] <= pkt_data;
              q_count <= q_count + 1;
            end

            4:
            begin
              q_pkt_data[895:0] <= q_pkt_data[1023:128];
              q_pkt_data[1023:896] <= pkt_data;
              q_count <= q_count + 1;
            end
          endcase
        end

        if (m_axis_rx_tuser[21])
          q_pkt_done <= 1;
        else
          q_pkt_done <= 0;
      end
      else
      begin
        q_count <= 0;
        q_shift_pos <= 0;
        q_pkt_done <= 0;
      end
    end

    always @ ( posedge clk ) 
    begin
      if (q_pkt_done)
      begin
        if (q_pkt_type[3])
        begin
          q_rx_be <= count_to_be(q_pkt_header[65:64], q_pkt_count, q_pkt_len);
          q_rx_control[7:0] <= q_pkt_count[7:0];
        end
        else
        begin
          q_rx_be <= first_and_last_to_be(q_pkt_first_be, q_pkt_last_be, q_pkt_len);
          q_rx_control[7:0] = first_and_last_to_count(q_pkt_first_be, q_pkt_last_be, q_pkt_len);
        end

        case (q_count)
          1: q_rx_data[127:0] <= q_pkt_data[1023:896];
          2: q_rx_data[255:0] <= q_pkt_data[1023:768];
          3: q_rx_data[383:0] <= q_pkt_data[1023:640];
          4: q_rx_data[511:0] <= q_pkt_data[1023:512];
          5: q_rx_data[639:0] <= q_pkt_data[1023:384];
          6: q_rx_data[767:0] <= q_pkt_data[1023:256];
          7: q_rx_data[895:0] <= q_pkt_data[1023:128];
          default: q_rx_data <= q_pkt_data;
        endcase

        q_rx_wr <= 1;
      end
      else
        q_rx_wr <= 0;
    end

  end    
endgenerate

endmodule
